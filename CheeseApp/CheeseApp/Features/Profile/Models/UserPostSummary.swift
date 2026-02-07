import Foundation

struct UserPostSummary: Identifiable, Hashable {
    let id: UUID
    let kind: PostKind
    let title: String
    let description: String
    let subtitle: String
    let price: Double?
    let createdAt: Date
    let authorId: UUID
    let authorName: String
    let authorAvatarURL: String?

    var relativeTimeText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    var priceDisplayText: String? {
        guard let price else { return nil }
        switch kind {
        case .rent:
            return "$\(Int(price))/mo"
        case .ride:
            return "$\(Int(price))/seat"
        case .secondhand:
            return "$\(Int(price))"
        case .team, .forum:
            return nil
        }
    }
}
