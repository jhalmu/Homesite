---
title: "Development Database"
order: 2
category: "database"
---

# Development Database

## Database Configuration

- **Database**: PostgreSQL
- **Host**: localhost
- **Port**: 5432
- **Database Name**: `homesite_dev`
- **Test Database**: `homesite_test`

## Common Database Commands

### Reset Database
```bash
# Drop, create, migrate, and seed
mix ecto.reset
```

### Migrations
```bash
# Run pending migrations
mix ecto.migrate

# Rollback last migration
mix ecto.rollback

# Rollback specific number of migrations
mix ecto.rollback --step 3

# Generate new migration
mix ecto.gen.migration migration_name
```

### Database Console
```bash
# Connect to development database
psql homesite_dev

# Connect to test database
psql homesite_test
```

## Useful SQL Queries

### Check User Count
```sql
SELECT role, COUNT(*) FROM users GROUP BY role;
```

### View Invitations
```sql
SELECT code, max_uses, current_uses, expires_at
FROM invitations
ORDER BY inserted_at DESC;
```

### Check Post Statistics
```sql
SELECT
  u.email,
  COUNT(p.id) as post_count,
  COUNT(CASE WHEN p.published_at IS NOT NULL THEN 1 END) as published_count
FROM users u
LEFT JOIN posts p ON p.user_id = u.id
GROUP BY u.email;
```

## Sandbox Mode (Tests)

Tests use Ecto Sandbox for database isolation:
- Each test runs in a transaction
- Changes are rolled back after each test
- Test invitation code `TEST-INVITE` is created automatically
- Test admin user is created in DataCase setup
