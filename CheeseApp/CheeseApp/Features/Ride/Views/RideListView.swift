//
//  RideListView.swift
//  CheeseApp
//
//  🚗 拼车列表视图
//  展示所有拼车信息，支持筛选
//

import SwiftUI

struct RideListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    @StateObject private var service = RideService.shared
    @StateObject private var postEditor = UserPostsService()
    @State private var searchText = ""
    @State private var selectedFilter: RideType = .all
    @State private var showingCreateRide = false
    @State private var showMessagingComingSoon = false
    @State private var editingPost: UserPostSummary?
    @State private var likingPostIDs: Set<UUID> = []
    @State private var selectedRide: RideItem?
    
    var body: some View {
        ZStack {
            AppColors.pageBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // 筛选栏
                    filterBar
                    
                    // 加载状态
                    if service.isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else if service.rides.isEmpty {
                        emptyState
                    } else {
                        // 拼车卡片列表
                        LazyVStack(spacing: 14) {
                            ForEach(filteredRides) { ride in
                                RideCardView(
                                    ride: ride,
                                    isOwnPost: authService.currentUser?.id == ride.driverId,
                                    onOpenTap: {
                                        selectedRide = ride
                                    },
                                    onContactTap: {
                                        showMessagingComingSoon = true
                                    },
                                    onLikeTap: {
                                        await toggleLike(for: ride)
                                    },
                                    onEditTap: {
                                        editingPost = toEditableSummary(ride)
                                    }
                                )
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .refreshable {
                await service.fetchRides()
            }
        }
        .navigationTitle("Carpool")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingCreateRide = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search destinations...")
        .navigationDestination(isPresented: $showingCreateRide) {
            CreateRideView()
        }
        .sheet(item: $editingPost) { post in
            EditPostSheet(post: post) { payload in
                try await postEditor.update(payload: payload)
                await service.fetchRides()
            }
        }
        .navigationDestination(item: $selectedRide) { ride in
            RideDetailView(ride: ride)
        }
        .alert("Messaging Coming Soon", isPresented: $showMessagingComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Ride messaging is not implemented yet. Please use another contact channel for now.")
        }
        .task {
            await service.fetchRides()
        }
    }
    
    // MARK: - 空状态
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "car")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No rides yet")
                .font(.system(size: 18, weight: .medium))
            Text("Post or find a ride!")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 60)
    }
    
    // MARK: - 筛选栏
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(RideType.allCases, id: \.self) { type in
                    FilterChip(
                        title: type.title,
                        isSelected: selectedFilter == type
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = type
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 筛选后的拼车
    private var filteredRides: [RideItem] {
        var result = service.rides
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.from.localizedCaseInsensitiveContains(searchText) ||
                $0.to.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if selectedFilter != .all {
            result = result.filter { $0.type == selectedFilter }
        }
        
        return result
    }

    private func toggleLike(for ride: RideItem) async {
        guard !likingPostIDs.contains(ride.id) else { return }
        likingPostIDs.insert(ride.id)
        defer { likingPostIDs.remove(ride.id) }

        do {
            _ = try await service.toggleLike(postId: ride.id, currentlyLiked: ride.isLiked)
        } catch {
            print("⚠️ Ride like failed: \(error)")
        }
    }

    private func toEditableSummary(_ ride: RideItem) -> UserPostSummary {
        UserPostSummary(
            id: ride.id,
            kind: .ride,
            title: "\(ride.from) → \(ride.to)",
            description: ride.carModel,
            subtitle: "\(ride.from) → \(ride.to)",
            price: ride.price > 0 ? ride.price : nil,
            createdAt: Date(),
            authorId: ride.driverId,
            authorName: ride.driverName,
            authorAvatarURL: ride.driverAvatar
        )
    }
}

// MARK: - 拼车类型
enum RideType: CaseIterable {
    case all, offering, looking
    
    var title: String {
        switch self {
        case .all: return "All"
        case .offering: return "Offering Ride"
        case .looking: return "Need Ride"
        }
    }
}

// MARK: - 拼车卡片
struct RideCardView: View {
    let ride: RideItem
    let isOwnPost: Bool
    var onOpenTap: (() -> Void)?
    var onContactTap: (() -> Void)?
    var onLikeTap: (() async -> Void)?
    var onEditTap: (() -> Void)?
    @State private var showingReportSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            if let imageUrl = ride.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .overlay {
                                Image(systemName: "car.fill")
                                    .foregroundStyle(.gray.opacity(0.45))
                            }
                    }
                }
                .frame(height: 170)
                .clipped()
            }

            // 头部：类型 + 时间
            HStack {
                // 类型标签
                HStack(spacing: 6) {
                    Image(systemName: ride.type == .offering ? "car.fill" : "hand.raised.fill")
                        .font(.system(size: 12))
                    Text(ride.type.title)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(ride.type == .offering ? AppColors.categoryColor(for: "carpool") : AppColors.categoryColor(for: "rent"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    (ride.type == .offering ? AppColors.categoryColor(for: "carpool") : AppColors.categoryColor(for: "rent")).opacity(0.15)
                )
                .cornerRadius(8)
                
                Spacer()
                
                // 时间
                Text(ride.dateText)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Menu {
                    if isOwnPost {
                        Button {
                            onEditTap?()
                        } label: {
                            Label("Edit", systemImage: "square.and.pencil")
                        }
                    } else {
                        Button(role: .destructive) {
                            showingReportSheet = true
                        } label: {
                            Label("Report", systemImage: "flag.fill")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(8)
                        .background(AppColors.accent.opacity(0.9))
                        .clipShape(Circle())
                }
            }
            .padding(16)
            
            Divider()
                .padding(.horizontal, 16)
            
            // 路线
            HStack(spacing: 16) {
                // 起点终点图标
                VStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                    
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 2, height: 30)
                    
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                }
                
                // 地点信息
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("From")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text(ride.from)
                            .font(.system(size: 15, weight: .medium))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("To")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text(ride.to)
                            .font(.system(size: 15, weight: .medium))
                    }
                }
                
                Spacer()
                
                // 价格和座位
                VStack(alignment: .trailing, spacing: 8) {
                    Text("$\(Int(ride.price))")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppColors.categoryColor(for: "carpool"))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 11))
                        Text("\(ride.seats) seats")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            
            Divider()
                .padding(.horizontal, 16)
            
            // 底部：司机信息
                HStack(spacing: 10) {
                    NavigationLink {
                        UserPostsView(userId: ride.driverId)
                    } label: {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Text(String(ride.driverName.prefix(1)))
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(ride.driverName)
                                    .font(.system(size: 14, weight: .medium))

                                if !ride.carModel.isEmpty {
                                    Text(ride.carModel)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        Task { await onLikeTap?() }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: ride.isLiked ? "heart.fill" : "heart")
                                .foregroundStyle(ride.isLiked ? .red : .secondary)
                            Text("\(ride.likeCount)")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: { onOpenTap?() }) {
                        Text(L10n.tr("View", "查看"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(AppColors.accent.opacity(0.85))
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    Button(action: { onContactTap?() }) {
                        Text("Contact")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(AppColors.accent)
                            .cornerRadius(10)
                    }
                }
            .padding(16)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
        .postHighlightStyle(ride.highlightType, cornerRadius: 20)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture { onOpenTap?() }
        .sheet(isPresented: $showingReportSheet) {
            ReportPostSheet(postId: ride.id, postKind: .ride)
        }
    }
}

#Preview {
    NavigationStack {
        RideListView()
    }
}

