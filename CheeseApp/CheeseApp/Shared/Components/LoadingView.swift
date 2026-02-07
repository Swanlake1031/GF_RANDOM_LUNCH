//
//  LoadingView.swift
//  CheeseApp
//
//  🎯 加载视图组件
//

import SwiftUI

// ============================================
// 加载视图
// ============================================

struct LoadingView: View {
    var message: String = "加载中..."
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text(message)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

#Preview {
    LoadingView()
}
