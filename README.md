# Homesite

A modern multi-user blog platform built with Phoenix LiveView and Elixir.

## Features

- **Blogging** - Markdown posts, tags, drafts, SEO optimization
- **Auth** - Passwordless magic links, invitation-only registration
- **Portfolio** - Project galleries with lightbox, social sharing
- **Feeds** - RSS/Atom/JSON, external feed aggregation (Mastodon, Bluesky, YouTube)
- **Chat** - Real-time IRC-style messaging
- **Search** - Full-text search across posts, tags, FAQs
- **i18n** - English and Finnish
- **Admin** - Dashboard, user management, analytics

## Tech Stack

- **Phoenix 1.8** / **LiveView 1.1** / **Elixir**
- **PostgreSQL** / **Ecto 3.13**
- **Tailwind CSS v4** / **DaisyUI**
- **Oban** (background jobs) / **Swoosh** (email)

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
mix test           # Run tests
mix test.all       # Full suite (format + compile + test + credo)
mix format         # Format code
mix credo --strict # Static analysis
```

## Project Structure

```
lib/
  homesite/          # Business logic (contexts)
    accounts/        # Users, auth, invitations
    content/         # Posts, tags
    chat/            # Real-time chat
    faqs/            # FAQ system
  homesite_web/      # Web layer
    live/            # LiveView modules
    components/      # UI components
assets/css/tokens/   # Design system (spacing, typography)
```

## Documentation

- **[CLAUDE.md](CLAUDE.md)** - Project guidelines
- **[AGENTS.md](AGENTS.md)** - Coding patterns
- **[DESIGN_SYSTEM_GUIDE.md](DESIGN_SYSTEM_GUIDE.md)** - CSS design tokens
- **[MEMO.md](MEMO.md)** - Session notes

## Deployment

Docker-based deployment to VPS with Caddy reverse proxy.

```bash
# Production
docker compose build app
docker compose up -d
```

## License

MIT

---

Built with Elixir and Phoenix
