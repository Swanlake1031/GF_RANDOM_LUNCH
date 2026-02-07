# Cheese App 数据库设计文档

## 📖 前言

本文档详细介绍 Cheese App 的数据库设计。
使用 Supabase（PostgreSQL）作为后端数据库。

---

## 🏗️ 数据库架构概览

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Cheese App 数据库                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │  profiles   │    │    posts    │    │ conversations│   │  messages   │  │
│  │  (用户资料)  │    │  (帖子通用)  │    │  (聊天会话)  │    │  (聊天消息)  │  │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘    └──────┬──────┘  │
│         │                  │                  │                  │         │
│         │                  ▼                  └──────────────────┘         │
│         │    ┌─────────────────────────────────┐                          │
│         │    │         帖子扩展表                │                          │
│         │    ├──────────┬──────────┬───────────┤                          │
│         │    │rent_posts│secondhand│ride_posts │                          │
│         │    │ (租房)   │ _posts   │  (拼车)   │                          │
│         │    │          │ (二手)   │           │                          │
│         │    ├──────────┼──────────┼───────────┤                          │
│         │    │team_posts│forum     │ comments  │                          │
│         │    │ (组队)   │ _posts   │  (评论)   │                          │
│         │    │          │ (论坛)   │           │                          │
│         │    └──────────┴──────────┴───────────┘                          │
│         │                  │                                               │
│         │                  ▼                                               │
│         │    ┌─────────────────────────────────┐                          │
│         │    │        post_images (图片)        │                          │
│         │    │        favorites (收藏)          │                          │
│         │    └─────────────────────────────────┘                          │
│         │                                                                  │
└─────────┴──────────────────────────────────────────────────────────────────┘
```

---

## 📊 核心表结构

### 1. profiles（用户资料）

存储用户的公开信息。

```sql
CREATE TABLE profiles (
    id           UUID PRIMARY KEY,        -- 与 auth.users.id 相同
    email        TEXT NOT NULL,           -- 邮箱（来自认证）
    full_name    TEXT,                    -- 显示名称
    avatar_url   TEXT,                    -- 头像链接
    school       TEXT,                    -- 学校
    major        TEXT,                    -- 专业
    grad_year    INTEGER,                 -- 毕业年份
    bio          TEXT,                    -- 个人简介
    wechat_id    TEXT,                    -- 微信号
    created_at   TIMESTAMPTZ,             -- 创建时间
    updated_at   TIMESTAMPTZ              -- 更新时间
);
```

#### 字段说明：

| 字段 | 类型 | 说明 |
|-----|------|-----|
| `id` | UUID | 用户唯一标识，与 Supabase Auth 用户 ID 相同 |
| `email` | TEXT | 用户邮箱 |
| `full_name` | TEXT | 用户昵称/真实姓名 |
| `avatar_url` | TEXT | 头像图片 URL |
| `school` | TEXT | 就读/毕业学校 |
| `major` | TEXT | 专业 |
| `grad_year` | INTEGER | 毕业年份，如 2025 |
| `bio` | TEXT | 个人简介 |
| `wechat_id` | TEXT | 微信号，用于私下联系 |

---

### 2. posts（帖子通用表）

所有类型帖子的公共字段。

```sql
CREATE TABLE posts (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID REFERENCES profiles(id),    -- 发布者
    post_type    TEXT NOT NULL,                   -- 帖子类型
    title        TEXT NOT NULL,                   -- 标题
    description  TEXT,                            -- 详细描述
    location     TEXT,                            -- 地点
    status       TEXT DEFAULT 'active',           -- 状态
    view_count   INTEGER DEFAULT 0,               -- 浏览次数
    is_anonymous BOOLEAN DEFAULT FALSE,           -- 是否匿名
    created_at   TIMESTAMPTZ DEFAULT now(),
    updated_at   TIMESTAMPTZ DEFAULT now()
);
```

#### 帖子类型（post_type）：

| 值 | 说明 |
|----|-----|
| `rent` | 租房 |
| `secondhand` | 二手交易 |
| `ride` | 拼车 |
| `team` | 组队 |
| `forum` | 论坛/树洞 |

#### 帖子状态（status）：

| 值 | 说明 |
|----|-----|
| `active` | 正常显示 |
| `closed` | 已完成/已关闭 |
| `deleted` | 已删除（软删除） |

---

### 3. rent_posts（租房扩展表）

租房帖子的特有字段。

```sql
CREATE TABLE rent_posts (
    post_id            UUID PRIMARY KEY REFERENCES posts(id),
    price              DECIMAL(10,2) NOT NULL,    -- 月租价格
    bedrooms           INTEGER,                   -- 卧室数量
    bathrooms          DECIMAL(3,1),              -- 卫生间数量（如 1.5）
    specs              TEXT,                      -- 房型规格（如 "2B2B"）
    property_type      TEXT DEFAULT 'apartment',  -- 房屋类型
    sqft               INTEGER,                   -- 面积（平方英尺）
    utilities_included BOOLEAN DEFAULT FALSE,     -- 是否包水电
    pets_allowed       BOOLEAN DEFAULT FALSE,     -- 是否允许宠物
    available_from     DATE,                      -- 起租日期
    lease_end_date     DATE                       -- 租约结束日期
);
```

#### 房屋类型（property_type）：

| 值 | 说明 |
|----|-----|
| `apartment` | 公寓 |
| `house` | 独栋房屋 |
| `condo` | 产权公寓 |
| `studio` | 单身公寓 |
| `room` | 单间出租 |

---

### 4. secondhand_posts（二手交易扩展表）

```sql
CREATE TABLE secondhand_posts (
    post_id      UUID PRIMARY KEY REFERENCES posts(id),
    price        DECIMAL(10,2) NOT NULL,    -- 售价
    category     TEXT NOT NULL,             -- 商品类别
    condition    TEXT DEFAULT 'good',       -- 成色
    is_negotiable BOOLEAN DEFAULT TRUE,     -- 是否可议价
    is_shipped   BOOLEAN DEFAULT FALSE      -- 是否可邮寄
);
```

#### 商品类别（category）：

| 值 | 说明 |
|----|-----|
| `electronics` | 电子产品 |
| `furniture` | 家具 |
| `textbooks` | 教材书籍 |
| `clothing` | 服装 |
| `vehicles` | 代步工具 |
| `other` | 其他 |

#### 成色（condition）：

| 值 | 说明 |
|----|-----|
| `new` | 全新 |
| `like_new` | 几乎全新 |
| `good` | 良好 |
| `fair` | 一般 |
| `poor` | 较差 |

---

### 5. ride_posts（拼车扩展表）

```sql
CREATE TABLE ride_posts (
    post_id         UUID PRIMARY KEY REFERENCES posts(id),
    departure       TEXT NOT NULL,          -- 出发地
    destination     TEXT NOT NULL,          -- 目的地
    departure_time  TIMESTAMPTZ NOT NULL,   -- 出发时间
    seats_available INTEGER DEFAULT 1,      -- 可用座位数
    price_per_seat  DECIMAL(10,2),          -- 每座价格
    is_driver       BOOLEAN DEFAULT TRUE,   -- 是否司机（否则是乘客）
    is_roundtrip    BOOLEAN DEFAULT FALSE,  -- 是否往返
    return_time     TIMESTAMPTZ             -- 返程时间
);
```

---

### 6. team_posts（组队扩展表）

```sql
CREATE TABLE team_posts (
    post_id       UUID PRIMARY KEY REFERENCES posts(id),
    category      TEXT NOT NULL,           -- 组队类型
    team_size     INTEGER DEFAULT 1,       -- 需要人数
    current_count INTEGER DEFAULT 1,       -- 当前人数
    skills_needed TEXT[],                  -- 需要的技能
    deadline      DATE                     -- 截止日期
);
```

#### 组队类型（category）：

| 值 | 说明 |
|----|-----|
| `study` | 学习小组 |
| `project` | 课程项目 |
| `hackathon` | 黑客马拉松 |
| `startup` | 创业 |
| `research` | 研究 |
| `other` | 其他 |

---

### 7. forum_posts（论坛/树洞扩展表）

```sql
CREATE TABLE forum_posts (
    post_id       UUID PRIMARY KEY REFERENCES posts(id),
    category      TEXT DEFAULT 'general',  -- 分类
    is_confession BOOLEAN DEFAULT FALSE    -- 是否是树洞/confession
);
```

---

### 8. comments（评论表）

```sql
CREATE TABLE comments (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id    UUID REFERENCES posts(id) ON DELETE CASCADE,
    user_id    UUID REFERENCES profiles(id),
    parent_id  UUID REFERENCES comments(id),  -- 父评论（用于回复）
    content    TEXT NOT NULL,
    is_anonymous BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now()
);
```

---

### 9. post_images（帖子图片表）

```sql
CREATE TABLE post_images (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id     UUID REFERENCES posts(id) ON DELETE CASCADE,
    url         TEXT NOT NULL,          -- 图片 URL
    order_index INTEGER DEFAULT 0,      -- 排序序号
    created_at  TIMESTAMPTZ DEFAULT now()
);
```

---

### 10. favorites（收藏表）

```sql
CREATE TABLE favorites (
    user_id    UUID REFERENCES profiles(id),
    post_id    UUID REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (user_id, post_id)  -- 复合主键，防止重复收藏
);
```

---

### 11. conversations（会话表）

```sql
CREATE TABLE conversations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user1_id        UUID REFERENCES profiles(id) NOT NULL,
    user2_id        UUID REFERENCES profiles(id) NOT NULL,
    related_post_id UUID REFERENCES posts(id),  -- 关联的帖子
    last_message_at TIMESTAMPTZ DEFAULT now(),
    created_at      TIMESTAMPTZ DEFAULT now(),
    
    -- 确保每对用户只有一个会话
    CONSTRAINT unique_conversation UNIQUE (user1_id, user2_id)
);
```

---

### 12. messages（消息表）

```sql
CREATE TABLE messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id       UUID REFERENCES profiles(id),
    content         TEXT NOT NULL,
    message_type    TEXT DEFAULT 'text',   -- text/image/system
    is_read         BOOLEAN DEFAULT FALSE,
    metadata        JSONB,                 -- 额外数据（如图片URL）
    created_at      TIMESTAMPTZ DEFAULT now()
);
```

---

## 🔐 行级安全（Row Level Security）

### 什么是 RLS？

RLS 是 PostgreSQL 的安全功能，让你定义"谁能访问哪些行"。

### 为什么需要 RLS？

没有 RLS：
```
❌ 用户 A 可以看到用户 B 的私人消息
❌ 用户可以删除别人的帖子
```

有了 RLS：
```
✅ 每个用户只能看到自己有权限看到的数据
✅ 只有帖子作者才能编辑/删除自己的帖子
```

### RLS 策略示例

```sql
-- 帖子表：所有人可以查看 active 帖子
CREATE POLICY "Anyone can view active posts"
ON posts FOR SELECT
USING (status = 'active');

