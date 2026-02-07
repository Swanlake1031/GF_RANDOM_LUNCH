//
//  CreateRideView.swift
//  CheeseApp
//
//  🚗 发布拼车信息表单
//

import SwiftUI


struct RideBasePostInsert: Encodable {
    let id: String
    let user_id: String
    let type: String
    let title: String
    let description: String?
    let is_anonymous: Bool
}

struct RideDetailInsert: Encodable {
    let id: String
    let departure_location: String
    let destination_location: String
    let departure_time: String
    let role: String
    let total_seats: Int?
    let available_seats: Int?
    let price_per_seat: Double?
    let is_free: Bool
    let is_flexible: Bool
    let contact_method: String
    let notes: String?
    let highlight_type: String
    let pinned_until: String?
}


struct CreateRideView: View {
    @Environment(\.dismiss) private var dismiss
    var onCreated: (() -> Void)? = nil
    
    // 表单字段
    @State private var fromLocation = ""
    @State private var toLocation = ""
    @State private var departureDate = Date()
    @State private var departureTime = Date()
    @State private var seats = 3
    @State private var price = ""
    @State private var isDriver = true
    @State private var notes = ""
    @State private var promotionPlan: PostPromotionPlan = .none
    
    // 状态
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var isValid: Bool {
        !fromLocation.isEmpty && !toLocation.isEmpty
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.94, blue: 0.88)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 角色选择
                    formSection(title: "你是") {
                        HStack(spacing: 12) {
                            roleButton("司机 🚗", isSelected: isDriver) { isDriver = true }
                            roleButton("乘客 🙋", isSelected: !isDriver) { isDriver = false }
                        }
                    }
                    
                    // 路线
                    formSection(title: "路线") {
                        formTextField(icon: "location.circle", placeholder: "出发地", text: $fromLocation)
                        
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.down")
                                .foregroundColor(.green)
                            Spacer()
                        }
                        
                        formTextField(icon: "mappin.circle", placeholder: "目的地", text: $toLocation)
                    }
                    
                    // 时间
                    formSection(title: "出发时间") {
                        HStack {
                            DatePicker("日期", selection: $departureDate, displayedComponents: .date)
                            DatePicker("时间", selection: $departureTime, displayedComponents: .hourAndMinute)
                        }
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // 座位和价格
                    if isDriver {
                        formSection(title: "座位 & 价格") {
                            HStack(spacing: 16) {
                                // 座位数
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("可载人数")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Stepper("\(seats) 人", value: $seats, in: 1...6)
                                        .padding()
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                
                                // 价格
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("每人价格")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        Text("$")
                                        TextField("0", text: $price)
                                            .keyboardType(.decimalPad)
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                    
                    // 备注
                    formSection(title: "备注") {
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
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
        .navigationTitle("Carpool / Ride")
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
                    Text(isDriver ? "发布拼车" : "寻找司机")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isValid ? Color.green : Color.gray)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!isValid || isLoading)
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

        // 合并日期和时间
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: departureDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: departureTime)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        let departureDateTime = calendar.date(from: combined) ?? departureDate
        let formatter = ISO8601DateFormatter()

        let postId = UUID().uuidString
        let parsedPrice = Double(price)
        let normalizedPrice = (parsedPrice ?? 0) > 0 ? parsedPrice : nil
        let defaultAnonymous = await MainActor.run {
            AuthService.shared.currentUser?.isAnonymousDefault ?? false
        }

        let basePostPayload = RideBasePostInsert(
            id: postId,
            user_id: userId.uuidString,
            type: "ride",
            title: "\(fromLocation) → \(toLocation)",
            description: notes.isEmpty ? nil : notes,
            is_anonymous: defaultAnonymous
        )

        let detailPayload = RideDetailInsert(
            id: postId,
            departure_location: fromLocation,
            destination_location: toLocation,
            departure_time: formatter.string(from: departureDateTime),
            role: isDriver ? "driver" : "passenger",
            total_seats: isDriver ? seats : nil,
            available_seats: isDriver ? seats : nil,
            price_per_seat: normalizedPrice,
            is_free: normalizedPrice == nil,
            is_flexible: false,
            contact_method: "app",
            notes: notes.isEmpty ? nil : notes,
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
                    .database("ride_posts")
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
    
    private func formTextField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)
            TextField(placeholder, text: text)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func roleButton(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isSelected ? Color.green : Color.white)
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }

}

#Preview {
    NavigationStack {
        CreateRideView()
            .environmentObject(AuthService.shared)
    }
}
