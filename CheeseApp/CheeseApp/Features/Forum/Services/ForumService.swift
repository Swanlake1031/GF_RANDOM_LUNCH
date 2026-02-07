//
//  ForumService.swift
//  CheeseApp
//
//  💬 论坛服务
//  处理论坛帖子的 CRUD 操作
//

import Foundation
import Supabase

// MARK: - UI 论坛帖子模型
struct ForumPostItem: Identifiable, Hashable {
    let id: UUID
    let authorId: UUID?
    let title: String
    let content: String
    let category: ForumCategory
    let authorName: String
    let isAnonymous: Bool
    let timeAgo: String
    var likes: Int
    var comments: Int
    let views: Int
    let tags: [String]
    var isLiked: Bool
    let isPinned: Bool
    let highlightType: PostHighlightType
    let imageUrls: [String]
    let hasImage: Bool

    static func == (lhs: ForumPostItem, rhs: ForumPostItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ForumCommentItem: Identifiable, Hashable {
    let id: UUID
    let postId: UUID
    let userId: UUID
    let parentId: UUID?
    let content: String
    let isAnonymous: Bool
    let likeCount: Int
    let createdAt: Date
    let timeAgo: String
    let authorName: String
    let authorAvatar: String?
}

// MARK: - 论坛服务
@MainActor
class ForumService: ObservableObject {

    static let shared = ForumService()

    private let supabase = SupabaseManager.shared

    @Published var posts: [ForumPostItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {}

    // MARK: - 获取所有论坛帖子
    func fetchPosts() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let dbPosts: [DBForumPost] = try await supabase
                .database("forum_posts_view")
                .select()
                .order("highlight_rank", ascending: true)
                .order("hot_score", ascending: false)
                .order("created_at", ascending: false)
                .execute()
                .value

            let reactionStates = await PostReactionService.shared.fetchStates(postIds: dbPosts.map(\.id))
            posts = dbPosts.map { convertToUIModel($0, reaction: reactionStates[$0.id]) }
            print("✅ 获取到 \(posts.count) 个论坛帖子")
        } catch {
            let nsError = error as NSError
            if error is CancellationError || (nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) {
                return
            }
            errorMessage = "加载失败: \(error.localizedDescription)"
            print("❌ 获取论坛帖子失败: \(error)")
        }
    }

    // MARK: - 获取单个帖子
    func fetchPost(postId: UUID) async throws -> ForumPostItem {
        let dbPost: DBForumPost = try await supabase
            .database("forum_posts_view")
            .select()
            .eq("id", value: postId.uuidString)
            .single()
            .execute()
            .value

        let reactionState = await PostReactionService.shared.fetchStates(postIds: [dbPost.id])[dbPost.id]
        let item = convertToUIModel(dbPost, reaction: reactionState)
        upsertLocalPost(item)
        return item
    }

    // MARK: - 获取评论
    func fetchComments(postId: UUID) async throws -> [ForumCommentItem] {
        let rows: [DBCommentRow] = try await supabase
            .database("comments")
            .select()
            .eq("post_id", value: postId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value

        let userIds = Array(Set(rows.filter { !$0.isAnonymous }.map(\.userId)))
        var profileMap: [UUID: DBProfileLite] = [:]

        if !userIds.isEmpty {
            let idFilters = userIds.map { $0 as any PostgrestFilterValue }
            let profiles: [DBProfileLite] = try await supabase
                .database("profiles")
                .select("id,full_name,avatar_url,email")
                .`in`("id", values: idFilters)
                .execute()
                .value
            profileMap = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })
        }

        return rows.map { row in
            let profile = profileMap[row.userId]
            let authorName: String = {
                if row.isAnonymous { return "Anonymous" }
                if let fullName = profile?.fullName, !fullName.isEmpty { return fullName }
                if let email = profile?.email, let localPart = email.split(separator: "@").first, !localPart.isEmpty {
                    return String(localPart)
                }
                return "User"
            }()

            return ForumCommentItem(
                id: row.id,
                postId: row.postId,
                userId: row.userId,
                parentId: row.parentId,
                content: row.content,
                isAnonymous: row.isAnonymous,
                likeCount: row.likeCount,
                createdAt: row.createdAt,
                timeAgo: formatTimeAgo(row.createdAt),
                authorName: authorName,
                authorAvatar: row.isAnonymous ? nil : profile?.avatarUrl
            )
        }
    }

