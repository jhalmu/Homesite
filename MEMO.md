# MEMO.md

Session notes and progress tracking for the Homesite project.

**Archives:**
- Entries Nov 21 - Dec 7, 2025 → `archived_docs/MEMO_ARCHIVE_2025-12-07.md`

---

## 2026-02-02 - Open Registration System + Bug Fixes #90, #89

### Session Summary

Implemented configurable user registration system with CAPTCHA protection and fixed two critical bugs.

#### Features Implemented

**Open User Registration System**
- Three registration modes: Closed, Invite Only (default), Open
- Cloudflare Turnstile CAPTCHA integration
- Admin settings UI at `/admin/settings` for real-time configuration
- Settings context with database storage (`app_settings` table)

**Registration Modes:**
- **Closed**: Registration disabled completely
- **Invite Only**: Requires valid invitation code (existing behavior)
- **Open**: Anyone can register, invitation code optional

**CAPTCHA Protection:**
- Optional Turnstile CAPTCHA widget in registration form
- Server-side verification with `Turnstile.verify/1`
- Environment variables: `TURNSTILE_SITE_KEY`, `TURNSTILE_SECRET_KEY`
- Toggleable via admin settings

**Admin Controls:**
- Toggle registration mode (radio buttons)
- Enable/disable CAPTCHA (toggle switch)
- Changes take effect immediately
- Route: `/admin/settings`

#### Bug Fixes

**#90 - Writing problems with long text** (HIGH PRIORITY)
- **Symptom**: Page jumping and reloading when writing long blog posts
- **Root cause**: `phx-change="validate"` with 500ms debounce triggered constant DOM updates
- **Fix**: Changed body textarea debounce from `"500"` to `"blur"`
- **Result**: Validation only triggers when user leaves the field, eliminating jumping
- File: `lib/homesite_web/live/post_live/form.ex:35`

**#89 - Can't add new tags when similar exist** (MEDIUM PRIORITY)
- **Symptom**: Tag creation blocked entirely when similar tags found
- **Root cause**: `create-and-add-tag` handler only showed warning, didn't allow creation
- **Fix**:
  - Added `force` parameter to handler
  - Updated warning UI with "Create anyway" button
  - Users now see suggestions first, can still create if needed
- Files: `lib/homesite_web/live/post_live/form.ex:495-522, 179-198`

#### Technical Implementation

**Dependencies Added:**
- `{:phoenix_turnstile, "~> 1.0"}` - Cloudflare Turnstile integration

**Database Schema:**
```sql
CREATE TABLE app_settings (
  id SERIAL PRIMARY KEY,
  key VARCHAR NOT NULL UNIQUE,
  value JSONB NOT NULL,
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

**Settings Context API:**
```elixir
Settings.registration_mode() # => :invite_only | :open | :closed
Settings.turnstile_enabled?() # => boolean
Settings.update_setting(key, value) # => {:ok, setting} | {:error, changeset}
```

**Accounts Context Updates:**
```elixir
# New function signature with mode support
Accounts.register_user(attrs, mode \\ nil)
  # Checks Settings.registration_mode() if mode not provided
  # Branches to: register_user_open/1 or register_user_with_invitation/1

# New public function
Accounts.register_user_open(attrs)
  # Allows registration without invitation (open mode)
  # Uses invitation if provided
```

**Registration LiveView Updates:**
- Checks registration mode on mount
- Conditionally renders invitation field (required vs optional)
- Shows CAPTCHA widget when enabled
- Verifies CAPTCHA server-side before calling `Accounts.register_user/1`

#### Files Created
- `lib/homesite/settings.ex` - Settings context (4 functions)
- `lib/homesite/settings/app_setting.ex` - AppSetting schema
- `lib/homesite_web/live/admin_live/settings/index.ex` - Admin settings UI
- `priv/repo/migrations/20260202182759_create_app_settings.exs`

#### Files Modified
- `mix.exs` - Added phoenix_turnstile dependency
- `config/runtime.exs` - Turnstile configuration
- `lib/homesite/accounts.ex` - Registration modes logic
- `lib/homesite_web/components/layouts/root.html.heex` - Turnstile script
- `lib/homesite_web/live/user_live/registration.ex` - Mode-aware form + CAPTCHA
- `lib/homesite_web/live/post_live/form.ex` - Debounce fix + tag creation fix
- `lib/homesite_web/router.ex` - Admin settings route

#### GitHub Issues

**Closed:**
- **#90** - Writing problems (HIGH PRIORITY)
- **#89** - Add new Tag bug (MEDIUM PRIORITY)

**Remaining:**
- **#83** - Consider: Show image preview in posts list (enhancement, can wait)

#### Security Maintained
- Rate limiting: 3 registrations/hour per IP (existing)
- Account lockout: 5 failures = 15 min lockout (existing)
- Auth logging: All events tracked (existing)
- Moderation: Bans/suspensions enforced (existing)
- **NEW**: Turnstile CAPTCHA prevents bot registrations

#### Test Results
- **1693 tests, 0 failures**
- All precommit checks passed
- Credo: 53 refactoring opportunities (pre-existing)

#### Production Setup Required

To enable CAPTCHA in production, add environment variables:
```bash
TURNSTILE_SITE_KEY=your_cloudflare_site_key
TURNSTILE_SECRET_KEY=your_cloudflare_secret_key
```

Get keys at: https://dash.cloudflare.com/ → Turnstile

**Default Settings:**
- Registration mode: `invite_only`
- CAPTCHA: `disabled`

#### Commits
- `c663934` - feat: Add open registration with CAPTCHA & fix writing bugs

---

## EOD Workflow & Known Issues Guide

### Known Issues System

Production bugs are tracked in `/admin/system` "Known Issues & Fixes" section.

**Two sources:**
1. **Manual JSON** (`priv/known_issues.json`) - for quick edits
2. **GitHub Issues** with `known-issue` label - syncs with "Sync from GitHub" button

### Creating a Known Issue on GitHub

When you encounter a **production bug**, create a GitHub issue:

1. Add label: `known-issue`
2. Format body:
```markdown
## Symptom
What users see when this happens

## Fix
How it was fixed (or "investigating" if ongoing)

