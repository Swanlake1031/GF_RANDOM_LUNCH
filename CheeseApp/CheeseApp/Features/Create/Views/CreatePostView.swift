//
//  CreatePostView.swift
//  CheeseApp
//
//  ➕ 创建帖子页面
//  选择发布类型并导航到具体表单
//

import SwiftUI

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: CreatePostType? = nil
    @State private var navigateToForm = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.pageBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // 标题
                        VStack(spacing: 8) {
                            Text(L10n.tr("What would you like to post?", "你想發布什麼？"))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(AppColors.textPrimary)
                            
                            Text(L10n.tr("Choose a category to get started", "先選擇一個分類開始"))
                                .font(.system(size: 15))
                                .foregroundStyle(AppColors.textMuted)
                        }
                        .padding(.top, 20)
                        
                        // 发布类型选择
                        VStack(spacing: 14) {
                            ForEach(CreatePostType.allCases, id: \.self) { type in
                                PostTypeCard(
                                    type: type,
                                    isSelected: selectedType == type
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedType = type
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        Spacer(minLength: 40)
                        
                        // 继续按钮
                        if selectedType != nil {
                            Button(action: {
                                navigateToForm = true
                            }) {
                                Text(L10n.tr("Continue", "繼續"))
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(AppColors.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .padding(.horizontal, 16)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle(L10n.tr("Create Post", "發布貼文"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.tr("Cancel", "取消")) {
                        dismiss()
                    }
                    .foregroundStyle(AppColors.accentStrong)
                }
            }
            .navigationDestination(isPresented: $navigateToForm) {
                if let type = selectedType {
                    destinationView(for: type)
                }
            }
        }
    }
    
    // 根据类型返回对应的创建视图
    @ViewBuilder
    private func destinationView(for type: CreatePostType) -> some View {
        switch type {
        case .rent:
            CreateRentView(onCreated: {
                dismiss()
            })
        case .market:
            CreateSecondhandView(onCreated: {
                dismiss()
            })
        case .carpool:
            CreateRideView(onCreated: {
                dismiss()
            })
        case .groups:
            CreateTeamView(onCreated: {
                dismiss()
            })
        case .forum:
            CreateForumView(onCreated: {
                dismiss()
            })
        }
    }
}

// MARK: - 创建帖子类型枚举 (UI专用)
enum CreatePostType: String, CaseIterable {
    case rent
    case market
    case carpool
    case groups
    case forum
    
    var title: String {
        switch self {
        case .rent: return L10n.tr("Rental Listing", "租房貼文")
        case .market: return L10n.tr("Sell an Item", "二手出售")
        case .carpool: return L10n.tr("Carpool / Ride", "拼車 / 找車")
        case .groups: return L10n.tr("Create a Group", "建立群組")
        case .forum: return L10n.tr("Forum Post", "論壇貼文")
        }
    }
    
    var subtitle: String {
        switch self {
        case .rent: return L10n.tr("Post an apartment, room, or sublease", "發布公寓、房間或轉租資訊")
        case .market: return L10n.tr("Sell textbooks, electronics, furniture...", "出售課本、電子產品、家具等")
        case .carpool: return L10n.tr("Offer or find a ride", "提供或尋找共乘")
        case .groups: return L10n.tr("Study groups, project teams, activities", "學習小組、專案團隊、活動社群")
        case .forum: return L10n.tr("Share thoughts, ask questions, confess...", "分享想法、提問、匿名發帖")
        }
    }
    
    var icon: String {
        switch self {
        case .rent: return "key.fill"
        case .market: return "bag.fill"
        case .carpool: return "car.fill"
        case .groups: return "person.2.fill"
        case .forum: return "bubble.left.and.bubble.right.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .rent:
            return AppColors.categoryColor(for: "rent")
        case .market:
            return AppColors.categoryColor(for: "market")
        case .carpool:
            return AppColors.categoryColor(for: "carpool")
        case .groups:
            return AppColors.categoryColor(for: "groups")
        case .forum:
            return AppColors.categoryColor(for: "forum")
        }
    }
}

// MARK: - 帖子类型卡片
struct PostTypeCard: View {
    let type: CreatePostType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 图标
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(type.color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: type.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(type.color)
                }
                
                // 文字
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text(type.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(AppColors.textMuted)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 选中指示
                ZStack {
                    Circle()
                        .stroke(isSelected ? type.color : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(type.color)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isSelected ? type.color : Color.clear, lineWidth: 2)
                    )
            )
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        }
    }
}

#Preview {
    CreatePostView()
}