-- 帖子表：只有作者可以更新
CREATE POLICY "Users can update own posts"
ON posts FOR UPDATE
USING (user_id = auth.uid());

-- 帖子表：只有作者可以删除
CREATE POLICY "Users can delete own posts"
ON posts FOR DELETE
USING (user_id = auth.uid());

-- 消息表：只有会话参与者可以查看
CREATE POLICY "Conversation members can view messages"
ON messages FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM conversations c
        WHERE c.id = messages.conversation_id
        AND (c.user1_id = auth.uid() OR c.user2_id = auth.uid())
    )
);
```

---

## 🔍 索引设计

### 什么是索引？

索引就像书的目录，帮助数据库快速找到数据。

### 为什么需要索引？

```
没有索引：查找一个帖子需要扫描所有行 → 慢
有索引：直接跳到目标位置 → 快
```

### 索引使用原则

1. **经常查询的列**需要索引
2. **外键**需要索引
3. **不要过度索引**：索引会占用空间，影响写入速度

### 示例索引

```sql
-- 按帖子类型查询
CREATE INDEX idx_posts_type ON posts(post_type);

-- 按状态筛选
CREATE INDEX idx_posts_status ON posts(status);

-- 按价格范围筛选
CREATE INDEX idx_rent_price ON rent_posts(price);

