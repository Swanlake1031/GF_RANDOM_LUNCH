//
//  RentDetailView.swift
//  CheeseApp
//
//  🏠 租房详情视图
//  展示单个房源的完整信息
//

import SwiftUI

struct RentDetailView: View {
    let post: RentPostItem
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    @ObservedObject private var rentService = RentService.shared
    @StateObject private var postEditor = UserPostsService()
    @State private var showContactSheet = false
    @State private var showingReportSheet = false
    @State private var editingPost: UserPostSummary?
    @State private var isLiking = false
    @State private var isLiked = false
    @State private var likeCount = 0
    @State private var currentImageIndex = 0
    @State private var showDeleteConfirm = false

    private var rentThemeColor: Color {
        AppColors.categoryColor(for: "rent")
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 背景色
            Color(red: 0.96, green: 0.94, blue: 0.88)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 图片轮播
                    imageCarousel
                    
                    // 内容区域
                    VStack(alignment: .leading, spacing: 20) {
                        // 标题和价格
                        titleSection
                        
                        // 房源信息
                        propertyInfoSection
                        
                        // 设施
                        amenitiesSection
                        
                        // 描述
                        descriptionSection
                        
                        // 房东信息
                        landlordSection
                        
                        // 位置
                        locationSection
                        
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            
            // 底部操作栏
            bottomBar
        }
        .navigationBarHidden(true)
        .safeAreaInset(edge: .top) { customNavBar }
        .sheet(isPresented: $showContactSheet) {
            contactSheet
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportPostSheet(postId: post.id, postKind: .rent)
        }
        .sheet(item: $editingPost) { summary in
            EditPostSheet(post: summary) { payload in
                try await postEditor.update(payload: payload)
                await rentService.fetchPosts()
            }
        }
        .alert(L10n.tr("Delete this post?", "確定刪除這篇貼文？"), isPresented: $showDeleteConfirm) {
            Button(L10n.tr("Cancel", "取消"), role: .cancel) {}
            Button(L10n.tr("Delete", "刪除"), role: .destructive) {
                Task { await deletePost() }
            }
        } message: {
            Text(L10n.tr("This action cannot be undone.", "刪除後無法復原。"))
        }
        .onAppear {
            isLiked = post.isLiked
            likeCount = post.likeCount
        }
    }
    
