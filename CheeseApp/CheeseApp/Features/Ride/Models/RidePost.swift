//
//  RidePost.swift
//  CheeseApp
//
//  🎯 拼车帖子模型
//

import Foundation

struct RidePost: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String?
    let departureLocation: String
    let destinationLocation: String
    let departureTime: Date
    let role: Role
    let totalSeats: Int?
    let availableSeats: Int?
    let pricePerSeat: Decimal?
    let isFree: Bool
    let isFlexible: Bool
    let contactMethod: ContactMethod
    let notes: String?
    let createdAt: Date

    enum Role: String, Codable, CaseIterable {
        case driver = "driver"
        case passenger = "passenger"
    }

    enum ContactMethod: String, Codable, CaseIterable {
        case app = "app"
        case wechat = "wechat"
        case phone = "phone"
        case text = "text"
    }

    var isDriver: Bool {
        role == .driver
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, role, notes
        case departureLocation = "departure_location"
        case destinationLocation = "destination_location"
        case departureTime = "departure_time"
        case totalSeats = "total_seats"
        case availableSeats = "available_seats"
        case pricePerSeat = "price_per_seat"
        case isFree = "is_free"
        case isFlexible = "is_flexible"
        case contactMethod = "contact_method"
        case createdAt = "created_at"
    }
}
