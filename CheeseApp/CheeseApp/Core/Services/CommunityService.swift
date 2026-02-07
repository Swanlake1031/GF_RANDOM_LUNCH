import Foundation

enum ReportReason: String, CaseIterable, Identifiable {
    case spam
    case harassment
    case fraud
    case inappropriate
    case misleading
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spam: return "Spam / Ads"
        case .harassment: return "Harassment"
        case .fraud: return "Fraud / Scam"
        case .inappropriate: return "Inappropriate Content"
        case .misleading: return "Misleading Info"
        case .other: return "Other"
        }
    }
}

enum FeedbackCategory: String, CaseIterable, Identifiable {
    case bug
    case feature
    case ui
    case performance
    case account
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bug: return "Bug"
        case .feature: return "Feature"
        case .ui: return "UI / UX"
        case .performance: return "Performance"
        case .account: return "Account"
        case .other: return "Other"
        }
    }
}

@MainActor
final class CommunityService {
    static let shared = CommunityService()

    private let supabase = SupabaseManager.shared

    private init() {}

    func submitPostReport(postId: UUID, reason: ReportReason, details: String?) async throws {
        let reporterId: UUID
        do {
            reporterId = try await AuthService.shared.requireAuthUserId()
        } catch {
            await AuthService.shared.checkSession()
            throw NSError(
                domain: "",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Please sign in before reporting"]
            )
        }

        let trimmedDetails = details?.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try await supabase
                .database("post_reports")
                .insert(PostReportInsert(
                    postId: postId,
                    reporterId: reporterId,
                    reason: reason.rawValue,
                    details: trimmedDetails?.isEmpty == true ? nil : trimmedDetails
                ))
                .execute()
        } catch {
            let lowered = error.localizedDescription.lowercased()
            if lowered.contains("duplicate key") || lowered.contains("unique") {
                throw NSError(
                    domain: "",
                    code: 409,
                    userInfo: [NSLocalizedDescriptionKey: "You already reported this post"]
                )
            }
            throw error
        }
    }

    func submitFeedback(category: FeedbackCategory, message: String, contactEmail: String?) async throws {
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else {
            throw NSError(
                domain: "",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Feedback message cannot be empty"]
            )
        }

        let userId = try? await AuthService.shared.requireAuthUserId()
        let trimmedEmail = contactEmail?.trimmingCharacters(in: .whitespacesAndNewlines)

        try await supabase
            .database("user_feedback")
            .insert(UserFeedbackInsert(
                userId: userId,
                category: category.rawValue,
                message: trimmedMessage,
                contactEmail: trimmedEmail?.isEmpty == true ? nil : trimmedEmail
            ))
            .execute()
    }
}

private struct PostReportInsert: Encodable {
    let postId: UUID
    let reporterId: UUID
    let reason: String
    let details: String?

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case reporterId = "reporter_id"
        case reason
        case details
    }
}

private struct UserFeedbackInsert: Encodable {
    let userId: UUID?
    let category: String
    let message: String
    let contactEmail: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case category
        case message
        case contactEmail = "contact_email"
    }
}
