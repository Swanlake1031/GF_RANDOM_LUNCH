//
//  ChatService.swift
//  CheeseApp
//
//  🎯 聊天服务
//

import Foundation

@MainActor
class ChatService: ObservableObject {
    static let shared = ChatService()
    
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    
    private init() {}
    
    func fetchConversations() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: 实现真正的 Supabase 查询
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
}
