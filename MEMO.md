# MEMO.md

Session notes and progress tracking for the Homesite project.

**Archives:**
- Entries Nov 21 - Dec 7, 2025 → `archived_docs/MEMO_ARCHIVE_2025-12-07.md`

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
