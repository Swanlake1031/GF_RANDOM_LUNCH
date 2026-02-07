//
//  ProfileView.swift
//  CheeseApp
//
//  👤 个人中心视图
//  展示真实用户信息、我的发布、设置等
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    
    // 用户便捷访问
    private var user: Profile? { authService.currentUser }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.pageBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 用户信息卡片
                        userInfoCard
                        
                        // 我的发布
                        myPostsSection
                        
                        // 更多功能
                        moreSection
                        
                        // 登出按钮
                        logoutButton
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationTitle(L10n.tr("Profile", "個人檔案"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    // MARK: - 用户信息卡片
    private var userInfoCard: some View {
        VStack(spacing: 16) {
            // 头像
            if let avatarUrl = user?.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    avatarPlaceholder
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            } else {
                avatarPlaceholder
            }
            
            // 名字 & 用户名
            VStack(spacing: 4) {
                Text(user?.fullName ?? user?.username ?? L10n.tr("New User", "新用戶"))
                    .font(.system(size: 22, weight: .bold))
                
                if let username = user?.username {
                    Text("@\(username)")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                
                if let school = user?.school, !school.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 12))
                        Text(school)
                            .font(.system(size: 14))
                    }
                    .foregroundStyle(.secondary)
                }
            }
            
            // 验证状态
            if user?.is_verified == true {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text(L10n.tr("Student Verified", "學生已驗證"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(20)
            }
            
            // 简介
            if let bio = user?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            // 编辑按钮
            Button(action: { showingEditProfile = true }) {
                Text(L10n.tr("Edit Profile", "編輯資料"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
    
    // MARK: - 头像占位符
    private var avatarPlaceholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [AppColors.accent, AppColors.accentStrong],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 80, height: 80)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
            }
    }
    
    // MARK: - 我的发布区块
    private var myPostsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("My Posts", "我的貼文"))
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 4)
            
            VStack(spacing: 1) {
                if let userId = user?.id {
                    NavigationLink(destination: UserPostsView(userId: userId)) {
                        ProfileMenuItem(icon: "square.and.pencil", title: L10n.tr("Manage My Posts", "管理我的貼文"), color: AppColors.link)
                    }
                    NavigationLink(destination: UserPostsView(userId: userId, initialKind: .rent)) {
                        ProfileMenuItem(icon: "key.fill", title: L10n.tr("Rental Listings", "租房貼文"), color: AppColors.link)
                    }
                    NavigationLink(destination: UserPostsView(userId: userId, initialKind: .secondhand)) {
                        ProfileMenuItem(icon: "bag.fill", title: L10n.tr("Items for Sale", "二手出售"), color: AppColors.link)
                    }
                    NavigationLink(destination: UserPostsView(userId: userId, initialKind: .ride)) {
                        ProfileMenuItem(icon: "car.fill", title: L10n.tr("Carpool Posts", "拼車貼文"), color: AppColors.link)
                    }
                    NavigationLink(destination: UserPostsView(userId: userId, initialKind: .team)) {
                        ProfileMenuItem(icon: "person.2.fill", title: L10n.tr("Group Posts", "群組貼文"), color: AppColors.link)
                    }
                    NavigationLink(destination: UserPostsView(userId: userId, initialKind: .forum)) {
                        ProfileMenuItem(icon: "bubble.left.fill", title: L10n.tr("Forum Posts", "論壇貼文"), color: AppColors.link)
                    }
                }
            }
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        }
    }
    
    // MARK: - 更多功能区块
    private var moreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("More", "更多功能"))
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 4)
            
            VStack(spacing: 1) {
                ProfileMenuItem(icon: "heart.fill", title: L10n.tr("Favorites", "收藏"), color: AppColors.link, showArrow: true)
                ProfileMenuItem(icon: "clock.fill", title: L10n.tr("History", "瀏覽紀錄"), color: AppColors.link, showArrow: true)
                ProfileMenuItem(icon: "bell.fill", title: L10n.tr("Notifications", "通知"), color: AppColors.link, showArrow: true)
                NavigationLink(destination: SupportCenterView()) {
                    ProfileMenuItem(icon: "questionmark.circle.fill", title: L10n.tr("Help & Support", "幫助與支援"), color: AppColors.link, showArrow: true)
                }
            }
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        }
    }
    
    // MARK: - 登出按钮
    private var logoutButton: some View {
        Button(action: {
            Task {
                try? await authService.signOut()
            }
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text(L10n.tr("Sign Out", "登出"))
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        }
    }
}

