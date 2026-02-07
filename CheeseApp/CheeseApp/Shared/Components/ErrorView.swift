//
//  ErrorView.swift
//  CheeseApp
//
//  🎯 错误视图组件
//

import SwiftUI

// ============================================
// 错误视图
// ============================================

struct ErrorView: View {
    let message: String
    let retryAction: (() -> Void)?
    
    init(_ message: String, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(AppColors.warning)
            
            Text(message)
                .font(AppFonts.body)
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
            
            if let retry = retryAction {
                Button("重试", action: retry)
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ErrorView("加载失败，请检查网络") {
        print("重试")
    }
}

// ============================================
// 帖子详情页统一顶部工具栏
// ============================================

struct PostDetailTopBar<Trailing: View>: View {
    let title: String
    let onBack: () -> Void
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        ZStack {
            HStack(spacing: 10) {
                Button(action: onBack) {
                    PostToolbarIconCircle(icon: "chevron.left")
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 10) {
                    trailing()
                }
            }

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, 72)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(AppColors.pageBackground.opacity(0.96))
    }
}

struct PostToolbarIconCircle: View {
    let icon: String
    var tint: Color = AppColors.link

    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.92))
            .frame(width: 36, height: 36)
            .overlay {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
    }
}