## Commit
abc1234 (optional)
```

3. Close the issue when fixed (status shows as "Fixed")

### EOD Checklist

When user says "EOD":
1. `mix test.all` - ensure tests pass
2. `gh issue list` - check open issues
3. Close completed issues: `gh issue close #XX --comment "Done in this session"`
4. Create `known-issue` labeled issues for any production bugs found
5. Update this MEMO.md with session summary
6. Commit & push

### Environment Variables for Production

```bash
PHX_HOST=orangedinos.de
PHX_ALTERNATE_HOST=juhahalmu.fi
PHX_CHECK_ORIGIN_HOSTS=juhahalmu.fi
```

---

## 2026-01-10 (evening) - Slug-Based Post URLs, Featured Images, Bugfixes Plan Archive

### Session Summary

Implemented slug-based URLs for posts and added featured image support to profile pages. Archived completed bugfixes plan.

#### Issues Completed

**#88 - Use Slugs Instead of IDs in Post URLs** (commit `ecf1134`)
- Changed post URLs from `/posts/:id/:slug` to `/posts/:slug`
- Benefits: Cleaner URLs, better SEO, consistent with tag pattern
- Added `get_post_by_slug!` and `get_public_post_by_slug!` to Content context
- Updated 80+ URL references across 25 files
- Created PostRedirectController with 301 redirects for old URLs:
  - `/posts/:id/:slug` → `/posts/:slug` (old format)
  - `/posts/:id` → `/posts/:slug` (legacy format)
- Updated router, LiveViews (Show, Form), SEO plug, feeds, sitemap
- Updated all templates and tests
- Router warning for overlapping patterns is harmless (redirects work correctly)

**#84 - Show Post Images on User Profile Page** (commit `20d4756`)
- Added featured image thumbnails (24x24) to profile post listings
- Images only show when `featured_image_url` is present
- Clickable images link to full post
- Changed flex alignment from `items-end` to `items-start`

**CI/CD Compilation Warning Fix** (commit `da9d431`)
- Removed unreachable route `get "/posts/:id"` that caused compilation warning
- Route was unreachable because `live "/posts/:slug"` matched first
- Very old `/posts/123` URLs now 404 (acceptable, format deprecated long ago)
- Recent `/posts/123/my-slug` URLs still redirect correctly

**Media Library Upload Preview Fix** (commit `5062e47`)
- Fixed image previews not showing after file selection
- Moved `<.live_file_input>` outside of `<label>` element
- LiveView can now properly detect file selection and update uploads
- Previews now appear immediately before form submission

**Content Security Policy Fix** (commit `5cdf7e3`)
- Added `blob:` to CSP `img-src` directive
- Fixes browser blocking LiveView upload preview images
- Blob URLs are created client-side from file inputs (safe to allow)
- Resolves CSP error: "blocked the loading of a resource (img-src) at blob:..."

#### Housekeeping

