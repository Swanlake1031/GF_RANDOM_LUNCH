-- ============================================
-- Cheese App 测试数据（与当前 migrations 对齐）
-- ============================================
--
-- 使用说明：
-- 1) 请先执行 001~009 全部迁移。
-- 2) 以下 UUID 对应的用户需要先存在于 auth.users，
--    否则 profiles 外键会失败。

-- ============================================
-- 1) Profiles
-- ============================================

INSERT INTO profiles (
  id, email, full_name, avatar_url, university, student_id, verified, is_anonymous
) VALUES
  (
    '00000000-0000-0000-0000-000000000001',
    'alice@test.com',
    'Alice',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=alice',
    'UCLA',
    NULL,
    TRUE,
    FALSE
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    'bob@test.com',
    'Bob',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=bob',
    'USC',
    NULL,
    FALSE,
    FALSE
  ),
  (
    '00000000-0000-0000-0000-000000000003',
    'carol@test.com',
    'Carol',
    'https://api.dicebear.com/7.x/avataaars/svg?seed=carol',
    'UC Irvine',
    NULL,
    FALSE,
    FALSE
  )
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 2) Rent
-- ============================================

INSERT INTO posts (id, user_id, type, title, description, status, is_anonymous, view_count)
VALUES (
  '10000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000001',
  'rent',
  'Westwood Studio Near Campus',
  'Walk to campus in 8 minutes. Quiet building, great natural light.',
  'active',
  FALSE,
  120
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO rent_posts (
  id, price, location, bedrooms, bathrooms, specs, property_type,
  is_available, available_from, lease_duration,
  utilities_included, pets_allowed, parking_available, laundry_type, amenities
) VALUES (
  '10000000-0000-0000-0000-000000000001',
  1650,
  'Westwood, Los Angeles, CA',
  0,
  1.0,
  'Studio',
  'studio',
  TRUE,
  CURRENT_DATE + INTERVAL '7 days',
  '12 months',
  TRUE,
  FALSE,
  TRUE,
  'in_building',
  '["WiFi", "Gym", "Furnished"]'::jsonb
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO post_images (post_id, url, order_index)
VALUES
  ('10000000-0000-0000-0000-000000000001', 'https://images.unsplash.com/photo-1493666438817-866a91353ca9?w=1200', 0),
  ('10000000-0000-0000-0000-000000000001', 'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=1200', 1)
ON CONFLICT DO NOTHING;

-- ============================================
-- 3) Secondhand
-- ============================================

INSERT INTO posts (id, user_id, type, title, description, status, is_anonymous, view_count)
VALUES (
  '20000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000002',
  'secondhand',
  'MacBook Air M2 16GB',
  'Great condition, battery health 98%, includes charger.',
  'active',
  FALSE,
  64
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO secondhand_posts (
  id, price, original_price, is_negotiable, is_free,
  category, condition, pickup_location, can_ship, shipping_fee, quantity, sold_count
) VALUES (
  '20000000-0000-0000-0000-000000000001',
  850,
  1199,
  TRUE,
  FALSE,
  'electronics',
  'good',
  'USC',
  FALSE,
  NULL,
  1,
  0
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO post_images (post_id, url, order_index)
VALUES
  ('20000000-0000-0000-0000-000000000001', 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=1200', 0)
ON CONFLICT DO NOTHING;

-- ============================================
-- 4) Ride
-- ============================================

INSERT INTO posts (id, user_id, type, title, description, status, is_anonymous, view_count)
VALUES (
  '30000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000003',
  'ride',
  'LA → LAX Airport (Friday Morning)',
  'Have room for 2 with luggage. Pickup near Westwood.',
  'active',
  FALSE,
  45
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO ride_posts (
  id, departure_location, destination_location, departure_time,
  role, total_seats, available_seats, price_per_seat, is_free,
  is_flexible, contact_method, notes
) VALUES (
  '30000000-0000-0000-0000-000000000001',
  'Westwood, Los Angeles',
  'LAX Airport',
  (NOW() + INTERVAL '2 days'),
  'driver',
  2,
  2,
  20,
  FALSE,
  FALSE,
  'app',
  'One carry-on per person.'
)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 5) Team
-- ============================================

INSERT INTO posts (id, user_id, type, title, description, status, is_anonymous, view_count)
VALUES (
  '40000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000001',
  'team',
  'Looking for 2 teammates for Hackathon',
  'Need iOS + backend teammate. Weekend availability preferred.',
  'active',
  FALSE,
  58
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO team_posts (
  id, category, course_name, professor, team_size, current_members, spots_available,
  skills_needed, skills_offered, deadline, commitment_hours,
  is_remote, meeting_location, has_compensation, compensation_details
) VALUES (
  '40000000-0000-0000-0000-000000000001',
  'hackathon',
  NULL,
  NULL,
  4,
  2,
  2,
  '["SwiftUI","Node.js"]'::jsonb,
  '["Product Design"]'::jsonb,
  CURRENT_DATE + INTERVAL '10 days',
  8,
  TRUE,
  NULL,
  FALSE,
  NULL
)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 6) Forum
-- ============================================

INSERT INTO posts (id, user_id, type, title, description, status, is_anonymous, view_count)
VALUES (
  '50000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000002',
  'forum',
  'How to find off-campus housing fast?',
  'Any tips for finding reliable leases near campus before fall quarter?',
  'active',
  FALSE,
  132
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO forum_posts (
  id, category, tags, allow_comments, is_pinned, is_locked, like_count, comment_count
) VALUES (
  '50000000-0000-0000-0000-000000000001',
  'question',
  '["housing","ucla","tips"]'::jsonb,
  TRUE,
  FALSE,
  FALSE,
  4,
  1
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO comments (post_id, user_id, parent_id, content, is_anonymous, like_count, is_deleted)
VALUES (
  '50000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000001',
  NULL,
  'Try joining student housing groups and verify lease terms in writing.',
  FALSE,
  0,
  FALSE
)
ON CONFLICT DO NOTHING;

-- ============================================
-- 7) Chat
-- ============================================

INSERT INTO conversations (
  id, user1_id, user2_id, related_post_id, last_message_at, last_message_preview,
  user1_unread_count, user2_unread_count
) VALUES (
  '60000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000002',
  '10000000-0000-0000-0000-000000000001',
  NOW(),
  'Hi, is this still available?',
  0,
  1
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO messages (conversation_id, sender_id, content, message_type, metadata, is_read, is_deleted)
VALUES (
  '60000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000001',
  'Hi, is this still available?',
  'text',
  '{}'::jsonb,
  FALSE,
  FALSE
)
ON CONFLICT DO NOTHING;
