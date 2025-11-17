# Homesite - Modern Phoenix LiveView Multi-Tenant CMS

A comprehensive content management system built with Phoenix 1.8.1+, LiveView 1.1+, and PostgreSQL 17.

## 🚀 Features

### Phase 1A: Foundation (Completed ✅)
- **Phoenix 1.8.1+** with **LiveView 1.1.17**
- **PostgreSQL 17** database with binary image storage
- **Tailwind 4.1.7** + **DaisyUI** for styling
- **Multi-lingual** support (Finnish primary, English)
- **User Authentication** with `phx.gen.auth`
- **Teams/Organizations** with multi-membership
- **Polymorphic Tags** system
- **Admin Dashboard** (Finnish UI)

### Phase 1B: Content System (In Progress 🚧)
- ✅ **Blog System** - Schema and migrations complete
- 🔄 **Image Gallery** - Planned
- 🔄 **Short Texts** - Planned
- 🔄 **Social Sharing** - Planned

## 📋 Tech Stack

- **Framework:** Phoenix 1.8.1+
- **LiveView:** 1.1.17+
- **Database:** PostgreSQL 17
- **UI:** Tailwind 4.1.7 + DaisyUI
- **Web Server:** Bandit
- **I18n:** Gettext (Finnish/English)

## 🗄️ Database Schema

### Users & Teams
```
users (extended)
├── avatar (binary)
├── bio_fi, bio_en (text)
├── role (user/curator/admin)
└── public_profile (boolean)

teams
├── name, slug
├── avatar (binary)
├── description_fi, description_en
└── settings (jsonb)

team_memberships (many-to-many)
├── user_id → users
├── team_id → teams
└── role (member/curator/admin)

team_invitations
├── team_id → teams
├── email, token
├── invited_by_id → users
└── expires_at
```

### Content
```
blog_posts
├── title_fi, title_en
├── content_fi, content_en
├── slug (auto-generated from Finnish title)
├── author_type, author_id (polymorphic: user OR team)
├── created_by_id → users (curator tracking)
├── curator_added (boolean)
├── status (draft/published)
├── published_at
└── metadata (jsonb)
```

### Tags (Polymorphic)
```
tags
├── name_fi, name_en
└── slug

taggings (polymorphic join)
├── tag_id → tags
├── taggable_type (blog_post/image/collection/thing)
└── taggable_id
```

## 🎨 Key Features Implemented

### 1. Polymorphic Associations
Content (blogs, images, collections) can be owned by either **users** or **teams**:
```elixir
author_type: "user" | "team"
author_id: references
```

### 2. Curator System
Track who created content vs. who owns it:
```elixir
created_by_id: user who uploaded
author_id: actual owner (can be different)
curator_added: true if curator assigned it
```

### 3. Multi-lingual Content
Finnish primary, English secondary:
```elixir
title_fi: "Otsikko"    # Required
title_en: "Title"      # Optional
content_fi: "..."      # Required
content_en: "..."      # Optional
```

### 4. Auto-Slugification
Finnish characters handled properly:
```elixir
"Käyttäjän Opas" → "kayttajan-opas"
"Blogi: Uutiset" → "blogi-uutiset"
```

## 🔐 Authentication & Permissions

### User Roles
- **user** - Regular user
- **curator** - Can create content for others
- **admin** - Full system access

### Team Roles
- **member** - Can view team content
- **curator** - Can manage team content
- **admin** - Full team management

### Routes (per AGENTS.md)
```elixir
# Public (`:current_user` scope)
GET  /                      # Home page
GET  /blogit/:slug         # View blog post

# Authenticated (`:require_authenticated_user` scope)
GET  /dashboard            # Admin dashboard
GET  /users/settings       # User settings
```

## 🚀 Getting Started

### Prerequisites
- Elixir 1.15+
- Erlang 26+
- PostgreSQL 17
- Node.js (for assets)

### Installation
```bash
# Clone the repository
git clone https://github.com/jhalmu/Homesite.git
cd Homesite

# Install dependencies
mix setup

# Create database and run migrations
mix ecto.setup

# Start the server
mix phx.server
```

Visit `http://localhost:4000`

### Default Accounts
Register at `/users/register`

## 📁 Project Structure

```
lib/
├── homesite/
│   ├── accounts/          # User authentication
│   │   ├── user.ex
│   │   ├── user_token.ex
│   │   └── scope.ex
│   ├── teams/             # Teams & memberships
│   │   ├── team.ex
│   │   ├── team_membership.ex
│   │   └── team_invitation.ex
│   ├── tags/              # Polymorphic tagging
│   │   ├── tag.ex
│   │   └── tagging.ex
│   └── content/           # Content management
│       └── blog_post.ex
└── homesite_web/
    ├── live/
    │   └── admin/
    │       └── dashboard_live.ex
    └── controllers/
        └── user_*.ex     # Auth controllers
```

## 🌍 Internationalization

### Supported Languages
- **Finnish** (fi) - Primary
- **English** (en) - Secondary

### Adding New Languages
1. Create locale directory:
   ```bash
   mkdir -p priv/gettext/sv/LC_MESSAGES
   ```

2. Copy and translate:
   ```bash
   cp priv/gettext/fi/LC_MESSAGES/errors.po priv/gettext/sv/LC_MESSAGES/
   ```

3. Update config:
   ```elixir
   config :homesite, HomesiteWeb.Gettext,
     locales: ~w(fi en sv)
   ```

## 🧪 Testing

```bash
# Run all tests
mix test

# Run specific test
mix test test/homesite/content_test.exs

# Run with coverage
mix test --cover
```

## 📝 Development Commands

```bash
# Database
mix ecto.create           # Create database
mix ecto.migrate          # Run migrations
mix ecto.rollback         # Rollback last migration
mix ecto.reset            # Drop, create, migrate

# Server
mix phx.server            # Start server
iex -S mix phx.server     # Start with IEx

# Code Quality
mix format                # Format code
mix compile --warnings-as-errors
```

## 🎯 Roadmap

### Phase 1B (Next)
- [ ] Blog Admin LiveView (list, create, edit)
- [ ] Blog Editor with Finnish/English tabs
- [ ] Public blog viewing pages
- [ ] Image Gallery with collections
- [ ] Image optimization & variants
- [ ] Short Texts/Messages (realtime)
- [ ] Social sharing & tracking

### Phase 2 (Future)
- [ ] Things marketplace
- [ ] Advanced search
- [ ] Comments system
- [ ] Activity feeds
- [ ] Email notifications
- [ ] API endpoints

## 📊 GitHub Issues

Track development progress:
- [#1 Blog System](https://github.com/jhalmu/Homesite/issues/1)
- [#2 Image Gallery](https://github.com/jhalmu/Homesite/issues/2)
- [#3 Admin Dashboard](https://github.com/jhalmu/Homesite/issues/3) ✅
- [#4 Short Texts](https://github.com/jhalmu/Homesite/issues/4)
- [#5 Social Sharing](https://github.com/jhalmu/Homesite/issues/5)

## 🤝 Contributing

This is a personal project, but suggestions and feedback are welcome via GitHub Issues.

## 📄 License

Copyright © 2024

## 🙏 Acknowledgments

Built with:
- [Phoenix Framework](https://phoenixframework.org)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)
- [DaisyUI](https://daisyui.com)
- [Tailwind CSS](https://tailwindcss.com)

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
