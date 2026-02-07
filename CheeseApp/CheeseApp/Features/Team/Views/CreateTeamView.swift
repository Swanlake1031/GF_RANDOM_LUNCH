//
//  CreateTeamView.swift
//  CheeseApp
//
//  👥 创建组队/学习小组表单
//

import SwiftUI


struct TeamBasePostInsert: Encodable {
    let id: String
    let user_id: String
    let type: String
    let title: String
    let description: String?
    let is_anonymous: Bool
}

struct TeamDetailInsert: Encodable {
    let id: String
    let category: String
    let team_size: Int
    let current_members: Int
    let spots_available: Int
    let skills_needed: [String]
    let deadline: String?
    let is_remote: Bool
    let highlight_type: String
    let pinned_until: String?
}


struct CreateTeamView: View {
    @Environment(\.dismiss) private var dismiss
    var onCreated: (() -> Void)? = nil
    
    // 表单字段
    @State private var title = ""
    @State private var description = ""
    @State private var category = "study"
    @State private var maxMembers = 5
    @State private var skills: [String] = []
    @State private var newSkill = ""
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var selectedImages: [UIImage] = []
    @State private var promotionPlan: PostPromotionPlan = .none
    
    // 状态
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let categories = [
        ("study", "学习小组"),
        ("project", "项目团队"),
        ("activity", "活动组织"),
        ("sports", "运动搭子"),
        ("other", "其他")
    ]
    
    var isValid: Bool {
        !title.isEmpty
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.94, blue: 0.88)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 基本信息
                    formSection(title: "组队信息") {
                        formTextField(icon: "person.2", placeholder: "组队标题（如：CS101 期末复习小组）", text: $title)
                    }
                    
                    // 分类
                    formSection(title: "类型") {
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
                    
                    // 人数
                    formSection(title: "招募人数") {
                        HStack {
                            Text("最多")
                                .foregroundColor(.secondary)
                            Spacer()
                            Stepper("\(maxMembers) 人", value: $maxMembers, in: 2...20)
                        }
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // 截止日期
                    formSection(title: "招募截止") {
                        VStack(spacing: 12) {
                            Toggle(isOn: $hasDeadline) {
                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundColor(.purple)
                                    Text("设置截止日期")
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            if hasDeadline {
                                DatePicker("截止日期", selection: $deadline, displayedComponents: .date)
                                    .padding()
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    
                    // 技能要求
                    formSection(title: "技能标签（可选）") {
                        VStack(alignment: .leading, spacing: 12) {
                            // 已添加的标签
                            if !skills.isEmpty {
                                TeamFlowLayout(spacing: 8) {
                                    ForEach(Array(skills.enumerated()), id: \.offset) { index, skill in
                                        HStack(spacing: 4) {
                                            Text(skill)
                                            Button(action: {
                                                guard skills.indices.contains(index) else { return }
                                                skills.remove(at: index)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.caption)
                                            }
                                        }
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.purple.opacity(0.15))
                                        .foregroundColor(.purple)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                            
                            // 添加新标签
                            HStack {
                                TextField("添加技能标签", text: $newSkill)
                                Button(action: addSkill) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.purple)
                                }
                                .disabled(newSkill.isEmpty)
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    // 描述
                    formSection(title: "详细描述") {
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .padding(12)
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
        .navigationTitle("Create a Group")
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
                    Text("发布组队")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isValid ? Color.purple : Color.gray)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!isValid || isLoading)
    }
    
    private func addSkill() {
        let trimmed = newSkill.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !skills.contains(trimmed) {
            skills.append(trimmed)
            newSkill = ""
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
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        let postId = UUID().uuidString
        let normalizedCategory = normalizedTeamCategory(category)
        let teamSize = max(maxMembers, 1)
        let defaultAnonymous = await MainActor.run {
            AuthService.shared.currentUser?.isAnonymousDefault ?? false
        }

        let basePostPayload = TeamBasePostInsert(
            id: postId,
            user_id: userId.uuidString,
            type: "team",
            title: title,
            description: description.isEmpty ? nil : description,
            is_anonymous: defaultAnonymous
        )

        let detailPayload = TeamDetailInsert(
            id: postId,
            category: normalizedCategory,
            team_size: teamSize,
            current_members: 1,
            spots_available: max(teamSize - 1, 0),
            skills_needed: skills,
            deadline: hasDeadline ? formatter.string(from: deadline) : nil,
            is_remote: true,
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
                    .database("team_posts")
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

    private func normalizedTeamCategory(_ value: String) -> String {
        switch value {
        case "study": return "study"
        case "project": return "course"
        case "activity": return "competition"
        case "sports": return "sports"
        case "hackathon": return "hackathon"
        case "other": return "other"
        default: return "other"
        }
    }

    // MARK: - 辅助组件
    
    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
    }
    
    private func formTextField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)
            TextField(placeholder, text: text)
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
                .background(isSelected ? Color.purple : Color.white)
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

// MARK: - FlowLayout (简单实现)
struct TeamFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalHeight = currentY + lineHeight
        }
        
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

#Preview {
    NavigationStack {
        CreateTeamView()
            .environmentObject(AuthService.shared)
    }
}
