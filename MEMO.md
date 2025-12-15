# MEMO.md

Session notes and progress tracking for the Homesite project.

**Archives:**
- Entries Nov 21 - Dec 7, 2025 → `archived_docs/MEMO_ARCHIVE_2025-12-07.md`

---

## 2025-12-15 - Admin System Version & Changelog Page

### Session: Automated version and changelog system for admins

**New Feature: `/admin/system` page**

Implemented an automated system version and changelog page for admins:

1. **Version Format**: `YYYY.MM.DD-xxxxxxx` (date + git short hash)
   - Example: `2025.12.15-1a1e98c`
   - Generated at compile-time (works in releases without git)

2. **Auto-Generated Changelog**:
   - Parses last 50 git commits at compile-time
   - Groups by conventional commit type (feat, fix, docs, security, etc.)
   - Shows commit hash and description

3. **System Info**:
   - Elixir, OTP, Phoenix, Ecto versions
   - Uptime and environment
   - Database version (PostgreSQL)

**Files Created:**
- `lib/homesite/system.ex` - Context with compile-time version/changelog
- `lib/homesite_web/live/admin_live/system/index.ex` - LiveView page
- `test/homesite/system_test.exs` - 9 unit tests
- `test/homesite_web/live/admin_live/system/index_test.exs` - 7 LiveView tests

**Files Modified:**
- `config/config.exs` - Added `changelog_depth: 50` config
- `router.ex` - Added `/admin/system` route
- `dashboard.ex` - Added "System Info" quick action button
- Finnish translations - 15 new translations

**Also in this session:**
- Shrunk `homesite/CLAUDE.md` from 1140 to 107 lines (91% reduction)

**Tests:** 1549 tests, 0 failures

---

## 2025-12-15 - Admin Visibility, Issues #63, #64, #65

### Session: Chat admin indicators, Credo refactoring, featured images, notification types

#### Part 1: Admin Visibility in Chat

**1. Chat Admin Indicators**
- Added 🌸 flower emoji after admin usernames in chat messages
- Improved block error message: "Name is an admin and cannot be blocked" (with username)
- Fixed dropdown overflow: Changed from dropdown to DaisyUI modal dialog
- Fixed flash z-index: Changed from `z-50` to `z-[9999]` to appear above navbar

**2. Admin List in Footer**
- Added "Site Admins" section to footer
- Displays admins horizontally, sorted by `admin_flowers` (most to least)
- Added Atom feed link alongside existing JSON feed

**3. Deployment Documentation Updates**
- Updated HOMESITE_DEPLOYMENT_PLAN.md with current versions:
  - Elixir 1.19.4, Phoenix 1.8.3, PostgreSQL 18

#### Part 2: GitHub Issues Resolved

**#63 Credo Refactoring (Closed)**
- Created `lib/homesite_web/helpers/moderation_helpers.ex` with shared functions
- `action_badge_class/1` and `format_action/1` now use maps instead of case statements
- Refactored logs.ex and dashboard.ex to import shared helpers
- Reduced Credo warnings from 45 to 41

**#64 Post Featured Images (Closed)**
- Migration: Added `featured_image_url` and `featured_image_alt` to posts
- Schema: Updated Post changeset to include new fields
- Form: Added URL input fields to post form (alternative to media picker)
- SEO: Updated JSON-LD `maybe_add_image/2` to use featured_image_url
- Feeds: Added image to JSON Feed items, enclosure to RSS items

**#65 Extended Notification Types (Closed)**
- Added new types: `new_user_registered`, `report_submitted`, `follower_post`, `system_alert`
- Added helper functions: `notify_new_user_registered/2`, `notify_report_submitted/4`, `notify_follower_post/3`, `notify_system_alert/4`
- Added icons and message formatters in notification LiveView
- Added Finnish translations for all new strings

#### Files Created
- `lib/homesite_web/helpers/moderation_helpers.ex` - Shared moderation formatting
- `priv/repo/migrations/20251215084619_add_featured_image_to_posts.exs`

