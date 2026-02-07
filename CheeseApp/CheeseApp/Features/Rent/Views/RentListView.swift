//
//  RentListView.swift
//  CheeseApp
//
//  🏠 租房列表视图
//  展示所有租房帖子，支持搜索和筛选
//

import SwiftUI

// MARK: - 租房列表视图
struct RentListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    @StateObject private var rentService = RentService.shared
    @StateObject private var postEditor = UserPostsService()
    @State private var searchText = ""
    @State private var selectedFilter: RentFilter = .all
    @State private var selectedPost: RentPostItem? = nil
    @State private var editingPost: UserPostSummary?
    @State private var likingPostIDs: Set<UUID> = []
    
    var body: some View {
        ZStack {
            // 背景色 - 奶酪米色
            Color(red: 0.96, green: 0.94, blue: 0.88)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // 筛选栏
                    filterBar
                    
                    // 加载状态
                    if rentService.isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else if rentService.posts.isEmpty {
                        emptyState
                    } else {
                        // 房源卡片列表
                        LazyVStack(spacing: 14) {
                            ForEach(filteredPosts) { post in
                                RentCardView(
                                    post: post,
                                    isOwnPost: authService.currentUser?.id == post.authorId,
                                    onTap: {
                                        selectedPost = post
                                    },
                                    onLikeTap: {
                                    await toggleLike(for: post)
                                    },
                                    onEditTap: {
                                    editingPost = toEditableSummary(post)
                                    }
                                )
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .refreshable {
                await rentService.fetchPosts()
            }
        }
        .task {
            // 页面加载时获取数据
            await rentService.fetchPosts()
        }
        .navigationTitle("Rent")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search listings...")
        .navigationDestination(item: $selectedPost) { post in
            RentDetailView(post: post)
        }
        .sheet(item: $editingPost) { post in
            EditPostSheet(post: post) { payload in
                try await postEditor.update(payload: payload)
                await rentService.fetchPosts()
            }
        }
    }
    
    // MARK: - 筛选栏
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(RentFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.title,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 空状态
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "house")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No listings yet")
                .font(.system(size: 18, weight: .medium))
            Text("Be the first to post a rental!")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 60)
    }
    
    // MARK: - 筛选后的帖子
    private var filteredPosts: [RentPostItem] {
        var result = rentService.posts
        
        // 文本搜索
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 类型筛选
        switch selectedFilter {
        case .all:
            break
        case .room:
            result = result.filter { $0.propertyType == .room }
        case .apartment:
            result = result.filter { $0.propertyType == .apartment }
        case .sublease:
            result = result.filter { $0.propertyType == .sublease }
        }
        
        return result
    }

    private func toggleLike(for post: RentPostItem) async {
        guard !likingPostIDs.contains(post.id) else { return }
        likingPostIDs.insert(post.id)
        defer { likingPostIDs.remove(post.id) }

        do {
            _ = try await rentService.toggleLike(postId: post.id, currentlyLiked: post.isLiked)
        } catch {
            print("⚠️ Rent like failed: \(error)")
        }
    }

    private func toEditableSummary(_ post: RentPostItem) -> UserPostSummary {
        UserPostSummary(
            id: post.id,
            kind: .rent,
            title: post.title,
            description: post.description,
            subtitle: post.location,
            price: post.price,
            createdAt: Date(),
            authorId: post.authorId,
            authorName: post.authorName,
            authorAvatarURL: post.authorAvatar
        )
    }
}

// MARK: - 筛选类型
enum RentFilter: CaseIterable {
    case all, room, apartment, sublease
    
    var title: String {
        switch self {
        case .all: return "All"
        case .room: return "Room"
        case .apartment: return "Apartment"
        case .sublease: return "Sublease"
        }
    }
}

// MARK: - 筛选标签组件
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.black : Color.white)
                )
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }
}

// MARK: - 租房卡片视图
struct RentCardView: View {
    let post: RentPostItem
    let isOwnPost: Bool
    var onTap: (() -> Void)?
    var onLikeTap: (() async -> Void)?
    var onEditTap: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // 图片区域
            ZStack(alignment: .topLeading) {
                // 图片
                if let imageUrl = post.imageUrl, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        placeholderImage
                    }
                } else {
                    placeholderImage
                }
            }
            .frame(height: 180)
            .clipped()
            
            // 内容区域
            VStack(alignment: .leading, spacing: 10) {
                // 标签行
                HStack(spacing: 8) {
                    Text(post.propertyType.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                    
                    Text(post.distance)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    
                    Spacer()

                    if isOwnPost {
                        Button {
                            onEditTap?()
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppColors.textMuted)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        Task { await onLikeTap?() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: post.isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 15))
                                .foregroundStyle(post.isLiked ? .red : .secondary)
                            Text("\(post.likeCount)")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                // 标题
                Text(post.title)
                    .font(.system(size: 17, weight: .semibold))
                    .lineLimit(1)
                
                // 价格和规格
                HStack {
                    Text("$\(Int(post.price))/mo")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(red: 0.2, green: 0.6, blue: 0.4))
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(post.specs)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                
                // 发布者信息
                HStack(spacing: 8) {
                    NavigationLink {
                        UserPostsView(userId: post.authorId)
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 24, height: 24)
                                .overlay {
                                    Text(String(post.authorName.prefix(1)))
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            
                            Text("Posted by \(post.authorName)")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text(post.timeAgo)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
        .postHighlightStyle(post.highlightType, cornerRadius: 20)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture { onTap?() }
    }
    
    private var placeholderImage: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 32))
                    .foregroundStyle(.gray.opacity(0.5))
            }
    }
}

// MARK: - 租房帖子模型
struct RentPostItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let price: Double
    let location: String
    let specs: String
    let propertyType: PropertyType
    let imageUrl: String?
    let authorId: UUID
    let authorName: String
    let authorAvatar: String?
    let distance: String
    let timeAgo: String
    let isFavorited: Bool
    var likeCount: Int
    var isLiked: Bool
    let highlightType: PostHighlightType
    let description: String
    let amenities: [String]
    let availableDate: Date
    let bedrooms: Int
    let bathrooms: Int
    
    enum PropertyType: String, CaseIterable {
        case room = "room"
        case apartment = "apartment"
        case sublease = "sublease"
        
        var displayName: String {
            switch self {
            case .room: return "Room"
            case .apartment: return "Apartment"
            case .sublease: return "Sublease"
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        RentListView()
    }
}
