//
//  HomeViewModel.swift
//  CheeseApp
//
//  🧠 首页视图模型
//  负责从 Supabase 获取首页所需的数据
//

import SwiftUI

// MARK: - 首页视图模型
@MainActor
class HomeViewModel: ObservableObject {
    
    // MARK: - Published 属性
    
    /// 快捷操作列表
    @Published var quickActions: [HomeQuickAction] = HomeQuickAction.defaultActions
    
    /// 精选推荐卡片
    @Published var featuredCards: [HomeCardItem] = []
    @Published var featuredRentPosts: [RentPostItem] = []
    
    /// 组队卡片
    @Published var groupsCard: HomeCardItem?
    
    /// 拼车卡片
    @Published var carpoolCard: HomeCardItem?
    
    /// 论坛热门帖子
    @Published var forumCards: [ForumCardItem] = []
    
    /// 加载状态
    @Published var isLoading = false
    
    /// 错误信息
    @Published var errorMessage: String?
    
    private let supabase = SupabaseManager.shared
    
    // MARK: - 初始化
    
    init() {
        Task {
            await loadData()
        }
    }
    
    // MARK: - 公开方法
    
    /// 刷新首页数据
    func refresh() async {
        await loadData()
    }
    
    /// 获取问候语
    func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return L10n.tr("Good Morning", "早安")
        case 12..<17:
            return L10n.tr("Good Afternoon", "午安")
        case 17..<21:
            return L10n.tr("Good Evening", "晚安")
        default:
            return L10n.tr("Good Night", "晚安")
        }
    }
    
    // MARK: - 私有方法
    
    /// 从 Supabase 加载数据
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // 并行加载各类数据
        async let rentTask: Void = loadRentPosts()
        async let teamTask: Void = loadTeamPost()
        async let rideTask: Void = loadRidePost()
        async let forumTask: Void = loadForumPosts()
        
        let _ = await (rentTask, teamTask, rideTask, forumTask)
    }
    
    /// 加载租房帖子
    private func loadRentPosts() async {
        do {
            let posts: [DBRentPost] = try await supabase
                .database("rent_posts_view")
                .select()
                .order("highlight_rank", ascending: true)
                .order("hot_score", ascending: false)
                .order("created_at", ascending: false)
                .limit(3)
                .execute()
                .value

            let reactions = await PostReactionService.shared.fetchStates(postIds: posts.map(\.id))
            featuredRentPosts = posts.map { post in
                let propertyType: RentPostItem.PropertyType = {
                    switch post.propertyType {
                    case "room": return .room
                    case "apartment": return .apartment
                    case "sublease": return .sublease
                    case "house", "condo": return .apartment
                    case "studio": return .room
                    default: return .apartment
                    }
                }()

                let bedrooms = max(post.bedrooms ?? 0, 0)
                let bathrooms = max(Int((post.bathrooms ?? 0).rounded()), 0)
                let specs = post.specs?.isEmpty == false
                    ? (post.specs ?? "")
                    : "\(bedrooms) Bed • \(bathrooms) Bath"

                return RentPostItem(
                    id: post.id,
                    title: post.title,
                    price: post.price,
                    location: post.location,
                    specs: specs,
                    propertyType: propertyType,
                    imageUrl: post.images?.first?.url,
                    authorId: post.userId,
                    authorName: post.userName ?? "Unknown",
                    authorAvatar: post.userAvatar,
                    distance: post.location,
                    timeAgo: formatTimeAgo(post.createdAt),
                    isFavorited: false,
                    likeCount: reactions[post.id]?.likeCount ?? 0,
                    isLiked: reactions[post.id]?.isLiked ?? false,
                    highlightType: PostHighlightType(rawValue: post.highlightType),
                    description: post.description ?? "",
                    amenities: post.amenities ?? [],
                    availableDate: Date(),
                    bedrooms: bedrooms,
                    bathrooms: bathrooms
                )
            }

            featuredCards = featuredRentPosts.map { post in
                let avatar: ImageSource = {
                    guard let userAvatar = post.authorAvatar, let url = URL(string: userAvatar) else {
                        return .placeholder
                    }
                    return .url(url)
                }()

                return HomeCardItem(
                    postId: post.id,
                    authorId: post.authorId,
                    image: {
                        guard let imageUrl = post.imageUrl, let url = URL(string: imageUrl) else { return .placeholder }
                        return .url(url)
                    }(),
                    pills: [
                        CardPill(text: "Rent", style: .tag),
                        CardPill(text: "$\(Int(post.price))/mo", style: .muted)
                    ],
                    title: post.title,
                    subtitle: "\(post.bedrooms) bed • \(post.bathrooms) bath • \(post.location)",
                    footer: .posted(
                        name: post.authorName,
                        avatar: avatar
                    ),
                    category: .rent,
                    highlightType: post.highlightType
                )
            }
        } catch {
            if shouldIgnore(error) { return }
            print("❌ 加载租房帖子失败: \(error)")
        }
    }
    
    /// 加载组队帖子
    private func loadTeamPost() async {
        do {
            let posts: [TeamPostResponse] = try await supabase
                .database("team_posts_view")
                .select()
                .order("highlight_rank", ascending: true)
                .order("hot_score", ascending: false)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value
            
            if let post = posts.first {
                let teamImageURL = await fetchFirstImageURL(for: post.id)
                let teamImage: ImageSource = teamImageURL.map(ImageSource.url) ?? .placeholder

                groupsCard = HomeCardItem(
                    postId: post.id,
                    image: teamImage,
                    pills: [
                        CardPill(text: "Groups", style: .tag),
                        CardPill(
                            text: "\(post.currentMembers ?? 1)/\(post.teamSize ?? post.currentMembers ?? 1) members",
                            style: .muted
                        )
                    ],
                    title: post.title,
                    subtitle: post.description ?? "Join our team!",
                    footer: .posted(
                        name: post.userName ?? "Organizer",
                        avatar: .placeholder
                    ),
                    category: .groups,
                    highlightType: PostHighlightType(rawValue: post.highlightType)
                )
            }
        } catch {
            if shouldIgnore(error) { return }
            print("❌ 加载组队帖子失败: \(error)")
        }
    }

    private func fetchFirstImageURL(for postId: UUID) async -> URL? {
        do {
            let rows: [SearchPostImageRow] = try await supabase
                .database("post_images")
                .select("url")
                .eq("post_id", value: postId.uuidString)
                .order("order_index", ascending: true)
                .limit(1)
                .execute()
                .value

            guard let urlString = rows.first?.url else { return nil }
            return URL(string: urlString)
        } catch {
            return nil
        }
    }
    
    /// 加载拼车帖子
    private func loadRidePost() async {
        do {
            let posts: [RidePostResponse] = try await supabase
                .database("ride_posts_view")
                .select()
                .order("highlight_rank", ascending: true)
                .order("hot_score", ascending: false)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value
            
            if let post = posts.first {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d, h:mm a"
                let timeStr = formatter.string(from: post.departureTime)
                
                carpoolCard = HomeCardItem(
                    postId: post.id,
                    image: .placeholder,
                    pills: [
                        CardPill(text: "Carpool", style: .tag),
                        CardPill(text: timeStr, style: .muted)
                    ],
                    title: "\(post.departureLocation) → \(post.destinationLocation)",
                    subtitle: "$\(Int(post.pricePerSeat ?? 0))/person • \(post.availableSeats ?? 0) seats",
                    footer: .hosted(
                        name: post.userName ?? "Driver",
                        avatar: .placeholder
                    ),
                    category: .carpool,
                    highlightType: PostHighlightType(rawValue: post.highlightType)
                )
            }
        } catch {
            if shouldIgnore(error) { return }
            print("❌ 加载拼车帖子失败: \(error)")
        }
    }
    
    /// 加载论坛帖子
    private func loadForumPosts() async {
        do {
            let posts: [ForumPostResponse] = try await supabase
                .database("forum_posts_view")
                .select()
                .order("highlight_rank", ascending: true)
                .order("hot_score", ascending: false)
                .order("created_at", ascending: false)
                .limit(3)
                .execute()
                .value
            
            forumCards = posts.map { post in
                ForumCardItem(
                    postId: post.id,
                    image: {
                        guard let firstURL = post.images?.first?.url, let url = URL(string: firstURL) else {
                            return .placeholder
                        }
                        return .url(url)
                    }(),
                    responseCount: "\(post.commentCount ?? 0) comments",
                    title: post.title,
                    author: post.isAnonymous ? "Anonymous" : (post.userName ?? "User"),
                    timeAgo: formatTimeAgo(post.createdAt),
                    highlightType: PostHighlightType(rawValue: post.highlightType)
                )
            }
        } catch {
            if shouldIgnore(error) { return }
            print("❌ 加载论坛帖子失败: \(error)")
        }
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

    private func shouldIgnore(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
    }
}