    // MARK: - 点赞 / 取消点赞
    func toggleLike(postId: UUID, currentlyLiked: Bool) async throws -> Bool {
        let newLiked = try await PostReactionService.shared.toggle(postId: postId, currentlyLiked: currentlyLiked)
        updateLocalLikeState(postId: postId, isLiked: newLiked)
        return newLiked
    }

    // MARK: - 发布评论
    func createComment(postId: UUID, content: String, isAnonymous: Bool) async throws {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userId: UUID
        do {
            userId = try await AuthService.shared.requireAuthUserId()
        } catch {
            await AuthService.shared.checkSession()
            throw NSError(
                domain: "",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: L10n.tr("Please sign in before commenting", "請先登入後再評論")]
            )
        }

        try await supabase
            .database("comments")
            .insert(CommentInsert(postId: postId, userId: userId, content: trimmed, isAnonymous: isAnonymous))
            .execute()

        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].comments += 1
        }
    }

    // MARK: - 转换模型
    private func convertToUIModel(_ dbPost: DBForumPost, reaction: PostReactionState?) -> ForumPostItem {
        let category: ForumCategory = {
            let tags = dbPost.tags ?? []
            if tags.contains(where: { $0.localizedCaseInsensitiveContains("meme") || $0 == "八卦" }) {
                return .meme
            }

            switch dbPost.category.lowercased() {
            case "question": return .question
            case "confession", "rant", "love": return .confession
            default: return .discussion
            }
        }()

        let authorName = dbPost.isAnonymous
            ? L10n.tr("Anonymous", "匿名")
            : (dbPost.userName ?? L10n.tr("Unknown", "未知用戶"))

        return ForumPostItem(
            id: dbPost.id,
            authorId: dbPost.isAnonymous ? nil : dbPost.userId,
            title: dbPost.title,
            content: dbPost.description ?? "",
            category: category,
            authorName: authorName,
            isAnonymous: dbPost.isAnonymous,
            timeAgo: formatTimeAgo(dbPost.createdAt),
            likes: reaction?.likeCount ?? dbPost.likeCount ?? 0,
            comments: dbPost.commentCount ?? 0,
            views: dbPost.viewCount ?? 0,
            tags: dbPost.tags ?? [],
            isLiked: reaction?.isLiked ?? false,
            isPinned: dbPost.isPinned ?? false,
            highlightType: PostHighlightType(rawValue: dbPost.highlightType),
            imageUrls: dbPost.images?.map(\.url) ?? [],
            hasImage: !(dbPost.images?.isEmpty ?? true)
        )
    }

    private func updateLocalLikeState(postId: UUID, isLiked: Bool) {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else { return }
        posts[index].isLiked = isLiked
        let delta = isLiked ? 1 : -1
        posts[index].likes = max(posts[index].likes + delta, 0)
    }

    private func upsertLocalPost(_ post: ForumPostItem) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index] = post
        } else {
            posts.insert(post, at: 0)
        }
    }

    private func formatTimeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        else if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        else { return "\(Int(interval / 86400))d ago" }
    }
}

// MARK: - 数据库论坛帖子模型（forum_posts_view）
struct DBForumPost: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let title: String
    let description: String?
    let category: String
    let tags: [String]?
    let isAnonymous: Bool
    let isPinned: Bool?
    let likeCount: Int?
    let commentCount: Int?
    let viewCount: Int?
    let highlightType: String?
    let hotScore: Double?
    let highlightRank: Int?
    let createdAt: Date
    let userName: String?
    let images: [DBForumImage]?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case category
        case tags
        case isAnonymous = "is_anonymous"
        case isPinned = "is_pinned"
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case viewCount = "view_count"
        case highlightType = "highlight_type"
        case hotScore = "hot_score"
        case highlightRank = "highlight_rank"
        case createdAt = "created_at"
        case userName = "user_name"
        case images
    }
}

struct DBForumImage: Codable {
    let id: UUID?
    let url: String
    let orderIndex: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case orderIndex = "order_index"
    }
}

struct DBCommentRow: Codable, Identifiable {
    let id: UUID
    let postId: UUID
    let userId: UUID
    let parentId: UUID?
    let content: String
    let isAnonymous: Bool
    let likeCount: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case parentId = "parent_id"
        case content
        case isAnonymous = "is_anonymous"
        case likeCount = "like_count"
        case createdAt = "created_at"
    }
}

struct DBProfileLite: Codable {
    let id: UUID
    let fullName: String?
    let avatarUrl: String?
    let email: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case email
    }
}

struct CommentInsert: Encodable {
    let postId: UUID
    let userId: UUID
    let content: String
    let isAnonymous: Bool

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case userId = "user_id"
        case content
        case isAnonymous = "is_anonymous"
    }
}
