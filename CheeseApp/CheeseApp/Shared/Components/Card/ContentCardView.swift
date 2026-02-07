//
//  ContentCardView.swift
//  CheeseApp
//
//  🎴 通用内容卡片组件
//  用于展示租房、拼车、组队等各类内容的卡片视图
//

import SwiftUI

// MARK: - 通用内容卡片视图
struct ContentCardView: View {
    /// 卡片数据
    let item: HomeCardItem
    
    /// 点击回调
    var onTap: (() -> Void)?
    
    /// 图片高度
    var imageHeight: CGFloat = 180
    
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
    }
    
    // MARK: - 卡片图片部分
    @ViewBuilder
    private var cardImage: some View {
        item.image.view
            .frame(height: imageHeight)
            .frame(maxWidth: .infinity)
            .clipped()
    }
    
    // MARK: - 卡片内容部分
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 标签行
            pillsRow
            
            // 标题
            Text(item.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // 副标题
            Text(item.subtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            
            // 底部区域
            footerView
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
    }
    
    // MARK: - 标签行
    private var pillsRow: some View {
        HStack(spacing: 8) {
            ForEach(item.pills) { pill in
                PillView(pill: pill)
            }
            Spacer()
        }
    }
    
    // MARK: - 底部视图
    @ViewBuilder
    private var footerView: some View {
        switch item.footer {
        case .posted(let name, let avatar):
            HStack(spacing: 8) {
                AvatarView(source: avatar, size: 18)
                Text("Posted by \(name)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
        case .hosted(let name, let avatar):
            HStack(spacing: 8) {
                AvatarView(source: avatar, size: 18)
                Text("Hosted by \(name)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
        case .avatars(let countText, let avatars):
            HStack(spacing: 10) {
                // 叠加头像
                ZStack {
                    ForEach(Array(avatars.prefix(3).enumerated()), id: \.offset) { index, source in
                        AvatarView(source: source, size: 18)
                            .offset(x: CGFloat(index) * 14)
                    }
                }
                .frame(width: 60, height: 18, alignment: .leading)
                
                Text(countText)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
        case .none:
            EmptyView()
        }
    }
}

// MARK: - 标签视图
struct PillView: View {
    let pill: CardPill
    
    var body: some View {
        Text(pill.text)
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(.systemGray6))
            )
            .foregroundStyle(.primary.opacity(pill.style == .tag ? 0.9 : 0.6))
    }
}

// MARK: - 头像视图
struct AvatarView: View {
    let source: ImageSource
    let size: CGFloat
    
    var body: some View {
        source.view
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(.white, lineWidth: 1))
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ContentCardView(
                item: HomeCardItem(
                    image: .placeholder,
                    pills: [
                        CardPill(text: "Rent", style: .tag),
                        CardPill(text: "0.4 mi away", style: .muted)
                    ],
                    title: "Studio Near Campus",
                    subtitle: "$1,200/mo  •  Available Now",
                    footer: .posted(name: "Emma L.", avatar: .placeholder),
                    highlightType: .urgent
                )
            )
            
            ContentCardView(
                item: HomeCardItem(
                    image: .placeholder,
                    pills: [
                        CardPill(text: "Groups", style: .tag),
                        CardPill(text: "12 members", style: .muted)
                    ],
                    title: "Study Group – CS 101",
                    subtitle: "Meet Tuesdays & Thursdays",
                    footer: .avatars(countText: "+9 others", avatars: [
                        .placeholder, .placeholder, .placeholder
                    ]),
                    highlightType: .normal
                )
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
