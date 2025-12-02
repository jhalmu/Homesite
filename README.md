# Homesite

> A modern, multi-user blog platform built with Phoenix LiveView and Elixir

**Homesite** is a scope-based multi-tenant blogging platform designed for personal websites and small communities. Each user has their own isolated space for creating blog posts, managing tags, and customizing their profile.

## ✨ Features

### Core Blogging
- ✅ **Rich Blog Posts** - Markdown rendering with MDEx
- ✅ **Tag System** - Organize posts with tags, tag-based filtering
- ✅ **Draft & Publish** - Save drafts, publish when ready
- ✅ **User Profiles** - Display name, avatar, bio, social handles
- ✅ **SEO Optimized** - Open Graph, Twitter Cards, meta tags

### Authentication & Security
- ✅ **Passwordless Auth** - Magic link authentication (primary)
- ✅ **Password Auth** - Argon2-secured passwords (fallback)
- ✅ **Invitation System** - Admin-controlled registration with invite codes
- ✅ **Rate Limiting** - Hammer-based protection (5 login, 3 registration per hour)
- ✅ **Scope Isolation** - Multi-tenancy with strict user data separation
- ✅ **CSRF Protection** - Built-in Phoenix security
- ✅ **Security Tested** - 23 invitation tests + comprehensive security suite

### Admin Features
- ✅ **Admin Dashboard** - Flower-based permission system (0-5 levels)
- ✅ **User Management** - View users, edit roles, manage permissions
- ✅ **Invitation Management** - Create/delete invite codes, track usage
- ✅ **Analytics** - User stats, content metrics (planned)

### Feeds & Syndication
- ✅ **RSS Feeds** - Site-wide, per-user, per-tag
- ✅ **Atom Feeds** - Standards-compliant syndication
- ✅ **JSON Feed** - Modern feed format
- ✅ **Autodiscovery** - Automatic feed detection
- ✅ **External Feed Adapters** - Aggregate from Mastodon, Bluesky, YouTube, RSS
- ✅ **Username Routing** - Custom @username URLs for profiles and feeds

### Internationalization
- ✅ **Multi-language** - English and Finnish support
- ✅ **Gettext Integration** - Easy translation management
- ✅ **User Preferences** - Per-user language selection

### Developer Experience
- ✅ **584 Tests** - All passing (ExUnit + Phoenix.LiveViewTest)
- ✅ **Playwright E2E** - End-to-end testing foundation
- ✅ **Credo** - Code quality analysis
- ✅ **Sobelow** - Security scanning
- ✅ **Format** - Consistent code formatting
- ✅ **Comprehensive Docs** - CLAUDE.md, AGENTS.md, guides

## 🚀 Technology Stack

### Core Framework
- **Phoenix 1.8.1** - Web framework
- **LiveView 1.1.0** - Real-time, server-rendered UI
- **Elixir ~> 1.14** - Functional programming language
- **PostgreSQL** - Primary database
- **Ecto 3.13** - Database wrapper and query language

### Frontend
- **Tailwind CSS v4** - Utility-first CSS (no config file)
- **DaisyUI** - Component library
- **esbuild** - JavaScript bundling
- **Phoenix SEO** - SEO and Open Graph tags

### Authentication & Security
- **Argon2** - Password hashing
- **Hammer** - Rate limiting with ETS backend
- **Swoosh** - Email delivery (magic links)
- **Sobelow** - Security analysis

### Content & Feeds
- **MDEx** - Markdown rendering
- **Atomex** - Atom feed generation
- **Floki** - HTML parsing and sanitization
- **Nimble Publisher** - Content publishing

### Testing & Development
- **ExUnit** - Unit and integration testing
- **Phoenix.LiveViewTest** - LiveView testing
- **Phoenix.Test.Playwright** - E2E browser testing
- **Credo** - Static analysis
- **mix_audit** - Dependency vulnerability scanning

## 📋 Prerequisites

- **Elixir** 1.14 or higher
- **Erlang/OTP** 25 or higher
- **PostgreSQL** 14 or higher
- **Node.js** 18 or higher (for asset compilation)

