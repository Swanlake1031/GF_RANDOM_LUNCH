//
//  TeamPost.swift
//  CheeseApp
//
//  🎯 组队帖子模型
//

import Foundation

struct TeamPost: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String?
    let category: Category
    let teamSize: Int?
    let currentMembers: Int
    let spotsAvailable: Int?
    let skillsNeeded: [String]?
    let deadline: Date?
    let createdAt: Date

    enum Category: String, Codable, CaseIterable {
        case course = "course"
        case hackathon = "hackathon"
        case competition = "competition"
        case startup = "startup"
        case study = "study"
        case sports = "sports"
        case gaming = "gaming"
        case other = "other"

        var displayName: String {
            switch self {
            case .course: return "课程项目"
            case .hackathon: return "黑客马拉松"
            case .competition: return "竞赛"
            case .startup: return "创业"
            case .study: return "学习小组"
            case .sports: return "运动队伍"
            case .gaming: return "游戏开黑"
            case .other: return "其他"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, category, deadline
        case teamSize = "team_size"
        case currentMembers = "current_members"
        case spotsAvailable = "spots_available"
        case skillsNeeded = "skills_needed"
        case createdAt = "created_at"
    }
}