-- 全文搜索
CREATE INDEX idx_posts_search ON posts USING gin(
    to_tsvector('chinese', title || ' ' || COALESCE(description, ''))
);
```

---

## 🔄 触发器

### 什么是触发器？

触发器是"自动执行的代码"，在特定事件发生时运行。

### 示例：自动更新 updated_at

```sql
-- 创建函数
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器
CREATE TRIGGER posts_updated_at
    BEFORE UPDATE ON posts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
```

### 示例：更新会话最后消息时间

```sql
-- 当发送新消息时，自动更新会话的 last_message_at
CREATE TRIGGER update_conversation_last_message
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_timestamp();
```

---

## 📈 视图（View）

### 什么是视图？

视图是"预先定义好的查询"，可以像表一样使用。

### 为什么用视图？

```sql
-- 不用视图：每次都要写复杂查询
SELECT p.*, r.price, r.bedrooms, ...
FROM posts p
JOIN rent_posts r ON p.id = r.post_id
JOIN profiles pr ON p.user_id = pr.id
LEFT JOIN post_images pi ON p.id = pi.post_id
WHERE ...

-- 用视图：一行搞定
SELECT * FROM rent_posts_view WHERE price < 1000;
```

### 租房帖子视图示例

```sql
CREATE VIEW rent_posts_view AS
SELECT 
    p.id,
    p.title,
    p.description,
    p.location,
    p.status,
    p.view_count,
    p.created_at,
    
    r.price,
    r.bedrooms,
    r.bathrooms,
    r.specs,
    r.property_type,
    r.utilities_included,
    r.pets_allowed,
    
    pr.full_name AS author_name,
    pr.avatar_url AS author_avatar,
    
    (SELECT array_agg(url ORDER BY order_index) 
     FROM post_images WHERE post_id = p.id) AS images
     
