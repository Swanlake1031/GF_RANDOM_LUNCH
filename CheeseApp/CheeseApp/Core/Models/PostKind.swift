import Foundation

enum PostKind: String, Codable, CaseIterable, Hashable {
    case rent
    case secondhand
    case ride
    case team
    case forum

    var displayName: String {
        switch self {
        case .rent: return "Rent"
        case .secondhand: return "Market"
        case .ride: return "Carpool"
        case .team: return "Groups"
        case .forum: return "Forum"
        }
    }

    var icon: String {
        switch self {
        case .rent: return "key.fill"
        case .secondhand: return "bag.fill"
        case .ride: return "car.fill"
        case .team: return "person.2.fill"
        case .forum: return "bubble.left.and.bubble.right.fill"
        }
    }

    var supportsPriceEditing: Bool {
        switch self {
        case .rent, .secondhand, .ride:
            return true
        case .team, .forum:
            return false
        }
    }
}