// MARK: - Supabase 响应模型

struct RentPostResponse: Codable {
    let id: UUID
    let title: String
    let price: Double
    let location: String
    let bedrooms: Int?
    let bathrooms: Double?
    let userName: String?
    let userAvatar: String?
    let highlightType: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, price, location, bedrooms, bathrooms
        case userName = "user_name"
        case userAvatar = "user_avatar"
        case highlightType = "highlight_type"
    }
}

struct TeamPostResponse: Codable {
    let id: UUID
    let title: String
    let description: String?
    let teamSize: Int?
    let currentMembers: Int?
    let userName: String?
    let highlightType: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description
        case teamSize = "team_size"
        case currentMembers = "current_members"
        case userName = "user_name"
        case highlightType = "highlight_type"
    }
}

struct RidePostResponse: Codable {
    let id: UUID
    let departureLocation: String
    let destinationLocation: String
    let departureTime: Date
    let availableSeats: Int?
    let pricePerSeat: Double?
    let userName: String?
    let highlightType: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case departureLocation = "departure_location"
        case destinationLocation = "destination_location"
        case departureTime = "departure_time"
        case availableSeats = "available_seats"
        case pricePerSeat = "price_per_seat"
        case userName = "user_name"
        case highlightType = "highlight_type"
    }
}

struct ForumPostResponse: Codable {
    let id: UUID
    let title: String
    let isAnonymous: Bool
    let commentCount: Int?
    let createdAt: Date
    let userName: String?
    let highlightType: String?
    let images: [ForumPostImageResponse]?
    
    enum CodingKeys: String, CodingKey {
        case id, title
        case isAnonymous = "is_anonymous"
        case commentCount = "comment_count"
        case createdAt = "created_at"
        case userName = "user_name"
        case highlightType = "highlight_type"
        case images
    }
}

struct ForumPostImageResponse: Codable {
    let url: String
}

private struct SearchPostImageRow: Codable {
    let url: String
}
