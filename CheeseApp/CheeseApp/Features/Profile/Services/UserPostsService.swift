import Foundation
import Supabase

struct EditableUserPostPayload {
    let id: UUID
    let kind: PostKind
    let title: String
    let description: String
    let price: Double?
    let rentDetails: RentEditableFields?

    init(
        id: UUID,
        kind: PostKind,
        title: String,
        description: String,
        price: Double?,
        rentDetails: RentEditableFields? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.description = description
        self.price = price
        self.rentDetails = rentDetails
    }
}

struct RentEditableFields {
    let location: String
    let bedrooms: Int
    let bathrooms: Double
    let propertyType: String
    let availableFrom: Date?
    let amenities: [String]
}

@MainActor
final class UserPostsService: ObservableObject {
    @Published private(set) var profile: Profile?
    @Published private(set) var posts: [UserPostSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = SupabaseManager.shared

    func load(userId: UUID) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let profileTask = fetchProfile(userId: userId)
            async let postsTask = fetchPosts(userId: userId)
            profile = try await profileTask
            posts = try await postsTask
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshPosts(userId: UUID) async {
        do {
            posts = try await fetchPosts(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func update(payload: EditableUserPostPayload) async throws {
        let trimmedTitle = payload.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Title cannot be empty"])
        }

        let trimmedDescription = payload.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let postUpdate = BasePostUpdate(
            title: trimmedTitle,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription
        )

        try await supabase
            .database("posts")
            .update(postUpdate)
            .eq("id", value: payload.id.uuidString)
            .execute()

        switch payload.kind {
        case .rent:
            guard let price = payload.price, price > 0 else {
                throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Rent price must be greater than 0"])
            }
            if let details = payload.rentDetails {
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.dateFormat = "yyyy-MM-dd"

                let normalizedLocation = details.location.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !normalizedLocation.isEmpty else {
                    throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Location cannot be empty"])
                }

                let normalizedAmenities = details.amenities.map {
                    $0.trimmingCharacters(in: .whitespacesAndNewlines)
                }.filter { !$0.isEmpty }

                try await supabase
                    .database("rent_posts")
                    .update(
                        RentPostFullUpdate(
                            price: price,
                            location: normalizedLocation,
                            bedrooms: max(details.bedrooms, 0),
                            bathrooms: max(details.bathrooms, 0),
                            propertyType: normalizedPropertyType(details.propertyType),
                            availableFrom: details.availableFrom.map { dateFormatter.string(from: $0) },
                            utilitiesIncluded: normalizedAmenities.contains("水电全包"),
                            petsAllowed: normalizedAmenities.contains("允许宠物"),
                            parkingAvailable: normalizedAmenities.contains("停车位"),
                            amenities: normalizedAmenities
                        )
                    )
                    .eq("id", value: payload.id.uuidString)
                    .execute()
            } else {
                try await supabase
                    .database("rent_posts")
                    .update(PriceOnlyUpdate(price: price))
                    .eq("id", value: payload.id.uuidString)
                    .execute()
            }

        case .secondhand:
            guard let price = payload.price, price >= 0 else {
                throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Price is required"])
            }
            try await supabase
                .database("secondhand_posts")
                .update(PriceOnlyUpdate(price: price))
                .eq("id", value: payload.id.uuidString)
                .execute()

        case .ride:
            let normalizedPrice = payload.price.flatMap { $0 > 0 ? $0 : nil }
            try await supabase
                .database("ride_posts")
                .update(RidePriceUpdate(pricePerSeat: normalizedPrice, isFree: normalizedPrice == nil))
                .eq("id", value: payload.id.uuidString)
                .execute()

        case .team, .forum:
            break
        }
    }

    func delete(postId: UUID) async throws {
        try await supabase
            .database("posts")
            .delete()
            .eq("id", value: postId.uuidString)
            .execute()

        posts.removeAll { $0.id == postId }
    }

    func fetchRentEditFields(postId: UUID) async throws -> RentEditableFields {
        let row: UserRentEditRow = try await supabase
            .database("rent_posts_view")
            .select("location,bedrooms,bathrooms,property_type,available_from,amenities")
            .eq("id", value: postId.uuidString)
            .single()
            .execute()
            .value

        return RentEditableFields(
            location: row.location,
            bedrooms: row.bedrooms ?? 1,
            bathrooms: row.bathrooms ?? 1,
            propertyType: row.propertyType,
            availableFrom: parseDate(row.availableFrom),
            amenities: row.amenities ?? []
        )
    }

    private func fetchProfile(userId: UUID) async throws -> Profile {
        try await supabase
            .database("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }

    private func fetchPosts(userId: UUID) async throws -> [UserPostSummary] {
        async let rentTask = fetchRentPosts(userId: userId)
        async let marketTask = fetchSecondhandPosts(userId: userId)
        async let rideTask = fetchRidePosts(userId: userId)
        async let teamTask = fetchTeamPosts(userId: userId)
        async let forumTask = fetchForumPosts(userId: userId)

        let merged = try await rentTask + marketTask + rideTask + teamTask + forumTask
        return merged.sorted { $0.createdAt > $1.createdAt }
    }

    private func fetchRentPosts(userId: UUID) async throws -> [UserPostSummary] {
        let rows: [UserRentRow] = try await supabase
            .database("rent_posts_view")
            .select("id,user_id,title,description,price,location,created_at,user_name,user_avatar")
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(100)
            .execute()
            .value

        return rows.map {
            UserPostSummary(
                id: $0.id,
                kind: .rent,
                title: $0.title,
                description: $0.description ?? "",
                subtitle: $0.location,
                price: $0.price,
                createdAt: $0.createdAt,
                authorId: $0.userId,
                authorName: $0.userName ?? "Unknown",
                authorAvatarURL: $0.userAvatar
            )
        }
    }

    private func fetchSecondhandPosts(userId: UUID) async throws -> [UserPostSummary] {
        let rows: [UserSecondhandRow] = try await supabase
            .database("secondhand_posts_view")
            .select("id,user_id,title,description,price,condition,created_at,user_name,user_avatar")
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(100)
            .execute()
            .value

        return rows.map {
            UserPostSummary(
                id: $0.id,
                kind: .secondhand,
                title: $0.title,
                description: $0.description ?? "",
                subtitle: $0.condition.capitalized,
                price: $0.price,
                createdAt: $0.createdAt,
                authorId: $0.userId,
                authorName: $0.userName ?? "Unknown",
                authorAvatarURL: $0.userAvatar
            )
        }
    }

    private func fetchRidePosts(userId: UUID) async throws -> [UserPostSummary] {
        let rows: [UserRideRow] = try await supabase
            .database("ride_posts_view")
            .select("id,user_id,title,description,departure_location,destination_location,price_per_seat,created_at,user_name,user_avatar")
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(100)
            .execute()
            .value

        return rows.map {
            UserPostSummary(
                id: $0.id,
                kind: .ride,
                title: $0.title,
                description: $0.description ?? "",
                subtitle: "\($0.departureLocation) → \($0.destinationLocation)",
                price: $0.pricePerSeat,
                createdAt: $0.createdAt,
                authorId: $0.userId,
                authorName: $0.userName ?? "Unknown",
                authorAvatarURL: $0.userAvatar
            )
        }
    }

    private func fetchTeamPosts(userId: UUID) async throws -> [UserPostSummary] {
        let rows: [UserTeamRow] = try await supabase
            .database("team_posts_view")
            .select("id,user_id,title,description,category,created_at,user_name,user_avatar")
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(100)
            .execute()
            .value

        return rows.map {
            UserPostSummary(
                id: $0.id,
                kind: .team,
                title: $0.title,
                description: $0.description ?? "",
                subtitle: $0.category.capitalized,
                price: nil,
                createdAt: $0.createdAt,
                authorId: $0.userId,
                authorName: $0.userName ?? "Unknown",
                authorAvatarURL: $0.userAvatar
            )
        }
    }

    private func fetchForumPosts(userId: UUID) async throws -> [UserPostSummary] {
        let rows: [UserForumRow] = try await supabase
            .database("forum_posts_view")
            .select("id,user_id,title,description,category,created_at,user_name,user_avatar")
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(100)
            .execute()
            .value

        return rows.map {
            UserPostSummary(
                id: $0.id,
                kind: .forum,
                title: $0.title,
                description: $0.description ?? "",
                subtitle: $0.category.capitalized,
                price: nil,
                createdAt: $0.createdAt,
                authorId: $0.userId,
                authorName: $0.userName ?? "Unknown",
                authorAvatarURL: $0.userAvatar
            )
        }
    }

    private func normalizedPropertyType(_ value: String) -> String {
        switch value {
        case "apartment", "house", "studio", "room", "condo":
            return value
        default:
            return "apartment"
        }
    }

    private func parseDate(_ value: String?) -> Date? {
        guard let value else { return nil }

        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: value) {
            return date
        }

        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
        return dateOnlyFormatter.date(from: value)
    }
}

private struct BasePostUpdate: Encodable {
    let title: String
    let description: String?
}

private struct PriceOnlyUpdate: Encodable {
    let price: Double
}

private struct RidePriceUpdate: Encodable {
    let pricePerSeat: Double?
    let isFree: Bool

    enum CodingKeys: String, CodingKey {
        case pricePerSeat = "price_per_seat"
        case isFree = "is_free"
    }
}

private struct RentPostFullUpdate: Encodable {
    let price: Double
    let location: String
    let bedrooms: Int
    let bathrooms: Double
    let propertyType: String
    let availableFrom: String?
    let utilitiesIncluded: Bool
    let petsAllowed: Bool
    let parkingAvailable: Bool
    let amenities: [String]

    enum CodingKeys: String, CodingKey {
        case price
        case location
        case bedrooms
        case bathrooms
        case propertyType = "property_type"
        case availableFrom = "available_from"
        case utilitiesIncluded = "utilities_included"
        case petsAllowed = "pets_allowed"
        case parkingAvailable = "parking_available"
        case amenities
    }
}

private struct UserRentRow: Codable {
    let id: UUID
    let userId: UUID
    let title: String
    let description: String?
    let price: Double
    let location: String
    let createdAt: Date
    let userName: String?
    let userAvatar: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case price
        case location
        case createdAt = "created_at"
        case userName = "user_name"
        case userAvatar = "user_avatar"
    }
}

private struct UserRentEditRow: Codable {
    let location: String
    let bedrooms: Int?
    let bathrooms: Double?
    let propertyType: String
    let availableFrom: String?
    let amenities: [String]?

    enum CodingKeys: String, CodingKey {
        case location
        case bedrooms
        case bathrooms
        case propertyType = "property_type"
        case availableFrom = "available_from"
        case amenities
    }
}

private struct UserSecondhandRow: Codable {
    let id: UUID
    let userId: UUID
    let title: String
    let description: String?
    let price: Double
    let condition: String
    let createdAt: Date
    let userName: String?
    let userAvatar: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case price
        case condition
        case createdAt = "created_at"
        case userName = "user_name"
        case userAvatar = "user_avatar"
    }
}

private struct UserRideRow: Codable {
    let id: UUID
    let userId: UUID
    let title: String
    let description: String?
    let departureLocation: String
    let destinationLocation: String
    let pricePerSeat: Double?
    let createdAt: Date
    let userName: String?
    let userAvatar: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case departureLocation = "departure_location"
        case destinationLocation = "destination_location"
        case pricePerSeat = "price_per_seat"
        case createdAt = "created_at"
        case userName = "user_name"
        case userAvatar = "user_avatar"
    }
}

private struct UserTeamRow: Codable {
    let id: UUID
    let userId: UUID
    let title: String
    let description: String?
    let category: String
    let createdAt: Date
    let userName: String?
    let userAvatar: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case category
        case createdAt = "created_at"
        case userName = "user_name"
        case userAvatar = "user_avatar"
    }
}

private struct UserForumRow: Codable {
    let id: UUID
    let userId: UUID
    let title: String
    let description: String?
    let category: String
    let createdAt: Date
    let userName: String?
    let userAvatar: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case category
        case createdAt = "created_at"
        case userName = "user_name"
        case userAvatar = "user_avatar"
    }
}
