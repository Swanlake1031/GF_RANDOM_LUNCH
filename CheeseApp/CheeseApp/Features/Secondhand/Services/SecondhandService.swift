//
//  SecondhandService.swift
//  CheeseApp
//
//  🛍️ 二手交易服务
//  处理二手商品的 CRUD 操作
//

import Foundation
import Supabase

// MARK: - UI 二手商品模型
struct SecondhandItem: Identifiable, Hashable {
    let id: UUID
    let sellerId: UUID
    let title: String
    let price: Double
    let category: ItemCategory
    let condition: String
    let seller: String
    let sellerAvatar: String?
    let description: String
    let timeAgo: String
    let imageUrl: String?
    var likeCount: Int
    var isLiked: Bool
    let highlightType: PostHighlightType
    var isSold: Bool = false

    static func == (lhs: SecondhandItem, rhs: SecondhandItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - 二手服务
@MainActor
class SecondhandService: ObservableObject {

    static let shared = SecondhandService()

    private let supabase = SupabaseManager.shared

    @Published var items: [SecondhandItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {}

    // MARK: - 获取所有二手商品
    func fetchItems() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let dbPosts: [DBSecondhandPost] = try await supabase
                .database("secondhand_posts_view")
                .select()
                .order("highlight_rank", ascending: true)
                .order("hot_score", ascending: false)
                .order("created_at", ascending: false)
                .execute()
                .value

            let reactionStates = await PostReactionService.shared.fetchStates(postIds: dbPosts.map(\.id))
            items = dbPosts.map { convertToUIModel($0, reaction: reactionStates[$0.id]) }
            print("✅ 获取到 \(items.count) 个二手商品")
        } catch {
            let nsError = error as NSError
            if error is CancellationError || (nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) {
                return
            }
            errorMessage = "加载失败: \(error.localizedDescription)"
            print("❌ 获取二手商品失败: \(error)")
        }
    }

    func toggleLike(postId: UUID, currentlyLiked: Bool) async throws -> Bool {
        let newLiked = try await PostReactionService.shared.toggle(postId: postId, currentlyLiked: currentlyLiked)
        if let index = items.firstIndex(where: { $0.id == postId }) {
            items[index].isLiked = newLiked
            let delta = newLiked ? 1 : -1
            items[index].likeCount = max(items[index].likeCount + delta, 0)
        }
        return newLiked
    }

    func fetchItem(postId: UUID) async throws -> SecondhandItem {
        let dbPost: DBSecondhandPost = try await supabase
            .database("secondhand_posts_view")
            .select()
            .eq("id", value: postId.uuidString)
            .single()
            .execute()
            .value

        let reaction = await PostReactionService.shared.fetchStates(postIds: [dbPost.id])[dbPost.id]
        return convertToUIModel(dbPost, reaction: reaction)
    }

    // MARK: - 转换模型
    private func convertToUIModel(_ dbPost: DBSecondhandPost, reaction: PostReactionState?) -> SecondhandItem {
        let category: ItemCategory = {
            switch dbPost.category.lowercased() {
            case "electronics": return .electronics
            case "books", "textbooks": return .books
            case "furniture": return .furniture
            case "clothing": return .clothing
            default: return .other
            }
        }()

        return SecondhandItem(
            id: dbPost.id,
            sellerId: dbPost.userId,
            title: dbPost.title,
            price: dbPost.price,
            category: category,
            condition: dbPost.condition,
            seller: dbPost.userName ?? "Unknown",
            sellerAvatar: dbPost.userAvatar,
            description: dbPost.description ?? "",
            timeAgo: formatTimeAgo(dbPost.createdAt),
            imageUrl: dbPost.images?.first?.url,
            likeCount: reaction?.likeCount ?? 0,
            isLiked: reaction?.isLiked ?? false,
            highlightType: PostHighlightType(rawValue: dbPost.highlightType),
            isSold: (dbPost.quantity ?? 1) <= (dbPost.soldCount ?? 0)
        )
    }

    private func formatTimeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        else if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        else { return "\(Int(interval / 86400))d ago" }
    }
}

// MARK: - 数据库二手帖子模型（secondhand_posts_view）
struct DBSecondhandPost: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let title: String
    let description: String?
    let category: String
    let condition: String
    let price: Double
    let isNegotiable: Bool
    let quantity: Int?
    let soldCount: Int?
    let createdAt: Date
    let userName: String?
    let userAvatar: String?
    let highlightType: String?
    let hotScore: Double?
    let images: [DBSecondhandImage]?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case category
        case condition
        case price
        case isNegotiable = "is_negotiable"
        case quantity
        case soldCount = "sold_count"
        case createdAt = "created_at"
        case userName = "user_name"
        case userAvatar = "user_avatar"
        case highlightType = "highlight_type"
        case hotScore = "hot_score"
        case images
    }
}

struct DBSecondhandImage: Codable {
    let id: UUID?
    let url: String
    let orderIndex: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case orderIndex = "order_index"
    }
}
