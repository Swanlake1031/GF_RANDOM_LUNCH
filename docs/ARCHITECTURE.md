# Cheese App 架构文档

## 📖 前言

本文档面向代码新手，详细解释 Cheese App 的架构设计。
即使你没有太多 iOS 开发经验，也能理解我们为什么这样设计。

---

## 🏗️ 整体架构

### 什么是 MVVM？

**MVVM** = Model-View-ViewModel

这是一种**设计模式**，用于组织代码结构。就像整理房间一样，把不同的东西放在不同的地方。

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│    View     │◀───▶│  ViewModel   │◀───▶│    Model    │
│  (界面展示)  │     │  (业务逻辑)   │     │  (数据结构)  │
└─────────────┘     └──────────────┘     └─────────────┘
```

#### 每层的职责：

**Model（模型层）**
- 📦 定义数据长什么样（结构体）
- 例如：`RentPost` 定义了租房帖子有哪些字段

**View（视图层）**
- 🎨 只负责界面展示
- 用户看到的所有东西
- 不处理复杂逻辑

**ViewModel（视图模型层）**
- 🧠 处理业务逻辑
- 从服务层获取数据
- 处理用户操作
- 告诉 View 显示什么

---

## 📂 项目目录结构

```
CheeseApp/
├── CheeseApp/
│   ├── CheeseAppApp.swift     # App 入口点
│   ├── MainTabView.swift      # 主标签页导航
│   │
│   ├── Core/                  # 核心层（全局通用）
│   │   ├── Config/           # 配置文件
│   │   │   ├── SupabaseClient.swift  # Supabase 连接
│   │   │   └── Tables.swift          # 表名常量
│   │   │
│   │   ├── Models/           # 数据模型
│   │   │   ├── BasePost.swift    # 帖子基类
│   │   │   ├── User.swift        # 用户模型
│   │   │   └── ChatMessage.swift # 聊天模型
│   │   │
│   │   ├── Services/         # 服务层（API调用）
│   │   │   ├── AuthService.swift
│   │   │   ├── ChatService.swift
│   │   │   └── ImageUploadService.swift
│   │   │
│   │   ├── Utils/            # 工具类
│   │   │   ├── Formatters.swift  # 格式化工具
│   │   │   └── Constants.swift   # 常量定义
│   │   │
│   │   └── Extensions/       # 扩展
│   │       ├── Date+Extensions.swift
│   │       └── View+Extensions.swift
│   │
│   ├── Shared/               # 共享组件
│   │   ├── Components/       # 可复用 UI 组件
│   │   │   ├── CustomButton.swift
│   │   │   ├── LoadingView.swift
│   │   │   └── ErrorView.swift
│   │   │
│   │   └── Theme/            # 主题样式
│   │       ├── Colors.swift
│   │       ├── Fonts.swift
│   │       └── Spacing.swift
│   │
│   └── Features/             # 功能模块
│       ├── Rent/             # 租房模块
│       ├── Secondhand/       # 二手交易模块
│       ├── Ride/             # 拼车模块
│       ├── Team/             # 组队模块
│       ├── Forum/            # 论坛模块
│       ├── Chat/             # 聊天模块
│       └── Profile/          # 个人中心模块
```

---

## 🧩 功能模块结构

每个功能模块都遵循相同的结构：

```
Features/Rent/
├── Models/              # 该模块的数据模型
│   ├── RentPost.swift
│   └── RentFilterOptions.swift
│
├── Services/            # 该模块的 API 服务
│   └── RentService.swift
│
├── ViewModels/          # 该模块的业务逻辑
│   ├── RentListViewModel.swift
│   ├── RentDetailViewModel.swift
│   └── CreateRentViewModel.swift
│
├── Views/               # 该模块的界面
│   ├── RentListView.swift
│   ├── RentDetailView.swift
│   ├── CreateRentView.swift
│   └── Components/
│       └── RentCardView.swift
│
└── Utils/               # 该模块的工具
    └── RentFormatter.swift
```

### 为什么这样组织？

1. **模块化**：每个功能独立，修改一个不影响其他
2. **可复用**：公共代码放在 Core 和 Shared
3. **易于理解**：文件名就说明了用途
4. **团队协作**：不同人负责不同模块

---

## 🔄 数据流

### 从用户操作到界面更新

```
用户点击"刷新"按钮
       ↓
View 调用 viewModel.refresh()
       ↓
ViewModel 调用 service.fetchPosts()
       ↓
Service 发送请求到 Supabase
       ↓
Supabase 返回数据
       ↓
Service 解析数据为 Model
       ↓
ViewModel 更新 @Published 属性
       ↓
SwiftUI 检测到变化，自动更新 View
       ↓
用户看到新数据
```

### 代码示例：

```swift
// 1. View 层 - 用户点击按钮
Button("刷新") {
    Task {
        await viewModel.refresh()
    }
}

// 2. ViewModel 层 - 处理业务逻辑
@MainActor
class RentListViewModel: ObservableObject {
    @Published var posts: [RentPost] = []
    
    func refresh() async {
        posts = try await rentService.fetchPosts()
    }
}

