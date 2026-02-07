//
//  SecondhandListView.swift
//  CheeseApp
//
//  🛍️ 二手市场列表视图
//  展示所有二手商品，支持搜索和分类筛选
//

import SwiftUI

struct SecondhandListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    @StateObject private var service = SecondhandService.shared
    @StateObject private var postEditor = UserPostsService()
    @State private var searchText = ""
    @State private var selectedCategory: ItemCategory = .all
    @State private var editingPost: UserPostSummary?
    @State private var likingPostIDs: Set<UUID> = []
    @State private var selectedItem: SecondhandItem?
    
    var body: some View {
        ZStack {
            // 背景色
            Color(red: 0.96, green: 0.94, blue: 0.88)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // 分类筛选
                    categoryFilter
                    
                    // 加载状态
                    if service.isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else if service.items.isEmpty {
                        emptyState
                    } else {
                        // 商品网格（固定两栏，不足时补空位，保证每格尺寸一致）
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 14),
                            GridItem(.flexible(), spacing: 14)
                        ], spacing: 14) {
                            ForEach(displayItems.indices, id: \.self) { index in
                                if let item = displayItems[index] {
                                    SecondhandCardView(
                                        item: item,
                                        isOwnPost: authService.currentUser?.id == item.sellerId,
                                        onLikeTap: {
                                            await toggleLike(for: item)
                                        },
                                        onEditTap: {
                                            editingPost = toEditableSummary(item)
                                        },
                                        onOpenTap: {
                                            selectedItem = item
                                        }
                                    )
                                } else {
                                    Color.clear
                                        .frame(height: 263)
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .refreshable {
                await service.fetchItems()
            }
        }
        .navigationTitle("Market")
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
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search items...")
        .sheet(item: $editingPost) { post in
            EditPostSheet(post: post) { payload in
                try await postEditor.update(payload: payload)
                await service.fetchItems()
            }
        }
        .navigationDestination(item: $selectedItem) { item in
            SecondhandDetailView(item: item)
        }
        .task {
            await service.fetchItems()
        }
    }
    
    // MARK: - 空状态
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bag")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No items yet")
                .font(.system(size: 18, weight: .medium))
            Text("Be the first to list something!")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 60)
    }
    
    // MARK: - 分类筛选
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ItemCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.title,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 筛选后的商品
    private var filteredItems: [SecondhandItem] {
        var result = service.items
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if selectedCategory != .all {
            result = result.filter { $0.category == selectedCategory }
        }
        
        return result
    }

    private var displayItems: [SecondhandItem?] {
        var result = filteredItems.map { Optional($0) }
        if result.count % 2 != 0 {
            result.append(nil)
        }
        return result
    }

    private func toggleLike(for item: SecondhandItem) async {
        guard !likingPostIDs.contains(item.id) else { return }
        likingPostIDs.insert(item.id)
        defer { likingPostIDs.remove(item.id) }

        do {
            _ = try await service.toggleLike(postId: item.id, currentlyLiked: item.isLiked)
        } catch {
            print("⚠️ Secondhand like failed: \(error)")
        }
    }

    private func toEditableSummary(_ item: SecondhandItem) -> UserPostSummary {
        UserPostSummary(
            id: item.id,
            kind: .secondhand,
            title: item.title,
            description: item.description,
            subtitle: item.condition,
            price: item.price,
            createdAt: Date(),
            authorId: item.sellerId,
            authorName: item.seller,
            authorAvatarURL: item.sellerAvatar
        )
    }
}

// MARK: - 商品分类
enum ItemCategory: CaseIterable {
    case all, electronics, books, furniture, clothing, other
    
    var title: String {
        switch self {
        case .all: return "All"
        case .electronics: return "Electronics"
        case .books: return "Books"
        case .furniture: return "Furniture"
        case .clothing: return "Clothing"
        case .other: return "Other"
        }
    }
}

// MARK: - 二手商品卡片
struct SecondhandCardView: View {
    let item: SecondhandItem
    let isOwnPost: Bool
    var onLikeTap: (() async -> Void)?
    var onEditTap: (() -> Void)?
    var onOpenTap: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 图片
            cardImage
            
            // 内容
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                HStack {
                    Text("$\(Int(item.price))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.categoryColor(for: "market"))
                    
                    Spacer()
                    
                    Text(item.condition)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    Button {
                        Task { await onLikeTap?() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: item.isLiked ? "heart.fill" : "heart")
                                .foregroundStyle(item.isLiked ? .red : .secondary)
                            Text("\(item.likeCount)")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: { onOpenTap?() }) {
                        Text(L10n.tr("View", "查看"))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppColors.accent)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    UserPostsView(userId: item.sellerId)
                } label: {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(AppColors.accent.opacity(0.25))
                            .frame(width: 20, height: 20)
                            .overlay {
                                Text(String(item.seller.prefix(1)).uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(AppColors.textPrimary)
                            }

                        Text(item.seller)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppColors.textMuted)

                        Spacer()

                        Text(item.timeAgo)
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.textMuted)
                    }
                    .padding(.top, 2)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color.white)
            .frame(height: 108, alignment: .top)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        .postHighlightStyle(item.highlightType, cornerRadius: 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 263)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture { onOpenTap?() }
    }

    private var cardImage: some View {
        ZStack {
            placeholderImage

            if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url, transaction: Transaction(animation: .none)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 155)
                            .clipped()
                    default:
                        EmptyView()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 155)
        .clipped()
    }
    
    private var placeholderImage: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.orange.opacity(0.2), Color.pink.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Image(systemName: iconFor(category: item.category))
                    .font(.system(size: 32))
                    .foregroundStyle(.gray.opacity(0.4))
            }
    }
    
    private func iconFor(category: ItemCategory) -> String {
        switch category {
        case .electronics: return "laptopcomputer"
        case .books: return "book.fill"
        case .furniture: return "sofa.fill"
        case .clothing: return "tshirt.fill"
        case .other: return "shippingbox.fill"
        case .all: return "tag.fill"
        }
    }
}