## 🏁 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/jhalmu/Homesite.git
cd homesite
```

### 2. Install Dependencies & Setup Database

```bash
mix setup
```

This single command will:
- Install Elixir dependencies
- Install Node.js dependencies for assets
- Create the database
- Run migrations
- Seed test data (5 test users)

### 3. Start the Server

```bash
mix phx.server
```

Or run inside IEx for interactive development:

```bash
iex -S mix phx.server
```

### 4. Visit the Application

Open your browser to: **http://localhost:4000**

### 5. Login with Test Users

Test users are created automatically with different permission levels:

| Email | Password | Role | Flowers | Permissions |
|-------|----------|------|---------|-------------|
| `user@example.com` | `testpassword123` | user | 0 | Regular user |
| `admin1@example.com` | `testpassword123` | admin | 🌸 | Basic admin |
| `admin2@example.com` | `testpassword123` | admin | 🌸🌸 | Content mod |
| `admin3@example.com` | `testpassword123` | admin | 🌸🌸🌸 | User mgmt |
| `admin5@example.com` | `testpassword123` | admin | 🌸🌸🌸🌸🌸 | Full admin |

## 🔧 Development Commands

### Running Tests

```bash
# Run all tests
mix test

# Run only failed tests
mix test --failed

# Run with Playwright E2E tests (optional)
mix test --include playwright

# Run full test suite (format + compile + test + credo)
mix test.all
```

### Code Quality

```bash
# Format code
mix format

# Run static analysis
mix credo --strict

# Security scanning
mix sobelow
mix deps.audit

# Pre-commit checks (compile with warnings as errors, format, test)
mix precommit
```

### Database

```bash
# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Reset database (drop, create, migrate, seed)
mix ecto.reset

# Generate migration
mix ecto.gen.migration migration_name

# Rollback last migration
mix ecto.rollback
```

### Assets

```bash
# Build assets (development)
mix assets.build

# Deploy assets (minified for production)
mix assets.deploy
```

### Seeds

```bash
# Create test users (if not already created)
mix seed_users

# Create admin user
mix seed_admin
```

### Email Preview (Development)

View sent emails at: **http://localhost:4000/dev/mailbox**

## 🏗️ Architecture Overview

### Scope-Based Multi-Tenancy

Homesite uses a **scope pattern** for data isolation:

```elixir
# All context functions require a scope as the first argument
Content.list_posts(scope)
Content.get_post!(scope, id)
Content.create_post(scope, attrs)
```

**Key Points:**
- Every user has an isolated data space
- Scope is automatically enforced in all queries
- Security pattern: `true = record.user_id == scope.user.id`
- Access user in templates: `@current_scope.user` (NOT `@current_user`)

### Context Boundaries

1. **Homesite.Accounts** - User management, authentication, invitations
2. **Homesite.Content** - Blog posts, tags, publishing
3. **Homesite.Feeds** - External feed aggregation (planned)

### LiveView Architecture

All interactive pages use Phoenix LiveView:

- **PostLive** - Post management (index, show, form)
- **TagLive** - Tag management
- **UserLive** - Settings, login, registration
- **AdminLive** - Admin dashboard, user management, invitations
- **DashboardLive** - User dashboard

### Database Schema

**Core Tables:**
- `users` - User accounts and profiles
- `posts` - Blog posts (belongs to user)
- `tags` - Tags (belongs to user)
- `post_tags` - Many-to-many join table
- `invitations` - Invite codes for registration

**See:** `priv/repo/migrations/` for full schema

## 🔒 Security Features

### Built-in Protections
- ✅ **Scope isolation** - Enforced at context level
- ✅ **CSRF protection** - Phoenix built-in
- ✅ **XSS prevention** - Automatic HTML escaping
- ✅ **Content-Security-Policy** - Restricts resource loading
- ✅ **Argon2 hashing** - Secure password storage
- ✅ **Rate limiting** - Login (5/min), Registration (3/hr)
- ✅ **Security headers** - `put_secure_browser_headers`

### Security Testing
```bash
# Run security scanner
mix sobelow --config

# Check for vulnerable dependencies
mix deps.audit

