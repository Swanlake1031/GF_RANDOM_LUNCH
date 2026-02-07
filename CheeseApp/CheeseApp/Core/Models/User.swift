//
//  User.swift
//  CheeseApp
//
//  🎯 用户数据模型
//

import Foundation

// ============================================
// 用户资料
// ============================================

struct Profile: Codable, Identifiable {
    let id: UUID
    let email: String
    var username: String?
    var fullName: String?
    var avatarUrl: String?
    var school: String?
    var major: String?
    var gradYear: Int?
    var bio: String?
    var wechatId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var is_verified: Bool?
    var isAnonymousDefault: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, email, username
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case school = "university"
        case major
        case gradYear = "grad_year"
        case bio
        case wechatId = "wechat_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case is_verified = "verified"
        case isAnonymousDefault = "is_anonymous"
    }
}
