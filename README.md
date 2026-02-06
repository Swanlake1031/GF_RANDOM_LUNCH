# 🧀 Cheese App

**留学生专属社区 App - Your Student Community Platform**

Cheese 是一款面向海外留学生的综合社区应用，提供租房、二手交易、拼车、组队、论坛等功能。

---

## 📱 功能特性

### 🏠 租房模块
- 发布/浏览房源信息
- 支持整租、分租、找室友
- 筛选：价格、房型、位置、是否允许宠物等
- 收藏感兴趣的房源

### 🛒 二手交易
- 发布/浏览二手商品
- 分类：电子产品、家具、教材、服装等
- 标注成色、是否可议价

### 🚗 拼车模块
- 发布/找拼车
- 支持司机/乘客两种模式
- 出发地、目的地、时间匹配

### 👥 组队模块
- 课程项目组队
- Hackathon 队友招募
- 学习小组

### 💬 论坛/树洞
- 自由讨论
- 匿名发帖
- 经验分享

### 💌 实时聊天
- 一对一私信
- 实时消息推送
- 支持发送图片

---

## 🛠 技术栈

### 前端
| 技术 | 用途 |
|-----|------|
| **Swift 6** | 编程语言 |
| **SwiftUI** | UI 框架 |
| **MVVM** | 架构模式 |
| **Swift Package Manager** | 依赖管理 |

### 后端
| 技术 | 用途 |
|-----|------|
| **Supabase** | 后端即服务 (BaaS) |
| **PostgreSQL** | 关系型数据库 |
| **Row Level Security** | 数据权限控制 |
| **Realtime** | 实时消息推送 |
| **Storage** | 图片文件存储 |

---

## 📂 项目结构

```
CheeseApp/
├── CheeseApp/
│   ├── CheeseAppApp.swift      # App 入口
│   ├── MainTabView.swift       # 主导航
│   │
│   ├── Core/                   # 核心层
│   │   ├── Config/            # Supabase 配置
│   │   ├── Models/            # 数据模型
│   │   ├── Services/          # API 服务
│   │   ├── Utils/             # 工具类
│   │   └── Extensions/        # 扩展
│   │
│   ├── Shared/                 # 共享组件
│   │   ├── Components/        # UI 组件
│   │   └── Theme/             # 主题样式
│   │
│   └── Features/               # 功能模块
│       ├── Rent/              # 租房
│       ├── Secondhand/        # 二手
│       ├── Ride/              # 拼车
│       ├── Team/              # 组队
│       ├── Forum/             # 论坛
│       ├── Chat/              # 聊天
│       └── Profile/           # 个人中心
│
├── Supabase/                   # 数据库
│   ├── migrations/            # SQL 迁移文件
│   └── seed.sql               # 测试数据
│
└── docs/                       # 文档
    ├── ARCHITECTURE.md        # 架构说明
    ├── DATABASE.md            # 数据库设计
    └── DEPLOYMENT.md          # 部署指南
```

---

## 🚀 快速开始

### 前置要求

- macOS 13.0+
- Xcode 15.0+
- Apple Developer 账号（发布需要）
- Supabase 账号

### 1. 克隆项目

```bash
git clone <项目地址>
cd CheeseApp
```

### 2. 配置 Supabase

1. 访问 [supabase.com](https://supabase.com) 创建项目
2. 如果旧库很乱，先执行 `Supabase/rebuild_public_and_bootstrap.sql` 清空 `public` schema
3. 在 SQL Editor 中按顺序执行 `Supabase/migrations/001...009` 所有 SQL 文件
4. 创建存储桶：`avatars`、`post-images`、`chat-images`

### 3. 配置 App

默认配置已在 `CheeseApp/CheeseApp/Core/Config/SupabaseClient.swift`。  
如需切换项目，优先在 Xcode Scheme 的 Environment Variables 设置：

- `SUPABASE_URL=https://你的项目.supabase.co`
- `SUPABASE_PUBLISHABLE_KEY=你的 publishable key`

### 4. 运行项目

1. 打开 `CheeseApp.xcodeproj`
2. 等待 Swift Package Manager 下载依赖
3. 选择模拟器
4. 点击 ▶️ 运行

---

## 📚 文档

| 文档 | 内容 |
|-----|------|
| [架构文档](docs/ARCHITECTURE.md) | 代码架构、设计模式、命名规范 |
| [数据库文档](docs/DATABASE.md) | 表结构、RLS 策略、索引设计 |
| [部署指南](docs/DEPLOYMENT.md) | 从开发到 App Store 的完整流程 |

---

## 🎨 设计规范

### 颜色系统

```swift
AppColors.primary       // 主色调（芝士黄）
AppColors.secondary     // 辅助色
AppColors.background    // 背景色（自动适应深色模式）
AppColors.text          // 文字颜色
AppColors.error         // 错误提示
AppColors.success       // 成功提示
```

### 间距系统

```swift
AppSpacing.xs           // 4pt
AppSpacing.small        // 8pt
AppSpacing.medium       // 16pt
AppSpacing.large        // 24pt
AppSpacing.xl           // 32pt
```

---

## 📱 截图

*（添加 App 截图）*

---

## 🤝 贡献

欢迎贡献代码！请遵循以下规范：

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

### 代码规范

- 遵循 Swift 官方 API Design Guidelines
- 所有新功能需要添加注释
- 每个功能模块遵循 MVVM 架构

---

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

---

## 📞 联系方式

- 反馈邮箱：feedback@cheeseapp.com
- 技术支持：support@cheeseapp.com

---

**Made with 🧀 for international students**
