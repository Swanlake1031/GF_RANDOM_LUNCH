//
//  AuthService.swift
//  CheeseApp
//
//  🔐 用户认证服务
//  使用 Supabase Auth 进行用户登录、注册、登出
//

import Foundation
import SwiftUI
import Supabase

// MARK: - 认证服务
@MainActor
class AuthService: ObservableObject {
    
    // 单例
    static let shared = AuthService()
    
    // Supabase 客户端引用
    private let supabase = SupabaseManager.shared
    
    // MARK: - 发布的状态
    @Published var currentUser: Profile?
    @Published var isLoading = false
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    // 防止重复检查
    private var hasCheckedSession = false
    
    private init() {
        // 不在 init 中自动检查，避免重复请求
    }
    
    // MARK: - 检查当前会话（只检查一次）
    func checkSessionOnce() async {
        // 如果已经检查过，直接返回
        guard !hasCheckedSession else { return }
        hasCheckedSession = true
        
        await checkSession()
    }
    
    // MARK: - 检查当前会话
    func checkSession() async {
        // 如果正在加载，不重复检查
        guard !isLoading else { return }
        
        do {
            let userId = try await requireAuthUserId()
            currentUser = nil
            await fetchUserProfile(userId: userId)
            isAuthenticated = currentUser != nil
        } catch {
            resetAuthState()
        }
    }

    // MARK: - 获取可用会话对应的用户 ID（含 refresh 与服务端校验）
    func requireAuthUserId() async throws -> UUID {
        let session: Session

        // 1) 优先使用当前会话；若失效则尝试 refresh
        do {
            let current = try await supabase.auth.session
            if current.isExpired {
                session = try await supabase.auth.refreshSession()
            } else {
                session = current
            }
        } catch {
            session = try await supabase.auth.refreshSession()
        }

        // 2) 服务端校验，避免本地残留 session
        let serverUser = try await supabase.auth.user()
        guard serverUser.id == session.user.id else {
            throw NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "登录状态无效，请重新登录"])
        }

        return session.user.id
    }

    // MARK: - 统一重置认证状态
    private func resetAuthState() {
        Task {
            try? await supabase.auth.signOut()
        }
        currentUser = nil
        isAuthenticated = false
        hasCheckedSession = false
    }
    
    // MARK: - 获取用户资料
    func fetchUserProfile(userId: UUID) async {
        do {
            let profile: Profile = try await supabase
                .database("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            currentUser = profile
        } catch {
            print("❌ 获取用户资料失败: \(error)")
        }
    }
    
    // MARK: - 邮箱密码登录
    func signIn(email: String, password: String) async throws {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let response = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            isAuthenticated = true
            await fetchUserProfile(userId: response.user.id)
            
            print("✅ 登录成功: \(email)")
        } catch {
            errorMessage = "登录失败: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - 注册
    func signUp(email: String, password: String, username: String) async throws {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            // 1. 创建用户账号（auth.users 插入后，数据库触发器会自动创建 profiles）
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: [
                    "username": .string(username),
                    "university": .string("Unknown")
                ]
            )

            // 2. 尝试更新可选资料字段。
            // 某些配置（如需要邮箱验证）下注册后可能暂时无会话，RLS 会拒绝 UPDATE。
            // 这不应阻断注册主流程，因此这里采用 best-effort。
            let user = response.user
            do {
                try await supabase
                    .database("profiles")
                    .update([
                        "full_name": username
                    ])
                    .eq("id", value: user.id.uuidString)
                    .execute()
            } catch {
                print("⚠️ 注册后更新资料失败（已忽略）: \(error)")
            }

            // 3. 只有存在真实会话才进入已登录态（避免无会话时写入触发 RLS）
            if let session = try? await supabase.auth.session {
                isAuthenticated = true
                await fetchUserProfile(userId: session.user.id)
                print("✅ 注册并登录成功: \(email)")
            } else {
                isAuthenticated = false
                currentUser = nil
                errorMessage = "注册成功，请先完成邮箱验证后登录"
                print("ℹ️ 注册成功但暂无会话，需要验证邮箱: \(email)")
            }
        } catch {
            errorMessage = "注册失败: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - 登出
    func signOut() async throws {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await supabase.auth.signOut()
            currentUser = nil
            isAuthenticated = false
            hasCheckedSession = false // 重置，允许下次检查
            print("✅ 已登出")
        } catch {
            errorMessage = "登出失败: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - 重置密码
    func resetPassword(email: String) async throws {
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            print("✅ 密码重置邮件已发送到: \(email)")
        } catch {
            errorMessage = "发送重置邮件失败"
            throw error
        }
    }
}