# Run security-specific tests
mix test test/homesite_web/security_test.exs
```

### Best Practices
1. Never skip scope checks in context functions
2. Always write security tests for new features
3. Rate limit authentication endpoints
4. Validate all user input at schema level
5. Keep dependencies updated
6. Review Sobelow warnings

## 📚 Documentation

Comprehensive documentation is available in the repository:

### User Guides
- **[Social Media Feed Adapters](docs/guides/SOCIAL_MEDIA_FEEDS.md)** - How to aggregate external feeds
- **[Username Routing System](docs/guides/USERNAME_ROUTING.md)** - Custom @username URLs guide
- **[Documentation Index](docs/README.md)** - Complete guide directory

### Developer Documentation
- **[CLAUDE.md](CLAUDE.md)** - Project guidelines for Claude Code
- **[AGENTS.md](AGENTS.md)** - Phoenix/LiveView/Elixir patterns
- **[REGISTRATION_STRATEGY.md](REGISTRATION_STRATEGY.md)** - Auth system documentation
- **[FEEDS.md](FEEDS.md)** - RSS/Atom/JSON feeds guide
- **[MODERN_CSS_GUIDE.md](MODERN_CSS_GUIDE.md)** - CSS patterns and responsive design
- **[EXTERNAL_FEEDS_PLAN.md](EXTERNAL_FEEDS_PLAN.md)** - External feed integration plan
- **[MEMO.md](MEMO.md)** - Session notes and historical context

## 🧪 Testing

### Test Suite Overview

- **584 ExUnit tests** - All passing
- **23 Invitation tests** - Full coverage of invite system
- **Security tests** - Scope isolation, authorization
- **LiveView tests** - User interactions, form submissions
- **Context tests** - Business logic validation

### Running Tests

```bash
# Quick test run
mix test

# Full suite with quality checks
mix test.all

# Specific test file
mix test test/homesite/accounts_test.exs

# Specific test by line number
mix test test/homesite/accounts_test.exs:123

# E2E tests (requires Playwright setup)
mix test --include playwright
```

### Test Coverage

- ✅ User authentication (passwordless + password)
- ✅ Invitation system (create, validate, use)
- ✅ Post CRUD operations
- ✅ Tag management
- ✅ Scope isolation
- ✅ Security boundaries
- ✅ Feed generation

## 🌐 Deployment

### Environment Variables

```bash
# Production configuration
export SECRET_KEY_BASE="..." # Generate with: mix phx.gen.secret
export DATABASE_URL="postgresql://user:pass@host/dbname"
export PHX_HOST="yourdomain.com"

# Email configuration (choose one adapter)
export POSTMARK_API_KEY="..."  # For Postmark
export SENDGRID_API_KEY="..."  # For SendGrid
export MAILGUN_API_KEY="..."   # For Mailgun
export MAILGUN_DOMAIN="..."
```

### Database Migrations

```bash
# Run migrations in production
mix ecto.migrate
```

### Asset Compilation

```bash
# Build and digest assets for production
mix assets.deploy
```

### Deployment Platforms

Homesite can be deployed to:
- **Fly.io** - Recommended for Elixir apps
- **Gigalixir** - Elixir-specific platform
- **Heroku** - With Elixir buildpack
- **Docker** - Containerized deployment
- **VPS** - Ubuntu/Debian with systemd

See: [Phoenix Deployment Guide](https://hexdocs.pm/phoenix/deployment.html)

## 🤝 Contributing

This is a personal project, but contributions are welcome!

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`mix test.all`)
5. Format code (`mix format`)
6. Commit changes (`git commit -m 'Add amazing feature'`)
7. Push to branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Code Style

- Follow Elixir style guide
- Run `mix format` before committing
- Keep Credo warnings to minimum
- Write tests for new features
- Document complex logic

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Phoenix Framework** - Productive web framework
- **Elixir** - Beautiful functional language
- **Tailwind CSS** - Utility-first CSS framework
- **DaisyUI** - Component library
- **Claude Code** - AI-assisted development

## 📞 Support

- **Issues:** https://github.com/jhalmu/Homesite/issues
- **Discussions:** https://github.com/jhalmu/Homesite/discussions

## 🗺️ Roadmap

### Completed ✅
- Multi-user blogging with scope isolation
- Invitation-only registration
- Admin dashboard with flower permissions
- RSS/Atom/JSON feeds
- Internationalization (EN/FI)
- External feed aggregation (#29) - Mastodon, Bluesky, YouTube, RSS
- Username routing system - Custom @username URLs

### In Progress 🚧
- User management UI (#10)
- Dashboard activity feed (#6)
- Playwright E2E test expansion (#27)

### Planned 📋
- Search functionality (#11)
- Analytics dashboard (#14)
- Email notifications (#13)
- Image gallery (#2)
- Social sharing system (#5)

---

**Built with ❤️ using Elixir and Phoenix**
