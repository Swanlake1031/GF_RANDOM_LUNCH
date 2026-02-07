//
//  BasePost.swift
//  CheeseApp
//
//  🎯 帖子基础模型
//

import Foundation

// ============================================
// 帖子类型枚举
// ============================================

enum PostType: String, Codable, CaseIterable {
    case rent = "rent"
    case secondhand = "secondhand"
    case ride = "ride"
    case team = "team"
    case forum = "forum"
    
    var displayName: String {
        switch self {
        case .rent: return "租房"
        case .secondhand: return "二手"
        case .ride: return "拼车"
        case .team: return "组队"
        case .forum: return "论坛"
        }
    }
    
    var iconName: String {
        switch self {
        case .rent: return "house.fill"
        case .secondhand: return "bag.fill"
        case .ride: return "car.fill"
        case .team: return "person.3.fill"
        case .forum: return "bubble.left.and.bubble.right.fill"
        }
    }
}

// ============================================
// 帖子状态枚举
// ============================================

enum PostStatus: String, Codable {
    case active = "active"
    case closed = "closed"
    case deleted = "deleted"
}

// ============================================
// 帖子基础协议
// ============================================

protocol BasePost: Identifiable, Codable {
    var id: UUID { get }
    var title: String { get }
    var description: String? { get }
    var location: String? { get }
    var status: PostStatus { get }
    var createdAt: Date { get }
}

// ============================================
// 通用帖子结构体
// ============================================

struct Post: BasePost {
    let id: UUID
    let userId: UUID
    let postType: PostType
    let title: String
    let description: String?
    let location: String?
    let status: PostStatus
    let viewCount: Int
    let isAnonymous: Bool
    let createdAt: Date
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case postType = "type"
        case title, description, location, status
        case viewCount = "view_count"
        case isAnonymous = "is_anonymous"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