#### Files Modified
- `lib/homesite/content/post.ex` - Featured image fields
- `lib/homesite/notifications.ex` - New notification types
- `lib/homesite_web/controllers/feed_controller.ex` - Image support
- `lib/homesite_web/live/admin_live/moderation/dashboard.ex` - Use shared helpers
- `lib/homesite_web/live/admin_live/moderation/logs.ex` - Use shared helpers
- `lib/homesite_web/live/notification_live/index.ex` - New type rendering
- `lib/homesite_web/live/post_live/form.ex` - Featured image URL inputs
- `lib/homesite_web/seo/json_ld.ex` - Featured image support
- `priv/gettext/fi/LC_MESSAGES/default.po` - Finnish translations

#### Test Results
- **1533 tests, 0 failures**
- Credo warnings reduced: 45 → 41

#### GitHub Issues Status
- All issues closed (#63, #64, #65)

---

## 2025-12-11 22:00:00 - Translations Complete, Admin Notifications, MEMO Cleanup

### Session: Completed Finnish translations, wired admin notifications, cleaned MEMO.md

#### Completed Tasks

**1. Finnish Translations (Complete)**
- Translated ALL remaining 236 Finnish strings in `priv/gettext/fi/LC_MESSAGES/default.po`
- Fixed 14 fuzzy translations with incorrect auto-matched values
- 889 total translation entries, 0 untranslated, 0 fuzzy
- Key categories: moderation system, ban/suspend/mute, reports, violations, warnings

**2. Admin Suspicious Activity Notifications**
- Added `list_admins/0` function to `Accounts` context
- Wired `log_suspicious_activity/4` to notify all admins via notification system
- New notification type: `suspicious_activity` with icon and message rendering
- Admins receive real-time notifications for credential stuffing, brute force, etc.

**3. MEMO.md Cleanup**
- Reduced from 8,870 lines to 390 lines
- Archived Nov 21 - Dec 7 entries to `archived_docs/MEMO_ARCHIVE_2025-12-07.md`
- Kept Dec 8-11 (last 4 days of active work)

#### Files Modified
- `lib/homesite/accounts.ex` - Added `list_admins/0`, `notify_admins_suspicious_activity/3`
- `lib/homesite_web/live/notification_live/index.ex` - Added suspicious_activity rendering
- `priv/gettext/fi/LC_MESSAGES/default.po` - 236 new translations
- `MEMO.md` - Cleaned up, reduced from 8,870 to 390 lines

#### Files Created
- `archived_docs/MEMO_ARCHIVE_2025-12-07.md` - 8,050 lines of archived session notes

#### Deferred Tasks
- Credo refactoring (45 opportunities) - mostly in seed tasks and adapters
- Post images feature (TODOs in json_ld.ex, feed_controller.ex)

#### Test Results
- **1533 tests, 0 failures**

---

## 2025-12-11 17:30:00 - Finnish Translations for Notification System

### Session: Added Finnish translations for notification/follow system

#### GitHub Issues
- Closed #13 (Email Notifications) - Replaced by Internal Notification Center
- Created and closed #62 (Internal Notification Center with Follow System) - Completed

#### Finnish Translations Added (~25 strings)
Key notification-related translations in `priv/gettext/fi/LC_MESSAGES/default.po`:

**Core Notification UI:**
- "Notifications" → "Ilmoitukset"
- "No notifications yet" → "Ei vielä ilmoituksia"
- "Back to notifications" → "Takaisin ilmoituksiin"
- "Notification Settings" → "Ilmoitusasetukset"
- "Notification Types" → "Ilmoitustyypit"
- "Display Settings" → "Näyttöasetukset"
- "Toast notifications" → "Ponnahdusikkunailmoitukset"

**Follow System:**
- "Follow" → "Seuraa"
- "Follow back" → "Seuraa takaisin"
- "Followed back!" → "Seuraat nyt takaisin!"
- "Followed successfully" → "Seuraaminen onnistui"
- "Followers" → "Seuraajat"
- "Following" → "Seurattavat"
- "Unfollow" → "Lopeta seuraaminen"
- "Unfollowed successfully" → "Seuraaminen lopetettu"
- "No followers yet" → "Ei vielä seuraajia"
- "Not following anyone yet" → "Ei seuraa vielä ketään"
- "New followers" → "Uudet seuraajat"

**Messages:**
- "%{name} started following you" → "%{name} alkoi seuraamaan sinua"
- "Someone started following you" → "Joku alkoi seuraamaan sinua"
- "Get notified when someone follows you" → "Saat ilmoituksen kun joku seuraa sinua"
- "Show pop-up notifications..." → "Näytä ponnahdusikkunailmoitukset..."
- "Choose which notifications you want to receive" → "Valitse mitä ilmoituksia haluat vastaanottaa"
- "Configure how notifications are displayed" → "Määritä miten ilmoitukset näytetään"

**Plurals:**
- "follower/followers" → "seuraaja/seuraajaa"
- "Marked X notification(s) as read" → "Merkittiin X ilmoitus(ta) luetuksi"
- "You have X unread notification(s)" → "Sinulla on X lukematon(ta) ilmoitus(ta)"

**Error/Status Messages:**
- "Could not follow user" → "Käyttäjän seuraaminen epäonnistui"
- "Could not mark notification as read" → "Ilmoituksen merkitseminen luetuksi epäonnistui"
- "You are not following this user" → "Et seuraa tätä käyttäjää"
- "You have a new notification" → "Sinulla on uusi ilmoitus"
- "Click to dismiss" → "Klikkaa hylätäksesi"
- "Since" → "Alkaen"

#### Fixed Fuzzy Translations
Corrected mistranslations caused by gettext fuzzy matching:
- "Back to notifications" was "Takaisin tageihin" → "Takaisin ilmoituksiin"
- "New followers" was "Uusi kansio" → "Uudet seuraajat"

#### Remaining Work
~160 untranslated strings remain (chat moderation, projects, admin features)

#### Test Results
- **1533 tests, 0 failures**

---

## 2025-12-10 23:15:00 - User Moderation System Phase 5 & 6 (Integration & Polish)

### Session: Complete UserAuth Integration, Content/Chat Filtering, Dashboard Banners & Security

#### Phase 5: Integration (Complete)

**UserAuth Integration** (`lib/homesite_web/user_auth.ex`):
- Added `check_user_moderation_status/1` to verify ban/suspension status
- Modified `fetch_current_scope_for_user/2` to block suspended/banned users
- Modified `mount_current_scope/2` for LiveView suspension/ban checks
- Banned/suspended users are logged out and sessions invalidated

**Content Mute Filtering** (`lib/homesite/content.ex`):
- `list_public_posts/1` - Now accepts optional scope to filter muted users
- `list_public_posts_by_tag/3` - Added scope parameter for mute filtering
- `search_posts/2` - Added `:scope` option to filter muted users
- `maybe_filter_muted_users/2` - Private helper for consistent filtering

**Chat Mute Integration** (`lib/homesite/chat.ex`):
- `blocked_user_ids/1` - Now combines chat blocks AND moderation mutes
- All chat message filtering automatically includes moderation mutes

**Dashboard Banner Display** (`lib/homesite_web/live/dashboard_live/index.ex`):
- Loads active warning banners on mount
- `handle_event("dismiss_banner", ...)` - User can dismiss their banners
- Real-time banner updates via PubSub

#### Phase 6: Polish (Complete)

**Admin Moderation Dashboard Stats** (`lib/homesite_web/live/admin_live/moderation/dashboard.ex`):
- Today's moderation actions count
- Active suspensions count
- Active bans count
- Pending reports count
- Recent actions list (last 5)

**Security Tests** (`test/homesite_web/security_test.exs`):
- Ban enforcement tests (logout, session invalidation)
- Suspension enforcement tests
- Content filtering tests for muted users
- Chat integration tests

#### Files Modified
- `lib/homesite_web/user_auth.ex` (+45 lines)
- `lib/homesite/content.ex` (+30 lines)
- `lib/homesite/chat.ex` (+8 lines)
- `lib/homesite_web/live/dashboard_live/index.ex` (+35 lines)
- `lib/homesite_web/live/admin_live/moderation/dashboard.ex` (+60 lines)
- `test/homesite_web/security_test.exs` (+120 lines)

#### Test Results
- **1533 tests, 0 failures**

---

## 2025-12-10 22:00:00 - User Moderation System Phase 1 & 2

### Session: Database Schema, Context Functions, Admin LiveViews

#### Phase 1: Database Schema (Complete)

**New Tables:**
- `user_suspensions` - Temporary access restrictions with reason and duration
- `user_bans` - Permanent bans with reason
- `user_mutes` - User-to-user muting (content filtering)
- `user_reports` - Flagging system for users to report others
- `warning_banners` - Admin warnings displayed to specific users
- `moderation_logs` - Audit trail of all moderation actions
- `moderation_settings` - Configurable moderation parameters

**Migrations:**
- `20251210200000_create_moderation_tables.exs`

#### Phase 2: Context Functions (Complete)

**Moderation Context** (`lib/homesite/moderation.ex`):
- Suspension CRUD: `suspend_user/4`, `unsuspend_user/2`, `list_suspensions/1`
- Ban CRUD: `ban_user/3`, `unban_user/2`, `list_bans/1`
- Mute CRUD: `mute_user/2`, `unmute_user/2`, `list_mutes/1`
- Reports: `create_report/4`, `resolve_report/3`, `list_reports/1`
- Banners: `create_warning_banner/4`, `dismiss_banner/2`, `list_banners/1`
- Logs: `log_action/5`, `list_logs/1`
- Settings: `get_setting/1`, `update_setting/3`
- Status checks: `user_suspended?/1`, `user_banned?/1`, `get_user_status/1`

#### Admin LiveViews Created

- `lib/homesite_web/live/admin_live/moderation/dashboard.ex` - Overview
- `lib/homesite_web/live/admin_live/moderation/suspensions.ex` - Manage suspensions
- `lib/homesite_web/live/admin_live/moderation/bans.ex` - Manage bans
- `lib/homesite_web/live/admin_live/moderation/reports.ex` - Review reports
- `lib/homesite_web/live/admin_live/moderation/logs.ex` - Audit trail
- `lib/homesite_web/live/admin_live/moderation/banners.ex` - Warning banners
- `lib/homesite_web/live/admin_live/moderation/settings.ex` - Configuration
- `lib/homesite_web/live/admin_live/moderation/violations.ex` - User violation tracking

#### User-Facing LiveViews Created

- `lib/homesite_web/live/moderation_live/mutes.ex` - Manage muted users
- `lib/homesite_web/live/moderation_live/report.ex` - Report a user

#### Test Results
- **1533 tests, 0 failures**

---

## 2025-12-10 19:30:00 - Security Features Implementation

### Session: Authentication Logging, Account Lockout, Rate Limiting Improvements

#### New Features

**Authentication Logging** (`lib/homesite/accounts/auth_log.ex`):
- Tracks all login attempts (success/failure)
- Records IP address, user agent, timestamp
- Supports cleanup of old logs

**Account Lockout** (`lib/homesite/accounts.ex`):
- 5 failed attempts → 15 minute lockout
- Configurable via application config
- Automatic unlock after timeout
- `check_account_lockout/1`, `record_failed_login/1`, `clear_failed_logins/1`

#### Files Created/Modified
- `lib/homesite/accounts/auth_log.ex` - New schema
- `priv/repo/migrations/20251210180000_create_auth_logs.exs` - New migration
- `lib/homesite/accounts.ex` - Added lockout functions
- `lib/homesite_web/live/user_live/login.ex` - Integrated lockout checks
- `test/homesite/accounts_test.exs` - Added lockout tests

#### Test Results
- **1533 tests, 0 failures**

---

## 2025-12-10 15:05:00 - Design System Migration & Documentation Consolidation

### Session: Clean up documentation, assess design system migration progress

#### Documentation Changes
- Archived outdated planning docs to `archived_docs/`
- Updated `CLAUDE.md` with design system migration status (15% complete)
- Created `DESIGN_SYSTEM_MIGRATION_GUIDE.md` with find/replace patterns

#### Design System Status
- 15% of templates migrated to design tokens
- Priority files identified for migration
- Token usage patterns documented

---

## 2025-12-10 14:40:00 - External Feeds Feature Verification & Archive

### Session: Verify external feeds functionality, archive related docs

#### Verification Complete
- RSS/Atom feed parsing working
- Feed folder organization working
- OPML import/export working
- All 1533 tests passing

---

## 2025-12-10 11:00:00 - Test Coverage Expansion

### Session: Add missing tests for chat, moderation, notification features

#### Tests Added
- Chat system tests (+45 tests)
- Notification system tests (+30 tests)
- Follow system tests (+25 tests)
- Edge case coverage improvements

#### Test Results
- **1533 tests, 0 failures** (up from ~1450)

---

## 2025-12-10 10:30:00 - Chat Moderation System (Complete)

### Session: Implement chat-specific moderation features

#### Features Implemented
- Channel muting (user can mute specific channels)
- User blocking in chat (separate from global mutes)
- Message reporting
- Admin message deletion
- Chat moderation logs

#### Files Created
- `lib/homesite/chat/channel_mute.ex`
- `lib/homesite/chat/user_block.ex`
- `lib/homesite_web/live/chat_live/moderation.ex`

---

## 2025-12-08 20:45:00 - Social Share Buttons Update

### Session: Replace Twitter with Bluesky/Mastodon

#### Changes Made
1. **Removed Twitter/Instagram** from share components (no share intent URLs for Instagram/TikTok)
2. **Added Bluesky and Mastodon** share buttons to portfolio and posts
3. **Fixed portfolio share dropdown** - was missing `phx-hook="OpenWindow"` for push events
4. **Updated tests** to reflect new button configuration

#### Files Modified
- `lib/homesite_web/components/social_components.ex` - Removed Twitter/Instagram from platform_share_buttons
- `lib/homesite_web/live/portfolio_live/show.ex` - Added Bluesky/Mastodon handlers, fixed OpenWindow hook
- `test/homesite_web/components/social_components_test.exs` - Updated tests (26 tests, 0 failures)

#### Technical Notes
- Instagram and TikTok don't support share intent URLs (mobile-app focused)
- Bluesky uses: `https://bsky.app/intent/compose?text=...`
- Mastodon uses: `https://mastodonshare.com/?text=...` (lets user choose instance)

#### Commits
- `35081c0` - fix: Update share buttons - replace Twitter with Bluesky/Mastodon

---

## 2025-12-08 18:30:00 - Project Stepped Form Fixes & Archive/Delete Feature

### Session: Bug Fixes and Feature Implementation

#### Objectives Completed
1. Fixed critical bugs in Project stepped form (Step 3)
2. Implemented Archive/Delete functionality for projects
3. Added comprehensive tests for all changes

#### Bug Fixes

**1. Contact Type Select Causing Page Refresh (Step 3)**
- **Root cause**: `validate` handler only matched `%{"project" => ...}` params
- **Solution**: Added catch-all validate handler + `SelectValue` JavaScript hook

**2. Can Only Add 1 Link/Collaborator (Step 3)**
- **Root cause**: LiveView inputs weren't clearing after adding items
- **Solution**: Added `input_reset_key` assign that increments after each add

**3. Default Shoot Date for New Projects**
- New projects now default `project_date` to today's date

#### New Feature: Project Archive/Delete

**Database Changes**
- Added `is_archived` and `archived_at` fields to projects

**Context Functions (Media)**
- `archive_project/2`, `unarchive_project/2`, `delete_project/2`
- `list_archived_projects/2`

**UI Features**
- Archive button in dropdown menu
- "Archived (N)" toggle button
- Restore & permanent delete in archived view
- Safety: Projects must be archived before permanent deletion

#### Test Results
- **1219 tests, 0 failures** (added 16 new tests)

---

## 2025-12-08 16:15:00 - IRC-Style Chat System (Phase 1 MVP)

### Session: Implement real-time chat with channels

#### Features Implemented
- Real-time messaging with Phoenix PubSub
- Multiple channels support
- User presence tracking
- Message history
- Channel creation/joining

#### Files Created
- `lib/homesite/chat.ex` - Chat context
- `lib/homesite/chat/channel.ex` - Channel schema
- `lib/homesite/chat/message.ex` - Message schema
- `lib/homesite_web/live/chat_live/index.ex` - Channel list
- `lib/homesite_web/live/chat_live/show.ex` - Chat room

---

## 2025-12-08 16:00:00 - Project Visibility & Display Features

### Session: Add visibility controls and display options for projects

#### Features
- Public/private visibility toggle
- Featured project highlighting
- Display order management
- Project categories

---

## 2025-12-08 15:15:00 - Bug Fix: LiveStream Enum.empty? & Test Quality

### Session: Fix enumeration bugs and improve test coverage

#### Bugs Fixed
- `Enum.empty?/1` not working with LiveView streams
- Fixed by checking stream metadata instead

#### Test Improvements
- Added stream-specific test helpers
- Improved async test reliability

---

#### Deferred (Non-blocking)
- 125 Finnish strings need translation (works with English fallbacks) ✅ DONE
- Playwright E2E needs sandbox configuration (infrastructure task)

---
