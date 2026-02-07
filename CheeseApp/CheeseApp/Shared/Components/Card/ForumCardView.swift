//
//  ForumCardView.swift
//  CheeseApp
//
//  💬 论坛卡片组件
//  专门用于展示论坛帖子的卡片视图
//

import SwiftUI

// MARK: - 论坛卡片视图
struct ForumCardView: View {
    /// 论坛卡片数据
    let item: ForumCardItem
    
    /// 点击回调
    var onTap: (() -> Void)?
    
    /// 图片高度
    var imageHeight: CGFloat = 160
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            VStack(spacing: 0) {
                // 顶部图片
                cardImage
                
                // 底部内容
                cardContent
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 8)
            .postHighlightStyle(item.highlightType, cornerRadius: 22)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
    
    // MARK: - 卡片图片
    @ViewBuilder
    private var cardImage: some View {
        item.image.view
            .frame(height: imageHeight)
            .frame(maxWidth: .infinity)
            .clipped()
    }
    
    // MARK: - 卡片内容
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 回复数量
            responseCountRow
            
            // 帖子标题
            Text(item.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // 作者和时间
            authorRow
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
    }
    
    // MARK: - 回复数量行
    private var responseCountRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "message.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            
            Text(item.responseCount)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - 作者信息行
    private var authorRow: some View {
        HStack(spacing: 8) {
            // 作者头像图标
            Image(systemName: "person.circle.fill")
                .foregroundStyle(.secondary.opacity(0.9))
            
            // 作者名
            Text(item.author)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            
            // 分隔符
            Text("•")
                .foregroundStyle(.secondary)
            
            // 发布时间
            Text(item.timeAgo)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ForumCardView(
                item: ForumCardItem(
                    postId: nil,
                    image: .placeholder,
                    responseCount: "234 responses",
                    title: "Best Coffee Spots for Late Night Study Sessions?",
                    author: "Sarah K.",
                    timeAgo: "2h ago",
                    highlightType: .pinned
                )
            )
            
            ForumCardView(
                item: ForumCardItem(
                    postId: nil,
                    image: .placeholder,
                    responseCount: "189 responses",
                    title: "Spring Break Plans – Who's Staying on Campus?",
                    author: "Jason T.",
                    timeAgo: "5h ago",
                    highlightType: .normal
                )
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
