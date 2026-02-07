//
//  RentService.swift
//  CheeseApp
//
//  🏠 租房服务
//  处理租房帖子的 CRUD 操作
//

import Foundation
import Supabase

// MARK: - 租房服务
@MainActor
class RentService: ObservableObject {

    static let shared = RentService()

    private let supabase = SupabaseManager.shared

    @Published var posts: [RentPostItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {}

    // MARK: - 获取所有租房帖子
    func fetchPosts() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let dbPosts: [DBRentPost] = try await supabase
                .database("rent_posts_view")
                .select()
                .order("highlight_rank", ascending: true)
                .order("hot_score", ascending: false)
                .order("created_at", ascending: false)
                .execute()
                .value

            let reactionStates = await PostReactionService.shared.fetchStates(postIds: dbPosts.map(\.id))
            posts = dbPosts.map { convertToUIModel($0, reaction: reactionStates[$0.id]) }
            print("✅ 获取到 \(posts.count) 个租房帖子")
        } catch {
            let nsError = error as NSError
            if error is CancellationError || (nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) {
                return
            }
            errorMessage = "加载失败: \(error.localizedDescription)"
            print("❌ 获取租房帖子失败: \(error)")
        }
    }

    // MARK: - 创建租房帖子
    func createPost(
        title: String,
        description: String,
        propertyType: String,
        bedrooms: Int,
        bathrooms: Int,
        price: Double,
        city: String,
        address: String,
        availableFrom: Date,
        amenities: [String],
        highlightType: String = "normal",
        pinnedUntil: String? = nil
    ) async throws -> UUID {

        let userId: UUID
        do {
            userId = try await AuthService.shared.requireAuthUserId()
        } catch {
            await AuthService.shared.checkSession()
            throw NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "请先登录"])
        }

        let postId = UUID()
        let location = address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? city : address
        let normalizedAmenities = amenities.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let postInsert = RentBasePostInsert(
            id: postId,
            userId: userId,
            type: "rent",
            title: title,
            description: description.isEmpty ? nil : description,
            isAnonymous: AuthService.shared.currentUser?.isAnonymousDefault ?? false
        )

        let rentInsert = RentDetailInsert(
            id: postId,
            price: price,
            location: location,
            bedrooms: bedrooms,
            bathrooms: Double(bathrooms),
            specs: "\(bedrooms)B\(bathrooms)B",
            propertyType: normalizedPropertyType(propertyType),
            availableFrom: dateFormatter.string(from: availableFrom),
            utilitiesIncluded: normalizedAmenities.contains("水电全包"),
            petsAllowed: normalizedAmenities.contains("允许宠物"),
            parkingAvailable: normalizedAmenities.contains("停车位"),
            laundryType: normalizedAmenities.contains("洗衣机") ? "in_unit" : nil,
            amenities: normalizedAmenities,
            highlightType: highlightType,
            pinnedUntil: pinnedUntil
        )

        try await supabase
            .database("posts")
            .insert(postInsert)
            .execute()

        do {
            try await supabase
                .database("rent_posts")
                .insert(rentInsert)
                .execute()
        } catch {
            // 避免留下仅有基础表记录的孤儿帖子
            _ = try? await supabase
                .database("posts")
                .delete()
                .eq("id", value: postId.uuidString)
                .execute()
            throw error
        }

        print("✅ 租房帖子创建成功: \(postId)")

        await fetchPosts()
        return postId
    }

    // MARK: - 转换数据库模型到 UI 模型
    func toggleLike(postId: UUID, currentlyLiked: Bool) async throws -> Bool {
        let newLiked = try await PostReactionService.shared.toggle(postId: postId, currentlyLiked: currentlyLiked)
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].isLiked = newLiked
            let delta = newLiked ? 1 : -1
            posts[index].likeCount = max(posts[index].likeCount + delta, 0)
        }
        return newLiked
    }

    private func convertToUIModel(_ dbPost: DBRentPost, reaction: PostReactionState?) -> RentPostItem {
        let propertyType: RentPostItem.PropertyType = {
            switch dbPost.propertyType {
            case "room": return .room
            case "apartment": return .apartment
            case "house", "condo": return .apartment
            case "studio": return .room
            default: return .apartment
            }
        }()

        let bedrooms = max(dbPost.bedrooms ?? 0, 0)
        let bathrooms = max(Int((dbPost.bathrooms ?? 0).rounded()), 0)
        let specs = dbPost.specs?.isEmpty == false
            ? (dbPost.specs ?? "")
            : "\(bedrooms) Bed • \(bathrooms) Bath"

        return RentPostItem(
            id: dbPost.id,
            title: dbPost.title,
            price: dbPost.price,
            location: dbPost.location,
            specs: specs,
            propertyType: propertyType,
            imageUrl: dbPost.images?.first?.url,
            authorId: dbPost.userId,
            authorName: dbPost.userName ?? "Unknown",
            authorAvatar: dbPost.userAvatar,
            distance: cityName(from: dbPost.location),
            timeAgo: formatTimeAgo(dbPost.createdAt),
            isFavorited: false,
            likeCount: reaction?.likeCount ?? 0,
            isLiked: reaction?.isLiked ?? false,
            highlightType: PostHighlightType(rawValue: dbPost.highlightType),
            description: dbPost.description ?? "",
            amenities: dbPost.amenities ?? [],
            availableDate: parseDate(dbPost.availableFrom) ?? Date(),
            bedrooms: bedrooms,
            bathrooms: bathrooms
        )
    }

    private func cityName(from location: String) -> String {
        let parts = location
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let last = parts.last {
            return last
        }
        return location.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedPropertyType(_ value: String) -> String {
        switch value {
        case "apartment", "house", "studio", "room", "condo":
            return value
        default:
            return "apartment"
        }
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

    private func formatTimeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }
}