// 3. Service 层 - API 调用
class RentService {
    func fetchPosts() async throws -> [RentPost] {
        return try await supabase
            .database("rent_posts_view")
            .select()
            .execute()
            .value
    }
}
```

---

## 🔐 认证流程

```
┌─────────┐    登录请求    ┌──────────┐    验证     ┌──────────┐
│  用户   │───────────────▶│ AuthService│─────────▶│ Supabase │
└─────────┘                └──────────┘           └──────────┘
                                │                      │
                                │◀─────────────────────┘
                                │  返回 Session + User
                                ↓
                         更新 isAuthenticated
                         加载用户 Profile
                                ↓
                         通知其他组件
```

### 认证状态管理

```swift
// AuthService 是单例，全局可访问
AuthService.shared.isAuthenticated  // 是否已登录
AuthService.shared.currentUser      // 当前用户

// 视图中使用
if authService.isAuthenticated {
    MainTabView()
} else {
    AuthView()
}
```

---

## 🔄 实时功能（聊天）

```
┌─────────┐                     ┌──────────────┐
│  用户A  │                     │   Supabase   │
└────┬────┘                     │   Realtime   │
     │                          └──────┬───────┘
     │  发送消息                        │
     │──────────────────────────────────▶
     │                                  │
     │                                  │  广播给订阅者
     │                                  ▼
     │                          ┌──────────────┐
     │◀─────────────────────────│   用户B App  │
     │  收到推送                └──────────────┘
```

### 代码示例：

```swift
// 订阅消息
await chatService.subscribeToMessages(
    conversationId: conversationId
) { message in
    // 收到新消息时的处理
    messages.append(message)
}
```

---

## 🎨 主题系统

### 统一的设计令牌

```swift
// 颜色
AppColors.primary        // 主色调
AppColors.background     // 背景色
AppColors.text           // 文字颜色

// 字体
AppFonts.title          // 标题字体
AppFonts.body           // 正文字体

// 间距
AppSpacing.small        // 8pt
AppSpacing.medium       // 16pt
AppSpacing.large        // 24pt
```

### 支持深色模式

```swift
// 颜色会自动适应深色/浅色模式
static let background = Color("Background") // 在 Assets 中定义
```

---

## 📦 依赖注入

### 什么是依赖注入？

简单说，就是"需要什么就传入什么"，而不是自己创建。

```swift
// ❌ 不好的做法：ViewModel 自己创建 Service
class RentListViewModel {
    let service = RentService() // 紧耦合，难以测试
}

// ✅ 好的做法：Service 从外部传入
class RentListViewModel {
    let service: RentService
    
    init(service: RentService = RentService.shared) {
        self.service = service
    }
}
```

---

## 🧪 可测试性

这种架构让测试变得容易：

```swift
// 创建一个假的 Service 用于测试
class MockRentService: RentService {
    override func fetchPosts() async throws -> [RentPost] {
        return [RentPost.mock] // 返回测试数据
    }
}

// 测试 ViewModel
func testRefresh() async {
    let viewModel = RentListViewModel(service: MockRentService())
    await viewModel.refresh()
    
    XCTAssertEqual(viewModel.posts.count, 1)
}
```

---

## 📝 命名规范

### 文件命名

| 类型 | 格式 | 示例 |
|-----|------|-----|
| 模型 | `{名称}Post.swift` | `RentPost.swift` |
| 视图模型 | `{名称}ViewModel.swift` | `RentListViewModel.swift` |
| 视图 | `{名称}View.swift` | `RentListView.swift` |
| 服务 | `{名称}Service.swift` | `RentService.swift` |
| 组件 | `{名称}View.swift` | `RentCardView.swift` |

### 变量命名

```swift
// 布尔值用 is/has/can 开头
var isLoading: Bool
var hasError: Bool
var canSubmit: Bool

// 数组用复数
var posts: [RentPost]
var images: [UIImage]

// 可选值清晰命名
var errorMessage: String?
var selectedPost: RentPost?
```

---

## ⚡ 性能优化

### 1. 图片懒加载

```swift
// 只在图片进入屏幕时才加载
AsyncImage(url: post.imageURL) { image in
    image.resizable()
} placeholder: {
    ProgressView()
}
```

### 2. 分页加载

```swift
// 列表滚动到底部时加载更多
.onAppear {
    if post == posts.last {
        loadNextPage()
    }
}
```

### 3. @MainActor 保证主线程

```swift
// ViewModel 所有 UI 相关操作都在主线程
@MainActor
class ViewModel: ObservableObject {
    @Published var data: [Item] = []
}
```

---

## 🔒 安全考虑

### 1. Row Level Security (RLS)

数据库层面的权限控制，确保用户只能访问自己的数据。

### 2. 敏感信息不在客户端存储

```swift
// ❌ 不要这样做
let apiSecret = "sk_live_xxx"

// ✅ 敏感信息放在 Supabase Edge Functions
```

### 3. 输入验证

```swift
// 客户端验证 + 服务端验证
guard !title.isEmpty else { return }
guard title.count <= 100 else { return }
```

---

## 🚀 下一步

1. 熟悉每个模块的代码
2. 从简单功能开始修改
3. 遵循现有的命名和结构规范
4. 有问题随时查阅本文档

Happy Coding! 🧀
