//
//  HomeView.swift
//  CheeseApp
//
//  🏠 首页主视图
//  展示问候语、搜索栏、快捷操作、精选内容、论坛热门等
//
//  ⚠️ 注意：此视图不包含底部 Tab Bar
//  底部导航由 MainTabView 统一管理
//

import SwiftUI

// MARK: - 首页视图
struct HomeView: View {
    /// 视图模型
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var authService: AuthService

    var onSearchRequested: (() -> Void)? = nil
    
    /// 导航状态
    @State private var showRentList = false
    @State private var showSecondhandList = false
    @State private var showRideList = false
    @State private var showTeamList = false
    @State private var showForumList = false
    @State private var selectedFeaturedPost: RentPostItem?
    @State private var selectedForumPostRoute: HomeForumPostRoute?
    @State private var selectedRidePostRoute: HomeRidePostRoute?
    @State private var selectedTeamPostRoute: HomeTeamPostRoute?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色 - 奶酪米色
                Color(red: 0.96, green: 0.94, blue: 0.88)
                    .ignoresSafeArea()
                
                // 主内容
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // 头部：问候语 + 验证状态
                        HomeHeaderView(
                            greeting: viewModel.getGreeting(),
                            universityName: authService.currentUser?.school ?? L10n.tr("Unknown University", "未知學校"),
                            isVerified: authService.currentUser?.is_verified ?? false
                        )
                        
                        // 搜索栏
                        HomeSearchBarView {
                            onSearchRequested?()
                        }
                        
                        // 快捷操作
                        QuickActionsRowView(actions: viewModel.quickActions) { action in
                            handleQuickAction(action)
                        }
                        .contentShape(Rectangle())
                        .zIndex(20)
                        
                        // 精选推荐区块
                        featuredSection
                            .zIndex(10)
                        
                        // 组队卡片
                        if let groupsCard = viewModel.groupsCard {
                            ContentCardView(item: groupsCard) {
                                if let postId = groupsCard.postId {
                                    selectedTeamPostRoute = nil
                                    DispatchQueue.main.async {
                                        selectedTeamPostRoute = HomeTeamPostRoute(id: postId)
                                    }
                                } else {
                                    showTeamList = true
                                }
                            }
                        }
                        
                        // 拼车卡片
                        if let carpoolCard = viewModel.carpoolCard {
                            ContentCardView(item: carpoolCard) {
                                if let postId = carpoolCard.postId {
                                    selectedRidePostRoute = nil
                                    DispatchQueue.main.async {
                                        selectedRidePostRoute = HomeRidePostRoute(id: postId)
                                    }
                                } else {
                                    showRideList = true
                                }
                            }
                        }
                        
                        // 论坛热门区块
                        forumSection
                            .zIndex(10)
                        
                        // 底部留白（避免被 Tab Bar 遮挡）
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
            .navigationBarHidden(true)
            // 导航目标
            .navigationDestination(isPresented: $showRentList) {
                RentListView()
            }
            .navigationDestination(isPresented: $showSecondhandList) {
                SecondhandListView()
            }
            .navigationDestination(isPresented: $showRideList) {
                RideListView()
            }
            .navigationDestination(isPresented: $showTeamList) {
                TeamListView()
            }
            .navigationDestination(isPresented: $showForumList) {
                ForumListView()
            }
            .navigationDestination(item: $selectedFeaturedPost) { post in
                RentDetailView(post: post)
            }
            .navigationDestination(item: $selectedForumPostRoute) { route in
                HomeForumDetailLoaderView(postId: route.id)
            }
            .navigationDestination(item: $selectedRidePostRoute) { route in
                HomeRideDetailLoaderView(postId: route.id)
            }
            .navigationDestination(item: $selectedTeamPostRoute) { route in
                HomeTeamDetailLoaderView(postId: route.id)
            }
        }
    }
    
    // MARK: - 精选推荐区块
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: L10n.tr("Featured Near You", "附近推薦")) {
                showRentList = true
            }
            
            ForEach(viewModel.featuredCards) { card in
                ContentCardView(item: card) {
                    if let postId = card.postId,
                       let post = viewModel.featuredRentPosts.first(where: { $0.id == postId }) {
                        selectedFeaturedPost = nil
                        DispatchQueue.main.async {
                            selectedFeaturedPost = post
                        }
                    } else {
                        showRentList = true
                    }
                }
            }
        }
    }
    
    // MARK: - 论坛热门区块
    private var forumSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: L10n.tr("Trending in Forum", "論壇熱門")) {
                showForumList = true
            }
            
            ForEach(viewModel.forumCards) { forumCard in
                ForumCardView(item: forumCard) {
                    if let postId = forumCard.postId {
                        selectedForumPostRoute = nil
                        DispatchQueue.main.async {
                            selectedForumPostRoute = HomeForumPostRoute(id: postId)
                        }
                    } else {
                        showForumList = true
                    }
                }
            }
        }
    }
    
    // MARK: - 处理快捷操作点击
    private func handleQuickAction(_ action: HomeQuickAction) {
        switch action.destination {
        case .rent:
            showRentList = true
        case .market:
            showSecondhandList = true
        case .carpool:
            showRideList = true
        case .groups:
            showTeamList = true
        case .forum:
            showForumList = true
        }
    }
}

private struct HomeForumPostRoute: Identifiable, Hashable {
    let id: UUID
}

private struct HomeRidePostRoute: Identifiable, Hashable {
    let id: UUID
}

private struct HomeTeamPostRoute: Identifiable, Hashable {
    let id: UUID
}

private struct HomeForumDetailLoaderView: View {
    let postId: UUID
    @State private var post: ForumPostItem?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let post {
                ForumDetailView(post: post)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                    Text(errorMessage ?? L10n.tr("Failed to load post", "載入貼文失敗"))
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
        }
        .navigationTitle(L10n.tr("Post", "貼文"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            post = try await ForumService.shared.fetchPost(postId: postId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct HomeRideDetailLoaderView: View {
    let postId: UUID
    @State private var ride: RideItem?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let ride {
                RideDetailView(ride: ride)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                    Text(errorMessage ?? L10n.tr("Failed to load post", "載入貼文失敗"))
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
        }
        .navigationTitle(L10n.tr("Post", "貼文"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            ride = try await RideService.shared.fetchRide(postId: postId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct HomeTeamDetailLoaderView: View {
    let postId: UUID
    @State private var team: TeamItem?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let team {
                TeamDetailView(team: team)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                    Text(errorMessage ?? L10n.tr("Failed to load post", "載入貼文失敗"))
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
        }
        .navigationTitle(L10n.tr("Post", "貼文"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            team = try await TeamService.shared.fetchTeam(postId: postId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview
#Preview {
    HomeView()
}
