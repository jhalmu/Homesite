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

### Password Authentication (Secondary)
Password login exists as a fallback:
- Uses Argon2 for secure password hashing
- Passwords optional during registration
- Login form accepts email + password
- Rate limited: 5 attempts per minute per IP

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

## Current Status: Testing Phase

### Registration Closed
Public registration is **temporarily disabled** while testing:
- Registration route commented out in `router.ex` (lines 108-122)
- Register link removed from navigation in `root.html.heex` (lines 78-81)
- To re-enable: uncomment the registration scope block

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

## Future: Invite System

### Requirements
1. **Invite Code Generation**
   - Admin creates invite codes
   - Optional: limit to specific email domain
   - Optional: set expiration date
   - Optional: single-use vs multi-use

2. **Registration Flow**
   - User visits `/users/register?invite=CODE`
   - System validates invite code
   - User completes registration
   - Invite marked as used (if single-use)

3. **Admin Interface**
   - Generate invite codes
   - View invite usage statistics
   - Revoke unused invites
   - Set default role for invitees

### Implementation Notes
- Add `invites` table with columns:
  - `code` (unique, indexed)
  - `created_by_user_id` (foreign key)
  - `max_uses` (integer, null = unlimited)
  - `current_uses` (integer, default 0)
  - `expires_at` (datetime, nullable)
  - `default_role` (string, default "user")
  - `inserted_at`, `updated_at`

- Add invite validation to registration flow
- Add admin UI for invite management (require flower level 3+)

## Recommendations

### For Testing Phase (Current)
✅ Keep registration closed
✅ Use test users with known passwords
✅ Test all permission levels thoroughly
⚠️ Document known email addresses for invites

### For Limited Release
1. **Enable invite system** before public registration
2. **Use passwordless authentication** as primary method
3. **Keep password login** as fallback for now
4. **Test email delivery** thoroughly in production
5. **Set up monitoring** for email delivery failures

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

## Timeline Considerations

**Phase 1: Testing (Current)**
- Duration: Until core features tested
- Users: 5 test users
- Access: Direct credential sharing

**Phase 2: Soft Launch (Invite-Only)**
- Duration: 1-3 months
- Users: 10-50 invited users
- Access: Invite codes
- Goal: Gather feedback, test email system

**Phase 3: Public Beta**
- Duration: 3-6 months
- Users: Unlimited
- Access: Open registration with email verification
- Goal: Scale testing, community building

**Phase 4: General Availability**
- Duration: Ongoing
- Users: Unlimited
- Access: Simplified registration (passwordless or social)
- Goal: Production stability

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
**Last updated:** 2025-11-24
**Status:** Testing phase - registration closed
