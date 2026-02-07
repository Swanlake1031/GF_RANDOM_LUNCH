//
//  HomeHeaderView.swift
//  CheeseApp
//
//  👋 首页头部组件
//  显示问候语、学校名称和验证状态
//

import SwiftUI

// MARK: - 首页头部视图
struct HomeHeaderView: View {
    let greeting: String           // 问候语（如 "Good Morning"）
    let universityName: String     // 学校名称
    let isVerified: Bool           // 是否已验证
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                // 问候语 + 验证徽章
                HStack(spacing: 10) {
                    Text(greeting)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                    
                    if isVerified {
                        VerifiedPillView()
                    }
                }
                
                // 学校名称
                Text(universityName)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppColors.textMuted)
            }
            
            Spacer()
        }
        .padding(.top, 6)
    }
}

// MARK: - 验证徽章组件
struct VerifiedPillView: View {
    var body: some View {
        HStack(spacing: 6) {
            // 验证图标
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.link)
            
            // "Verified" 文字
            Text(L10n.tr("Verified", "已驗證"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

// MARK: - Preview
#Preview {
    VStack {
        HomeHeaderView(
            greeting: "Good Morning",
            universityName: "University of California, Berkeley",
            isVerified: true
        )
        
        HomeHeaderView(
            greeting: "Good Evening",
            universityName: "Stanford University",
            isVerified: false
        )
    }
    .padding()
}
