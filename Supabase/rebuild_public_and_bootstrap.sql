-- ============================================================================
-- PUBLIC SCHEMA RESET (DESTRUCTIVE)
--
-- Use this in a new/throwaway environment when schema is messy and you want a
-- clean rebuild from migration files.
-- ============================================================================

BEGIN;

-- 1) Drop and recreate public schema
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;

-- 2) Restore standard Supabase/public grants
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT CREATE ON SCHEMA public TO postgres, service_role;

-- Keep default object privileges predictable for API roles
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT EXECUTE ON FUNCTIONS TO anon, authenticated, service_role;

-- 3) Ensure extension required by migrations exists
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

COMMIT;

-- ============================================================================
-- NEXT STEP (manual)
-- Run migration files in order:
--   Supabase/migrations/001_initial_schema.sql
--   Supabase/migrations/002_rent_posts.sql
--   Supabase/migrations/003_secondhand_posts.sql
--   Supabase/migrations/004_ride_posts.sql
--   Supabase/migrations/005_team_posts.sql
--   Supabase/migrations/006_forum_posts.sql
--   Supabase/migrations/007_chat_system.sql
--   Supabase/migrations/008_rls_policies.sql
--   Supabase/migrations/009_enable_all_rls.sql
--
-- Optional: run Supabase/seed.sql for test data.
-- ============================================================================