// MARK: - 个人中心菜单项
struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let color: Color
    var showArrow: Bool = true
    
    var body: some View {
        HStack(spacing: 14) {
            // 图标
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 34, height: 34)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color)
            }
            
            // 标题
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppColors.textPrimary)
            
            Spacer()
            
            if showArrow {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(.systemGray3))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.cardBackground)
    }
}

// MARK: - 编辑资料视图
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    
    @State private var fullName: String = ""
    @State private var username: String = ""
    @State private var school: String = ""
    @State private var major: String = ""
    @State private var bio: String = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.pageBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 头像编辑
                        VStack(spacing: 12) {
                            Circle()
                                .fill(AppColors.accent)
                                .frame(width: 100, height: 100)
                                .overlay {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.white)
                                }
                            
                            Button(L10n.tr("Change Photo", "更換照片")) {
                                // TODO: 添加头像选择
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppColors.accentStrong)
                        }
                        .padding(.top, 20)
                        
                        // 表单
                        VStack(spacing: 16) {
                            formField(title: L10n.tr("Full Name", "姓名"), text: $fullName, placeholder: L10n.tr("Your full name", "你的全名"))
                            formField(title: L10n.tr("Username", "用戶名"), text: $username, placeholder: L10n.tr("username", "用戶名"))
                            formField(title: L10n.tr("School", "學校"), text: $school, placeholder: "UC Berkeley")
                            formField(title: L10n.tr("Major", "科系"), text: $major, placeholder: L10n.tr("Computer Science", "計算機科學"))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(L10n.tr("Bio", "個人簡介"))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                                
                                TextEditor(text: $bio)
                                    .frame(minHeight: 100)
                                    .padding(12)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(L10n.tr("Edit Profile", "編輯資料"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.tr("Cancel", "取消")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.tr("Save", "儲存")) {
                        Task { await saveProfile() }
                    }
                    .fontWeight(.semibold)
                    .disabled(isSaving)
                }
            }
            .onAppear {
                if let user = authService.currentUser {
                    fullName = user.fullName ?? ""
                    username = user.username ?? ""
                    school = user.school ?? ""
                    major = user.major ?? ""
                    bio = user.bio ?? ""
                }
            }
        }
    }
    
    private func formField(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: text)
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func saveProfile() async {
        isSaving = true
        defer { isSaving = false }
        
        guard let userId = authService.currentUser?.id else { return }
        
        do {
            try await SupabaseManager.shared
                .database("profiles")
                .update([
                    "full_name": fullName,
                    "university": school
                ])
                .eq("id", value: userId.uuidString)
                .execute()
            
            // 刷新用户资料
            await authService.fetchUserProfile(userId: userId)
            dismiss()
        } catch {
            print("❌ 保存资料失败: \(error)")
        }
    }
}

