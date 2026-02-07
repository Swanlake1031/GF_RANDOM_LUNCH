//
//  CheeseAppApp.swift
//  CheeseApp dohvad-rojHab-6nihsa
 
//
//  🎯 App 入口点
//

import SwiftUI

@main
struct CheeseAppApp: App {
    
    /// 认证服务 - 管理用户登录状态
    @StateObject private var authService = AuthService.shared
    @StateObject private var languageStore = AppLanguageStore.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    MainTabView()
                } else {
                    AuthView()
                }
            }
            .id(languageStore.current.rawValue)
            .environmentObject(authService)
            .environmentObject(languageStore)
            .environment(\.locale, Locale(identifier: languageStore.localeIdentifier))
            .preferredColorScheme(.light)
            .task {
                // 只在 App 启动时检查一次会话
                await authService.checkSessionOnce()
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task {
                    await authService.checkSession()
                }
            }
        }
    }
}
