---
title: "Recent Features & Updates"
order: 6
category: "features"
---

# Recent Features & Updates

## December 2025

### User Profile & Dashboard Enhancements

**Username Routing System** ✅
- Optional @username URLs (e.g., `/users/@johndoe`)
- Claim your username in Settings
- Profile accessible via username or numeric ID
- Reserved usernames protected (admin, api, system, etc.)
- RSS/Atom/JSON feeds work with usernames

**Dashboard Improvements** ✅
- **Profile Stats Card**: Published posts, total views, subscribers
- **Feed Analytics**: Unread count, read today/week, top sources
- **Profile URL**: Copy link, view public profile, share buttons
- **Username Celebration Modal**: Shows when username is claimed

**Profile Page Enhancements** ✅
- Stats section: Posts count, avg read time, member since
- Subscribe section: RSS/Atom/JSON feed links with copy buttons
- Share functionality: Web Share API + clipboard fallback

### External Feeds System (Phases 1-5)

**Phase 1: Unified Feed View with Read Tracking** ✅
- Chronological feed at `/feed`
- Read/unread visual indicators
- Bookmark actions
- Infinite scroll pagination
- Platform-specific rendering (YouTube thumbnails, Bluesky avatars)

**Phase 2: Folder Organization** ✅
- Create folders for organizing feeds
- Custom icons and colors
- Drag-and-drop assignment (future UI)
- Filter feed by folder

**Phase 3: New Platform Adapters** ✅
- Reddit adapter (subreddits + user feeds)
- TikTok adapter (via RSS bridges)
- Twitter/Nitter configuration (dormant but ready)

**Phase 4: Performance Optimizations** ✅
- Database indexes for feed queries
- Pagination optimization
- Cleanup worker for old items

**Phase 5: Integration Features** ✅
- Timeline view (unified blog posts + feed items)
- OPML import/export
- Analytics dashboard (engagement metrics, top sources)

### Search System

**Unified Search** ✅
- Search across Posts, Tags, and FAQs simultaneously
- PostgreSQL pg_trgm fuzzy matching
- Parallel execution for performance
- Bilingual FAQ search (English/Finnish)
- Relevance-based ordering
- Categorized results with counts

**Search Analytics** ✅
- Track all queries with performance metrics
- Popular searches dashboard
- Zero-result queries (identify content gaps)
- Average search duration tracking

### SEO & Accessibility

**SEO Improvements** ✅
- Dynamic sitemap.xml generation
- JSON-LD structured data (BlogPosting, FAQPage, Organization)
- Breadcrumbs schema
- Meta tags optimization

**WCAG AA Compliance** ✅
- Fixed landmark structure (proper main, nav, header)
- Heading hierarchy (H1 → H2 → H3)
- Button accessibility (aria-labels on icon buttons)
- Color contrast improvements (13.8:1 light, 12.4:1 dark)
- 10 comprehensive accessibility tests

### FAQ System

**User FAQs** ✅
- Bilingual support (English/Finnish)
- Public viewing (no authentication)
- Admin-only CRUD operations
- Active/inactive toggle
- Display ordering
- 7 sample FAQs covering major features

**Admin FAQs** ✅
- Separate admin-only category
- Same bilingual structure
- Access restricted to admin role

### Theme System

**DaisyUI Theme Overhaul** ✅
- 5 professional themes: light, dark, business, corporate, cyberpunk
- Dropdown theme switcher (replaced 3-button toggle)
- Removed 225 lines of custom CSS variable mappings
- Pure DaisyUI with proper dark mode support
- System preference detection (`prefers-color-scheme`)

**Dark Mode Fixes** ✅
- Converted hardcoded Tailwind colors to DaisyUI theme colors
- Feed pages now respect theme selection
- Form inputs and code blocks contrast fixed

## November 2025

### Core Features

**Blog Post System** ✅
- Markdown support with syntax highlighting
- Tags and categories
- Draft/published status
- Read time calculation
- Slug auto-generation
- Social sharing buttons