struct RideDetailView: View {
    let ride: RideItem

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    @StateObject private var postEditor = UserPostsService()
    @ObservedObject private var service = RideService.shared

    @State private var isLiked: Bool
    @State private var likeCount: Int
    @State private var isLiking = false
    @State private var showContactAlert = false
    @State private var showDeleteConfirm = false
    @State private var showReportSheet = false
    @State private var editingPost: UserPostSummary?

    init(ride: RideItem) {
        self.ride = ride
        _isLiked = State(initialValue: ride.isLiked)
        _likeCount = State(initialValue: ride.likeCount)
    }

    private var isOwnPost: Bool {
        authService.currentUser?.id == ride.driverId
    }

    var body: some View {
        ZStack {
            AppColors.pageBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    routeSection
                    detailSection
                    driverSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            PostDetailTopBar(title: L10n.tr("Ride Post", "拼車貼文"), onBack: { dismiss() }) {
                ShareLink(item: "\(ride.from) → \(ride.to)") {
                    PostToolbarIconCircle(icon: "square.and.arrow.up")
                }

                Menu {
                    if isOwnPost {
                        Button {
                            editingPost = UserPostSummary(
                                id: ride.id,
                                kind: .ride,
                                title: "\(ride.from) → \(ride.to)",
                                description: ride.carModel,
                                subtitle: "\(ride.from) → \(ride.to)",
                                price: ride.price,
                                createdAt: Date(),
                                authorId: ride.driverId,
                                authorName: ride.driverName,
                                authorAvatarURL: ride.driverAvatar
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
                            showReportSheet = true
                        } label: {
                            Label(L10n.tr("Report", "檢舉"), systemImage: "flag.fill")
                        }
                    }
                } label: {
                    PostToolbarIconCircle(icon: "ellipsis")
                }
            }
        }
        .sheet(item: $editingPost) { post in
            EditPostSheet(post: post) { payload in
                try await postEditor.update(payload: payload)
            }
        }
        .sheet(isPresented: $showReportSheet) {
            ReportPostSheet(postId: ride.id, postKind: .ride)
        }
        .alert(L10n.tr("Delete this post?", "確定刪除這篇貼文？"), isPresented: $showDeleteConfirm) {
            Button(L10n.tr("Cancel", "取消"), role: .cancel) {}
            Button(L10n.tr("Delete", "刪除"), role: .destructive) {
                Task { await deletePost() }
            }
        } message: {
            Text(L10n.tr("This action cannot be undone.", "刪除後無法復原。"))
        }
        .alert(L10n.tr("Contact", "聯絡"), isPresented: $showContactAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(L10n.tr("Ride chat is not implemented yet.", "拼車聊天功能尚未實作。"))
        }
    }

    private var routeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(ride.type.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.categoryColor(for: "carpool"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppColors.categoryColor(for: "carpool").opacity(0.15))
                    .clipShape(Capsule())

                Spacer()

                Text(ride.dateText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.textMuted)
            }

            Text("\(ride.from) → \(ride.to)")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            HStack(spacing: 14) {
                Label("$\(Int(ride.price))/seat", systemImage: "dollarsign.circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.categoryColor(for: "carpool"))

                Label("\(ride.seats) seats", systemImage: "person.2")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.textMuted)

                Spacer()
            }
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("Details", "詳細資訊"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            if !ride.carModel.isEmpty {
                Label(ride.carModel, systemImage: "car.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.textMuted)
            }

            HStack(spacing: 14) {
                Button {
                    Task { await toggleLike() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(isLiked ? .red : AppColors.textMuted)
                        Text("\(likeCount)")
                            .foregroundStyle(AppColors.textMuted)
                    }
                    .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.plain)
                .disabled(isLiking)

                Spacer()

                Button {
                    showContactAlert = true
                } label: {
                    Text(L10n.tr("Contact Driver", "聯絡車主"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(AppColors.accent)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private var driverSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.tr("Posted By", "發佈者"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            NavigationLink {
                UserPostsView(userId: ride.driverId)
            } label: {
                HStack(spacing: 10) {
                    Circle()
                        .fill(AppColors.accent.opacity(0.9))
                        .frame(width: 38, height: 38)
                        .overlay {
                            Text(String(ride.driverName.prefix(1)).uppercased())
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(ride.driverName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)

                        Text(L10n.tr("Tap to view profile", "點擊查看個人頁"))
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.textMuted)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.textMuted)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private func toggleLike() async {
        guard !isLiking else { return }
        isLiking = true
        defer { isLiking = false }

        do {
            let newLiked = try await service.toggleLike(postId: ride.id, currentlyLiked: isLiked)
            isLiked = newLiked
            likeCount = max(likeCount + (newLiked ? 1 : -1), 0)
        } catch {
            print("⚠️ Ride detail like failed: \(error)")
        }
    }

    private func deletePost() async {
        do {
            try await postEditor.delete(postId: ride.id)
            dismiss()
        } catch {
            print("❌ Delete ride post failed: \(error)")
        }
    }
}