    // MARK: - 自定义导航栏
    private var customNavBar: some View {
        PostDetailTopBar(title: L10n.tr("Rent Post", "租房貼文"), onBack: { dismiss() }) {
            ShareLink(item: "\(post.title) - \(post.location)") {
                PostToolbarIconCircle(icon: "square.and.arrow.up")
            }

            Menu {
                if authService.currentUser?.id == post.authorId {
                    Button {
                        editingPost = UserPostSummary(
                            id: post.id,
                            kind: .rent,
                            title: post.title,
                            description: post.description,
                            subtitle: post.location,
                            price: post.price,
                            createdAt: Date(),
                            authorId: post.authorId,
                            authorName: post.authorName,
                            authorAvatarURL: post.authorAvatar
                        )
                    } label: {
                        Label(L10n.tr("Edit", "編輯"), systemImage: "square.and.pencil")
                    }

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label(L10n.tr("Delete", "刪除"), systemImage: "trash")
                    }
                } else {
                    Button(role: .destructive) {
                        showingReportSheet = true
                    } label: {
                        Label(L10n.tr("Report", "檢舉"), systemImage: "flag.fill")
                    }
                }
            } label: {
                PostToolbarIconCircle(icon: "ellipsis")
            }
        }
    }
    
    // MARK: - 图片轮播
    private var imageCarousel: some View {
        ZStack(alignment: .bottom) {
            if let imageURL = post.imageUrl, let url = URL(string: imageURL) {
                TabView(selection: $currentImageIndex) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        placeholderImage
                    }
                    .tag(0)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 300)
            } else {
                placeholderImage
                    .frame(height: 300)
            }
            
            // 分页指示器
            HStack(spacing: 6) {
                ForEach(0..<1, id: \.self) { index in
                    Circle()
                        .fill(currentImageIndex == index ? Color.white : Color.white.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Capsule().fill(.black.opacity(0.3)))
            .padding(.bottom, 16)
        }
    }

    private var placeholderImage: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.3),
                        Color.purple.opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.6))
            }
    }
    
    // MARK: - 标题区域
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 类型标签
            HStack(spacing: 8) {
                Text(post.propertyType.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(rentThemeColor.opacity(0.16))
                    .foregroundStyle(rentThemeColor)
                    .cornerRadius(6)

                Text(post.location)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.textMuted)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(isLiked ? .red : AppColors.textMuted)
                    Text("\(likeCount)")
                        .foregroundStyle(AppColors.textMuted)
                }
                .font(.system(size: 13, weight: .semibold))
                .onTapGesture {
                    Task { await toggleLike() }
                }
                .allowsHitTesting(!isLiking)
            }
            
            // 标题
            Text(post.title)
                .font(.system(size: 26, weight: .bold))
            
            // 价格
            HStack(alignment: .bottom, spacing: 4) {
                Text("$\(Int(post.price))")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(rentThemeColor)
                
                Text("/month")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .offset(y: -3)
            }
        }
    }
    
    // MARK: - 房源信息
    private var propertyInfoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Property Details")
                .font(.system(size: 18, weight: .semibold))
            
            HStack(spacing: 0) {
                PropertyInfoItem(icon: "bed.double.fill", value: "\(post.bedrooms)", label: "Beds", tint: rentThemeColor)
                PropertyInfoItem(icon: "shower.fill", value: "\(post.bathrooms)", label: "Baths", tint: rentThemeColor)
                PropertyInfoItem(icon: "calendar", value: formatDate(post.availableDate), label: "Available", tint: rentThemeColor)
            }
            .padding(.vertical, 16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        }
    }
    
    // MARK: - 设施
    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Amenities")
                .font(.system(size: 18, weight: .semibold))
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(post.amenities.enumerated()), id: \.offset) { _, amenity in
                    HStack(spacing: 10) {
                        Image(systemName: iconFor(amenity: amenity))
                            .font(.system(size: 16))
                            .foregroundStyle(rentThemeColor)
                            .frame(width: 24)
                        
                        Text(amenity)
                            .font(.system(size: 14))
                        
                        Spacer()
                    }
                    .padding(14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                }
            }
        }
    }
    
    // MARK: - 描述
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.system(size: 18, weight: .semibold))
            
            Text(post.description)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
    }
    
    // MARK: - 房东信息
    private var landlordSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Posted By")
                .font(.system(size: 18, weight: .semibold))
            
            HStack(spacing: 14) {
                NavigationLink {
                    UserPostsView(userId: post.authorId)
                } label: {
                    HStack(spacing: 14) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [rentThemeColor, rentThemeColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .overlay {
                                Text(String(post.authorName.prefix(1)))
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(post.authorName)
                                .font(.system(size: 17, weight: .semibold))

                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(rentThemeColor)

                                Text("Verified Student")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // 响应时间
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Usually responds")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    
                    Text("within 2 hours")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(rentThemeColor)
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        }
    }
    
    // MARK: - 位置
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Location")
                .font(.system(size: 18, weight: .semibold))
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.red)
                    
                    Text(post.location)
                        .font(.system(size: 15))
                }
                
                // 地图占位符
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 180)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "map")
                                .font(.system(size: 32))
                                .foregroundStyle(.gray)
                            Text("Map View")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        }
    }
    
    // MARK: - 底部操作栏
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                // 价格信息
                VStack(alignment: .leading, spacing: 2) {
                    Text("$\(Int(post.price))/mo")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("All inclusive")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // 联系按钮
                Button(action: { showContactSheet = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "message.fill")
                        Text("Contact")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.95, green: 0.85, blue: 0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
        }
    }
    
    // MARK: - 联系弹窗
    private var contactSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 房东头像
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [rentThemeColor, rentThemeColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay {
                        Text(String(post.authorName.prefix(1)))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                    }
                
                Text("Contact \(post.authorName)")
                    .font(.system(size: 22, weight: .bold))
                
                // 联系选项
                VStack(spacing: 12) {
                    ContactOptionButton(icon: "message.fill", title: "Send Message", subtitle: "Usually responds within 2 hours", color: rentThemeColor)
                    
                    ContactOptionButton(icon: "phone.fill", title: "Request Phone Number", subtitle: "Landlord will share if interested", color: AppColors.link)
                    
                    ContactOptionButton(icon: "calendar", title: "Schedule Tour", subtitle: "Request an in-person viewing", color: AppColors.accentStrong)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 32)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showContactSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - 辅助方法
    private func toggleLike() async {
        guard !isLiking else { return }
        isLiking = true
        defer { isLiking = false }

        do {
            let newLiked = try await rentService.toggleLike(postId: post.id, currentlyLiked: isLiked)
            isLiked = newLiked
            likeCount = max(likeCount + (newLiked ? 1 : -1), 0)
        } catch {
            print("⚠️ Rent detail like failed: \(error)")
        }
    }

    private func deletePost() async {
        do {
            try await postEditor.delete(postId: post.id)
            dismiss()
        } catch {
            print("❌ Delete rent post failed: \(error)")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func iconFor(amenity: String) -> String {
        let lowercased = amenity.lowercased()
        if lowercased.contains("wifi") { return "wifi" }
        if lowercased.contains("laundry") { return "washer.fill" }
        if lowercased.contains("parking") { return "car.fill" }
        if lowercased.contains("gym") { return "dumbbell.fill" }
        if lowercased.contains("pool") { return "figure.pool.swim" }
        if lowercased.contains("ac") { return "air.conditioner.horizontal.fill" }
        if lowercased.contains("furnished") { return "sofa.fill" }
        if lowercased.contains("kitchen") { return "refrigerator.fill" }
        return "checkmark.circle.fill"
    }
}

// MARK: - 房源信息项
struct PropertyInfoItem: View {
    let icon: String
    let value: String
    let label: String
    var tint: Color = AppColors.categoryColor(for: "rent")
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(tint)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
            
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 联系选项按钮
struct ContactOptionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        Button(action: { }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(.systemGray3))
            }
            .padding(14)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

// MARK: - Preview
#Preview {
    RentDetailView(post: RentPostItem(
        id: UUID(),
        title: "Preview Apartment",
        price: 1500,
        location: "Los Angeles, CA",
        specs: "2 Bed • 1 Bath",
        propertyType: .apartment,
        imageUrl: nil,
        authorId: UUID(),
        authorName: "Preview User",
        authorAvatar: nil,
        distance: "0.5 mi",
        timeAgo: "1h ago",
        isFavorited: false,
        likeCount: 0,
        isLiked: false,
        highlightType: .normal,
        description: "This is a preview description for the apartment.",
        amenities: ["WiFi", "Parking", "Laundry"],
        availableDate: Date(),
        bedrooms: 2,
        bathrooms: 1
    ))
}