// MARK: - 数据库租房帖子模型（rent_posts_view）
struct DBRentPost: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let title: String
    let description: String?
    let propertyType: String
    let bedrooms: Int?
    let bathrooms: Double?
    let price: Double
    let specs: String?
    let location: String
    let availableFrom: String?
    let amenities: [String]?
    let createdAt: Date
    let userName: String?
    let userAvatar: String?
    let highlightType: String?
    let hotScore: Double?
    let images: [DBPostImage]?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case propertyType = "property_type"
        case bedrooms
        case bathrooms
        case price
        case specs
        case location
        case availableFrom = "available_from"
        case amenities
        case createdAt = "created_at"
        case userName = "user_name"
        case userAvatar = "user_avatar"
        case highlightType = "highlight_type"
        case hotScore = "hot_score"
        case images
    }
}

struct DBPostImage: Codable {
    let id: UUID?
    let url: String
    let orderIndex: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case orderIndex = "order_index"
    }
}

// MARK: - 写入模型
struct RentBasePostInsert: Encodable {
    let id: UUID
    let userId: UUID
    let type: String
    let title: String
    let description: String?
    let isAnonymous: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case title
        case description
        case isAnonymous = "is_anonymous"
    }
}

struct RentDetailInsert: Encodable {
    let id: UUID
    let price: Double
    let location: String
    let bedrooms: Int
    let bathrooms: Double
    let specs: String
    let propertyType: String
    let availableFrom: String
    let utilitiesIncluded: Bool
    let petsAllowed: Bool
    let parkingAvailable: Bool
    let laundryType: String?
    let amenities: [String]
    let highlightType: String
    let pinnedUntil: String?

    enum CodingKeys: String, CodingKey {
        case id
        case price
        case location
        case bedrooms
        case bathrooms
        case specs
        case propertyType = "property_type"
        case availableFrom = "available_from"
        case utilitiesIncluded = "utilities_included"
        case petsAllowed = "pets_allowed"
        case parkingAvailable = "parking_available"
        case laundryType = "laundry_type"
        case amenities
        case highlightType = "highlight_type"
        case pinnedUntil = "pinned_until"
    }
}
