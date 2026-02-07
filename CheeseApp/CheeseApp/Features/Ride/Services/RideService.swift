//
//  RideService.swift
//  CheeseApp
//
//  🚗 拼车服务
//  处理拼车帖子的 CRUD 操作
//

import Foundation
import Supabase

// MARK: - UI 拼车模型
struct RideItem: Identifiable, Hashable {
    let id: UUID
    let driverId: UUID
    let from: String
    let to: String
    let date: Date
    let price: Double
    let seats: Int
    let type: RideType
    let driverName: String
    let driverAvatar: String?
    let imageUrl: String?
    var likeCount: Int
    var isLiked: Bool
    let highlightType: PostHighlightType
    var carModel: String = ""

    var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }

    static func == (lhs: RideItem, rhs: RideItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - 拼车服务
@MainActor
class RideService: ObservableObject {

    static let shared = RideService()

    private let supabase = SupabaseManager.shared

    @Published var rides: [RideItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {}

    // MARK: - 获取所有拼车帖子
    func fetchRides() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let dbPosts: [DBRidePost] = try await supabase
                .database("ride_posts_view")
                .select()
                .order("highlight_rank", ascending: true)
                .order("hot_score", ascending: false)
                .order("created_at", ascending: false)
                .execute()
                .value

            let imageMap = try await fetchFirstImageMap(postIds: dbPosts.map(\.id))
            let reactionStates = await PostReactionService.shared.fetchStates(postIds: dbPosts.map(\.id))
            rides = dbPosts.map {
                convertToUIModel($0, reaction: reactionStates[$0.id], imageUrl: imageMap[$0.id])
            }
            print("✅ 获取到 \(rides.count) 个拼车帖子")
        } catch {
            let nsError = error as NSError
            if error is CancellationError || (nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) {
                return
            }
            errorMessage = "加载失败: \(error.localizedDescription)"
            print("❌ 获取拼车帖子失败: \(error)")
        }
    }

    func toggleLike(postId: UUID, currentlyLiked: Bool) async throws -> Bool {
        let newLiked = try await PostReactionService.shared.toggle(postId: postId, currentlyLiked: currentlyLiked)
        if let index = rides.firstIndex(where: { $0.id == postId }) {
            rides[index].isLiked = newLiked
            let delta = newLiked ? 1 : -1
            rides[index].likeCount = max(rides[index].likeCount + delta, 0)
        }
        return newLiked
    }

    func fetchRide(postId: UUID) async throws -> RideItem {
        let row: DBRidePost = try await supabase
            .database("ride_posts_view")
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
        _ dbPost: DBRidePost,
        reaction: PostReactionState?,
        imageUrl: String?
    ) -> RideItem {
        let isDriver = dbPost.role == "driver"

        return RideItem(
            id: dbPost.id,
            driverId: dbPost.userId,
            from: dbPost.departureLocation,
            to: dbPost.destinationLocation,
            date: dbPost.departureTime,
            price: dbPost.pricePerSeat ?? 0,
            seats: max(dbPost.availableSeats ?? 0, 0),
            type: isDriver ? .offering : .looking,
            driverName: dbPost.userName ?? "Unknown",
            driverAvatar: dbPost.userAvatar,
            imageUrl: imageUrl,
            likeCount: reaction?.likeCount ?? 0,
            isLiked: reaction?.isLiked ?? false,
            highlightType: PostHighlightType(rawValue: dbPost.highlightType),
            carModel: dbPost.notes ?? ""
        )
    }

    private func fetchFirstImageMap(postIds: [UUID]) async throws -> [UUID: String] {
        guard !postIds.isEmpty else { return [:] }

        let ids = postIds.map { $0 as any PostgrestFilterValue }
        let rows: [DBRidePostImage] = try await supabase
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
}

// MARK: - 数据库拼车帖子模型（ride_posts_view）
struct DBRidePost: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let departureLocation: String
    let destinationLocation: String
    let departureTime: Date
    let availableSeats: Int?
    let pricePerSeat: Double?
    let role: String
    let notes: String?
    let userName: String?
    let userAvatar: String?
    let highlightType: String?
    let hotScore: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case departureLocation = "departure_location"
        case destinationLocation = "destination_location"
        case departureTime = "departure_time"
        case availableSeats = "available_seats"
        case pricePerSeat = "price_per_seat"
        case role
        case notes
        case userName = "user_name"
        case userAvatar = "user_avatar"
        case highlightType = "highlight_type"
        case hotScore = "hot_score"
    }
}

struct DBRidePostImage: Codable {
    let postId: UUID
    let url: String
    let orderIndex: Int?

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case url
        case orderIndex = "order_index"
    }
}
