//
//  ChatMessage.swift
//  CheeseApp
//
//  🎯 聊天消息模型
//

import Foundation

// ============================================
// 会话模型
// ============================================

struct Conversation: Codable, Identifiable {
    let id: UUID
    let user1Id: UUID
    let user2Id: UUID
    let relatedPostId: UUID?
    let lastMessageAt: Date
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case user1Id = "user1_id"
        case user2Id = "user2_id"
        case relatedPostId = "related_post_id"
        case lastMessageAt = "last_message_at"
        case createdAt = "created_at"
    }
}

// ============================================
// 消息模型
// ============================================

struct Message: Codable, Identifiable {
    let id: UUID
    let conversationId: UUID
    let senderId: UUID
    let content: String
    let messageType: String
    var isRead: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case content
        case messageType = "message_type"
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}