**Authentication** ✅
- Password-based and magic-link login
- Invitation system (controlled registration)
- Admin vs user roles
- Session management
- CSRF protection

**Feed System** ✅
- RSS, Atom, and JSON feeds
- Per-user feeds (`/users/@username/feed.rss`)
- Auto-discovery links
- Valid XML generation

## Testing Infrastructure

### Current Test Count: 704 tests

**Test Categories:**
- Content tests: 106 tests (posts, tags)
- Feed tests: 106 tests (adapters, interactions, folders)
- Search tests: 48 tests (unified search, fuzzy matching)
- FAQ tests: 17 tests (bilingual, CRUD)
- Accessibility tests: 10 tests (WCAG AA compliance)
- Security tests: Scope isolation across all contexts

### Running Tests

```bash
# All tests
mix test

# Specific category
mix test test/homesite/external_feeds_test.exs

# With Playwright E2E
mix test --include playwright

# Full suite with Credo
mix test.all
```

## Performance Metrics

### Database
- PostgreSQL with proper indexes
- Ecto query optimization
- Sandbox isolation in tests
- Migration rollback support

### Frontend
- Tailwind CSS v4 build: 87-91ms
- esbuild: 9-10ms
- LiveView for real-time updates
- Infinite scroll pagination

## Security Features

### Rate Limiting (Hammer)
- Login: 5 attempts/min per IP
- Registration: 3 attempts/hour per IP
- ETS backend with 4-hour expiry
- 10-minute cleanup intervals

### Security Scanning
```bash
# Static security analysis
mix sobelow --config

# Dependency vulnerability scan
mix deps.audit
```

### Scope Isolation
- All context functions enforce user boundaries
- Pattern matching: `true = record.user_id == scope.user.id`
- Raises `MatchError` on unauthorized access
- 100% test coverage for scope violations

## Admin Features

### Admin Dashboard (`/admin`)
- Real-time analytics overview
- Search metrics (7-day totals, avg duration)
- Popular searches table
- No-result searches (content gaps)
- Recent activity log

### Admin Authorization
- Reusable `:require_admin` on_mount hook
- Used in FAQ management, admin dashboard
- Raises `NotAuthorizedError` for non-admins

## JavaScript Enhancements

### Custom Hooks
- `TableOfContents` - Active section tracking with Intersection Observer
- `LocalTime` - Client-side date formatting
- `AvatarPreview` - Live avatar upload preview
- `AutoDismissFlash` - Auto-dismiss flash messages (10s)
- `CopyToClipboard` - Generic clipboard operations
- `Share` - Web Share API with fallback
- `WebShareApi` - Platform share tracking

## Documentation

### Available Docs
- `CLAUDE.md` - Project guidelines and commands
- `AGENTS.md` - Phoenix/LiveView patterns and best practices
- `ACCESSIBILITY.md` - WCAG compliance guide (future)
- `EXTERNAL_FEEDS.md` - Feed system documentation
- `REGISTRATION_STRATEGY.md` - Auth system docs
- `USERNAME_ROUTING.md` - Username system docs (future)
- Design system: `/dev/design-system` (future skill)

### Dev FAQs (this page)
- Only available in development environment
- Markdown-based with compile-time parsing
- Syntax highlighting for code examples
- Category filtering

## Deployment

### Production Guides
- `TAILSCALE_DEPLOYMENT.md` - Manual Docker + Tailscale
- `COOLIFY_TAILSCALE_DEPLOYMENT.md` - Recommended Coolify approach
- Both guides include complete checklists
- Cost: $60-115/year (domain + electricity)

## What's Next?

### Planned Features
- Email notifications for new posts (#13)
- Short texts system/messages/feed (#4)
- Image gallery/media context (#2)
- Timeline view (posts + feed items)
- Full-text search with highlighting
- Feed refresh scheduling UI

### Deferred/Future
- Monetization strategy (#30)
- Mobile app (LiveView Native)
- Collaborative posting
- Advanced analytics
