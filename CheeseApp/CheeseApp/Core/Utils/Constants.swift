//
//  Constants.swift
//  CheeseApp
//
//  🎯 应用常量
//

import Foundation
import SwiftUI

// ============================================
// App 常量
// ============================================

enum AppConstants {
    static let appName = "Cheese"
    static let defaultPageSize = 20
    static let maxTitleLength = 100
    static let maxDescriptionLength = 2000
    static let maxImagesPerPost = 9
}

// ============================================
// 表名常量
// ============================================

enum Tables {
    static let profiles = "profiles"
    static let posts = "posts"
    static let postImages = "post_images"
    static let favorites = "favorites"
    static let rentPosts = "rent_posts"
    static let secondhandPosts = "secondhand_posts"
    static let ridePosts = "ride_posts"
    static let teamPosts = "team_posts"
    static let forumPosts = "forum_posts"
    static let comments = "comments"
    static let conversations = "conversations"
    static let messages = "messages"
    static let rentPostsView = "rent_posts_view"
}

// ============================================
// 存储桶常量
// ============================================

enum StorageBuckets {
    static let avatars = "avatars"
    static let postImages = "post-images"
}

// ============================================
// 语言设置
// ============================================

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case chinese = "zh-Hans"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        }
    }
}

final class AppLanguageStore: ObservableObject {
    static let shared = AppLanguageStore()

    @Published private(set) var current: AppLanguage

    private let key = "app_language"

    private init() {
        let saved = UserDefaults.standard.string(forKey: key)
        current = AppLanguage(rawValue: saved ?? "") ?? .english
    }

    func setLanguage(_ language: AppLanguage) {
        guard current != language else { return }
        current = language
        UserDefaults.standard.set(language.rawValue, forKey: key)
    }

    var localeIdentifier: String {
        switch current {
        case .english:
            return "en"
        case .chinese:
            return "zh-Hans"
        }
    }
}

enum L10n {
    static func tr(_ english: String, _ chinese: String) -> String {
        AppLanguageStore.shared.current == .chinese ? chinese : english
    }
}