**Archived BUGFIXES_PLAN.md**
- Moved to `archived_docs/BUGFIXES_PLAN_2025-12-31.md`
- All issues from that plan (#73-#80) have been completed

#### GitHub Issues

**Closed:**
- **#88** - Slug-based post URLs (implemented)
- **#84** - Profile post images (implemented)

**Remaining:**
- **#83** - Consider: Show image preview in posts list (marked "maybe skip")

#### Files Modified

**Core Changes:**
- `lib/homesite/content.ex` - Added slug-based lookup functions
- `lib/homesite_web/router.ex` - Updated routes to use :slug only
- `lib/homesite_web/controllers/post_redirect_controller.ex` - New redirect controller
- `lib/homesite_web/live/post_live/show.ex` - Fetch by slug
- `lib/homesite_web/live/post_live/form.ex` - Updated apply_action, return_path
- `lib/homesite_web/plugs/seo_plug.ex` - Match and fetch by slug

**URL Updates (80+ locations):**
- Components: content_components.ex
- Controllers: feed_controller.ex, sitemap_controller.ex
- LiveViews: dashboard, page/home, search, post, following, user/profile, tag, project
- Tests: All test files updated to use slug-based URLs

**Profile Images:**
- `lib/homesite_web/live/user_live/profile.ex` - Added featured image display

**CI/CD Fixes:**
- `lib/homesite_web/router.ex` - Removed unreachable route
- `lib/homesite_web/controllers/post_redirect_controller.ex` - Removed unused function

**Media Library:**
- `lib/homesite_web/live/media_live/index.ex` - Fixed file input structure

**Security:**
- `lib/homesite_web/plugs/content_security_policy.ex` - Added blob: to img-src

#### Commits This Session
1. `ecf1134` - feat: Use slugs instead of IDs in post URLs (#88)
2. `20d4756` - feat: Show featured images on user profile posts (#84)
3. `9d6361a` - docs: Update MEMO.md with session summary
4. `da9d431` - fix: Remove unreachable route to fix CI/CD warning
5. `5062e47` - fix: Fix media library upload preview not showing
6. `5cdf7e3` - fix: Add blob: URLs to Content-Security-Policy img-src

#### Test Results
- **1693 tests, 0 failures**
- Credo: 53 refactoring opportunities (pre-existing)
- CI/CD: All pipelines passing ✓

#### Technical Notes

- Post slugs already unique in database with constraint
- Router pattern `/posts/:slug` matches both numeric IDs and slugs at compile time
- Redirect routes handle old URLs correctly via Integer.parse check
- LiveView routes take precedence, but slug lookup fails for numeric IDs (404)
- This is correct behavior - old numeric URLs get redirected

---

## 2026-01-10 - Bug Fixes, Lighthouse Testing, SEO Improvements

### Session Summary

Fixed bugs, added Lighthouse CI testing, improved SEO with tags in structured data.

#### Issues Completed

**#85 - User page URL popup copy button doesn't work** (commit `4a85e74`)
- Copy button was missing `phx-hook="CopyToClipboard"` attribute
- Added hook and id to receive clipboard events from server

#### Features Implemented

**Media Library Upload Preview Fix** (commit `329e640`)
- Disabled `auto_upload` to allow `live_img_preview` to work properly
- Added `entry.valid?` check before rendering preview with error fallback
- Removed GIF from accepted types (ImageProcessor doesn't support it)
- Fixed error messages (max file size 5MB → 20MB)

**Lighthouse CI Testing** (commit `c21bf82`)
- New `mix lighthouse` task runs Google Lighthouse audits
- Uses Playwright's bundled Chromium browser
- Supports `--start-server` flag to auto-start Phoenix server
- Supports `--threshold` flag to set minimum performance score
- New `test.full` alias: runs `test.all` + lighthouse

**SEO: Tags in JSON-LD** (commit `4e00836`)
- Post tags now included as `"keywords"` in BlogPosting structured data
- Improves SEO by providing search engines with structured tag data

#### GitHub Issues

**Created:**
- **#88** - Use slugs instead of IDs in post URLs (enhancement, planned)

**Closed:**
- **#85** - Copy button fix
- **#87** - Already implemented (first post featured image)

**Remaining:**
- **#83** - Consider: Show image preview in posts list (maybe skip)
- **#84** - Show post images on user profile page
- **#88** - Use slugs instead of IDs in post URLs (new)

#### Lighthouse Audit Results (Dev Mode)
- Performance: 55-68 (expected in dev, unminified assets)
- Accessibility: 100 ✅
- Best Practices: 100 ✅
- SEO: 100 ✅

#### Test Results
- **1697 tests, 0 failures**

---

## 2026-01-02 (evening) - Issues #81, #82, #86, #87 Implemented

### Session Summary

Implemented 4 GitHub issues: tag filter search, featured image search fixes, frontpage improvements.

#### Issues Completed

**#81 - Media Library Tag Filter Search** (commit `0ddc23d`)
- Replaced dropdown with search input + autocomplete
- Shows selected tag as badge with clear button
- 1+ char triggers search with post counts in suggestions

**#82 - Featured Image Search Fixed** (commit `1524274`)
- Search now includes original filename and alt text
- Uses ILIKE for short queries (< 3 chars)
- Added tag filter dropdown in media picker
- Added orientation filter (landscape/portrait/square)

**#86 - Frontpage Feed Items** (final: `20436f4`)
- Public to all visitors
- Max 3 items per feed source, max 8 total
- "View all feeds" link only for authenticated users

**#87 - First Post Featured Image** (commit `ec9829d`)
- Featured image shown only on the first/latest post
- Grid posts and older posts don't show images
- Clickable image links to post

#### GitHub Issues Created Earlier (#81-#87)

**Remaining:**
- **#83** - Consider: Show image preview in posts list (maybe skip)
- **#84** - Show post images on user profile page
- **#85** - User page URL popup copy button doesn't work

#### Files Modified
- `lib/homesite_web/live/media_live/index.ex` - Tag filter search
- `lib/homesite/media.ex` - Improved search_media_items
- `lib/homesite_web/live/post_live/form.ex` - Media picker filters
- `lib/homesite/external_feeds.ex` - list_public_feed_items
- `lib/homesite_web/live/page_live/home.ex` - Use public feed items
- `lib/homesite_web/live/page_live/home.html.heex` - Featured image on first post

#### Test Results
- **1691 tests, 0 failures**

---

## 2026-01-02 - Media Library Tagging System + Following Feed

### Session Summary

Implemented two major features: Media Library Tagging System and Following Feed.

#### Features Implemented

**Media Library Tagging System (#80)**
- Created `media_item_tags` join table for many-to-many relationship
- Created `MediaItemTag` schema at `lib/homesite/media/media_item_tag.ex`
- Updated `MediaItem` schema with `many_to_many :tags` association
- Added context functions: `update_media_item_tags/3`, `list_media_tags/1`, `count_media_items_by_tag/1`
- Updated `list_media_items/2` and `list_orphaned_media_items/2` to filter by tag_id
- UI features:
  - Tag filter dropdown in media library
  - Batch tag selection during upload (apply same tags to all images)
  - Individual tag editing via modal
  - Tag badges on media item cards

**Following Feed**
- Created `FollowingLive.Index` showing posts from followed users
- Added `list_posts_from_following/2` to Content context
- Added navigation link at `/following`

#### Accessibility Fixes
- Added `aria-label` to aspect ratio filter select
- Added `aria-label` to tag filter select
- Fixes critical a11y violations in media library

#### Translations Added
Finnish translations for all new strings:
- Media tagging: "Lisää tagit ladattaviin kuviin", "Muokkaa tageja", "Tagit päivitetty onnistuneesti", etc.
- Following feed: "Seuraa muita käyttäjiä nähdäksesi heidän julkaisunsa täällä", "Ei vielä julkaisuja seuraamiltasi käyttäjiltä", etc.
- Aria labels: "Suodata kuvasuhteen mukaan", "Suodata tagin mukaan"

#### Pre-existing Accessibility Issues (Not Fixed)
These are pre-existing issues discovered during testing:
- **Heading order violations**: Several pages use `h3` without proper `h1 > h2` hierarchy
- **Portfolio empty state**: "No projects available" uses `h3` without parent headings
- **Feed/Media cards**: Card titles use `h3` without proper hierarchy
- **Login contrast in dark theme**: May have contrast ratio issues
- **Orphan filter button test**: Test can't find button due to badge inside button element

#### Files Created
- `priv/repo/migrations/20260102072359_create_media_item_tags.exs`
- `lib/homesite/media/media_item_tag.ex`
- `lib/homesite_web/live/following_live/index.ex` (earlier in session)

#### Files Modified
- `lib/homesite/media/media_item.ex` - Added tags association
- `lib/homesite/media.ex` - Added tag functions, updated queries with preload
- `lib/homesite_web/live/media_live/index.ex` - Tag filter, upload tags, editing UI, aria-labels
- `lib/homesite/content.ex` - Added `list_posts_from_following/2`
- `priv/gettext/fi/LC_MESSAGES/default.po` - Finnish translations

#### Commits
- `5ef63a6` - feat: Add tagging system to media library (#80)
- `5d01fd8` - fix: Add translations and aria-labels for media tagging

#### Test Results
- **1691 tests, 0 failures**
- Playwright tests: 6 failures (all pre-existing accessibility issues)
- Dialyzer: 5 errors (pre-existing, including known legacy warning in search.ex)

---

## 2025-12-31 (evening) - Issues #75, #77 + Deployment

### Session Summary

Implemented remaining enhancement issues and deployed to production.

#### Issues Implemented

**#75 - Show Edited Time on Modified Posts**
- Added `was_edited?/1` helper (detects if updated > 5 min after publish)
- Added `format_relative_date/1` for friendly dates (today, yesterday, X days ago)
- Added edited indicator with pencil icon to post show template
- Added Finnish translations for all new strings
- Files: `post_live/show.ex`, `default.po` (en/fi)

**#77 - Author Avatar in Social Share**
- Created `ImageController` with HTTP endpoints for images:
  - `GET /images/posts/:post_id/hero` - serves hero images
  - `GET /images/users/:user_id/avatar` - serves user avatars
- Updated `SEO` module with image priority: hero_image > author_avatar > default
- Added routes to router
- Updated Sobelow config for false positives (trusted database content)
- Files: `image_controller.ex`, `seo.ex`, `router.ex`, `.sobelow-conf`

#### Bug Fixes
- Fixed `delete_old_feed_items` test (isolation-safe assertions)
- Fixed media live tests (check for event name instead of localized text)
- Added secondary sort key to `list_orphaned_media_items` for deterministic pagination

#### Deployment
- All 1691 tests passing
- CI/CD pipeline: Test → Build → Deploy to Hetzner
- Production live at orangedinos.de

---

## 2025-12-31 (afternoon) - Bug Fixes #74, #76, #78, #79, #80 + Comprehensive Tests

### Session Summary

Implemented fixes for 5 GitHub issues and added comprehensive test coverage.

#### Issues Fixed

**#74 - Time Field Shows 12:00 Default**
- Root cause: `format_time(_)` catch-all returned "12:00" for ISO8601 strings
- Fix: Added string datetime parsing clauses to `format_time` and `format_date`
- Files: `form.ex`, `form_components.ex`

**#76 - Page Refresh/Scroll Issues**
- Root cause: AutoGrow hook triggering on every input caused scroll jumps
- Fix: Preserve scroll position in `updated()`, add `phx-debounce="500"` to textarea
- Files: `assets/js/app.js`, `form.ex`

**#78 - User Following Not Accessible**
- Finding: Following feature fully implemented, just needed UI discoverability
- Fix: Made author names/avatars clickable links to user profiles
- Files: `core_components.ex` (`author_byline`), `home.html.heex`

**#79 - RSS Feed Limit Per Source**
- New function: `list_feed_items_limited_per_source/2`
- Uses SQL window function: `ROW_NUMBER() OVER PARTITION BY`
- Features: Limits to 3/source, prioritizes unread, exempts bookmarked
- Files: `external_feeds.ex`, `feed_live/index.ex`

**#80 - Media Library Orphan Filter**
- New functions: `list_orphaned_media_items/1`, `count_orphaned_media_items/1`
- UI: "Unused" toggle button with count badge
- Shows images not added to any portfolio project
- Files: `media.ex`, `media_live/index.ex`

#### Tests Added

**External Feeds Tests** (`external_feeds_test.exs`):
- 12 new tests for `list_feed_items_limited_per_source/2`
- Covers: limit per source, total limit, unread priority, bookmark exempt, offset, scope isolation

**Media Tests** (`media_test.exs`):
- 12 new tests for orphan filter functions
- Covers: orphan detection, scope isolation, limit/offset, aspect filter, count updates

**Media LiveView Tests** (`media_live/index_test.exs`):
- 6 new tests for orphan filter UI
- Covers: button display, toggle behavior, empty state, count updates, accessibility

**Feed LiveView Tests** (`feed_live/index_test.exs`):
- Created new test file with 17 tests
- Covers: rendering, source limiting, mark read/bookmark, filter, pagination, accessibility

**Accessibility Tests** (`accessibility_test.exs`):
- 8 new Playwright E2E tests
- Covers: Media library, Feed page, Portfolio page accessibility

#### Test Results
- **186 new tests added**
- **1 pre-existing failure** (delete_old_feed_items isolation issue)

---

## 2025-12-31 - Bug Tracking Session: GitHub Issues #73-80

### Session Summary

Created comprehensive bug tracking and enhancement planning documentation.

#### GitHub Issues Created

**HIGH Priority Bugs:**
- **#73** - Blog post publicity toggle not working (posts show on frontpage but 404 when clicked)
- **#76** - Page refresh/scroll issues when writing long text

**MEDIUM Priority:**
- **#74** - Time field shows 12:00 default in edit mode
- **#78** - User following feature not accessible in UI (backend complete, UI missing)
- **#79** - RSS feed limit per source (show 3 per source for variety)
- **#80** - Media library folders and orphan image filter

**LOW Priority Enhancements:**
- **#75** - Show edited time on modified posts
- **#77** - Author avatar in share template when no featured image

#### Root Causes Identified

1. **Publicity Bug (CONFIRMED)**: `list_public_posts()` at `content.ex:386` only checks `published_at IS NOT NULL` but misses `is_public = true` check
2. **Time Default (CONFIRMED)**: `format_time(nil)` at `form.ex:673` returns hardcoded `"12:00"`
3. **Following (CONFIRMED WORKING)**: Routes exist at `router.ex:287-288`, just needs UI links

#### Files Created

- `BUGFIXES_PLAN.md` - Detailed solutions, questions, and ideas for each issue

#### Quality Checks

- Tests: `mix test.all`
- Code quality: `mix credo --strict`

---

## 2025-12-25 (afternoon) - ApexCharts, Activity Logging, Admin Dashboard Charts

### Session Summary

Major analytics upgrade with beautiful charts and automatic activity logging.

#### Features Implemented

**1. ApexCharts Integration**
- Replaced Chart.js with ApexCharts for modern visualizations
- Created ApexChart hook with full dark mode support
- Added sparkline mode for mini charts
- Theme detection and auto-update on theme change

**2. Activity Logging in Production**
- Integrated `Analytics.log_activity` in Content context:
  - Create/update/delete/publish post
  - Create tag
- Added user registration logging in Accounts context
- Async logging via Task.Supervisor (non-blocking)

**3. Admin Dashboard Charts (/admin)**
- Added "Quick Insights" section with 3 mini charts:
  - Activity Sparkline (7-day trend)
  - User Breakdown (donut: users vs admins)
  - Content Status (donut: published vs drafts)

**4. Analytics Dashboard Enhanced (/admin/analytics)**
- Activity Trend (30-day area chart)
- Activity by Type (donut chart)
- Search Trend (30-day area chart)
- Top Countries (horizontal bar)
- All charts now use ApexCharts

**5. Dev Seed Data**
- Created `priv/repo/seeds/analytics_seed.exs`
- 300 activity logs over 30 days
- 150 search queries with geo data
- 9 countries with realistic cities

**6. connect_info Fixed**
- Added `:peer_data` and `:user_agent` to endpoint.ex
- Enables IP address and user agent tracking in LiveViews

#### Files Created
- `priv/repo/seeds/analytics_seed.exs` - Analytics mock data

#### Files Modified
- `assets/js/app.js` - ApexChart hook with dark mode
- `assets/package.json` - Added apexcharts dependency
- `lib/homesite/accounts.ex` - Registration logging
- `lib/homesite/analytics.ex` - Trend query functions
- `lib/homesite/content.ex` - Activity logging integration
- `lib/homesite_web/endpoint.ex` - connect_info fix
- `lib/homesite_web/live/admin_live/dashboard.ex` - Quick Insights charts
- `lib/homesite_web/live/admin_live/analytics/index.ex` - ApexCharts config
- `test/homesite/analytics_test.exs` - 7 new tests, resilience fixes

#### Test Results
- **1655 tests, 0 failures**

#### Deployment
- CI/CD triggered automatically on push to main
- Docker image built and deployed to Hetzner

---

## 2025-12-25 - Geo Analytics, Share Dropdown, Search Compact, Translations

### Session Summary

Christmas session with multiple fixes and features.

#### Features Implemented

**1. Geo Analytics (Country/City Tracking)**
- Added MaxMind GeoLite2-City database integration
- New `Homesite.Analytics.Geo` module for IP geolocation
- Added `country` and `city` fields to `activity_logs` and `search_queries`
- Admin dashboard shows Geographic Analytics section with top countries/cities
- Country flag emojis generated from ISO codes

**2. Posts Index Share Button (Fixed)**
- Replaced broken Share button with dropdown menu (same as portfolio page)
- Options: Bluesky, Mastodon, LinkedIn, Email
- Uses `OpenWindow` hook pattern for cross-browser compatibility
- Translated to Finnish

**3. Search Results Compact Layout**
- Moved Tags section first (above Posts)
- Added card backgrounds with `card bg-base-100 shadow-sm`
- Reduced spacing and font sizes for compact list

**4. Translations Fixed**
- Removed 3 fuzzy translation flags
- Added missing translations: Commit, Fix, Fixed, Known Issues & Fixes, etc.
- Fixed incorrect translations (Open: "Avaa valikko" → "Avoin")

#### Files Created
- `lib/homesite/analytics/geo.ex` - Geo lookup module
- `priv/repo/migrations/20251224230323_add_country_to_analytics.exs`
- `priv/repo/migrations/20251224234532_add_city_to_analytics.exs`

#### Files Modified
- `lib/homesite/analytics.ex` - Geo integration, new analytics functions
- `lib/homesite_web/live/admin_live/analytics/index.ex` - Geo stats display
- `lib/homesite_web/live/post_live/index.ex` - Share dropdown
- `lib/homesite_web/live/search_live/index.html.heex` - Compact layout
- `lib/homesite_web/components/social_components.ex` - Added gettext
- `assets/js/app.js` - Simplified Share hook
- `priv/gettext/fi/LC_MESSAGES/default.po` - Fixed fuzzy + added translations

#### Test Results
- **1648 tests, 0 failures**

### Session Continued (late evening)

Fixed production issues and housekeeping.

#### Fixes

**1. Search Broken in Production**
- **Symptom**: Search failed in production but worked in dev
- **Root cause**: `Mix.env()` not available in production releases (Mix not loaded)
- **Fix**: Use compile-time module attribute `@env Mix.env()` instead
- **File**: `lib/homesite/search.ex:91`

**2. Email Translations**
- Already implemented: `with_locale/2` uses user's `preferred_language`
- Registration emails are bilingual (EN + FI for new users)
- Added missing Finnish translations for email strings

**3. FAQ Export to Production**
- Ran `mix faq.export_sql` to export 44 FAQs
- Imported to production: `docker exec -i homesite-db-1 psql -U homesite homesite_prod < priv/repo/faq_export.sql`
- Categories: 6 admin, 38 user FAQs

#### Housekeeping

**1. Archived Outdated Docs**
- Moved to `archived_docs/`: HOMESITE_DEPLOYMENT_PLAN.md, REGISTRATION_STRATEGY.md, DEPLOYMENT.md
- Deleted: test_results.txt, test_results_final.txt (Nov 28)
- Kept: DESIGN_SYSTEM_GUIDE.md (has practical usage patterns not elsewhere)

**2. README Cleanup**
- Reduced from 479 to 83 lines
- Removed outdated roadmap items
- Focused on essentials: features, quick start, commands

#### Key Learnings

1. **Mix.env() in releases**: Use `@env Mix.env()` at compile-time, not runtime
2. **Gettext dynamic strings**: Strings passed to `Gettext.gettext/2` dynamically aren't auto-extracted
3. **FAQ export**: Use UPSERT (`ON CONFLICT ... DO UPDATE`) for safe re-imports
4. **MaxMind with locus**: Library auto-updates every 6 hours, handles R2 redirects, only needs `MAXMIND_LICENSE_KEY`

---

## 2025-12-22 (evening) - Dual Domain Configuration & Auto GitHub Sync

### Session Summary

Fixed domain configuration for serving both orangedinos.de and juhahalmu.fi.

#### Issues Fixed

**1. www.orangedinos.de Redirecting to juhahalmu.fi**
- **Root cause**: Caddyfile had `www.{$PHX_HOST}, www.orangedinos.de` redirecting to `{$PHX_HOST}`
- **Fix**: Split into separate redirect blocks, each going to its own non-www

**2. WebSocket Origin Check Failing on Secondary Domain**
- **Root cause**: `PHX_CHECK_ORIGIN_HOSTS` missing from docker-compose.yml
- **Fix**: Added to app service environment

**3. Caddy Not Reading PHX_ALTERNATE_HOST**
- **Root cause**: Variable not passed to caddy service
- **Fix**: Added `PHX_ALTERNATE_HOST` to caddy environment

#### New Feature: Pre-Push GitHub Issue Sync

Created git pre-push hook that automatically syncs known issues before every push:
- Runs `Homesite.System.sync_known_issues_from_github()`
- If issues changed, creates auto-commit
- Tracked copy in `scripts/pre-push` for reinstalling

#### Files Modified
- `Caddyfile` - Use `PHX_ALTERNATE_HOST` env var, separate www redirects
- `docker-compose.yml` - Add `PHX_CHECK_ORIGIN_HOSTS` and `PHX_ALTERNATE_HOST`
- `.git/hooks/pre-push` - Auto-sync GitHub issues (local only)
- `scripts/pre-push` - Tracked copy of hook

#### Commits
- `398b72b` - fix: Support dual domains via environment variables
- `7e2052c` - fix: Add missing env vars to docker-compose.yml

#### Test Results
- **1608 tests, 0 failures**

---

## 2025-12-22 - GitHub Issues #67-71, Known Issues System, WebSocket Fix

### Session Summary

Fixed multiple GitHub issues and added a Known Issues tracking system with GitHub sync.

#### Issues Closed

- **#70** - Fix copy button in dashboard (switched to CopyButton hook)
- **#67** - Add feedback notes column to admin feedback page
- **#69** - Add known issues section to /admin/system with GitHub sync
- **#71** - Create custom domain setup guide (DevFaq)

#### Features Implemented

**1. WebSocket Origin Check for Multiple Domains**
- Added `PHX_CHECK_ORIGIN_HOSTS` env var support in `runtime.exs`
- Allows LiveView connections from multiple domains (juhahalmu.fi, orangedinos.de)

**2. Known Issues System**
- JSON config file: `priv/known_issues.json`
- GitHub sync: Fetches issues with `known-issue` label
- Admin UI: `/admin/system` shows issues with status badges
- Sync button only visible in dev environment

**3. Admin Dashboard Updates**
- Added Dev FAQs link to Quick Actions
- Fixed copy button using CopyButton hook pattern

**4. Documentation**
- Created `priv/dev_faqs/008-custom-domain-setup.md`
- Added EOD workflow instructions to MEMO.md
- Created `known-issue` GitHub label

#### Files Created
- `priv/known_issues.json` - Known issues data
- `priv/dev_faqs/008-custom-domain-setup.md` - Custom domain guide

#### Files Modified
- `config/runtime.exs` - WebSocket origin check
- `lib/homesite/system.ex` - GitHub sync functions
- `lib/homesite_web/live/admin_live/system/index.ex` - Known issues UI
- `lib/homesite_web/live/admin_live/dashboard.ex` - Dev FAQs link
- `lib/homesite_web/live/admin_live/feedback/index.ex` - Feedback notes column
- `lib/homesite_web/live/dashboard_live/index.ex` - Remove unused handler
- `lib/homesite_web/live/dashboard_live/index.html.heex` - CopyButton hook

#### Commits
- `f858164` - feat: Add known issues system with GitHub sync (#69, #70, #67, #71)
- `9900dd9` - style: Fix formatting in system.ex
- `969241f` - fix: Correct Dev FAQs route from /dev/faqs to /faqs
- `ea97ef1` - fix: Hide GitHub sync button in production

#### Test Results
- **1608 tests, 0 failures**

#### Remaining Issues
- **#68** - Verify active feedback system (manual testing needed)

---

## 2025-12-21 - Production SMTP & Avatar Upload Fixes

### Session Summary

Resolved multiple production deployment issues on Hetzner server (juhahalmu.fi).

#### Issues Fixed

**1. Magic Link Emails Not Sending**
- **Symptom**: Form submitted (flash appeared) but no email sent, TLS handshake error
- **Error**: `{:error, {:retries_exceeded, {:temporary_failure, ~c"78.46.5.205", :tls_failed}}}`
- **Fix**: Relaxed TLS settings in `config/runtime.exs`:
  - `tls: :always` → `tls: :if_available`
  - Added `tls_options: [verify: :verify_none]`

**2. Avatar Upload 404 Errors**
- **Symptom**: Avatars saved but Caddy returned 404
- **Root cause**: Caddyfile path mapping was wrong - looking for `/uploads/uploads/avatars/file.jpg`
- **Fix**: Added `uri strip_prefix /uploads` in Caddyfile before `file_server`

**3. Avatar Upload Permission Denied**
- **Symptom**: `touch: cannot touch '/app/uploads/test.txt': Permission denied`
- **Fix**: `docker compose exec -u root app chown -R nobody:nogroup /app/uploads`

**4. Old Avatar Files Not Cleaned Up in Production**
- **Symptom**: Avatar files accumulating, old ones never deleted
- **Root cause**: `delete_avatar_file/1` was using `priv/static` path, not `UPLOADS_PATH`
- **Fix**: Updated function to use `System.get_env("UPLOADS_PATH")` with fallback

**5. Server Repo Missing**
- `/opt/homesite` had no git repo - had to clone fresh from GitHub
- Restored `.env` from `/tmp/.env.backup`

#### Files Modified
- `config/runtime.exs` - Relaxed SMTP TLS settings
- `Caddyfile` - Added `uri strip_prefix /uploads` for correct path mapping
- `lib/homesite/accounts.ex` - Fixed `delete_avatar_file/1` for production paths

#### Commits
- `959db71` - fix: Relax SMTP TLS settings for Hetzner mail server
- `bd0a819` - chore: Add release files for Docker build
- `a6702e9` - fix: Correct Caddy path for serving uploaded files
- `c007825` - fix: Delete old avatar files correctly in production

#### Test Results
- **230 tests, 0 failures**

---

## 2025-12-18 - Fix Section Editing Nested Forms Bug

### Session Summary

#### Problem Identified
- Could not edit "Book Information" sections in Book projects
- Users redirected to start when adding/editing sections on Step 5
- Root cause: **Nested HTML forms** - browser spec forbids `<form>` inside `<form>`

#### Solution: Modal-Based Section Editing
Extracted section editing to a modal rendered OUTSIDE the main form.

#### Changes Made

**1. Modal State in stepped_form.ex**
- Added assigns: `show_section_modal`, `modal_section`, `modal_section_form`
- Updated `edit_section` to open modal instead of inline editing
- Added `close_section_modal` event handler
- Rendered modal AFTER main form closes (avoids nesting)

**2. New section_edit_modal Component**
- Created in `content_section_components.ex`
- DaisyUI modal with form (NOT nested)
- Supports all section types: book_info, code_block, rich_text, etc.

**3. Simplified content_section_card**
- Removed inline editing form
- Now only displays section content with edit/delete buttons

**4. Test Fixture Added**
- `content_section_fixture/3` in `media_fixtures.ex`

**5. Translation Added**
- "Edit Section" → "Muokkaa osiota" (Finnish)

#### Files Modified
- `lib/homesite_web/live/project_live/stepped_form.ex`
- `lib/homesite_web/components/content_section_components.ex`
- `test/support/fixtures/media_fixtures.ex`
- `priv/gettext/fi/LC_MESSAGES/default.po`

#### Test Results
- **1584 tests, 0 failures**

---

## 2025-12-18 - Project Content Sections & Template Enhancements

### Session Summary

#### Features Implemented

**1. Content Sections for Projects**
- Created `content_sections` table with JSONB metadata field
- Schema supports multiple section types: rich_text, code_block, book_info, chapter, gear_spec, movie_info
- Each section has: section_type, title, content, metadata, display_order
- Full CRUD operations with scope isolation

**2. Template-Specific Section Types**
- Photography: rich_text only (image-focused)
- Coding: code_block + rich_text (defaults: Overview, Key Code)
- Writing: chapter + rich_text (default: Chapter 1)
- Books: book_info + chapter + rich_text (defaults: Book Info, Summary, Review)
- Gears: gear_spec + rich_text (default: Specifications)
- Movies: movie_info + rich_text (default: Movie Info)
- Custom: all section types available

**3. Book Info Metadata**
- ISBN, Publisher, Author, Pages, Language
- Format (paperback, hardcover, ebook, audiobook)
- Edition, Publication Year
- Rating (1-5), Reading Status (want_to_read, reading, completed, dnf)
- Automatic integer normalization for pages/year/rating

**4. ContentSectionComponents Module**
- `content_section_card/1` - Main card with edit/delete controls
- Type-specific forms: book_info_form, code_block_form, rich_text_form, gear_spec_form, movie_info_form
- Type-specific displays with markdown rendering (MDEx)
- `add_section_dropdown/1` - Dropdown to add available section types

**5. Drag-and-Drop Section Reordering**
- New `SortableSections` JavaScript hook
- Drag handle on each section card
- Real-time reorder via `reorder_sections` event

**6. Step 5 Bug Fix**
- Fixed "Save & Add Content" button causing crash for non-photography templates
- Root cause: Button had both `type="submit"` and `phx-click`, sending empty params
- Solution: Use `name="action" value="save_and_add_content"` with pattern matching

#### Files Created
- `priv/repo/migrations/20251218063505_create_content_sections.exs`
- `lib/homesite/media/content_section.ex`
- `lib/homesite_web/components/content_section_components.ex`

#### Files Modified
- `lib/homesite/media.ex` - Added ContentSection CRUD functions
- `lib/homesite/media/project.ex` - Added content_sections association
- `lib/homesite/media/project_template.ex` - Added default_sections, available_section_types
- `lib/homesite_web/live/project_live/stepped_form.ex` - Integrated content sections UI
- `assets/js/hooks/sortable.js` - Added SortableSections hook
- `assets/js/app.js` - Registered SortableSections hook
- `test/homesite/media_test.exs` - Added 13 content section tests

#### Test Results
- **1584 tests, 0 failures**

---

## 2025-12-17 - Shared Tags, Portfolio Fixes, Media Upload Improvements

### Session Summary

#### Features Implemented

**1. Shared Tag System for Projects**
- Created `project_tags` join table migration
- Created `ProjectTag` schema (`lib/homesite/media/project_tag.ex`)
- Updated `Tag` schema with `many_to_many :projects` association
- Updated `Project` schema: replaced `field :tags, {:array, :string}` with proper association
- Added `put_tags/3` helper in Project changeset
- Step 5 (Content) with media picker implemented

**2. Portfolio Name/Slug Fixes**
- Fixed portfolio name update (was working, but slug was regenerating)
- Implemented slug preservation: existing slug kept when name updated for typo fixes
- Added `line-clamp-2` name truncation in portfolio index with `title` tooltip
- Created comprehensive portfolio tests (`test/homesite_web/live/portfolio_live_test.exs` - 12 tests)

**3. Media Upload Improvements**
- Added "Maximum 1000 characters" hint to project description field
- Increased upload limit from 5MB to 20MB
- Added auto-resize for images > 6000px dimensions before processing
- Redesigned upload preview UI with larger grid thumbnails and progress overlay
- Added Finnish translations for all new strings

**4. Compilation Warnings Fix**
- Fixed "Failed to find closing `<pre>`" warnings during compilation
- Root cause: NimblePublisher was running Earmark on body AFTER our custom MDEx parser
- Solution: Created `Homesite.DevFaqs.HtmlPassthrough` no-op converter
- Added `html_converter: Homesite.DevFaqs.HtmlPassthrough` to NimblePublisher config

**5. Test Fixes**
- Fixed FAQ test failures after portfolio FAQ migration (count mismatches)
- Updated tests to use `has_element?` instead of string matching for "Edit" assertions
- Added `Repo.delete_all(Faq)` in test setups to clear migration data

#### Files Created
- `priv/repo/migrations/20251217161052_create_project_tags.exs`
- `priv/repo/migrations/20251217172440_add_portfolio_faqs.exs`
- `lib/homesite/media/project_tag.ex`
- `lib/homesite/dev_faqs/html_passthrough.ex`
- `priv/dev_faqs/007-portfolio-projects.md`
- `test/homesite_web/live/portfolio_live_test.exs`

#### Files Modified
- `lib/homesite/content/tag.ex` - Added projects association
- `lib/homesite/media/project.ex` - Replaced tags field, slug preservation
- `lib/homesite/media/image_processor.ex` - 20MB limit, auto-resize large images
- `lib/homesite/dev_faqs.ex` - Added html_converter option
- `lib/homesite_web/live/media_live/index.ex` - Upload UI improvements
- `lib/homesite_web/live/portfolio_live/index.ex` - Name truncation
- `lib/homesite_web/live/project_live/stepped_form.ex` - Description hint
- `priv/gettext/fi/LC_MESSAGES/default.po` - Finnish translations

#### Test Results
- **1567 tests, 0 failures**

---

## 2025-12-17 (earlier) - Shared Tags for Projects & Debugging Notes

### Session: Implement unified tag system for Projects (same as Posts)

#### Features Implemented

**Shared Tag System:**
- Created `project_tags` join table migration
- Created `ProjectTag` schema (`lib/homesite/media/project_tag.ex`)
- Updated `Tag` schema with `many_to_many :projects` association
- Updated `Project` schema: replaced `field :tags, {:array, :string}` with proper association
- Added `put_tags/3` helper in Project changeset
- Updated `calculate_completion/2` to handle Tag structs

**SteppedForm Updates:**
- Added tag picker UI to Metadata step (Step 2)
- Tag search with suggestions
- Create new tags inline
- Step 5 (Content) with media picker already implemented

**Display Fixes:**
- `ProjectLive.Show`: Added `:tags` preload, display `tag.name`
- `PortfolioLive.Show`: Added `:tags` preload, display `tag.name`

#### Test Fixes
- Updated 3 tests using removed "Skip to Save" button to use new navigation flow

#### Debugging Note: Misleading FeedbackLive.PromptModal Error

**Symptom:** Error message says "cannot convert component HomesiteWeb.FeedbackLive.PromptModal to HTML"

**Actual Cause:** An earlier error in the LiveView (e.g., calling `length()` on unloaded association) triggers Phoenix error page rendering. The error layout includes a `live_component`, which can't render in error context.

**Pattern to recognize:** When you see live_component rendering errors in layouts, the root cause is often an earlier error that triggered error page rendering. Check the stacktrace for the original error.

**In this case:** `length(@project.tags)` was called on `#Ecto.Association.NotLoaded` because `:tags` wasn't in preloads.

**Prevention:** Always preload associations before using them in templates. Consider using `Ecto.assoc_loaded?/1` for defensive checks.

#### Files Created
- `priv/repo/migrations/20251217161052_create_project_tags.exs`
- `lib/homesite/media/project_tag.ex`

#### Files Modified
- `lib/homesite/content/tag.ex` - Added projects association
- `lib/homesite/media/project.ex` - Replaced tags field with association
- `lib/homesite_web/live/project_live/show.ex` - Added tags preload, fixed display
- `lib/homesite_web/live/portfolio_live/show.ex` - Added tags preload, fixed display
- `lib/homesite_web/live/project_live/stepped_form.ex` - Tag UI + Step 5
- `test/homesite_web/live/project_live_test.exs` - Updated navigation tests

#### Test Results
- **1555 tests, 0 failures**

---

## 2025-12-16 - Design System Migration & Playwright Verification

### Session: CSS design token migration and E2E test verification

**Design System Migration (98% complete)**

Migrated ~219 of ~223 hardcoded Tailwind spacing and typography values to CSS custom properties:

- `gap-N` → `gap-[var(--space-*)]`
- `mt-N`, `mb-N`, `px-N`, `py-N` → spacing tokens
- `text-sm`, `text-lg`, `text-xl` → `text-[var(--text-*)]`

**Token Mappings:**
- `--space-inline` (gap-1, mt-1)
- `--space-xs` (gap-2/3, mt-2, mb-2)
- `--space-sm` (gap-4, mt-4, px-4)
- `--space-md` (gap-6, mt-6, mb-6)
- `--space-lg` (gap-8, py-8)
- `--space-xl` (larger responsive values)

**Intentional Exceptions (4):**
- `focus:px-4`, `focus:py-2` - Accessibility skip-link (precise pixels)
- `lg:mx-0` - Responsive margin reset
- `scroll-mt-24` - Scroll anchor navigation offset

**Files Updated:** 33 files across components, live views, templates

**Playwright E2E Sandbox - Verified Working**

- SQL sandbox properly configured in `config/test.exs` and `endpoint.ex`
- 15 E2E tests passing (3 tag workflow + 12 accessibility)
- Run with: `mix test --include playwright`

**Commits:**
- `1ae1c32` - style: Design system migration - batch 3 spacing updates
- `facdf15` - style: Design system migration - complete spacing/typography

**Tests:** 1555 tests, 0 failures

---

## 2025-12-15 - New Machine Setup (Fedora Bluefin)

### Session: Project setup on new development machine

**Environment:**
- Fedora Bluefin (immutable Linux with Homebrew)
- PostgreSQL 18 via `brew services`
- Node.js installed for npm dependencies

**Setup Steps Completed:**
1. Installed Hex and Rebar: `mix local.hex --force && mix local.rebar --force`
2. Installed dependencies: `mix deps.get`
3. Created PostgreSQL role: `CREATE ROLE postgres WITH LOGIN SUPERUSER PASSWORD 'postgres'`
4. Created database and ran migrations (59 migrations)
5. Installed JS dependencies: `npm install` in assets directory
6. Created admin user: `admin@example.com` / `adminpassword123` (5 admin flowers)

**Tests:** 1549 tests (some connection pool timeouts with high concurrency - use `--max-cases 4` if needed)

**Known Issues:**
- GitHub CLI not accessible from this machine (network/firewall)

---

### 🔴 DATA MIGRATION REMINDER

**FAQ SQLs need to be exported from the other machine:**
- User FAQs (DevFaqs) - development documentation data
- Admin FAQs (Faqs) - bilingual FAQ content

**Future consideration:** Create SQL dump utilities for easier data portability between development machines.

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
- Playwright E2E sandbox configuration ✅ DONE (15 E2E tests passing)

---
