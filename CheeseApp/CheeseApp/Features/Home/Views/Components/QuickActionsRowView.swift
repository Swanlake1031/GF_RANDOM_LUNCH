//
//  QuickActionsRowView.swift
//  CheeseApp
//
//  ⚡ 快捷操作行组件
//  显示一排可点击的快捷入口按钮
//

import SwiftUI

// MARK: - 快捷操作行视图
struct QuickActionsRowView: View {
    /// 快捷操作数据列表
    let actions: [HomeQuickAction]
    
    /// 点击回调
    var onActionTap: ((HomeQuickAction) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            Text(L10n.tr("Quick Actions", "快捷操作"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
            
            // 按钮行
            HStack(spacing: 14) {
                ForEach(actions) { action in
                    QuickActionItemView(action: action) {
                        onActionTap?(action)
                    }
                }
            }
        }
    }
}

// MARK: - 单个快捷操作按钮
struct QuickActionItemView: View {
    let action: HomeQuickAction
    var onTap: (() -> Void)?
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            VStack(spacing: 8) {
                // 图标容器
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.white)
                        .frame(width: 56, height: 56)
                        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
                    
                    Image(systemName: action.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.85))
                }
                
                // 标题
                Text(localizedTitle(for: action))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textMuted)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private func localizedTitle(for action: HomeQuickAction) -> String {
        switch action.destination {
        case .rent:
            return L10n.tr("Rent", "租房")
        case .market:
            return L10n.tr("Market", "二手")
        case .carpool:
            return L10n.tr("Carpool", "拼車")
        case .groups:
            return L10n.tr("Groups", "群組")
        case .forum:
            return L10n.tr("Forum", "論壇")
        }
    }
}

// MARK: - Preview
#Preview {
    QuickActionsRowView(actions: HomeQuickAction.defaultActions) { action in
        print("Tapped: \(action.title)")
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
