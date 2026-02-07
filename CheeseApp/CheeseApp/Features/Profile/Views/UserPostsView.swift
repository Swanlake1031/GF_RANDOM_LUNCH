import SwiftUI

struct UserPostsView: View {
    let userId: UUID
    var initialKind: PostKind? = nil

    @EnvironmentObject private var authService: AuthService
    @StateObject private var service = UserPostsService()

    @State private var editingPost: UserPostSummary?
    @State private var reportingPost: UserPostSummary?
    @State private var deletingPost: UserPostSummary?

    private var isCurrentUser: Bool {
        authService.currentUser?.id == userId
    }

    private var visiblePosts: [UserPostSummary] {
        guard let initialKind else { return service.posts }
        return service.posts.filter { $0.kind == initialKind }
    }

    private var screenTitle: String {
        if isCurrentUser {
            if let initialKind {
                return "My \(initialKind.displayName) Posts"
            }
            return "Manage My Posts"
        }
        if let initialKind {
            return "\(initialKind.displayName) Posts"
        }
        return "Profile"
    }

    var body: some View {
        ZStack {
            AppColors.pageBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    profileHeader

                    if service.isLoading {
                        ProgressView()
                            .padding(.top, 36)
                    } else if visiblePosts.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(visiblePosts) { post in
                                UserPostCard(
                                    post: post,
                                    isCurrentUser: isCurrentUser,
                                    onEdit: { editingPost = post },
                                    onReport: { reportingPost = post },
                                    onDelete: { deletingPost = post }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(screenTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await service.load(userId: userId)
        }
        .sheet(item: $editingPost) { post in
            EditPostSheet(post: post) { payload in
                try await service.update(payload: payload)
                await service.refreshPosts(userId: userId)
            }
        }
        .sheet(item: $reportingPost) { post in
            ReportPostSheet(postId: post.id, postKind: post.kind)
        }
        .alert(
            L10n.tr("Delete this post?", "確定刪除這篇貼文？"),
            isPresented: Binding(
                get: { deletingPost != nil },
                set: { if !$0 { deletingPost = nil } }
            ),
            presenting: deletingPost
        ) { post in
            Button(L10n.tr("Cancel", "取消"), role: .cancel) {
                deletingPost = nil
            }
            Button(L10n.tr("Delete", "刪除"), role: .destructive) {
                Task {
                    do {
                        try await service.delete(postId: post.id)
                        await service.refreshPosts(userId: userId)
                        deletingPost = nil
                    } catch {
                        deletingPost = nil
                    }
                }
            }
        } message: { _ in
            Text(L10n.tr("This action cannot be undone.", "刪除後無法復原。"))
        }
    }

    private var profileHeader: some View {
        HStack(spacing: 12) {
            avatarView(urlString: service.profile?.avatarUrl, fallbackName: service.profile?.fullName ?? service.profile?.email ?? "U")
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(service.profile?.fullName ?? service.profile?.email ?? "User")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text("\(visiblePosts.count) posts")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textMuted)
            }

            Spacer()
        }
        .padding(14)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 30))
                .foregroundStyle(.secondary)
            Text("No posts yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.top, 36)
    }

    private func avatarView(urlString: String?, fallbackName: String) -> some View {
        Group {
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    avatarPlaceholder(name: fallbackName)
                }
            } else {
                avatarPlaceholder(name: fallbackName)
            }
        }
        .clipShape(Circle())
    }

    private func avatarPlaceholder(name: String) -> some View {
        Circle()
            .fill(AppColors.accent)
            .overlay {
                Text(String(name.prefix(1)).uppercased())
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
            }
    }
}

private struct UserPostCard: View {
    let post: UserPostSummary
    let isCurrentUser: Bool
    let onEdit: () -> Void
    let onReport: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label(post.kind.displayName, systemImage: post.kind.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())

                Spacer()

                Text(post.relativeTimeText)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textMuted)

                Menu {
                    if isCurrentUser {
                        Button {
                            onEdit()
                        } label: {
                            Label("Edit", systemImage: "square.and.pencil")
                        }

                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }

                    if !isCurrentUser {
                        Button(role: .destructive) {
                            onReport()
                        } label: {
                            Label("Report", systemImage: "flag.fill")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColors.textMuted)
                        .frame(width: 28, height: 28)
                }
            }

            Text(post.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            if !post.description.isEmpty {
                Text(post.description)
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.textMuted)
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                if let priceText = post.priceDisplayText {
                    Text(priceText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.link)
                }

                Text(post.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textMuted)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}