FROM posts p
JOIN rent_posts r ON p.id = r.post_id
LEFT JOIN profiles pr ON p.user_id = pr.id
WHERE p.post_type = 'rent' AND p.status = 'active';
```

---

## 🔧 数据库迁移

### 迁移文件说明

| 文件 | 内容 |
|-----|------|
| `001_initial_schema.sql` | 创建核心表 |
| `002_rent_posts.sql` | 租房扩展表 |
| `003_secondhand_posts.sql` | 二手扩展表 |
| `004_ride_posts.sql` | 拼车扩展表 |
| `005_team_posts.sql` | 组队扩展表 |
| `006_forum_posts.sql` | 论坛扩展表 |
| `007_chat_system.sql` | 聊天系统 |
| `008_rls_policies.sql` | 安全策略 |

### 如何执行迁移

1. 打开 Supabase Dashboard
2. 进入 SQL Editor
3. 按顺序执行每个迁移文件
4. 或使用 Supabase CLI：

```bash
supabase db push
```

---

## 📊 性能优化建议

### 1. 使用分页

```sql
-- 不要一次查所有
SELECT * FROM posts LIMIT 20 OFFSET 0;
```

### 2. 只查需要的列

```sql
-- 列表页不需要 description
SELECT id, title, price, location FROM rent_posts_view;
```

### 3. 使用连接池

Supabase 已自动配置 PgBouncer 连接池。

### 4. 定期清理

```sql
-- 清理30天前的已删除帖子
DELETE FROM posts 
WHERE status = 'deleted' 
AND updated_at < NOW() - INTERVAL '30 days';
```

---

## 🧪 测试数据

参见 `Supabase/seed.sql` 文件。

执行后会创建：
- 测试用户
- 各类型的示例帖子
- 示例会话和消息

---

Happy Coding! 🧀
