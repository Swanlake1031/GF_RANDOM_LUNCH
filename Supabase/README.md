# Supabase Schema Workflow

This folder is the source of truth for database schema.

## Files
- `migrations/`: ordered schema migrations (`001` to `009`)
- `rebuild_public_and_bootstrap.sql`: destructive reset for `public` schema only
- `seed.sql`: optional test data

## Clean Rebuild
1. Run `rebuild_public_and_bootstrap.sql` in Supabase SQL Editor.
2. Run `migrations/001...009` in order.
3. Optionally run `seed.sql`.

## Team Rule
- Never rely on ad-hoc SQL as the long-term schema state.
- Every schema change must be added as a new migration file.
