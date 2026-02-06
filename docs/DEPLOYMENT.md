# Cheese App 部署指南

## 📖 前言

本指南帮助你从零开始部署 Cheese App。
即使你是第一次发布 iOS 应用，也能跟着步骤完成。

---

## 📋 部署清单

### 第一阶段：开发环境

- [ ] 安装 Xcode（最新版本）
- [ ] 注册 Apple Developer 账号
- [ ] 克隆项目代码
- [ ] 配置 Supabase

### 第二阶段：Supabase 配置

- [ ] 创建 Supabase 项目
- [ ] 执行数据库迁移
- [ ] 配置存储桶
- [ ] 设置认证

### 第三阶段：App 配置

- [ ] 配置 Bundle ID
- [ ] 配置签名证书
- [ ] 填写 Supabase 密钥
- [ ] 测试功能

### 第四阶段：App Store 提交

- [ ] 准备 App 截图
- [ ] 填写 App 信息
- [ ] 构建并上传
- [ ] 提交审核

---

## 🔧 第一阶段：开发环境配置

### 1. 安装 Xcode

1. 打开 Mac App Store
2. 搜索 "Xcode"
3. 点击下载（大约 12GB）
4. 安装完成后打开 Xcode
5. 同意许可协议
6. 安装命令行工具

```bash
# 验证安装
xcode-select --version
```

### 2. 注册 Apple Developer 账号

