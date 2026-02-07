//
//  SecondhandPost.swift
//  CheeseApp
//
//  🎯 二手交易帖子模型
//

import Foundation

struct SecondhandPost: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String?
    let price: Decimal
    let category: Category
    let condition: Condition
    let isNegotiable: Bool
    let isFree: Bool
    let pickupLocation: String?
    let canShip: Bool
    let quantity: Int
    let soldCount: Int
    let createdAt: Date

    enum Category: String, Codable, CaseIterable {
        case electronics = "electronics"
        case furniture = "furniture"
        case clothing = "clothing"
        case books = "books"
        case appliances = "appliances"
        case sports = "sports"
        case beauty = "beauty"
        case other = "other"

        var displayName: String {
            switch self {
            case .electronics: return "电子产品"
            case .furniture: return "家具"
            case .clothing: return "服装"
            case .books: return "教材书籍"
            case .appliances: return "家电"
            case .sports: return "运动用品"
            case .beauty: return "美妆个护"
            case .other: return "其他"
            }
        }
    }

    enum Condition: String, Codable, CaseIterable {
        case new = "new"
        case likeNew = "like_new"
        case good = "good"
        case fair = "fair"
        case poor = "poor"

        var displayName: String {
            switch self {
            case .new: return "全新"
            case .likeNew: return "几乎全新"
            case .good: return "良好"
            case .fair: return "一般"
            case .poor: return "较差"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, price, category, condition, quantity
        case isNegotiable = "is_negotiable"
        case isFree = "is_free"
        case pickupLocation = "pickup_location"
        case canShip = "can_ship"
        case soldCount = "sold_count"
        case createdAt = "created_at"
    }
}
