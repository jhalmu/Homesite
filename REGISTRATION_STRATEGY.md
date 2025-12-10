# Registration Strategy

## Current Authentication System

### Magic Link Authentication (Primary)
The application uses **passwordless authentication via magic links** as the primary method:

1. User enters email on login page
2. System generates a signed token (valid for 1 hour)
3. Email sent via Swoosh with magic link
4. User clicks link to authenticate
5. Token validated and session created

**Implementation**: `HomesiteWeb.UserAuth` module handles token generation/validation

### Password Authentication (Legacy Fallback)
Password login exists as an **optional fallback** for users who prefer it:
- Users register **without passwords** (passwordless by default)
- Users can optionally add a password later in Settings
- Uses Argon2 for secure password hashing
- Login form shows magic link first, password second
- Rate limited: 5 attempts per minute per IP

**Note:** Password is a safety net, not the primary method. If email delivery fails, users with passwords can still log in.

## Email System Configuration

### Development (Current Setup)
- **Adapter**: `Swoosh.Adapters.Local`
- **Preview**: Available at `http://localhost:4000/dev/mailbox`
- **No actual emails sent** - stored in memory for preview

### Production Requirements
To enable magic link authentication in production, configure one of:

1. **Postmark** (Recommended for transactional email)
   ```elixir
   config :homesite, Homesite.Mailer,
     adapter: Swoosh.Adapters.Postmark,
     api_key: System.get_env("POSTMARK_API_KEY")
   ```

2. **SendGrid**
   ```elixir
   config :homesite, Homesite.Mailer,
     adapter: Swoosh.Adapters.Sendgrid,
     api_key: System.get_env("SENDGRID_API_KEY")
   ```

3. **Mailgun**
   ```elixir
   config :homesite, Homesite.Mailer,
     adapter: Swoosh.Adapters.Mailgun,
     api_key: System.get_env("MAILGUN_API_KEY"),
     domain: System.get_env("MAILGUN_DOMAIN")
   ```

## Registration Approaches Comparison

### Option 1: Passwordless-First (Recommended)
**Pros:**
- Better UX (no password to remember)
- More secure (no weak passwords)
- Simpler onboarding
- Already implemented and working

**Cons:**
- Requires working email system
- Users must check email to log in
- Dependency on email delivery

**Best for:**
- Small, trusted user base
- When email reliability is high
- Reducing support burden

### Option 2: Hybrid (Current Implementation)
**Pros:**
- Users choose their preferred method
- Works if email system fails
- Familiar to users who prefer passwords

**Cons:**
- More complex auth flow
- Users may choose weak passwords
- Increased attack surface

**Best for:**
- Larger user bases
- When email reliability varies
- Transitioning from password-based auth

### Option 3: Password-Only
**Pros:**
- No email dependency
- Instant access
- Traditional flow

**Cons:**
- Password management burden
- More support requests (forgot password)
- Less secure user behavior

**Best for:**
- Internal tools
- When email is unavailable

## Current Status: Invitation-Only

### Registration Enabled with Invitation Requirement
Public registration is **enabled but requires invitation code**:
- Registration route active in `router.ex`
- Users must have a valid invitation code to register
- Admins can generate invitation codes at `/admin/invitations`

### Test Users Created
Five test users with different permission levels:

| Email | Role | Flowers | Permissions |
|-------|------|---------|-------------|
| user@example.com | user | 0 | Regular user access |
| admin1@example.com | admin | 🌸 | Basic admin access |
| admin2@example.com | admin | 🌸🌸 | Content moderation |
| admin3@example.com | admin | 🌸🌸🌸 | User management |
| admin5@example.com | admin | 🌸🌸🌸🌸🌸 | Full administrative access |

**All test users password:** `testpassword123`

## ✅ Implemented: Invitation System

### Features
1. **Invite Code Generation**
   - Admins can create invite codes at `/admin/invitations`
   - Auto-generated 8-character codes (or custom)
   - Optional max uses (unlimited if not set)
   - Optional expiration date
   - Set default role (user or admin)

2. **Registration Flow**
   - User visits `/users/register?invite=CODE` (code pre-filled)
   - Or manually enters invitation code on registration page
   - System validates invite code (not expired, not exhausted)
   - User completes registration
   - Invite current_uses incremented automatically

3. **Admin Interface** (`/admin/invitations`)
   - Create new invitation codes
   - View all active invitations
   - See usage stats (current uses / max uses)
   - Check expiration status
   - Delete unused/expired invitations
   - Copy codes to clipboard

