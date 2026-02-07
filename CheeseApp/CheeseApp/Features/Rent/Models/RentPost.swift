//
//  RentPost.swift
//  CheeseApp
//
//  🎯 租房帖子模型
//

import Foundation

// ============================================
// 租房帖子
// ============================================

struct RentPost: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String?
    let location: String?
    let price: Decimal
    let bedrooms: Int?
    let bathrooms: Decimal?
    let specs: String?
    let propertyType: PropertyType
    let utilitiesIncluded: Bool
    let petsAllowed: Bool
    let availableFrom: Date?
    let createdAt: Date
    
    enum PropertyType: String, Codable, CaseIterable {
        case apartment = "apartment"
        case house = "house"
        case condo = "condo"
        case studio = "studio"
        case room = "room"
        
        var displayName: String {
            switch self {
            case .apartment: return "公寓"
            case .house: return "独栋"
            case .condo: return "产权公寓"
            case .studio: return "单身公寓"
            case .room: return "单间"
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, location, price, bedrooms, bathrooms, specs
        case propertyType = "property_type"
        case utilitiesIncluded = "utilities_included"
        case petsAllowed = "pets_allowed"
        case availableFrom = "available_from"
        case createdAt = "created_at"
    }
}
