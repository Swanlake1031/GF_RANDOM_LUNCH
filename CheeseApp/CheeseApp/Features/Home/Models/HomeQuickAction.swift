//
//  HomeQuickAction.swift
//  CheeseApp
//
//  ⚡ 首页快捷操作数据模型
//  定义首页顶部的快捷入口按钮数据
//

import SwiftUI

// MARK: - 快捷操作模型
/// 首页快捷操作按钮的数据结构
struct HomeQuickAction: Identifiable {
    let id = UUID()
    let icon: String        // SF Symbol 图标名称
    let title: String       // 按钮标题
    let destination: QuickActionDestination  // 跳转目标
    
    /// 便捷初始化方法
    init(icon: String, title: String, destination: QuickActionDestination) {
        self.icon = icon
        self.title = title
        self.destination = destination
    }
}

// MARK: - 跳转目标枚举
/// 定义快捷操作按钮点击后的跳转目标
enum QuickActionDestination: String, CaseIterable {
    case rent = "rent"          // 租房列表
    case market = "market"      // 二手市场
    case carpool = "carpool"    // 拼车
    case groups = "groups"      // 组队
    case forum = "forum"        // 论坛
    
    /// 获取对应的 Tab 索引（如果有）
    var tabIndex: Int? {
        switch self {
        case .rent: return 1
        case .market: return 2
        case .carpool: return 3
        case .groups: return 4
        case .forum: return nil  // 论坛可能是单独页面
        }
    }
}

// MARK: - 预设快捷操作
extension HomeQuickAction {
    /// 默认的快捷操作列表
    static let defaultActions: [HomeQuickAction] = [
        HomeQuickAction(icon: "key.fill", title: "Rent", destination: .rent),
        HomeQuickAction(icon: "bag.fill", title: "Market", destination: .market),
        HomeQuickAction(icon: "car.fill", title: "Carpool", destination: .carpool),
        HomeQuickAction(icon: "person.2.fill", title: "Groups", destination: .groups),
        HomeQuickAction(icon: "bubble.left.and.bubble.right.fill", title: "Forum", destination: .forum)
    ]
}

