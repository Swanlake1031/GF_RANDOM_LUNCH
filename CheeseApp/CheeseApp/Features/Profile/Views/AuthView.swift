//
//  AuthView.swift
//  CheeseApp
//
//  🔐 登录/注册视图
//  用户认证入口，支持邮箱登录和注册
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject private var languageStore: AppLanguageStore
    
    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var isLoading = false
    @State private var showPassword = false
    
    var body: some View {
        ZStack {
            // 背景色 - 奶酪米色
            AppColors.pageBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer(minLength: 16)

                    languageSwitcher
                    
                    // Logo 区域
                    logoSection
                    
                    // 表单区域
                    formSection
                    
                    // 主按钮
                    primaryButton
                    
                    // 分割线
                    divider
                    
                    // 社交登录
                    socialLogin
                    
                    // 切换登录/注册
                    switchModeButton
                    
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarHidden(true)
    }

    private var languageSwitcher: some View {
        HStack {
            Spacer()
            Picker("Language", selection: Binding(
                get: { languageStore.current },
                set: { languageStore.setLanguage($0) }
            )) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 170)
        }
    }
    
    // MARK: - Logo 区域
    private var logoSection: some View {
        VStack(spacing: 16) {
            // Logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.85, blue: 0.45),
                                Color(red: 0.95, green: 0.75, blue: 0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color(red: 0.95, green: 0.85, blue: 0.45).opacity(0.4), radius: 20, x: 0, y: 10)
                
                Text("🧀")
                    .font(.system(size: 48))
            }
            
            // 标题
            VStack(spacing: 6) {
                Text("Cheese")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                
                Text(L10n.tr("Student Community", "學生社群"))
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.textMuted)
            }
        }
    }
    
    // MARK: - 表单区域
    private var formSection: some View {
        VStack(spacing: 16) {
            // 用户名（仅注册时显示）
            if !isLogin {
                CustomTextField(
                    icon: "person.fill",
                    placeholder: L10n.tr("Username", "用戶名"),
                    text: $username
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // 邮箱
            CustomTextField(
                icon: "envelope.fill",
                placeholder: L10n.tr("Email", "電子郵件"),
                text: $email,
                keyboardType: .emailAddress
            )
            
            // 密码
            CustomTextField(
                icon: "lock.fill",
                placeholder: L10n.tr("Password", "密碼"),
                text: $password,
                isSecure: !showPassword,
                trailingIcon: showPassword ? "eye.slash.fill" : "eye.fill",
                trailingAction: { showPassword.toggle() }
            )
            
            // 忘记密码（仅登录时显示）
            if isLogin {
                HStack {
                    Spacer()
                    Button(action: { }) {
                        Text(L10n.tr("Forgot Password?", "忘記密碼？"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.link)
                    }
                }
            }
            
            // 错误提示
            if let error = authService.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundStyle(.red)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .animation(.spring(response: 0.3), value: isLogin)
    }
    
    // MARK: - 主按钮
    private var primaryButton: some View {
        Button(action: {
            performAuth()
        }) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                } else {
                    Text(isLogin ? L10n.tr("Sign In", "登入") : L10n.tr("Create Account", "建立帳號"))
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color(red: 0.95, green: 0.85, blue: 0.45))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color(red: 0.95, green: 0.85, blue: 0.45).opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .disabled(isLoading || !isFormValid)
        .opacity(isFormValid ? 1 : 0.6)
    }
    
    // MARK: - 分割线
    private var divider: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(AppColors.divider)
                .frame(height: 1)
            
            Text(L10n.tr("or continue with", "或使用以下方式"))
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textMuted)
            
            Rectangle()
                .fill(AppColors.divider)
                .frame(height: 1)
        }
    }
    
    // MARK: - 社交登录
    private var socialLogin: some View {
        HStack(spacing: 16) {
            SocialLoginButton(icon: "apple.logo", name: L10n.tr("Apple", "Apple"))
            SocialLoginButton(icon: "g.circle.fill", name: L10n.tr("Google", "Google"))
        }
    }
    
    // MARK: - 切换模式按钮
    private var switchModeButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                isLogin.toggle()
            }
        }) {
            HStack(spacing: 4) {
                Text(isLogin ? L10n.tr("Don't have an account?", "還沒有帳號？") : L10n.tr("Already have an account?", "已經有帳號？"))
                    .foregroundStyle(AppColors.textMuted)
                
                Text(isLogin ? L10n.tr("Sign Up", "註冊") : L10n.tr("Sign In", "登入"))
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.link)
            }
            .font(.system(size: 15))
        }
    }
    
    // MARK: - 辅助方法
    private var isFormValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 6
        let usernameValid = isLogin || username.count >= 2
        return emailValid && passwordValid && usernameValid
    }
    
    private func performAuth() {
        isLoading = true
        Task {
            defer { isLoading = false }
            if isLogin {
                try? await authService.signIn(email: email, password: password)
            } else {
                try? await authService.signUp(email: email, password: password, username: username)
            }
        }
    }
}

// MARK: - 自定义输入框
struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var trailingIcon: String? = nil
    var trailingAction: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(AppColors.textMuted)
                .frame(width: 24)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 16))
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            
            if let trailingIcon = trailingIcon {
                Button(action: { trailingAction?() }) {
                    Image(systemName: trailingIcon)
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.textMuted)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - 社交登录按钮
struct SocialLoginButton: View {
    let icon: String
    let name: String
    
    var body: some View {
        Button(action: { }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                
                Text(name)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        }
    }
}

// MARK: - Preview
#Preview {
    AuthView()
        .environmentObject(AuthService.shared)
}