### Database Schema
Table: `invitations`
- `code` (string, unique, indexed) - The invitation code
- `created_by_user_id` (foreign key to users) - Who created it
- `max_uses` (integer, nullable) - Null = unlimited uses
- `current_uses` (integer, default 0) - How many times used
- `expires_at` (utc_datetime, nullable) - When it expires
- `default_role` (string, default "user") - Role for new users
- `inserted_at`, `updated_at` (timestamps)

### Implementation Files
- **Migration**: `priv/repo/migrations/*_create_invitations.exs`
- **Schema**: `lib/homesite/accounts/invitation.ex`
- **Context**: `lib/homesite/accounts.ex` (invitation functions)
- **LiveView**: `lib/homesite_web/live/admin_live/invitations/index.ex`
- **Registration**: `lib/homesite_web/live/user_live/registration.ex` (validates invites)
- **Routes**: `lib/homesite_web/router.ex`
  - `/admin/invitations` - Admin management UI
  - `/users/register` - Registration with invite requirement
- **Tests**: `test/homesite/accounts_test.exs` (23 invitation tests)

## Recommendations

### ✅ Completed: Invitation System
- ✅ Invitation system implemented and tested
- ✅ Registration requires valid invitation code
- ✅ Admin UI for managing invitations
- ✅ All 234 tests passing (including 23 invitation tests)

### For Current Phase (Invitation-Only)
1. **Create initial invitations** for trusted users
2. **Test email delivery** with real invitations
3. **Monitor invitation usage** in admin dashboard
4. **Use passwordless authentication** as primary method
5. **Keep password login** as fallback

### For Public Launch
1. **Choose primary auth method** based on user feedback
2. **Consider removing** less-used method to simplify
3. **Add social login** (Google, GitHub) if user base grows
4. **Implement 2FA** for admin accounts (flower level 3+)

## Security Considerations

### Current Protections
- ✅ Rate limiting on login (5 attempts/minute)
- ✅ Rate limiting on registration (3 attempts/hour)
- ✅ Argon2 password hashing
- ✅ CSRF protection
- ✅ Secure session handling
- ✅ Signed tokens for magic links (1-hour expiry)

### Additional Recommendations
- [ ] Add email verification for password resets
- [ ] Log authentication attempts
- [ ] Alert on suspicious activity
- [ ] Implement account lockout after N failed attempts
- [ ] Add CAPTCHA for repeated failed logins
- [ ] Monitor for credential stuffing attacks

## Email Templates

Current email templates in `lib/homesite_web/`:
- `user_notifier.ex` - Email composition
- Uses HEEx templates for HTML emails

### Templates to Review/Improve
1. **Magic link email** - Clear call-to-action, expiry time
2. **Password reset email** - Security warnings
3. **Email confirmation** - Welcome message
4. **Invite email** - When invite system is added

## Timeline

**✅ Phase 1: Testing (Completed)**
- Duration: November 2025
- Users: 5 test users
- Access: Direct credential sharing
- Status: All core features tested

**🎯 Phase 2: Invitation-Only (Current - Implemented 2025-11-28)**
- Duration: Started 2025-11-28
- Users: Invite-only (unlimited)
- Access: Admin-generated invitation codes
- Goal: Controlled growth, gather feedback, test email system
- Features:
  - ✅ Invitation code system
  - ✅ Admin management UI
  - ✅ Registration validation
  - ✅ Usage tracking

**Phase 3: Future Considerations**
- Consider opening registration with email verification
- Or keep invitation-only for exclusive community
- Add social login if user base grows
- Implement 2FA for admin accounts

## Related Files

- `lib/homesite_web/user_auth.ex` - Authentication logic
- `lib/homesite/accounts.ex` - User management
- `lib/homesite_web/router.ex` - Route definitions
- `lib/homesite_web/live/user_live/registration.ex` - Registration form
- `lib/homesite_web/live/user_live/login.ex` - Login form
- `config/config.exs` - Swoosh configuration
- `priv/repo/seeds.exs` - Database seeding

## Questions to Answer

1. **Who is the target audience?**
   - Personal blog with selective access?
   - Community platform with open registration?
   - Internal tool for specific organization?

2. **What's the expected user volume?**
   - < 50 users: Simple invite system sufficient
   - 50-500 users: Need automated onboarding
   - 500+ users: Consider social login, automated verification

3. **How critical is immediate access?**
   - High: Password login required
   - Medium: Hybrid approach
   - Low: Passwordless only

4. **What's the email reliability?**
   - High: Passwordless works well
   - Medium: Hybrid recommended
   - Low: Password-only safer

5. **What's the support capacity?**
   - High: Can handle password reset requests
   - Low: Passwordless reduces support burden

---

**Document created:** 2025-11-24
**Last updated:** 2025-12-10
**Status:** Invitation-only - passwordless-first with optional password fallback
