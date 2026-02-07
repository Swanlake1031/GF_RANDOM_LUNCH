//
//  ForumListView.swift
//  CheeseApp
//
//  💬 论坛列表视图
//  展示论坛帖子，支持分类筛选
//

import SwiftUI

struct ForumListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    @StateObject private var service = ForumService.shared
    @StateObject private var postEditor = UserPostsService()
    @State private var searchText = ""
    @State private var selectedCategory: ForumCategory = .all
    @State private var showingCreatePost = false
    @State private var selectedPost: ForumPostItem?
    @State private var editingPost: UserPostSummary?
    @State private var likingPostIDs: Set<UUID> = []
    
    var body: some View {
        ZStack {
            AppColors.pageBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // 分类筛选
                    categoryFilter
                    
                    // 加载状态
                    if service.isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else if service.posts.isEmpty {
                        emptyState
                    } else {
                        // 帖子列表
                        LazyVStack(spacing: 14) {
                            ForEach(filteredPosts) { post in
                                ForumPostCardView(
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
                await service.fetchPosts()
            }
        }
        .navigationTitle(L10n.tr("Forum", "論壇"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingCreatePost = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: L10n.tr("Search posts...", "搜尋貼文...")
        )
        .navigationDestination(isPresented: $showingCreatePost) {
            CreateForumView()
        }
        .navigationDestination(item: $selectedPost) { post in
            ForumDetailView(post: post)
        }
        .sheet(item: $editingPost) { post in
            EditPostSheet(post: post) { payload in
                try await postEditor.update(payload: payload)
                await service.fetchPosts()
            }
        }
        .task {
            await service.fetchPosts()
        }
    }
    
    // MARK: - 空状态
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(L10n.tr("No posts yet", "還沒有貼文"))
                .font(.system(size: 18, weight: .medium))
            Text(L10n.tr("Start a conversation!", "來開始第一篇討論吧！"))
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 60)
    }
    
    // MARK: - 分类筛选
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ForumCategory.allCases, id: \.self) { category in
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
    
    // MARK: - 筛选后的帖子
    private var filteredPosts: [ForumPostItem] {
        var result = service.posts
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if selectedCategory != .all {
            result = result.filter { $0.category == selectedCategory }
        }
        
        return result
    }

    private func toggleLike(for post: ForumPostItem) async {
        guard !likingPostIDs.contains(post.id) else { return }
        likingPostIDs.insert(post.id)
        defer { likingPostIDs.remove(post.id) }

        do {
            _ = try await service.toggleLike(postId: post.id, currentlyLiked: post.isLiked)
        } catch {
            print("⚠️ Forum like failed: \(error)")
        }
    }

    private func toEditableSummary(_ post: ForumPostItem) -> UserPostSummary {
        UserPostSummary(
            id: post.id,
            kind: .forum,
            title: post.title,
            description: post.content,
            subtitle: post.category.title,
            price: nil,
            createdAt: Date(),
            authorId: post.authorId ?? UUID(),
            authorName: post.authorName,
            authorAvatarURL: nil
        )
    }
}

// MARK: - 论坛分类
enum ForumCategory: CaseIterable {
    case all, discussion, question, confession, meme
    
    var title: String {
        switch self {
        case .all: return L10n.tr("All", "全部")
        case .discussion: return L10n.tr("Discussion", "討論")
        case .question: return L10n.tr("Q&A", "問答")
        case .confession: return L10n.tr("Confession", "匿名")
        case .meme: return L10n.tr("Memes", "迷因")
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "tray.full.fill"
        case .discussion: return "bubble.left.and.bubble.right.fill"
        case .question: return "questionmark.circle.fill"
        case .confession: return "theatermasks.fill"
        case .meme: return "face.smiling.fill"
        }
    }
}

// MARK: - 论坛帖子卡片
struct ForumPostCardView: View {
    let post: ForumPostItem
    let isOwnPost: Bool
    var onTap: (() -> Void)?
    var onLikeTap: (() async -> Void)?
    var onEditTap: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部：分类 + 时间 + 置顶
            HStack {
                // 分类标签
                HStack(spacing: 6) {
                    Image(systemName: post.category.icon)
                        .font(.system(size: 10))
                    Text(post.category.title)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color(.systemGray6))
                .cornerRadius(6)
                
                if post.isPinned || post.highlightType == .pinned {
                    HStack(spacing: 4) {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 9))
                        Text(L10n.tr("Pinned", "置頂"))
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(AppColors.accentStrong)
                }
                
                Spacer()
                
                Text(post.timeAgo)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Menu {
                    if isOwnPost {
                        Button {
                            onEditTap?()
                        } label: {
                            Label(L10n.tr("Edit", "編輯"), systemImage: "square.and.pencil")
                        }
                    } else {
                        Label(L10n.tr("Open details to report", "進入詳情後可檢舉"), systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 22, height: 22)
                }
            }
            
            // 作者信息
            HStack(spacing: 10) {
                if post.isAnonymous {
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "theatermasks.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                        }
                    
                    Text(L10n.tr("Anonymous", "匿名"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                } else {
                    if let authorId = post.authorId {
                        NavigationLink {
                            UserPostsView(userId: authorId)
                        } label: {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppColors.accentStrong, AppColors.accent],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        Text(String(post.authorName.prefix(1)))
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(.white)
                                    }

                                Text(post.authorName)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(AppColors.textPrimary)
                            }
                        }
                        .buttonStyle(.plain)
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.accentStrong, AppColors.accent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .overlay {
                                Text(String(post.authorName.prefix(1)))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                            }

                        Text(post.authorName)
                            .font(.system(size: 13, weight: .medium))
                    }
                }
            }
            
            // 标题
            Text(post.title)
                .font(.system(size: 17, weight: .semibold))
                .lineLimit(2)
            
            // 内容预览
            Text(post.content)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .lineLimit(3)
            
            // 图片预览（如果有）
            if post.hasImage {
                if let firstURLString = post.imageUrls.first, let url = URL(string: firstURLString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.14))
                    }
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            
            Divider()
            
            // 底部：互动数据
            HStack(spacing: 20) {
                // 点赞
                HStack(spacing: 6) {
                    Button {
                        Task { await onLikeTap?() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: post.isLiked ? "heart.fill" : "heart")
                                .foregroundStyle(post.isLiked ? .red : .secondary)
                            Text("\(post.likes)")
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                // 评论
                HStack(spacing: 6) {
                    Image(systemName: "bubble.right")
                    Text("\(post.comments)")
                }
                
                // 浏览
                HStack(spacing: 6) {
                    Image(systemName: "eye")
                    Text("\(post.views)")
                }
                
                Spacer()
                
                // 分享
                Button(action: { }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
        .postHighlightStyle(post.highlightType, cornerRadius: 20)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture { onTap?() }
    }
}

#Preview {
    NavigationStack {
        ForumListView()
    }
}
struct ForumDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    @ObservedObject private var service = ForumService.shared
    @StateObject private var postEditor = UserPostsService()

    private let tabBarReservedSpace: CGFloat = 84

    @State private var post: ForumPostItem
    @State private var comments: [ForumCommentItem] = []
    @State private var commentText = ""
    @State private var commentAnonymous = false
    @State private var isLoading = false
    @State private var isLiking = false
    @State private var isSubmittingComment = false
    @State private var errorMessage: String?
    @State private var showingReportSheet = false
    @State private var editingPost: UserPostSummary?
    @State private var showingDeleteConfirm = false

    init(post: ForumPostItem) {
        _post = State(initialValue: post)
    }

    var body: some View {
        ZStack {
            AppColors.pageBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    postHeader
                    postContent
                    commentSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 180)
            }
            .refreshable {
                await reloadData()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            PostDetailTopBar(title: L10n.tr("Forum Post", "論壇貼文"), onBack: { dismiss() }) {
                ShareLink(item: post.title) {
                    PostToolbarIconCircle(icon: "square.and.arrow.up")
                }

                Menu {
                    if authService.currentUser?.id == post.authorId {
                        Button {
                            editingPost = UserPostSummary(
                                id: post.id,
                                kind: .forum,
                                title: post.title,
                                description: post.content,
                                subtitle: post.category.title,
                                price: nil,
                                createdAt: Date(),
                                authorId: post.authorId ?? UUID(),
                                authorName: post.authorName,
                                authorAvatarURL: nil
                            )
                        } label: {
                            Label(L10n.tr("Edit", "編輯"), systemImage: "square.and.pencil")
                        }

                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Label(L10n.tr("Delete", "刪除"), systemImage: "trash")
                        }
                    } else {
                        Button(role: .destructive) {
                            showingReportSheet = true
                        } label: {
                            Label(L10n.tr("Report", "檢舉"), systemImage: "flag.fill")
                        }
                    }
                } label: {
                    PostToolbarIconCircle(icon: "ellipsis")
                }
            }
        }
        .overlay(alignment: .bottom) {
            commentComposer
                .padding(.bottom, tabBarReservedSpace)
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportPostSheet(postId: post.id, postKind: .forum)
        }
        .sheet(item: $editingPost) { summary in
            EditPostSheet(post: summary) { payload in
                try await postEditor.update(payload: payload)
                await reloadData()
            }
        }
        .alert(L10n.tr("Delete this post?", "確定刪除這篇貼文？"), isPresented: $showingDeleteConfirm) {
            Button(L10n.tr("Cancel", "取消"), role: .cancel) {}
            Button(L10n.tr("Delete", "刪除"), role: .destructive) {
                Task { await deletePost() }
            }
        } message: {
            Text(L10n.tr("This action cannot be undone.", "刪除後無法復原。"))
        }
        .task {
            await reloadData()
        }
        .onReceive(service.$posts) { latestPosts in
            guard let updated = latestPosts.first(where: { $0.id == post.id }) else { return }
            post = updated
        }
    }

    private var postHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label(post.category.title, systemImage: post.category.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())

                if post.isPinned {
                    Label(L10n.tr("Pinned", "置頂"), systemImage: "pin.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppColors.link)
                }

                Spacer()

                Text(post.timeAgo)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textMuted)
            }

            if let authorId = post.authorId, !post.isAnonymous {
                NavigationLink {
                    UserPostsView(userId: authorId)
                } label: {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(AppColors.accent)
                            .frame(width: 32, height: 32)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)
                            }

                        Text(post.authorName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "theatermasks.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                        }

                    Text(L10n.tr("Anonymous", "匿名"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.textPrimary)
                }
            }
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private var postContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(post.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            if !post.content.isEmpty {
                Text(post.content)
                    .font(.system(size: 15))
                    .foregroundStyle(AppColors.textMuted)
                    .lineSpacing(4)
            }

            if !post.imageUrls.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(post.imageUrls.enumerated()), id: \.offset) { _, imageURL in
                            if let url = URL(string: imageURL) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.gray.opacity(0.15))
                                }
                                .frame(width: 220, height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }
                }
            }

            if !post.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(post.tags.enumerated()), id: \.offset) { _, tag in
                            Text("#\(tag)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppColors.link)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppColors.link.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Divider().overlay(AppColors.divider)

            HStack(spacing: 18) {
                Button(action: {
                    Task { await toggleLike() }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(post.isLiked ? .red : AppColors.textMuted)
                        Text("\(post.likes)")
                    }
                    .font(.system(size: 14, weight: .medium))
                }
                .disabled(isLiking)

                HStack(spacing: 6) {
                    Image(systemName: "bubble.right")
                    Text("\(post.comments)")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.textMuted)

                HStack(spacing: 6) {
                    Image(systemName: "eye")
                    Text("\(post.views)")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.textMuted)

                Spacer()
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("Comments", "評論"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)
            } else if comments.isEmpty {
                Text(L10n.tr("No comments yet. Be the first to reply.", "還沒有評論，來當第一位留言者吧。"))
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(comments) { comment in
                        commentRow(comment)
                    }
                }
            }
        }
    }

    private func commentRow(_ comment: ForumCommentItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(comment.isAnonymous ? Color(.systemGray4) : AppColors.accent.opacity(0.9))
                .frame(width: 30, height: 30)
                .overlay {
                    Image(systemName: comment.isAnonymous ? "theatermasks.fill" : "person.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(comment.authorName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)

                    Text(comment.timeAgo)
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textMuted)

                    Spacer()

                    if comment.likeCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                            Text("\(comment.likeCount)")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(AppColors.textMuted)
                    }
                }

                Text(comment.content)
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private var commentComposer: some View {
        VStack(spacing: 10) {
            Divider().overlay(AppColors.divider)

            HStack(alignment: .center, spacing: 10) {
                TextField(L10n.tr("Write a comment...", "寫下你的評論..."), text: $commentText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button(action: {
                    Task { await submitComment() }
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 40, height: 40)
                        .background(AppColors.accent)
                        .clipShape(Circle())
                }
                .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmittingComment)
                .opacity(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
            }

            Toggle(L10n.tr("Comment anonymously", "匿名評論"), isOn: $commentAnonymous)
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textMuted)
                .tint(AppColors.link)
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(AppColors.pageBackground)
    }

    private func reloadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let latestPostTask = service.fetchPost(postId: post.id)
            async let latestCommentsTask = service.fetchComments(postId: post.id)
            let (latestPost, latestComments) = try await (latestPostTask, latestCommentsTask)
            post = latestPost
            comments = latestComments
            errorMessage = nil
        } catch {
            if isCancellation(error) { return }
            errorMessage = "\(L10n.tr("Load failed", "載入失敗")): \(error.localizedDescription)"
        }
    }

    private func toggleLike() async {
        guard !isLiking else { return }
        isLiking = true
        defer { isLiking = false }

        let previousLiked = post.isLiked
        let previousLikes = post.likes
        let optimisticLiked = !previousLiked
        let optimisticLikes = max(previousLikes + (optimisticLiked ? 1 : -1), 0)
        post.isLiked = optimisticLiked
        post.likes = optimisticLikes

        do {
            let committedLiked = try await service.toggleLike(postId: post.id, currentlyLiked: previousLiked)
            post.isLiked = committedLiked
            if let synced = service.posts.first(where: { $0.id == post.id }) {
                post.likes = synced.likes
            } else if committedLiked != optimisticLiked {
                post.likes = max(previousLikes + (committedLiked ? 1 : -1), 0)
            }
            errorMessage = nil
        } catch {
            post.isLiked = previousLiked
            post.likes = previousLikes
            if isCancellation(error) { return }
            errorMessage = error.localizedDescription
        }
    }

    private func submitComment() async {
        let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSubmittingComment else { return }

        isSubmittingComment = true
        defer { isSubmittingComment = false }

        do {
            try await service.createComment(postId: post.id, content: trimmed, isAnonymous: commentAnonymous)
            commentText = ""
            commentAnonymous = false
            comments = try await service.fetchComments(postId: post.id)
            if let updated = service.posts.first(where: { $0.id == post.id }) {
                post.comments = updated.comments
            }
            errorMessage = nil
        } catch {
            if isCancellation(error) { return }
            errorMessage = error.localizedDescription
        }
    }

    private func deletePost() async {
        do {
            try await postEditor.delete(postId: post.id)
            dismiss()
        } catch {
            if isCancellation(error) { return }
            errorMessage = error.localizedDescription
        }
    }

    private func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == URLError.cancelled.rawValue
    }
}

#Preview {
    NavigationStack {
        ForumDetailView(
            post: ForumPostItem(
                id: UUID(),
                authorId: UUID(),
                title: "How to find good study spots on campus?",
                content: "Need recommendations for late-night study.",
                category: .question,
                authorName: "Alice",
                isAnonymous: false,
                timeAgo: "1h ago",
                likes: 4,
                comments: 2,
                views: 80,
                tags: ["study", "campus"],
                isLiked: false,
                isPinned: false,
                highlightType: .normal,
                imageUrls: [],
                hasImage: false
            )
        )
    }
}
