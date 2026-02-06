//
//  SupabaseClient.swift
//  CheeseApp
//
//  Supabase 客户端配置入口
//

import Foundation
import Supabase

final class SupabaseManager {

    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        let config = SupabaseConfig.load()
        guard let url = URL(string: config.url) else {
            fatalError("Invalid Supabase URL")
        }
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: config.publishableKey,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }

    var auth: AuthClient {
        return client.auth
    }
    
    func database(_ table: String) -> PostgrestQueryBuilder {
        return client.from(table)
    }
    
    func storage(_ bucket: String) -> StorageFileApi {
        return client.storage.from(bucket)
    }
    
    var realtime: RealtimeClientV2 {
        return client.realtimeV2
    }
}

private struct SupabaseConfig {
    let url: String
    let publishableKey: String

    static func load(environment: [String: String] = ProcessInfo.processInfo.environment) -> SupabaseConfig {
        let defaultURL = "https://zeuivahkowbxmfzsnagt.supabase.co"
        let defaultPublishableKey = "sb_publishable_29EL6LWWqeED8kLtLDk6_A_Ez8OXwf1"

        let envURL = environment["SUPABASE_URL"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let envKey = environment["SUPABASE_PUBLISHABLE_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines)

        return SupabaseConfig(
            url: nonEmpty(envURL) ?? defaultURL,
            publishableKey: nonEmpty(envKey) ?? defaultPublishableKey
        )
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        return value.isEmpty ? nil : value
    }
}
