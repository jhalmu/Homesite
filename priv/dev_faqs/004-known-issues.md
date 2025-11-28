---
title: "Known Issues and Gotchas"
order: 4
category: "troubleshooting"
---

# Known Issues and Gotchas

## Authentication

### Magic Link vs Password Registration

The app supports BOTH magic-link and password-based authentication:

- **Password Registration**: Requires invitation code, sets `hashed_password`
- **Magic Link Login**: Only works for users WITHOUT a password set
- **Test Fixtures**: Use `unconfirmed_user_fixture_no_password()` for magic-link tests

**Gotcha**: Trying to use magic-link login with a password-enabled user will raise:
```
RuntimeError: magic link log in is not allowed for unconfirmed users with a password set!
```

### Invitation System

- All user registrations require a valid invitation code
- Admin registrations bypass invitation requirement
- Test invitation `TEST-INVITE` is auto-created in test environment
- Invitations track usage count and can have expiration dates

## Database

### Timestamp Precision

Database uses `:utc_datetime` (no microseconds). Always use:
```elixir
DateTime.utc_now(:second)  # Correct
DateTime.utc_now()         # Wrong - includes microseconds
```

### Sandbox Isolation

- Each test runs in isolated transaction
- Data created in one test is NOT visible to others
- `DataCase.ensure_test_invitation()` runs in EACH test's transaction
- That's why test invitation must be created per-test, not once globally

## Scope Pattern

### All Context Functions Require Scope

```elixir
# Correct
Content.list_posts(scope)
Faqs.create_faq(scope, attrs)

# Wrong - will fail
Content.list_posts()
```

### Always Use @current_scope in Templates

```heex
<!-- Correct -->
<%= @current_scope.user.email %>

<!-- Wrong -->
<%= @current_user.email %>
```

## LiveView

### Form Handling

Always use `to_form/2` in LiveView:
```elixir
# Correct
assign(socket, form: to_form(changeset))

# Wrong
assign(socket, changeset: changeset)
```

### Route Helpers

Phoenix 1.8 uses verified routes:
```elixir
# Correct
~p"/posts/#{post}"

# Wrong (deprecated)
Routes.post_path(conn, :show, post)
```

## Common Errors

### "invitation_code is invalid"
- Test invitation not created in ConnCase
- Fixed by adding `Homesite.DataCase.ensure_test_invitation()` to ConnCase setup

### "no match of right hand side value: {:error, changeset}"
- Trying to create user without invitation code
- Use `valid_user_attributes()` which includes `TEST-INVITE`

### "Numbers larger than 9999 should be written with underscores"
- Credo warning for readability
- Use `100_000` instead of `100000`

## Oban Workers

Currently disabled in development to prevent errors:
- `FeedScheduler` - RSS feed updates
- `AlgorithmUpdater` - Post ranking algorithm

These are commented out in `config/config.exs` until implemented.
