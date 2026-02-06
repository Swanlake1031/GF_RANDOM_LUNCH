# Supabase Reset Guide

## Purpose
Reset a broken/messy schema and rebuild from the project migration files.

## 1) Reset `public` schema (destructive)
Run this file once in Supabase SQL Editor:

`/Users/timonayf/Desktop/GF/Supabase/rebuild_public_and_bootstrap.sql`

This drops all current app data in `public`.

## 2) Rebuild schema from migrations
Run files in this exact order:

1. `Supabase/migrations/001_initial_schema.sql`
2. `Supabase/migrations/002_rent_posts.sql`
3. `Supabase/migrations/003_secondhand_posts.sql`
4. `Supabase/migrations/004_ride_posts.sql`
5. `Supabase/migrations/005_team_posts.sql`
6. `Supabase/migrations/006_forum_posts.sql`
7. `Supabase/migrations/007_chat_system.sql`
8. `Supabase/migrations/008_rls_policies.sql`
9. `Supabase/migrations/009_enable_all_rls.sql`

## 3) Optional seed data
Run:

`/Users/timonayf/Desktop/GF/Supabase/seed.sql`

## 4) App-side validation
1. Remove app from iOS Simulator.
2. Build and run from Xcode again.
3. Sign in with a fresh account and test create/read in each module.

## Rules to keep schema clean
- Do not run ad-hoc SQL directly in production.
- Any schema change must be added as a new file under `Supabase/migrations/`.
- Keep `Supabase/migrations/` as the single source of truth.
