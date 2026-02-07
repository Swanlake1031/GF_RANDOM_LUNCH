//
//  TeamListView.swift
//  CheeseApp
//
//  👥 组队列表视图
//  展示所有组队信息，支持筛选
//

import SwiftUI

struct TeamListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    @StateObject private var service = TeamService.shared
    @StateObject private var postEditor = UserPostsService()
    @State private var searchText = ""
    @State private var selectedCategory: TeamCategory = .all
    @State private var showingCreateGroup = false
    @State private var showMessagingComingSoon = false
    @State private var joinedTeamIDs: Set<UUID> = []
    @State private var editingPost: UserPostSummary?
    @State private var likingPostIDs: Set<UUID> = []
    @State private var selectedTeam: TeamItem?
    
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
                    } else if service.teams.isEmpty {
                        emptyState
                    } else {
                        // 组队卡片列表
                        LazyVStack(spacing: 14) {
                            ForEach(filteredTeams) { team in
                                TeamCardView(
                                    team: team,
                                    isJoined: joinedTeamIDs.contains(team.id),
                                    isOwnPost: authService.currentUser?.id == team.creatorId
                                ) {
                                    joinedTeamIDs.insert(team.id)
                                    showMessagingComingSoon = true
                                } onLikeTap: {
                                    await toggleLike(for: team)
                                } onEditTap: {
                                    editingPost = toEditableSummary(team)
                                } onOpenTap: {
                                    selectedTeam = team
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
                await service.fetchTeams()
            }
        }
        .navigationTitle("Groups")
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
                Button(action: { showingCreateGroup = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search groups...")
        .navigationDestination(isPresented: $showingCreateGroup) {
            CreateTeamView()
        }
        .sheet(item: $editingPost) { post in
            EditPostSheet(post: post) { payload in
                try await postEditor.update(payload: payload)
                await service.fetchTeams()
            }
        }
        .navigationDestination(item: $selectedTeam) { team in
            TeamDetailView(team: team)
        }
        .alert("Messaging Coming Soon", isPresented: $showMessagingComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Group chat is not implemented yet. The team join action has been saved locally.")
        }
        .task {
            await service.fetchTeams()
        }
    }
    
    // MARK: - 空状态
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No groups yet")
                .font(.system(size: 18, weight: .medium))
            Text("Create or find a group!")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 60)
    }
    
    // MARK: - 分类筛选
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TeamCategory.allCases, id: \.self) { category in
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
    
    // MARK: - 筛选后的组队
    private var filteredTeams: [TeamItem] {
        var result = service.teams
        
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

    private func toggleLike(for team: TeamItem) async {
        guard !likingPostIDs.contains(team.id) else { return }
        likingPostIDs.insert(team.id)
        defer { likingPostIDs.remove(team.id) }

        do {
            _ = try await service.toggleLike(postId: team.id, currentlyLiked: team.isLiked)
        } catch {
            print("⚠️ Team like failed: \(error)")
        }
    }

    private func toEditableSummary(_ team: TeamItem) -> UserPostSummary {
        UserPostSummary(
            id: team.id,
            kind: .team,
            title: team.title,
            description: team.description,
            subtitle: team.category.title,
            price: nil,
            createdAt: Date(),
            authorId: team.creatorId,
            authorName: team.creatorName,
            authorAvatarURL: team.creatorAvatar
        )
    }
}

// MARK: - 组队分类
enum TeamCategory: CaseIterable {
    case all, study, project, hackathon, sports, social
    
    var title: String {
        switch self {
        case .all: return "All"
        case .study: return "Study"
        case .project: return "Project"
        case .hackathon: return "Hackathon"
        case .sports: return "Sports"
        case .social: return "Social"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .gray
        case .study: return AppColors.categoryColor(for: "rent")
        case .project: return AppColors.categoryColor(for: "groups")
        case .hackathon: return AppColors.accentStrong
        case .sports: return AppColors.categoryColor(for: "carpool")
        case .social: return AppColors.categoryColor(for: "forum")
        }
    }
}

// MARK: - 组队卡片
struct TeamCardView: View {
    let team: TeamItem
    let isJoined: Bool
    let isOwnPost: Bool
    var onJoinTap: (() -> Void)?
    var onLikeTap: (() async -> Void)?
    var onEditTap: (() -> Void)?
    var onOpenTap: (() -> Void)?
    @State private var showingReportSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let imageUrl = team.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .overlay {
                                Image(systemName: "person.3.fill")
                                    .foregroundStyle(.gray.opacity(0.45))
                            }
                    }
                }
                .frame(height: 160)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            // 头部：分类 + 紧急标签
            HStack {
                // 分类标签
                Text(team.category.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(team.category.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(team.category.color.opacity(0.15))
                    .cornerRadius(8)
                
                if team.isUrgent {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.red)
                            .frame(width: 6, height: 6)
                        Text("Urgent")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.red)
                    }
                }
                
                Spacer()
                
                // 人数进度
                HStack(spacing: 6) {
                    ForEach(0..<team.maxMembers, id: \.self) { i in
                        Circle()
                            .fill(i < team.currentMembers ? team.category.color : Color(.systemGray4))
                            .frame(width: 8, height: 8)
                    }
                }

                Menu {
                    if isOwnPost {
                        Button {
                            onEditTap?()
                        } label: {
                            Label("Edit", systemImage: "square.and.pencil")
                        }
                    } else {
                        Button(role: .destructive) {
                            showingReportSheet = true
                        } label: {
                            Label("Report", systemImage: "flag.fill")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(8)
                        .background(AppColors.accent.opacity(0.9))
                        .clipShape(Circle())
                }
            }
            
            // 标题
            Text(team.title)
                .font(.system(size: 17, weight: .semibold))
                .lineLimit(2)
            
            // 描述
            Text(team.description)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            // 技能标签
            if !team.skills.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(team.skills.enumerated()), id: \.offset) { _, skill in
                            Text(skill)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(.systemGray6))
                                .cornerRadius(6)
                        }
                    }
                }
            }
            
            Divider()
            
            // 底部：发布者 + 截止日期
            HStack {
                // 发布者
                NavigationLink {
                    UserPostsView(userId: team.creatorId)
                } label: {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [team.category.color, team.category.color.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                            .overlay {
                                Text(String(team.creatorName.prefix(1)))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }

                        Text(team.creatorName)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // 截止日期
                if let deadline = team.deadline {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text("Due \(formatDate(deadline))")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(.secondary)
                }

                Button {
                    Task { await onLikeTap?() }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: team.isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(team.isLiked ? .red : .secondary)
                        Text("\(team.likeCount)")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Button(action: { onOpenTap?() }) {
                    Text(L10n.tr("View", "查看"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppColors.accent.opacity(0.85))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                // 加入按钮
                Button(action: { onJoinTap?() }) {
                    Text(isJoined ? "Joined" : "Join")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isJoined ? Color.secondary : Color.black)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(isJoined ? Color(.systemGray5) : AppColors.accent)
                        .cornerRadius(8)
                }
                .disabled(isJoined)
            }
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
        .postHighlightStyle(team.highlightType, cornerRadius: 20)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture { onOpenTap?() }
        .sheet(isPresented: $showingReportSheet) {
            ReportPostSheet(postId: team.id, postKind: .team)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        TeamListView()
    }
}

struct TeamDetailView: View {
    let team: TeamItem

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    @StateObject private var postEditor = UserPostsService()
    @ObservedObject private var service = TeamService.shared

    @State private var isLiked: Bool
    @State private var likeCount: Int
    @State private var isLiking = false
    @State private var isJoined = false
    @State private var showJoinAlert = false
    @State private var showDeleteConfirm = false
    @State private var showReportSheet = false
    @State private var editingPost: UserPostSummary?

    init(team: TeamItem) {
        self.team = team
        _isLiked = State(initialValue: team.isLiked)
        _likeCount = State(initialValue: team.likeCount)
    }

    private var isOwnPost: Bool {
        authService.currentUser?.id == team.creatorId
    }

    var body: some View {
        ZStack {
            AppColors.pageBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerSection
                    skillsSection
                    creatorSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            PostDetailTopBar(title: L10n.tr("Group Post", "組隊貼文"), onBack: { dismiss() }) {
                ShareLink(item: team.title) {
                    PostToolbarIconCircle(icon: "square.and.arrow.up")
                }

                Menu {
                    if isOwnPost {
                        Button {
                            editingPost = UserPostSummary(
                                id: team.id,
                                kind: .team,
                                title: team.title,
                                description: team.description,
                                subtitle: team.category.title,
                                price: nil,
                                createdAt: Date(),
                                authorId: team.creatorId,
                                authorName: team.creatorName,
                                authorAvatarURL: team.creatorAvatar
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
            ReportPostSheet(postId: team.id, postKind: .team)
        }
        .alert(L10n.tr("Delete this post?", "確定刪除這篇貼文？"), isPresented: $showDeleteConfirm) {
            Button(L10n.tr("Cancel", "取消"), role: .cancel) {}
            Button(L10n.tr("Delete", "刪除"), role: .destructive) {
                Task { await deletePost() }
            }
        } message: {
            Text(L10n.tr("This action cannot be undone.", "刪除後無法復原。"))
        }
        .alert(L10n.tr("Join Request", "加入申請"), isPresented: $showJoinAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(isJoined
                 ? L10n.tr("You have already joined this group.", "你已加入此群組。")
                 : L10n.tr("Group chat is coming soon.", "群組聊天功能即將推出。"))
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(team.category.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.categoryColor(for: "groups"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppColors.categoryColor(for: "groups").opacity(0.15))
                    .clipShape(Capsule())

                Spacer()

                if let deadline = team.deadline {
                    Label(formatDate(deadline), systemImage: "calendar")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.textMuted)
                }
            }

            Text(team.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Text(team.description)
                .font(.system(size: 15))
                .foregroundStyle(AppColors.textMuted)
                .lineSpacing(4)

            HStack(spacing: 14) {
                Label("\(team.currentMembers)/\(team.maxMembers)", systemImage: "person.2")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.textMuted)

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

                Spacer()

                Button {
                    if !isJoined { isJoined = true }
                    showJoinAlert = true
                } label: {
                    Text(isJoined ? L10n.tr("Joined", "已加入") : L10n.tr("Join", "加入"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isJoined ? AppColors.textMuted : .black)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(isJoined ? Color(.systemGray5) : AppColors.accent)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.tr("Skills Needed", "需要技能"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            if team.skills.isEmpty {
                Text(L10n.tr("No specific skills required", "暫無指定技能"))
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.textMuted)
            } else {
                TeamFlowLayout(spacing: 8) {
                    ForEach(Array(team.skills.enumerated()), id: \.offset) { _, skill in
                        Text(skill)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppColors.categoryColor(for: "groups"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(AppColors.categoryColor(for: "groups").opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private var creatorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.tr("Organizer", "發起人"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            NavigationLink {
                UserPostsView(userId: team.creatorId)
            } label: {
                HStack(spacing: 10) {
                    Circle()
                        .fill(AppColors.accent.opacity(0.9))
                        .frame(width: 38, height: 38)
                        .overlay {
                            Text(String(team.creatorName.prefix(1)).uppercased())
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(team.creatorName)
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

    private func toggleLike() async {
        guard !isLiking else { return }
        isLiking = true
        defer { isLiking = false }

        do {
            let newLiked = try await service.toggleLike(postId: team.id, currentlyLiked: isLiked)
            isLiked = newLiked
            likeCount = max(likeCount + (newLiked ? 1 : -1), 0)
        } catch {
            print("⚠️ Team detail like failed: \(error)")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func deletePost() async {
        do {
            try await postEditor.delete(postId: team.id)
            dismiss()
        } catch {
            print("❌ Delete team post failed: \(error)")
        }
    }
}
