//
//  MainTabView.swift
//  CheeseApp
//
//  🎯 主标签导航视图
//  自定义底部导航栏：Home - Search - Create(+) - Chat - Profile
//

import SwiftUI

// MARK: - 主视图
struct MainTabView: View {
    @State private var selectedTab: TabItem = .home
    @State private var showCreatePost = false
    @State private var homeRootResetID = UUID()
    @State private var searchRootResetID = UUID()
    @State private var profileRootResetID = UUID()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 主内容区域
            Group {
                switch selectedTab {
                case .home:
                    HomeView {
                        selectedTab = .search
                    }
                    .id(homeRootResetID)
                case .search:
                    SearchView()
                        .id(searchRootResetID)
                case .chat:
                    NavigationStack {
                        ChatListView()
                    }
                case .profile:
                    ProfileView()
                        .id(profileRootResetID)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 自定义底部导航栏
            CustomTabBar(
                selectedTab: $selectedTab,
                onHomeReselect: {
                    homeRootResetID = UUID()
                },
                onSearchReselect: {
                    searchRootResetID = UUID()
                },
                onProfileReselect: {
                    profileRootResetID = UUID()
                },
                onCreateTap: {
                    showCreatePost = true
                }
            )
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showCreatePost) {
            CreatePostView()
        }
    }
}

// MARK: - Tab 枚举
enum TabItem: String, CaseIterable {
    case home
    case search
    case chat
    case profile
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .search: return "magnifyingglass"
        case .chat: return "bubble.left.and.bubble.right"
        case .profile: return "person"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .search: return "magnifyingglass"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .profile: return "person.fill"
        }
    }
}

// MARK: - 自定义底部导航栏
struct CustomTabBar: View {
    @Binding var selectedTab: TabItem
    var onHomeReselect: () -> Void
    var onSearchReselect: () -> Void
    var onProfileReselect: () -> Void
    var onCreateTap: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Home
            TabBarButton(
                icon: TabItem.home.icon,
                selectedIcon: TabItem.home.selectedIcon,
                isSelected: selectedTab == .home,
                showIndicator: true
            ) {
                if selectedTab == .home {
                    onHomeReselect()
                } else {
                    selectedTab = .home
                }
            }
            
            // Search
            TabBarButton(
                icon: TabItem.search.icon,
                selectedIcon: TabItem.search.selectedIcon,
                isSelected: selectedTab == .search,
                showIndicator: true
            ) {
                if selectedTab == .search {
                    onSearchReselect()
                } else {
                    selectedTab = .search
                }
            }
            
            // Center Create Button (+)
            CreateButton(action: onCreateTap)
                .padding(.horizontal, 12)
            
            // Chat
            TabBarButton(
                icon: TabItem.chat.icon,
                selectedIcon: TabItem.chat.selectedIcon,
                isSelected: selectedTab == .chat,
                showIndicator: true
            ) {
                selectedTab = .chat
            }
            
            // Profile
            TabBarButton(
                icon: TabItem.profile.icon,
                selectedIcon: TabItem.profile.selectedIcon,
                isSelected: selectedTab == .profile,
                showIndicator: true
            ) {
                if selectedTab == .profile {
                    onProfileReselect()
                } else {
                    selectedTab = .profile
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 9)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.black)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -5)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

// MARK: - Tab 按钮
struct TabBarButton: View {
    let icon: String
    let selectedIcon: String
    let isSelected: Bool
    let showIndicator: Bool
    let action: () -> Void
    
    // 奶酪黄色
    private let accentColor = Color(red: 0.95, green: 0.85, blue: 0.45)
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: isSelected ? selectedIcon : icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isSelected ? accentColor : .white.opacity(0.5))
                
                // 选中指示器
                if showIndicator {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isSelected ? accentColor : Color.clear)
                        .frame(width: 24, height: 3)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - 中间创建按钮
struct CreateButton: View {
    let action: () -> Void
    
    // 奶酪黄色
    private let accentColor = Color(red: 0.95, green: 0.85, blue: 0.45)
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(accentColor)
                    .frame(width: 52, height: 52)
                    .shadow(color: accentColor.opacity(0.4), radius: 10, x: 0, y: 4)
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.black)
            }
        }
        .offset(y: -8)
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(AuthService.shared)
}
