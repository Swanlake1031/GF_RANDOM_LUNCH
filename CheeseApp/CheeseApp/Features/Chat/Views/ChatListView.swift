//
//  ChatListView.swift
//  CheeseApp
//
//  💬 聊天列表视图
//  显示所有对话，支持搜索和未读消息
//

import SwiftUI

struct ChatListView: View {
    @State private var searchText = ""
    @State private var conversations: [ConversationItem] = ConversationItem.samples
    
    var body: some View {
        ZStack {
            // 背景色 - 奶酪米色
            Color(red: 0.96, green: 0.94, blue: 0.88)
                .ignoresSafeArea()
            
            if conversations.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 搜索框
                        searchBar
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        
                        // 对话列表
                        LazyVStack(spacing: 0) {
                            ForEach(filteredConversations) { conversation in
                                ChatRow(conversation: conversation)
                            }
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
                        .padding(.horizontal, 16)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
        }
        .navigationTitle("Messages")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 18))
                }
            }
        }
    }
    
    // MARK: - 搜索框
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            
            TextField("Search messages...", text: $searchText)
                .font(.system(size: 15))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 空状态
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.5))
            
            Text("No messages yet")
                .font(.system(size: 20, weight: .semibold))
            
            Text("Start a conversation by messaging\nsomeone about their post")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - 过滤后的对话
    private var filteredConversations: [ConversationItem] {
        if searchText.isEmpty {
            return conversations
        }
        return conversations.filter {
            $0.userName.localizedCaseInsensitiveContains(searchText) ||
            $0.lastMessage.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - 对话数据模型
struct ConversationItem: Identifiable {
    let id = UUID()
    let userName: String
    let userAvatar: String?
    let lastMessage: String
    let timestamp: Date
    let unreadCount: Int
    let isOnline: Bool
    let postTitle: String?
    
    // Mock 数据
    static let samples: [ConversationItem] = [
        ConversationItem(
            userName: "Emma Wilson",
            userAvatar: "mock_avatar_1",
            lastMessage: "Is the apartment still available? I'm very interested!",
            timestamp: Date().addingTimeInterval(-300),
            unreadCount: 2,
            isOnline: true,
            postTitle: "Studio Near Campus"
        ),
        ConversationItem(
            userName: "Alex Chen",
            userAvatar: "mock_avatar_2",
            lastMessage: "Great, I'll pick you up at 9am tomorrow",
            timestamp: Date().addingTimeInterval(-3600),
            unreadCount: 0,
            isOnline: true,
            postTitle: "LAX Airport Ride"
        ),
        ConversationItem(
            userName: "Sarah Kim",
            userAvatar: "mock_avatar_3",
            lastMessage: "Thanks for joining our study group! 📚",
            timestamp: Date().addingTimeInterval(-7200),
            unreadCount: 0,
            isOnline: false,
            postTitle: "CS 161 Study Group"
        ),
        ConversationItem(
            userName: "Mike Johnson",
            userAvatar: "mock_avatar_1",
            lastMessage: "Is $150 okay for the MacBook?",
            timestamp: Date().addingTimeInterval(-86400),
            unreadCount: 1,
            isOnline: false,
            postTitle: "MacBook Pro 14\""
        ),
        ConversationItem(
            userName: "Lisa Wang",
            userAvatar: "mock_avatar_2",
            lastMessage: "See you at the meeting!",
            timestamp: Date().addingTimeInterval(-172800),
            unreadCount: 0,
            isOnline: false,
            postTitle: nil
        ),
    ]
}

// MARK: - 聊天行
struct ChatRow: View {
    let conversation: ConversationItem
    
    var body: some View {
        HStack(spacing: 14) {
            // 头像
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 54, height: 54)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.gray)
                    }
                
                // 在线状态
                if conversation.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                        .overlay {
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        }
                }
            }
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.userName)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Spacer()
                    
                    Text(formatTime(conversation.timestamp))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                
                // 关联帖子
                if let postTitle = conversation.postTitle {
                    Text(postTitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                }
                
                // 最后消息
                Text(conversation.lastMessage)
                    .font(.system(size: 14))
                    .foregroundStyle(conversation.unreadCount > 0 ? .primary : .secondary)
                    .lineLimit(1)
            }
            
            // 未读数
            if conversation.unreadCount > 0 {
                Text("\(conversation.unreadCount)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.95, green: 0.85, blue: 0.45))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview
#Preview {
    ChatListView()
}
