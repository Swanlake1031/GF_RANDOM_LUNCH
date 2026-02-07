//
//  TeamService.swift
//  CheeseApp
//
//  👥 组队服务
//  处理组队帖子的 CRUD 操作
//

import Foundation
import Supabase

// MARK: - UI 组队模型
struct TeamItem: Identifiable, Hashable {
    let id: UUID
    let creatorId: UUID
    let title: String
    let description: String
    let category: TeamCategory
    let currentMembers: Int
    let maxMembers: Int
    let skills: [String]
    let deadline: Date?
    let creatorName: String
    let creatorAvatar: String?
    let imageUrl: String?
    var likeCount: Int
    var isLiked: Bool
    let highlightType: PostHighlightType
    let isUrgent: Bool

    static func == (lhs: TeamItem, rhs: TeamItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - 组队服务
@MainActor
class TeamService: ObservableObject {

    static let shared = TeamService()

    private let supabase = SupabaseManager.shared

    @Published var teams: [TeamItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {}

    // MARK: - 获取所有组队帖子
    func fetchTeams() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let dbPosts: [DBTeamPost] = try await supabase
                .database("team_posts_view")
                .select()
                .order("highlight_rank", ascending: true)
                .order("hot_score", ascending: false)
                .order("created_at", ascending: false)
                .execute()
                .value

            let imageMap = try await fetchFirstImageMap(postIds: dbPosts.map(\.id))
            let reactionStates = await PostReactionService.shared.fetchStates(postIds: dbPosts.map(\.id))
            teams = dbPosts.map {
                convertToUIModel($0, reaction: reactionStates[$0.id], imageUrl: imageMap[$0.id])
            }
            print("✅ 获取到 \(teams.count) 个组队帖子")
        } catch {
            let nsError = error as NSError
            if error is CancellationError || (nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) {
                return
            }
            errorMessage = "加载失败: \(error.localizedDescription)"
            print("❌ 获取组队帖子失败: \(error)")
        }
    }

    func toggleLike(postId: UUID, currentlyLiked: Bool) async throws -> Bool {
        let newLiked = try await PostReactionService.shared.toggle(postId: postId, currentlyLiked: currentlyLiked)
        if let index = teams.firstIndex(where: { $0.id == postId }) {
            teams[index].isLiked = newLiked
            let delta = newLiked ? 1 : -1
            teams[index].likeCount = max(teams[index].likeCount + delta, 0)
        }
        return newLiked
    }

    func fetchTeam(postId: UUID) async throws -> TeamItem {
        let row: DBTeamPost = try await supabase
            .database("team_posts_view")
            .select()
            .eq("id", value: postId.uuidString)
            .single()
            .execute()
            .value

        let imageMap = try await fetchFirstImageMap(postIds: [row.id])
        let reaction = await PostReactionService.shared.fetchStates(postIds: [row.id])[row.id]
        return convertToUIModel(row, reaction: reaction, imageUrl: imageMap[row.id])
    }

    // MARK: - 转换模型
    private func convertToUIModel(
        _ dbPost: DBTeamPost,
        reaction: PostReactionState?,
        imageUrl: String?
    ) -> TeamItem {
        let category: TeamCategory = {
            switch dbPost.category.lowercased() {
            case "study": return .study
            case "course", "project": return .project
            case "hackathon": return .hackathon
            case "sports": return .sports
            case "competition", "startup", "gaming", "social", "activity", "other":
                return .social
            default:
                return .study
            }
        }()

        let currentMembers = max(dbPost.currentMembers ?? 1, 1)
        let maxMembers = max(dbPost.teamSize ?? currentMembers, currentMembers)
        let deadlineDate = parseDate(dbPost.deadline)
        let isUrgent: Bool = {
            guard let deadlineDate else { return false }
            let interval = deadlineDate.timeIntervalSinceNow
            return interval > 0 && interval < 7 * 24 * 60 * 60
        }()

        return TeamItem(
            id: dbPost.id,
            creatorId: dbPost.userId,
            title: dbPost.title,
            description: dbPost.description ?? "",
            category: category,
            currentMembers: currentMembers,
            maxMembers: maxMembers,
            skills: dbPost.skillsNeeded ?? [],
            deadline: deadlineDate,
            creatorName: dbPost.userName ?? "Unknown",
            creatorAvatar: dbPost.userAvatar,
            imageUrl: imageUrl,
            likeCount: reaction?.likeCount ?? 0,
            isLiked: reaction?.isLiked ?? false,
            highlightType: PostHighlightType(rawValue: dbPost.highlightType),
            isUrgent: isUrgent
        )
    }

    private func fetchFirstImageMap(postIds: [UUID]) async throws -> [UUID: String] {
        guard !postIds.isEmpty else { return [:] }

        let ids = postIds.map { $0 as any PostgrestFilterValue }
        let rows: [DBTeamPostImage] = try await supabase
            .database("post_images")
            .select("post_id,url,order_index")
            .`in`("post_id", values: ids)
            .order("order_index", ascending: true)
            .execute()
            .value

        var map: [UUID: String] = [:]
        for row in rows where map[row.postId] == nil {
            map[row.postId] = row.url
        }
        return map
    }

    private func parseDate(_ value: String?) -> Date? {
        guard let value else { return nil }

        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: value) {
            return date
        }

        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
        return dateOnlyFormatter.date(from: value)
    }
}

// MARK: - 数据库组队帖子模型（team_posts_view）
struct DBTeamPost: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let title: String
    let description: String?
    let category: String
    let teamSize: Int?
    let currentMembers: Int?
    let skillsNeeded: [String]?
    let deadline: String?
    let userName: String?
    let userAvatar: String?
    let highlightType: String?
    let hotScore: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case category
        case teamSize = "team_size"
        case currentMembers = "current_members"
        case skillsNeeded = "skills_needed"
        case deadline
        case userName = "user_name"
        case userAvatar = "user_avatar"
        case highlightType = "highlight_type"
        case hotScore = "hot_score"
    }
}

struct DBTeamPostImage: Codable {
    let postId: UUID
    let url: String
    let orderIndex: Int?

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case url
        case orderIndex = "order_index"
    }
}
