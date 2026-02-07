//
//  HomeSearchBarView.swift
//  CheeseApp
//
//  🔍 首页搜索栏组件
//  黑色圆角搜索框，点击后可跳转到搜索页面
//

import SwiftUI

// MARK: - 首页搜索栏视图
struct HomeSearchBarView: View {
    /// 搜索栏点击回调
    var onTap: (() -> Void)?
    
    /// 占位文字
    var placeholder: String = L10n.tr("Search rooms, rides, events...", "搜尋租房、拼車、活動...")
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            HStack(spacing: 10) {
                // 搜索图标
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                
                // 占位文字
                Text(placeholder)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
                
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(.black.opacity(0.92))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        HomeSearchBarView()
        
        HomeSearchBarView(placeholder: "Search anything...")
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
