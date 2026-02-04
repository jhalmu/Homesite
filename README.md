# Homesite

A modern multi-user blog platform built with Phoenix LiveView and Elixir.

## Features

- **Blogging** - Markdown posts, tags, drafts, SEO optimization, read time estimates
- **Auth** - Password + magic links, invitation-only registration, Cloudflare Turnstile
- **Portfolio** - Project galleries with lightbox, social sharing
- **Feeds** - RSS/Atom/JSON output, external feed aggregation (Mastodon, Bluesky, YouTube, Reddit)
- **Chat** - Real-time IRC-style messaging
- **Search** - Full-text fuzzy search across posts, tags, FAQs (pg_trgm)
- **i18n** - English and Finnish with bilingual FAQ system
- **Admin** - Dashboard, user management (ban/suspend/delete), flower-based permissions

## Tech Stack

- **Phoenix 1.8** / **LiveView 1.1** / **Elixir 1.18**
- **PostgreSQL** / **Ecto 3.13**
- **Tailwind CSS v4** / **DaisyUI 5**
- **Oban** (background jobs) / **Swoosh** (email)
- **Playwright** (E2E testing) / **axe-core** (accessibility)

## Quick Start

```bash
# Setup and start
mix setup
mix phx.server
```

Visit http://localhost:4000

**Test login:** `user@example.com` / `testpassword123`

## Commands

```bash
mix test           # Run tests (1705 tests)
mix test.all       # Full suite (format + compile + test + credo)
mix format         # Format code
mix credo --strict # Static analysis
mix sobelow        # Security scanning
```

## Project Structure

```
lib/
  homesite/          # Business logic (contexts)
    accounts/        # Users, auth, invitations, permissions
    content/         # Posts, tags
    moderation/      # Bans, suspensions
    faqs/            # Bilingual FAQ system
    external_feeds/  # Feed aggregation
  homesite_web/      # Web layer
    live/            # LiveView modules
      admin_live/    # Admin interfaces
    components/      # UI components
    plugs/           # Request processing
assets/css/tokens/   # Design system (spacing, typography)
priv/
  dev_faqs/          # Developer documentation (markdown)
  repo/seeds/        # Database seeds including FAQs
```

## Permission System

Two-tier access control:

| Level | Role | Flowers | Access |
|-------|------|---------|--------|
| User | user | - | Read/write own content |
| Admin L1 | admin | 🌸 | View dashboard |
| Admin L2 | admin | 🌸🌸 | Manage FAQs |
| Admin L3 | admin | 🌸🌸🌸 | User management |
| Admin L4 | admin | 🌸🌸🌸🌸 | Promote admins |
| Admin L5 | admin | 🌸🌸🌸🌸🌸 | Full access |

## Documentation

- **[CLAUDE.md](CLAUDE.md)** - Project guidelines and commands
- **[AGENTS.md](AGENTS.md)** - Coding patterns and best practices
- **[DESIGN_SYSTEM_GUIDE.md](DESIGN_SYSTEM_GUIDE.md)** - CSS design tokens
- **[MEMO.md](MEMO.md)** - Session notes
- **/dev/faqs** - Developer FAQs (dev environment only)
- **/faq** - User FAQs (public)

## Testing

```bash
# Unit & integration tests
mix test                    # 1705 tests

# E2E tests with Playwright
mix test --include playwright

# Full pre-commit check
mix test.all

# Accessibility audit
npx playwright test --project=chromium accessibility
```

## Deployment

Docker-based deployment to VPS with Caddy reverse proxy.

```bash
# Production build
docker compose build app
docker compose up -d
```

See `COOLIFY_TAILSCALE_DEPLOYMENT.md` for recommended deployment approach.

## License

MIT

---

Built with Elixir and Phoenix
