import Foundation
import Supabase

struct PostReactionState {
    let isLiked: Bool
    let likeCount: Int
}

@MainActor
final class PostReactionService {
    static let shared = PostReactionService()

    private let supabase = SupabaseManager.shared

    private init() {}

    func fetchStates(postIds: [UUID]) async -> [UUID: PostReactionState] {
        guard !postIds.isEmpty else { return [:] }

        let ids = postIds.map { $0 as any PostgrestFilterValue }
        var countMap: [UUID: Int] = [:]

        do {
            let allLikes: [ReactionLikeTargetRow] = try await supabase
                .database("likes")
                .select("target_id")
                .eq("target_type", value: "post")
                .`in`("target_id", values: ids)
                .execute()
                .value

            for row in allLikes {
                countMap[row.targetId, default: 0] += 1
            }
        } catch {
            if !shouldIgnore(error) {
                print("⚠️ Failed to fetch post like counts: \(error)")
            }
        }

        var likedSet: Set<UUID> = []
        if let userId = try? await AuthService.shared.requireAuthUserId() {
            do {
                let likedRows: [ReactionLikeTargetRow] = try await supabase
                    .database("likes")
                    .select("target_id")
                    .eq("target_type", value: "post")
                    .eq("user_id", value: userId.uuidString)
                    .`in`("target_id", values: ids)
                    .execute()
                    .value
                likedSet = Set(likedRows.map(\.targetId))
            } catch {
                if !shouldIgnore(error) {
                    print("⚠️ Failed to fetch current user's like states: \(error)")
                }
            }
        }

        var result: [UUID: PostReactionState] = [:]
        for postId in postIds {
            result[postId] = PostReactionState(
                isLiked: likedSet.contains(postId),
                likeCount: countMap[postId, default: 0]
            )
        }
        return result
    }

    func toggle(postId: UUID, currentlyLiked: Bool) async throws -> Bool {
        let userId: UUID
        do {
            userId = try await AuthService.shared.requireAuthUserId()
        } catch {
            await AuthService.shared.checkSession()
            throw NSError(
                domain: "",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Please sign in before liking posts"]
            )
        }

        if currentlyLiked {
            try await supabase
                .database("likes")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .eq("target_type", value: "post")
                .eq("target_id", value: postId.uuidString)
                .execute()
            return false
        }

        do {
            try await supabase
                .database("likes")
                .insert(ReactionLikeInsert(userId: userId, targetType: "post", targetId: postId))
                .execute()
            return true
        } catch {
            let message = error.localizedDescription.lowercased()
            if message.contains("duplicate key") || message.contains("unique") {
                return true
            }
            throw error
        }
    }

    private func shouldIgnore(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
    }
}

private struct ReactionLikeTargetRow: Codable {
    let targetId: UUID

    enum CodingKeys: String, CodingKey {
        case targetId = "target_id"
    }
}

private struct ReactionLikeInsert: Encodable {
    let userId: UUID
    let targetType: String
    let targetId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case targetType = "target_type"
        case targetId = "target_id"
    }
}
