//
//  CustomButton.swift
//  CheeseApp
//
//  🎯 自定义按钮组件
//

import SwiftUI

// ============================================
// 自定义按钮
// ============================================

struct CustomButton: View {
    let title: String
    let style: ButtonStyle
    let isLoading: Bool
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
        case danger
    }
    
    init(
        _ title: String,
        style: ButtonStyle = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
                    .font(AppFonts.button)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(10)
        }
        .disabled(isLoading)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return AppColors.primary
        case .secondary: return AppColors.secondaryBackground
        case .danger: return AppColors.error
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return AppColors.text
        case .danger: return .white
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        CustomButton("主要按钮") {}
        CustomButton("次要按钮", style: .secondary) {}
        CustomButton("加载中", isLoading: true) {}
    }
    .padding()
}

enum PostPromotionPlan: String, CaseIterable, Identifiable {
    case none
    case urgent7Days
    case urgent14Days

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:
            return L10n.tr("Normal", "普通发布")
        case .urgent7Days:
            return L10n.tr("Urgent 7 Days", "急帖 7 天")
        case .urgent14Days:
            return L10n.tr("Urgent 14 Days", "急帖 14 天")
        }
    }

    var subtitle: String {
        switch self {
        case .none:
            return L10n.tr("No boost", "不加速")
        case .urgent7Days:
            return L10n.tr("Paid boost", "付费加速")
        case .urgent14Days:
            return L10n.tr("Paid boost", "付费加速")
        }
    }

    var highlightType: String {
        switch self {
        case .none:
            return "normal"
        case .urgent7Days, .urgent14Days:
            return "urgent"
        }
    }

    var durationDays: Int? {
        switch self {
        case .none:
            return nil
        case .urgent7Days:
            return 7
        case .urgent14Days:
            return 14
        }
    }

    var pinnedUntil: String? {
        guard let durationDays else { return nil }
        let endDate = Date().addingTimeInterval(TimeInterval(durationDays * 24 * 60 * 60))
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: endDate)
    }

    var isPaid: Bool {
        self != .none
    }
}

struct PostPromotionSection: View {
    @Binding var selectedPlan: PostPromotionPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.tr("Paid Promotion", "付费推广"))
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                if selectedPlan.isPaid {
                    Text(L10n.tr("Urgent Boost", "急帖高亮"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppColors.accent)
                        .clipShape(Capsule())
                }
            }

            Text(L10n.tr("Gold border + cheese badge + flashing urgent label", "金色边框 + 奶酪徽章 + 闪烁急帖标签"))
                .font(.footnote)
                .foregroundStyle(AppColors.textMuted)

            VStack(spacing: 8) {
                ForEach(PostPromotionPlan.allCases) { plan in
                    Button {
                        selectedPlan = plan
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: selectedPlan == plan ? "largecircle.fill.circle" : "circle")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(selectedPlan == plan ? AppColors.accentStrong : AppColors.textMuted)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(plan.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppColors.textPrimary)
                                Text(plan.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(AppColors.textMuted)
                            }

                            Spacer()
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selectedPlan == plan ? AppColors.accent.opacity(0.22) : Color.white)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
