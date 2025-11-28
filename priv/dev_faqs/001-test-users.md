---
title: "Test Users and Accounts"
order: 1
category: "authentication"
---

# Test Users and Accounts

## Available Test Users

### Regular User
- **Email**: `test-user@example.com`
- **Password**: `hello world!`
- **Role**: user
- **Status**: Confirmed

### Admin User
- **Email**: `test-admin@example.com`
- **Password**: `test-password-123`
- **Role**: admin
- **Admin Flowers**: 5

## Test Invitation Code

For testing user registration:
- **Code**: `TEST-INVITE`
- **Max Uses**: Unlimited
- **Expires**: Never
- **Default Role**: user

## Creating Test Users

```elixir
# In iex -S mix
alias Homesite.Accounts

# Create a regular user
{:ok, user} = Accounts.register_user(%{
  email: "new-user@example.com",
  password: "hello world!",
  invitation_code: "TEST-INVITE"
})

# Create an admin user
{:ok, admin} = Accounts.register_admin(%{
  email: "new-admin@example.com",
  password: "admin-password",
  role: "admin",
  admin_flowers: 3
})
```

## Resetting Test Data

```bash
# Reset database with fresh test data
mix ecto.reset

# Seed admin user
mix seed.admin

# Seed test users
mix seed.users
```
