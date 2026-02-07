//
//  Colors.swift
//  CheeseApp
//
//  🎯 颜色定义
//

import SwiftUI

// ============================================
// 应用颜色
// ============================================

enum AppColors {
    /// 主色调（芝士黄）
    static let primary = Color(red: 1.0, green: 0.725, blue: 0.176)
    
    /// 次要色
    static let secondary = Color(red: 0.4, green: 0.4, blue: 0.45)
    
    /// 背景色
    static let background = Color(.systemBackground)
    
    /// 次要背景色
    static let secondaryBackground = Color(.secondarySystemBackground)
    
    /// 文字色
    static let text = Color(.label)
    
    /// 次要文字色
    static let secondaryText = Color(.secondaryLabel)

    /// 固定浅色主题主文本（避免系统深色模式导致浅底白字）
    static let textPrimary = Color(red: 0.10, green: 0.10, blue: 0.12)

    /// 固定浅色主题次文本
    static let textMuted = Color(red: 0.42, green: 0.42, blue: 0.46)
    
    /// 成功色
    static let success = Color.green
    
    /// 警告色
    static let warning = Color.orange
    
    /// 错误色
    static let error = Color.red

    /// 页面底色（与首页保持一致）
    static let pageBackground = Color(red: 0.96, green: 0.94, blue: 0.88)

    /// 卡片底色
    static let cardBackground = Color.white

    /// 主题强调色（按钮）
    static let accent = Color(red: 0.95, green: 0.85, blue: 0.45)

    /// 主题强调深色（渐变/hover）
    static let accentStrong = Color(red: 0.90, green: 0.75, blue: 0.35)

    /// 文本链接/强调
    static let link = Color(red: 0.78, green: 0.60, blue: 0.20)

    /// 选中态深色
    static let selectedBackground = Color.black

    /// 分割线
    static let divider = Color(.systemGray5)

    /// 按业务类型映射统一色板
    static func categoryColor(for type: String) -> Color {
        switch type.lowercased() {
        case "rent", "rentals":
            return Color(red: 0.22, green: 0.45, blue: 0.85)
        case "market", "secondhand", "marketplace":
            return Color(red: 0.93, green: 0.76, blue: 0.29)
        case "carpool", "ride":
            return Color(red: 0.20, green: 0.60, blue: 0.40)
        case "groups", "group", "team":
            return Color(red: 0.52, green: 0.36, blue: 0.86)
        case "forum":
            return Color(red: 0.90, green: 0.38, blue: 0.56)
        default:
            return secondary
        }
    }
}

enum PostHighlightType: String, Codable, Hashable {
    case normal
    case urgent
    case pinned
    case breaking

    init(rawValue: String?) {
        guard let rawValue,
              let type = PostHighlightType(rawValue: rawValue.lowercased()) else {
            self = .normal
            return
        }
        self = type
    }

    var badgeText: String {
        switch self {
        case .normal:
            return ""
        case .urgent:
            return L10n.tr("URGENT", "急租")
        case .pinned:
            return L10n.tr("PROMO", "置顶")
        case .breaking:
            return L10n.tr("BREAKING", "爆料")
        }
    }

    var borderColor: Color {
        switch self {
        case .normal:
            return .clear
        case .urgent:
            return Color(red: 0.95, green: 0.80, blue: 0.25)
        case .pinned:
            return AppColors.accent
        case .breaking:
            return Color(red: 0.92, green: 0.35, blue: 0.50)
        }
    }

    var badgeBackground: Color {
        switch self {
        case .normal:
            return .clear
        case .urgent:
            return Color(red: 0.96, green: 0.82, blue: 0.28)
        case .pinned:
            return AppColors.accent
        case .breaking:
            return Color(red: 0.92, green: 0.35, blue: 0.50)
        }
    }

    var badgeForeground: Color {
        switch self {
        case .normal:
            return .clear
        default:
            return .black
        }
    }

    var iconName: String {
        switch self {
        case .normal:
            return ""
        case .urgent:
            return "crown.fill"
        case .pinned:
            return "seal.fill"
        case .breaking:
            return "bolt.fill"
        }
    }

    var shouldShowCheese: Bool {
        self == .urgent
    }

    var shouldShowBadge: Bool {
        self != .normal
    }

    var isBlinking: Bool {
        self == .urgent
    }
}

struct PostHighlightBadgeView: View {
    let type: PostHighlightType
    @State private var pulse = false

    var body: some View {
        if type.shouldShowBadge {
            HStack(spacing: 5) {
                if type.shouldShowCheese {
                    Text("🧀")
                        .font(.system(size: 10))
                }

                Image(systemName: type.iconName)
                    .font(.system(size: 9, weight: .bold))

                Text(type.badgeText)
                    .font(.system(size: 10, weight: .heavy))
                    .lineLimit(1)
            }
            .foregroundStyle(type.badgeForeground)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(type.badgeBackground)
            .clipShape(Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(.white.opacity(0.55), lineWidth: 0.8)
            )
            .shadow(color: type.borderColor.opacity(0.35), radius: 10, x: 0, y: 4)
            .opacity(type.isBlinking ? (pulse ? 1 : 0.62) : 1)
            .onAppear {
                guard type.isBlinking else { return }
                withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                    pulse.toggle()
                }
            }
        }
    }
}

struct PostHighlightCardModifier: ViewModifier {
    let type: PostHighlightType
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay {
                if type != .normal {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(type.borderColor, lineWidth: 2)
                        .shadow(
                            color: type == .urgent
                                ? Color(red: 0.95, green: 0.80, blue: 0.25).opacity(0.45)
                                : .clear,
                            radius: type == .urgent ? 8 : 0,
                            x: 0,
                            y: 0
                        )
                }
            }
            .overlay(alignment: .topLeading) {
                PostHighlightBadgeView(type: type)
                    .padding(10)
            }
    }
}

extension View {
    func postHighlightStyle(_ type: PostHighlightType, cornerRadius: CGFloat) -> some View {
        modifier(PostHighlightCardModifier(type: type, cornerRadius: cornerRadius))
    }
}
