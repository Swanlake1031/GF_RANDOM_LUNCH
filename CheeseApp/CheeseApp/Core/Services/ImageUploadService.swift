//
//  ImageUploadService.swift
//  CheeseApp
//
//  🎯 图片上传服务
//

import SwiftUI
import Supabase

@MainActor
class ImageUploadService {
    static let shared = ImageUploadService()
    
    private init() {}
    
    func uploadImage(_ image: UIImage, to bucket: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.82) else {
            throw NSError(
                domain: "",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Unable to process image data"]
            )
        }

        let userId = (try? await AuthService.shared.requireAuthUserId())?.uuidString ?? "anonymous"
        let path = "\(userId)/\(UUID().uuidString).jpg"

        try await SupabaseManager.shared
            .storage(bucket)
            .upload(
                path,
                data: data,
                options: FileOptions(contentType: "image/jpeg")
            )

        let publicURL = try SupabaseManager.shared
            .storage(bucket)
            .getPublicURL(path: path)

        return publicURL.absoluteString
    }
    
    func uploadImages(_ images: [UIImage], to bucket: String) async throws -> [String] {
        var urls: [String] = []
        for image in images {
            let url = try await uploadImage(image, to: bucket)
            urls.append(url)
        }
        return urls
    }

    func attachImages(_ images: [UIImage], toPostId postId: UUID) async throws -> [String] {
        guard !images.isEmpty else { return [] }

        let urls = try await uploadImages(images, to: StorageBuckets.postImages)
        let payload = urls.enumerated().map { index, url in
            PostImageInsert(postId: postId, url: url, orderIndex: index)
        }

        try await SupabaseManager.shared
            .database(Tables.postImages)
            .insert(payload)
            .execute()

        return urls
    }
}

private struct PostImageInsert: Encodable {
    let postId: UUID
    let url: String
    let orderIndex: Int

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case url
        case orderIndex = "order_index"
    }
}