1. 访问 [developer.apple.com](https://developer.apple.com)
2. 点击 "Account"
3. 使用 Apple ID 登录
4. 同意开发者协议
5. **付费订阅**：$99/年（用于发布到 App Store）

### 3. 克隆并打开项目

```bash
# 克隆项目
git clone <项目地址> CheeseApp
cd CheeseApp

# 打开 Xcode 项目
open CheeseApp/CheeseApp.xcodeproj
```

### 4. 解决依赖

Xcode 会自动使用 Swift Package Manager 下载依赖。

如果没有自动下载：
1. 菜单栏：File → Packages → Resolve Package Versions
2. 等待下载完成

---

## ☁️ 第二阶段：Supabase 配置

### 1. 创建 Supabase 项目

1. 访问 [supabase.com](https://supabase.com)
2. 点击 "Start your project"
3. 使用 GitHub 登录
4. 点击 "New Project"
5. 填写项目信息：
   - **Name**: cheese-app
   - **Database Password**: 设置强密码（记下来）
   - **Region**: 选择离用户最近的（如 West US）
6. 点击 "Create new project"
7. 等待约 2 分钟初始化

### 2. 获取 API 密钥

1. 进入项目 Dashboard
2. 点击左侧 "Settings" → "API"
3. 复制以下信息：
   - **Project URL**: 类似 `https://xxx.supabase.co`
   - **publishable key**: 通常以 `sb_publishable_...` 开头

### 3. 执行数据库迁移

1. 在 Supabase Dashboard 点击 "SQL Editor"
2. 如果历史 schema 已经混乱，先运行 `Supabase/rebuild_public_and_bootstrap.sql` 做一次彻底 reset（会清空 `public` 数据）
3. 按顺序执行迁移文件：
 

```
Supabase/migrations/001_initial_schema.sql
Supabase/migrations/002_rent_posts.sql
Supabase/migrations/003_secondhand_posts.sql
Supabase/migrations/004_ride_posts.sql
Supabase/migrations/005_team_posts.sql
Supabase/migrations/006_forum_posts.sql
Supabase/migrations/007_chat_system.sql
Supabase/migrations/008_rls_policies.sql
Supabase/migrations/009_enable_all_rls.sql
```

每个文件：
1. 复制文件内容
2. 粘贴到 SQL Editor
3. 点击 "Run"
4. 确认无错误

### 4. 配置存储桶

1. 点击左侧 "Storage"
2. 创建以下存储桶：

| 存储桶名称 | 类型 | 用途 |
|-----------|------|-----|
| `avatars` | Public | 用户头像 |
| `post-images` | Public | 帖子图片 |
| `chat-images` | Private | 聊天图片 |

创建步骤：
1. 点击 "New bucket"
2. 输入名称
3. 勾选 "Public bucket"（仅对 avatars 和 post-images）
4. 点击 "Create bucket"

### 5. 配置存储桶策略

对于公开存储桶（avatars, post-images），添加访问策略：

1. 点击存储桶名称
2. 点击 "Policies" 标签
3. 添加策略：

**任何人可以查看：**
```sql
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
TO public
USING ( bucket_id = 'avatars' );
```

**登录用户可以上传：**
```sql
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK ( bucket_id = 'avatars' );
```

### 6. 配置认证

1. 点击左侧 "Authentication" → "Providers"
2. 确保 "Email" 已启用
3. 可选：配置第三方登录（Google, Apple 等）

邮件设置：
1. 点击 "Email Templates"
2. 自定义确认邮件模板（可选）

---

## 📱 第三阶段：App 配置

### 1. 配置 Bundle ID

1. 在 Xcode 中选择项目
2. 选择 "CheeseApp" Target
3. 在 "General" 标签：
   - **Bundle Identifier**: `com.yourname.cheeseapp`
   - **Display Name**: `Cheese`
   - **Version**: `1.0.0`
   - **Build**: `1`

### 2. 配置签名

1. 在 "Signing & Capabilities" 标签
2. 勾选 "Automatically manage signing"
3. 选择你的 Team（Apple Developer 账号）
4. Xcode 会自动创建证书和描述文件

### 3. 填写 Supabase 配置

默认值在 `CheeseApp/CheeseApp/Core/Config/SupabaseClient.swift`，  
建议通过 Xcode Scheme 的 Environment Variables 覆盖：

- `SUPABASE_URL=https://你的项目ID.supabase.co`
- `SUPABASE_PUBLISHABLE_KEY=你的 publishable key`

⚠️ **安全提示**：
- `publishable` 公钥可以放在代码中（它是公开的）
- `service_role` 密钥**绝对不能**放在客户端代码中

### 4. 配置 App Icons

1. 准备 1024x1024 的 App 图标
2. 在 Xcode 中：
   - 打开 `Assets.xcassets`
   - 点击 `AppIcon`
   - 拖入图标图片

### 5. 本地测试

1. 选择模拟器（如 iPhone 15）
2. 点击 ▶️ 运行按钮
3. 测试所有功能：
   - [ ] 注册/登录
   - [ ] 浏览帖子
   - [ ] 发布帖子
   - [ ] 上传图片
   - [ ] 聊天功能
   - [ ] 个人中心

---

## 🚀 第四阶段：App Store 提交

### 1. 准备素材

#### App 截图

需要准备以下尺寸的截图：

| 设备 | 尺寸 |
|-----|------|
| iPhone 15 Pro Max | 1290 × 2796 |
| iPhone 8 Plus | 1242 × 2208 |
| iPad Pro 12.9" | 2048 × 2732 |

每个尺寸最少 1 张，最多 10 张。

建议截图：
1. 首页/列表页
2. 详情页
3. 发布页面
4. 聊天页面
5. 个人中心

#### App 图标

- 1024 × 1024 PNG，无透明度

#### App 描述

准备：
- 简短描述（30 字以内）
- 详细描述
- 关键词
- 支持 URL
- 隐私政策 URL

### 2. 创建 App Store Connect 记录

1. 访问 [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. 点击 "My Apps" → "+"
3. 填写 App 信息：
   - **Name**: Cheese
   - **Primary Language**: Chinese, Simplified
   - **Bundle ID**: 选择你在 Xcode 配置的
   - **SKU**: cheese-app（唯一标识）

### 3. 填写 App 信息

在 App Store Connect 中填写：

**App 信息**
- 类别：社交
- 副类别：生活
- 年龄分级：填写问卷

**版本信息**
- 上传截图
- 填写描述
- 填写关键词（用逗号分隔）
- 填写支持 URL
- 填写隐私政策 URL

**App Review 信息**
- 联系方式
- 测试账号（如需登录测试）
- 备注

### 4. 构建并上传

#### 方法一：Xcode 直接上传

1. 在 Xcode 中：
   - Product → Archive
   - 等待构建完成
   - 点击 "Distribute App"
   - 选择 "App Store Connect"
   - 一路下一步
   - 上传

#### 方法二：使用 Transporter

1. 从 App Store 下载 Transporter
2. 在 Xcode 中 Archive
3. 点击 "Distribute App" → "Custom"
4. 选择 "App Store Connect" → "Export"
5. 导出 .ipa 文件
6. 用 Transporter 上传

### 5. 提交审核

1. 在 App Store Connect 中选择刚上传的构建版本
2. 检查所有信息无误
3. 点击 "Submit for Review"
4. 回答导出合规问题（通常选 No）

### 6. 等待审核

- 首次审核：通常 24-48 小时
- 更新审核：通常 24 小时内
- 可能被拒：按照拒绝原因修改后重新提交

---

## 📝 App 审核常见问题

### 1. 登录/注册问题

**问题**：审核员无法登录
**解决**：在 App Review Information 提供测试账号

### 2. 隐私政策

**问题**：缺少或无效的隐私政策链接
**解决**：确保隐私政策 URL 可访问，内容完整

### 3. 用户生成内容

**问题**：没有举报/屏蔽功能
**解决**：添加举报按钮和内容审核机制

### 4. 崩溃

**问题**：审核时 App 崩溃
**解决**：在提交前充分测试，检查 Crashlytics 日志

### 5. 元数据

**问题**：截图与实际 App 不符
**解决**：确保截图来自最新版本

---

## 🔄 更新发布流程

1. 修改 Version 号（如 1.0.0 → 1.1.0）
2. 增加 Build 号
3. 重新 Archive 并上传
4. 在 App Store Connect 创建新版本
5. 选择新构建
6. 填写更新说明
7. 提交审核

---

## 🛠️ 故障排查

### Xcode 签名问题

```bash
# 清理派生数据
rm -rf ~/Library/Developer/Xcode/DerivedData

# 重置签名
在 Xcode 中取消勾选再重新勾选 "Automatically manage signing"
```

### Supabase 连接问题

1. 检查 URL 和 Key 是否正确
2. 检查网络连接
3. 在 Supabase Dashboard 查看日志

### 上传失败

1. 检查网络连接
2. 确保 Apple ID 有效
3. 检查证书是否过期

---

## 📊 发布后监控

### Crashlytics（可选）

1. 集成 Firebase Crashlytics
2. 监控崩溃报告
3. 及时修复问题

### App Analytics

1. 在 App Store Connect 查看：
   - 下载量
   - 活跃用户
   - 留存率
   - 评分和评论

### Supabase 监控

1. Database → Logs 查看数据库日志
2. Edge Functions → Logs 查看函数日志
3. 设置告警

---

## ✅ 发布完成后

- [ ] 在真机上从 App Store 下载测试
- [ ] 验证所有功能正常
- [ ] 监控首日数据
- [ ] 准备好客服响应
- [ ] 收集用户反馈
- [ ] 规划下一版本

---

恭喜你完成了 Cheese App 的发布！🎉🧀