// MARK: - 设置页
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject private var languageStore: AppLanguageStore

    @AppStorage("settings_push_notifications") private var pushNotifications = true
    @AppStorage("settings_email_notifications") private var emailNotifications = false
    @AppStorage("settings_show_verified_badge") private var showVerifiedBadge = true
    @AppStorage("settings_auto_play_media") private var autoPlayMedia = true
    @AppStorage("settings_haptic_feedback") private var hapticFeedback = true

    @State private var defaultAnonymousPosting = false
    @State private var isSavingAnonymousPreference = false
    @State private var settingsError: String?
    @State private var showSignOutConfirm = false
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.pageBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        settingsHeader(title: L10n.tr("Account", "帳號"))
                        settingsCard {
                            Button(action: { showEditProfile = true }) {
                                settingsRow(
                                    icon: "person.crop.circle",
                                    title: L10n.tr("Edit Profile", "編輯個人資料"),
                                    subtitle: L10n.tr("Update your name, school and bio", "更新你的姓名、學校與簡介")
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        settingsHeader(title: L10n.tr("Notifications", "通知"))
                        settingsCard {
                            Toggle(L10n.tr("Push Notifications", "推播通知"), isOn: $pushNotifications)
                                .tint(AppColors.link)
                            Divider().overlay(AppColors.divider)
                            Toggle(L10n.tr("Email Notifications", "電子郵件通知"), isOn: $emailNotifications)
                                .tint(AppColors.link)
                        }

                        settingsHeader(title: L10n.tr("App Preferences", "應用偏好"))
                        settingsCard {
                            Toggle(L10n.tr("Show Verified Badge", "顯示驗證徽章"), isOn: $showVerifiedBadge)
                                .tint(AppColors.link)
                            Divider().overlay(AppColors.divider)
                            Toggle(L10n.tr("Auto Play Media", "自動播放媒體"), isOn: $autoPlayMedia)
                                .tint(AppColors.link)
                            Divider().overlay(AppColors.divider)
                            Toggle(L10n.tr("Haptic Feedback", "觸感回饋"), isOn: $hapticFeedback)
                                .tint(AppColors.link)
                        }

                        settingsHeader(title: L10n.tr("Privacy", "隱私"))
                        settingsCard {
                            Toggle(L10n.tr("Default Anonymous Posting", "預設匿名發文"), isOn: $defaultAnonymousPosting)
                                .tint(AppColors.link)
                                .disabled(isSavingAnonymousPreference)
                                .onChange(of: defaultAnonymousPosting) { _, newValue in
                                    Task { await updateAnonymousPosting(enabled: newValue) }
                                }

                            Divider().overlay(AppColors.divider)

                            Label(L10n.tr("Theme: Cheese Classic", "主題：Cheese Classic"), systemImage: "paintpalette")
                                .foregroundStyle(AppColors.textMuted)

                            Divider().overlay(AppColors.divider)

                            HStack {
                                Label(L10n.tr("Language", "語言"), systemImage: "character.book.closed")
                                    .foregroundStyle(AppColors.textMuted)
                                Spacer()
                                Picker("Language", selection: Binding(
                                    get: { languageStore.current },
                                    set: { languageStore.setLanguage($0) }
                                )) {
                                    ForEach(AppLanguage.allCases) { language in
                                        Text(language.displayName).tag(language)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.segmented)
                                .frame(width: 180)
                            }
                        }

                        settingsHeader(title: L10n.tr("Data & Storage", "資料與儲存"))
                        settingsCard {
                            Button(action: clearCache) {
                                settingsRow(
                                    icon: "trash",
                                    title: L10n.tr("Clear Image Cache", "清除圖片快取"),
                                    subtitle: L10n.tr("Free up local storage", "釋放本地儲存空間")
                                )
                            }
                            .buttonStyle(.plain)

                            Divider().overlay(AppColors.divider)

                            NavigationLink(destination: SupportCenterView()) {
                                settingsRow(
                                    icon: "questionmark.circle",
                                    title: L10n.tr("Help & Support", "幫助與支援"),
                                    subtitle: L10n.tr("Report issues and feedback", "問題回報與功能建議")
                                )
                            }
                            .buttonStyle(.plain)

                            Divider().overlay(AppColors.divider)

                            Button(action: { showSignOutConfirm = true }) {
                                settingsRow(
                                    icon: "rectangle.portrait.and.arrow.right",
                                    title: L10n.tr("Sign Out", "登出"),
                                    subtitle: L10n.tr("Sign out on this device", "登出目前裝置"),
                                    tint: .red,
                                    showChevron: false
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        settingsHeader(title: L10n.tr("About", "關於"))
                        settingsCard {
                            settingsRow(
                                icon: "app.badge",
                                title: L10n.tr("Version", "版本"),
                                subtitle: appVersionText,
                                showChevron: false
                            )
                        }

                        if let settingsError {
                            Text(settingsError)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle(L10n.tr("Settings", "設定"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.tr("Done", "完成")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert(L10n.tr("Sign out?", "確定登出？"), isPresented: $showSignOutConfirm) {
                Button(L10n.tr("Cancel", "取消"), role: .cancel) {}
                Button(L10n.tr("Sign Out", "登出"), role: .destructive) {
                    Task {
                        do {
                            try await authService.signOut()
                            dismiss()
                        } catch {
                            settingsError = error.localizedDescription
                        }
                    }
                }
            } message: {
                Text(L10n.tr("You can sign back in anytime.", "你可以隨時重新登入。"))
            }
            .onAppear {
                defaultAnonymousPosting = authService.currentUser?.isAnonymousDefault ?? false
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
        }
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private func settingsHeader(title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(AppColors.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }

    private func settingsRow(
        icon: String,
        title: String,
        subtitle: String,
        tint: Color = AppColors.link,
        showChevron: Bool = true
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textMuted)
            }

            Spacer()

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.textMuted)
            }
        }
        .padding(.vertical, 8)
    }

    private var appVersionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }

    private func clearCache() {
        URLCache.shared.removeAllCachedResponses()
    }

    private func updateAnonymousPosting(enabled: Bool) async {
        guard let userId = authService.currentUser?.id else { return }
        isSavingAnonymousPreference = true
        defer { isSavingAnonymousPreference = false }

        do {
            try await SupabaseManager.shared
                .database("profiles")
                .update(["is_anonymous": enabled])
                .eq("id", value: userId.uuidString)
                .execute()

            await authService.fetchUserProfile(userId: userId)
            settingsError = nil
        } catch {
            settingsError = error.localizedDescription
            defaultAnonymousPosting = authService.currentUser?.isAnonymousDefault ?? false
        }
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
        .environmentObject(AuthService.shared)
}
