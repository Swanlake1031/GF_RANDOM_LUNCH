//
//  CreateRentView.swift
//  CheeseApp
//
//  📝 发布租房帖子视图
//

import SwiftUI

struct CreateRentView: View {
    @StateObject private var viewModel = CreateRentViewModel()
    @Environment(\.dismiss) private var dismiss
    var onCreated: (() -> Void)? = nil
    @State private var selectedImages: [UIImage] = []
    
    // 房屋类型选项
    private let propertyTypes = ["apartment", "house", "studio", "room", "condo"]
    private let propertyTypeNames = ["公寓", "独栋", "单间", "合租房间", "公寓大楼"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                Color(red: 0.96, green: 0.94, blue: 0.88)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 基本信息
                        formSection(title: "基本信息") {
                            formTextField(
                                icon: "pencil",
                                placeholder: "标题（如：近校区温馨单间）",
                                text: $viewModel.title
                            )
                            
                            formTextField(
                                icon: "dollarsign.circle",
                                placeholder: "月租价格",
                                text: $viewModel.price,
                                keyboardType: .decimalPad
                            )
                            
                            formTextField(
                                icon: "building.2",
                                placeholder: "城市",
                                text: $viewModel.city
                            )
                            
                            formTextField(
                                icon: "mappin.circle",
                                placeholder: "详细地址",
                                text: $viewModel.address
                            )
                        }
                        
                        // 房屋信息
                        formSection(title: "房屋信息") {
                            // 房屋类型
                            VStack(alignment: .leading, spacing: 8) {
                                Text("房屋类型")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(Array(zip(propertyTypes, propertyTypeNames)), id: \.0) { type, name in
                                            Button {
                                                viewModel.propertyType = type
                                            } label: {
                                                Text(name)
                                                    .font(.subheadline.weight(.medium))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 10)
                                                    .background(
                                                        viewModel.propertyType == type
                                                            ? Color("CheeseAccent")
                                                            : Color.white
                                                    )
                                                    .foregroundColor(
                                                        viewModel.propertyType == type
                                                            ? .white
                                                            : .primary
                                                    )
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            
                            // 卧室 & 卫生间
                            HStack(spacing: 12) {
                                counterField(
                                    title: "卧室",
                                    value: $viewModel.bedrooms,
                                    icon: "bed.double"
                                )
                                
                                counterField(
                                    title: "卫生间",
                                    value: $viewModel.bathrooms,
                                    icon: "shower"
                                )
                            }
                            
                            // 入住日期
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.secondary)
                                Text("可入住日期")
                                    .foregroundColor(.secondary)
                                Spacer()
                                DatePicker(
                                    "",
                                    selection: $viewModel.availableDate,
                                    displayedComponents: .date
                                )
                                .labelsHidden()
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        // 设施
                        formSection(title: "设施") {
                            amenitiesGrid
                        }
                        
                        // 描述
                        formSection(title: "详细描述") {
                            TextEditor(text: $viewModel.description)
                                .frame(minHeight: 120)
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    Group {
                                        if viewModel.description.isEmpty {
                                            Text("描述一下你的房源，包括周边设施、交通等...")
                                                .foregroundColor(.gray.opacity(0.5))
                                                .padding(16)
                                        }
                                    },
                                    alignment: .topLeading
                                )
                        }

                        // 图片
                        formSection(title: "图片（可选）") {
                            imageSection
                        }

                        formSection(title: "推广选项") {
                            PostPromotionSection(selectedPlan: $viewModel.promotionPlan)
                        }
                        
                        // 错误信息
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.subheadline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        // 发布按钮
                        Button {
                            Task { await submit() }
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                    Text("发布租房信息")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                viewModel.isValid
                                    ? Color("CheeseAccent")
                                    : Color.gray
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!viewModel.isValid || viewModel.isLoading)
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("发布租房")
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundStyle(AppColors.accentStrong)
                }
            }
        }
    }
    
    // MARK: - 设施选择网格
    private var amenitiesGrid: some View {
        let amenitiesList = [
            ("wifi", "WiFi"),
            ("washer", "洗衣机"),
            ("air.conditioner.horizontal", "空调"),
            ("parkingsign", "停车位"),
            ("leaf", "允许宠物"),
            ("bolt", "水电全包"),
            ("tv", "电视"),
            ("refrigerator", "冰箱")
        ]
        
        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(amenitiesList, id: \.1) { icon, name in
                Button {
                    if viewModel.amenities.contains(name) {
                        viewModel.amenities.remove(name)
                    } else {
                        viewModel.amenities.insert(name)
                    }
                } label: {
                    HStack {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                        Text(name)
                            .font(.subheadline)
                        Spacer()
                        if viewModel.amenities.contains(name) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color("CheeseAccent"))
                        }
                    }
                    .padding()
                    .background(
                        viewModel.amenities.contains(name)
                            ? Color("CheeseAccent").opacity(0.1)
                            : Color.white
                    )
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    // MARK: - 辅助组件
    
    private func formSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content()
        }
    }
    
    private func formTextField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private func counterField(
        title: String,
        value: Binding<Int>,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                Text(title)
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
            
            HStack {
                Button {
                    if value.wrappedValue > 1 {
                        value.wrappedValue -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(value.wrappedValue > 1 ? Color("CheeseAccent") : .gray)
                }
                
                Text("\(value.wrappedValue)")
                    .font(.title3.weight(.semibold))
                    .frame(width: 40)
                
                Button {
                    value.wrappedValue += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color("CheeseAccent"))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
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
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func submit() async {
        await viewModel.submit()
        guard viewModel.isSuccess else { return }

        if !selectedImages.isEmpty, let postId = viewModel.lastCreatedPostId {
            do {
                _ = try await ImageUploadService.shared.attachImages(selectedImages, toPostId: postId)
            } catch {
                viewModel.errorMessage = "帖子已发布，但图片上传失败：\(error.localizedDescription)"
                return
            }
        }

        if let onCreated {
            onCreated()
        } else {
            dismiss()
        }
    }
}

#Preview {
    CreateRentView()
}
