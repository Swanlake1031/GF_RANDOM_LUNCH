//
//  CreateForumView.swift
//  CheeseApp
//
//  💬 发布论坛帖子/树洞表单
//

import SwiftUI

struct ForumBasePostInsert: Encodable {
    let id: String
    let user_id: String
    let type: String
    let title: String
    let description: String?
    let is_anonymous: Bool
}

struct ForumDetailInsert: Encodable {
    let id: String
    let category: String
    let tags: [String]
    let allow_comments: Bool
    let highlight_type: String
    let pinned_until: String?
}


struct CreateForumView: View {
    @Environment(\.dismiss) private var dismiss
    var onCreated: (() -> Void)? = nil
    
    // 表单字段
    @State private var title = ""
    @State private var content = ""
    @State private var isAnonymous = false
    @State private var didInitializeAnonymous = false
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var selectedImages: [UIImage] = []
    @State private var promotionPlan: PostPromotionPlan = .none
    
    // 预设标签
    private let suggestedTags = ["求助", "吐槽", "分享", "提问", "校园生活", "学习", "情感", "八卦"]
    
    // 状态
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var isValid: Bool {
        !title.isEmpty && !content.isEmpty
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.94, blue: 0.88)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 匿名选项
                    HStack {
                        Image(systemName: isAnonymous ? "person.fill.questionmark" : "person.fill")
                            .foregroundColor(isAnonymous ? .pink : .secondary)
                        
                        Toggle(isAnonymous ? "匿名发布 🎭" : "实名发布", isOn: $isAnonymous)
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // 标题
                    formSection(title: "标题") {
                        TextField("想说点什么...", text: $title)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // 标签
                    formSection(title: "标签") {
                        VStack(alignment: .leading, spacing: 12) {
                            // 已选标签
                            if !tags.isEmpty {
                                FlowLayout(spacing: 8) {
                                    ForEach(Array(tags.enumerated()), id: \.offset) { index, tag in
                                        HStack(spacing: 4) {
                                            Text("#\(tag)")
                                            Button(action: {
                                                guard tags.indices.contains(index) else { return }
                                                tags.remove(at: index)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.caption)
                                            }
                                        }
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.pink.opacity(0.15))
                                        .foregroundColor(.pink)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                            
                            // 推荐标签
                            Text("推荐标签")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(
                                    Array(suggestedTags.filter { !tags.contains($0) }.enumerated()),
                                    id: \.offset
                                ) { _, tag in
                                    Button(action: { tags.append(tag) }) {
                                        Text("#\(tag)")
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.white)
                                            .foregroundColor(.secondary)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            
                            // 自定义标签
                            HStack {
                                TextField("添加自定义标签", text: $newTag)
                                Button(action: addTag) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.pink)
                                }
                                .disabled(newTag.isEmpty)
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    // 内容
                    formSection(title: "内容") {
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $content)
                                .frame(minHeight: 200)
                                .padding(12)
                            
                            if content.isEmpty {
                                Text("分享你的想法、提问、或者只是想找人聊聊...")
                                    .foregroundColor(.gray.opacity(0.5))
                                    .padding(16)
                                    .allowsHitTesting(false)
                            }
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    formSection(title: "图片（可选）") {
                        imageSection
                    }

                    formSection(title: "推广选项") {
                        PostPromotionSection(selectedPlan: $promotionPlan)
                    }
                    
                    // 错误信息
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                    
                    // 发布按钮
                    submitButton
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
        .navigationTitle("Forum Post")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(AppColors.accentStrong)
                }
            }
        }
        .onAppear {
            guard !didInitializeAnonymous else { return }
            isAnonymous = AuthService.shared.currentUser?.isAnonymousDefault ?? false
            didInitializeAnonymous = true
        }
    }
    
    private var submitButton: some View {
        Button(action: { Task { await submit() } }) {
            HStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                    Text(isAnonymous ? "匿名发布" : "发布帖子")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isValid ? Color.pink : Color.gray)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!isValid || isLoading)
    }
    
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            tags.append(trimmed)
            newTag = ""
        }
    }
    
    private func submit() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let userId: UUID
        do {
            userId = try await AuthService.shared.requireAuthUserId()
        } catch {
            await AuthService.shared.checkSession()
            errorMessage = "请先登录后再发布"
            return
        }

        let postId = UUID().uuidString
        let normalizedCategory = normalizedForumCategory(from: tags)

        let basePostPayload = ForumBasePostInsert(
            id: postId,
            user_id: userId.uuidString,
            type: "forum",
            title: title,
            description: content,
            is_anonymous: isAnonymous
        )

        let detailPayload = ForumDetailInsert(
            id: postId,
            category: normalizedCategory,
            tags: tags,
            allow_comments: true,
            highlight_type: promotionPlan.highlightType,
            pinned_until: promotionPlan.pinnedUntil
        )

            do {
                try await SupabaseManager.shared
                    .database("posts")
                    .insert(basePostPayload)
                    .execute()

            do {
                try await SupabaseManager.shared
                    .database("forum_posts")
                    .insert(detailPayload)
                    .execute()
            } catch {
                _ = try? await SupabaseManager.shared
                    .database("posts")
                    .delete()
                    .eq("id", value: postId)
                    .execute()
                throw error
            }

            if !selectedImages.isEmpty, let postUUID = UUID(uuidString: postId) {
                do {
                    _ = try await ImageUploadService.shared.attachImages(selectedImages, toPostId: postUUID)
                } catch {
                    errorMessage = "帖子已发布，但图片上传失败：\(error.localizedDescription)"
                    return
                }
            }

            await ForumService.shared.fetchPosts()

            if let onCreated {
                onCreated()
            } else {
                dismiss()
            }
        } catch {
            errorMessage = publishErrorMessage(from: error)
        }
    }

    private func publishErrorMessage(from error: Error) -> String {
        let message = error.localizedDescription.lowercased()
        if message.contains("row-level security") || message.contains("permission denied") {
            return "发布失败：登录状态失效或无写入权限，请重新登录后重试"
        }
        return "发布失败: \(error.localizedDescription)"
    }

    private func normalizedForumCategory(from tags: [String]) -> String {
        let tagSet = Set(tags)

        if tagSet.contains("求助") || tagSet.contains("提问") {
            return "question"
        }
        if tagSet.contains("吐槽") {
            return "rant"
        }
        if tagSet.contains("分享") {
            return "share"
        }
        if tagSet.contains("情感") {
            return "love"
        }
        if tagSet.contains("校园生活") || tagSet.contains("学习") {
            return "life"
        }
        return "other"
    }

    
    // MARK: - 辅助组件
    
    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
    }

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ImagePicker(selectedImages: $selectedImages, maxCount: 6)
                .font(.subheadline.weight(.semibold))

            if !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { _, image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 78, height: 78)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        CreateForumView()
            .environmentObject(AuthService.shared)
    }
}
