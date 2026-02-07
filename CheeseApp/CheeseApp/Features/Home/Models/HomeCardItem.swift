//
//  HomeCardItem.swift
//  CheeseApp
//
//  🏠 首页卡片数据模型
//  用于展示各类内容卡片（租房、拼车、组队等）的轻量级 DTO
//

import SwiftUI

// MARK: - 图片来源枚举
/// 支持本地资源图片和网络 URL 图片
enum ImageSource {
    case asset(String)      // 本地 Assets 中的图片名称
    case url(URL)           // 网络图片 URL
    case placeholder        // 默认占位图
    
    /// 将图片来源转换为 SwiftUI View
    @ViewBuilder
    var view: some View {
        switch self {
        case .asset(let name):
            // 尝试加载本地图片，失败则显示占位符
            Image(name)
                .resizable()
                .scaledToFill()
        case .url(let url):
            // 异步加载网络图片
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    Rectangle().fill(Color.gray.opacity(0.2))
                }
            }
        case .placeholder:
            // 灰色占位矩形
            Rectangle().fill(Color.gray.opacity(0.2))
        }
    }
}

// MARK: - 标签样式枚举
enum PillStyle {
    case tag      // 主要标签（如分类）
    case muted    // 次要标签（如距离、时间）
}

// MARK: - 标签模型
struct CardPill: Identifiable {
    let id = UUID()
    let text: String
    let style: PillStyle
    
    init(text: String, style: PillStyle = .tag) {
        self.text = text
        self.style = style
    }
}

// MARK: - 卡片底部样式枚举
enum CardFooterStyle {
    case posted(name: String, avatar: ImageSource)   // "Posted by xxx"
    case hosted(name: String, avatar: ImageSource)   // "Hosted by xxx"
    case avatars(countText: String, avatars: [ImageSource])  // 多头像 + 数量
    case none
}

// MARK: - 首页卡片数据模型
/// 用于首页展示的通用卡片数据结构
struct HomeCardItem: Identifiable {
    let id = UUID()
    let postId: UUID?               // 关联真实帖子 ID
    let authorId: UUID?             // 关联作者 ID
    let image: ImageSource          // 卡片顶部图片
    let pills: [CardPill]           // 标签数组
    let title: String               // 主标题
    let subtitle: String            // 副标题
    let footer: CardFooterStyle     // 底部样式
    let category: HomeCardCategory  // 所属分类
    let highlightType: PostHighlightType
    
    /// 便捷初始化方法
    init(
        postId: UUID? = nil,
        authorId: UUID? = nil,
        image: ImageSource = .placeholder,
        pills: [CardPill] = [],
        title: String,
        subtitle: String,
        footer: CardFooterStyle = .none,
        category: HomeCardCategory = .featured,
        highlightType: PostHighlightType = .normal
    ) {
        self.postId = postId
        self.authorId = authorId
        self.image = image
        self.pills = pills
        self.title = title
        self.subtitle = subtitle
        self.footer = footer
        self.category = category
        self.highlightType = highlightType
    }
}

// MARK: - 卡片分类枚举
enum HomeCardCategory: String, CaseIterable {
    case featured = "Featured"      // 精选推荐
    case rent = "Rent"              // 租房
    case market = "Market"          // 二手市场
    case carpool = "Carpool"        // 拼车
    case groups = "Groups"          // 组队
    case forum = "Forum"            // 论坛
}

// MARK: - 论坛卡片数据模型
/// 专门用于论坛帖子的卡片数据
struct ForumCardItem: Identifiable {
    let id = UUID()
    let postId: UUID?
    let image: ImageSource          // 封面图
    let responseCount: String       // 回复数量文字
    let title: String               // 帖子标题
    let author: String              // 作者名
    let timeAgo: String             // 发布时间
    let highlightType: PostHighlightType
}
