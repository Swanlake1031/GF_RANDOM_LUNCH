//
//  CreateSecondhandView.swift
//  CheeseApp
//
//  🛍️ 发布二手物品表单
//

import SwiftUI

struct SecondhandBasePostInsert: Encodable {
    let id: String
    let user_id: String
    let type: String
    let title: String
    let description: String?
    let is_anonymous: Bool
}

struct SecondhandDetailInsert: Encodable {
    let id: String
    let price: Double
    let category: String
    let condition: String
    let is_negotiable: Bool
    let is_free: Bool
    let pickup_location: String?
    let can_ship: Bool
    let quantity: Int
    let highlight_type: String
    let pinned_until: String?
}


struct CreateSecondhandView: View {
    @Environment(\.dismiss) private var dismiss
    var onCreated: (() -> Void)? = nil
    
    // 表单字段
    @State private var title = ""
    @State private var description = ""
    @State private var price = ""
    @State private var category = "electronics"
    @State private var condition = "good"
    @State private var isNegotiable = true
    @State private var selectedImages: [UIImage] = []
    @State private var promotionPlan: PostPromotionPlan = .none
    
    // 状态
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let categories = [
        ("electronics", "电子产品"),
        ("furniture", "家具"),
        ("books", "教材书籍"),
        ("clothing", "服装"),
        ("sports", "运动用品"),
        ("other", "其他")
    ]
    
    private let conditions = [
        ("new", "全新"),
        ("like_new", "几乎全新"),
        ("good", "良好"),
        ("fair", "一般"),
        ("poor", "较差")
    ]
    
    var isValid: Bool {
        !title.isEmpty && !price.isEmpty
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.94, blue: 0.88)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 基本信息
                    formSection(title: "物品信息") {
                        formTextField(icon: "tag", placeholder: "物品名称", text: $title)
                        formTextField(icon: "dollarsign.circle", placeholder: "价格", text: $price, keyboardType: .decimalPad)
                    }
                    
                    // 分类
                    formSection(title: "分类") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(categories, id: \.0) { cat, name in
                                    chipButton(name, isSelected: category == cat) {
                                        category = cat
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // 成色
                    formSection(title: "成色") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(conditions, id: \.0) { cond, name in
                                    chipButton(name, isSelected: condition == cond) {
                                        condition = cond
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // 选项
                    formSection(title: "其他") {
                        Toggle(isOn: $isNegotiable) {
                            HStack {
                                Image(systemName: "hand.raised")
                                    .foregroundColor(.orange)
                                Text("可议价")
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    formSection(title: "图片（可选）") {
                        imageSection
                    }

                    formSection(title: "推广选项") {
                        PostPromotionSection(selectedPlan: $promotionPlan)
                    }
                    
                    // 描述
                    formSection(title: "详细描述") {
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
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
        .navigationTitle("Sell an Item")
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
    }
    
    private var submitButton: some View {
        Button(action: { Task { await submit() } }) {
            HStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                    Text("发布物品")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isValid ? Color.orange : Color.gray)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!isValid || isLoading)
    }
    
    private func submit() async {
        guard let priceValue = Double(price) else {
            errorMessage = "请输入有效价格"
            return
        }

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
        let normalizedCategory = category == "textbooks" ? "books" : category
        let defaultAnonymous = await MainActor.run {
            AuthService.shared.currentUser?.isAnonymousDefault ?? false
        }

        let basePostPayload = SecondhandBasePostInsert(
            id: postId,
            user_id: userId.uuidString,
            type: "secondhand",
            title: title,
            description: description.isEmpty ? nil : description,
            is_anonymous: defaultAnonymous
        )

        let detailPayload = SecondhandDetailInsert(
            id: postId,
            price: priceValue,
            category: normalizedCategory,
            condition: condition,
            is_negotiable: isNegotiable,
            is_free: false,
            pickup_location: nil,
            can_ship: false,
            quantity: 1,
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
                    .database("secondhand_posts")
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


    
    // MARK: - 辅助组件
    
    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
    }
    
    private func formTextField(icon: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func chipButton(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.orange : Color.white)
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
        CreateSecondhandView()
            .environmentObject(AuthService.shared)
    }
}
