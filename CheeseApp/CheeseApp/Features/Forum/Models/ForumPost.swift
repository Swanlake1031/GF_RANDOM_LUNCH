//
//  ForumPost.swift
//  CheeseApp
//
//  🎯 论坛帖子模型
//

import Foundation

struct ForumPost: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String?
    let category: String
    let tags: [String]?
    let isAnonymous: Bool
    let isPinned: Bool
    let isLocked: Bool
    let viewCount: Int
    let likeCount: Int
    let commentCount: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, description, category, tags
        case isAnonymous = "is_anonymous"
        case isPinned = "is_pinned"
        case isLocked = "is_locked"
        case viewCount = "view_count"
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case createdAt = "created_at"
    }
}

struct Comment: Codable, Identifiable {
    let id: UUID
    let postId: UUID
    let userId: UUID
    let parentId: UUID?
    let content: String
    let isAnonymous: Bool
    let isDeleted: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case parentId = "parent_id"
        case content
        case isAnonymous = "is_anonymous"
        case isDeleted = "is_deleted"
        case createdAt = "created_at"
    }
}