#Preview {
    NavigationStack {
        SecondhandListView()
    }
}

struct SecondhandDetailView: View {
    let item: SecondhandItem

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    @StateObject private var postEditor = UserPostsService()
    @ObservedObject private var service = SecondhandService.shared

    @State private var isLiked: Bool
    @State private var likeCount: Int
    @State private var isLiking = false
    @State private var showContactAlert = false
    @State private var showDeleteConfirm = false
    @State private var showReportSheet = false
    @State private var editingPost: UserPostSummary?

    init(item: SecondhandItem) {
        self.item = item
        _isLiked = State(initialValue: item.isLiked)
        _likeCount = State(initialValue: item.likeCount)
    }

    private var isOwnPost: Bool {
        authService.currentUser?.id == item.sellerId
    }

    var body: some View {
        ZStack {
            AppColors.pageBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    mediaSection
                    headerSection
                    descriptionSection
                    sellerSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            PostDetailTopBar(title: L10n.tr("Market Post", "二手貼文"), onBack: { dismiss() }) {
                ShareLink(item: "\(item.title) - $\(Int(item.price))") {
                    PostToolbarIconCircle(icon: "square.and.arrow.up")
                }

                Menu {
                    if isOwnPost {
                        Button {
                            editingPost = UserPostSummary(
                                id: item.id,
                                kind: .secondhand,
                                title: item.title,
                                description: item.description,
                                subtitle: item.condition,
                                price: item.price,
                                createdAt: Date(),
                                authorId: item.sellerId,
                                authorName: item.seller,
                                authorAvatarURL: item.sellerAvatar
                            )
                        } label: {
                            Label(L10n.tr("Edit", "編輯"), systemImage: "square.and.pencil")
                        }

                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label(L10n.tr("Delete", "刪除"), systemImage: "trash")
                        }
                    } else {
                        Button(role: .destructive) {
                            showReportSheet = true
                        } label: {
                            Label(L10n.tr("Report", "檢舉"), systemImage: "flag.fill")
                        }
                    }
                } label: {
                    PostToolbarIconCircle(icon: "ellipsis")
                }
            }
        }
        .sheet(item: $editingPost) { post in
            EditPostSheet(post: post) { payload in
                try await postEditor.update(payload: payload)
            }
        }
        .sheet(isPresented: $showReportSheet) {
            ReportPostSheet(postId: item.id, postKind: .secondhand)
        }
        .alert(L10n.tr("Delete this post?", "確定刪除這篇貼文？"), isPresented: $showDeleteConfirm) {
            Button(L10n.tr("Cancel", "取消"), role: .cancel) {}
            Button(L10n.tr("Delete", "刪除"), role: .destructive) {
                Task { await deletePost() }
            }
        } message: {
            Text(L10n.tr("This action cannot be undone.", "刪除後無法復原。"))
        }
        .alert(L10n.tr("Contact", "聯絡"), isPresented: $showContactAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(L10n.tr("Messaging is coming soon.", "站內訊息功能即將推出。"))
        }
    }

    private var mediaSection: some View {
        Group {
            if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(alignment: .topLeading) {
            Text(item.category.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.categoryColor(for: "market"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.92))
                .clipShape(Capsule())
                .padding(12)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("$\(Int(item.price))")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppColors.categoryColor(for: "market"))

                Text(item.condition)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())

                Spacer()
            }

            HStack(spacing: 14) {
                Button {
                    Task { await toggleLike() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(isLiked ? .red : AppColors.textMuted)
                        Text("\(likeCount)")
                            .foregroundStyle(AppColors.textMuted)
                    }
                    .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.plain)
                .disabled(isLiking)

                Text(item.timeAgo)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textMuted)

                Spacer()

                Button {
                    showContactAlert = true
                } label: {
                    Text(L10n.tr("Contact", "聯絡"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(AppColors.accent)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.tr("Description", "描述"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            Text(item.description.isEmpty ? L10n.tr("No description", "尚無描述") : item.description)
                .font(.system(size: 15))
                .foregroundStyle(AppColors.textMuted)
                .lineSpacing(4)
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private var sellerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.tr("Seller", "賣家"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            NavigationLink {
                UserPostsView(userId: item.sellerId)
            } label: {
                HStack(spacing: 10) {
                    Circle()
                        .fill(AppColors.accent.opacity(0.9))
                        .frame(width: 38, height: 38)
                        .overlay {
                            Text(String(item.seller.prefix(1)).uppercased())
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.seller)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)

                        Text(L10n.tr("Tap to view profile", "點擊查看個人頁"))
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.textMuted)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.textMuted)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        AppColors.categoryColor(for: "market").opacity(0.22),
                        AppColors.accent.opacity(0.24)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Image(systemName: "bag")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
    }

    private func toggleLike() async {
        guard !isLiking else { return }
        isLiking = true
        defer { isLiking = false }

        do {
            let newLiked = try await service.toggleLike(postId: item.id, currentlyLiked: isLiked)
            isLiked = newLiked
            likeCount = max(likeCount + (newLiked ? 1 : -1), 0)
        } catch {
            print("⚠️ Secondhand detail like failed: \(error)")
        }
    }

    private func deletePost() async {
        do {
            try await postEditor.delete(postId: item.id)
            dismiss()
        } catch {
            print("❌ Delete secondhand post failed: \(error)")
        }
    }
}
