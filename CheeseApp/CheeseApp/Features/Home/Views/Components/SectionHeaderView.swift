//
//  SectionHeaderView.swift
//  CheeseApp
//
//  📌 区块标题组件
//  用于各内容区块的标题行，可带"查看全部"按钮
//

import SwiftUI

// MARK: - 区块标题视图
struct SectionHeaderView: View {
    /// 标题文字
    let title: String
    
    /// 是否显示"See All"按钮
    var showSeeAll: Bool = true
    
    /// "See All"点击回调
    var onSeeAllTap: (() -> Void)?
    
    var body: some View {
        HStack {
            // 标题
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
            
            Spacer()
            
            // "See All" 按钮
            if showSeeAll {
                Button(action: {
                    onSeeAllTap?()
                }) {
                    Text(L10n.tr("See All", "查看全部"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.link)
                }
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        SectionHeaderView(title: "Featured Near You")
        
        SectionHeaderView(title: "Trending in Forum", showSeeAll: false)
        
        SectionHeaderView(title: "Groups") {
            print("See all tapped")
        }
    }
    .padding()
}
