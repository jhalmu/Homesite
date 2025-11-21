# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Information Sources Priority

**CRITICAL**: When working in this codebase, consult information sources in this order:

1. **AGENTS.md** - Primary source for project guidelines, patterns, and best practices
2. **Context7 MCP** - For up-to-date library documentation (use `mcp__context7__*` tools)
3. **Internet search** - Only after consulting the above sources

Always check AGENTS.md first for project-specific patterns before making architectural decisions.

## Git & GitHub Workflow

**CRITICAL**: Follow this workflow when working on the codebase:

### When to Commit & Push
1. **Before major changes** - Always commit and push current work before starting significant refactoring or new features
2. **When context is filling** - Monitor token usage and commit/push when context approaches limits
3. **Before ending session** - Always update MEMO.md (see below) and push to GitHub

### GitHub Issues for Task Management
- **Use GitHub Issues** to track what has been done and what needs to be done
- Create issues for:
  - Completed work (close immediately with summary)
  - Planned features and improvements
  - Known bugs or technical debt
- Reference issue numbers in commit messages: `git commit -m "Fix user scope issue #123"`

### MEMO.md Protocol
**Before ending any coding session**, update `MEMO.md`:
- Add datetime stamp for each entry (use ISO 8601 format: `2025-11-21 14:30:00`)
- Summarize what was accomplished
- Note any pending tasks or decisions needed
- Document any blockers or issues encountered
- Provide context for next session

### Repository Management
- **Old commits can be overwritten for now** (force push is acceptable during development)
- Use `git add .` carefully - review changes before committing
- Write descriptive commit messages following the project's style

## Essential Commands

### Development
- **Setup:** `mix setup` (installs deps, creates DB, runs migrations, sets up assets)
- **Start server:** `mix phx.server` or `iex -S mix phx.server` (visit http://localhost:4000)
- **Test:** `mix test` (runs all tests)
- **Test specific file:** `mix test test/path/to/test.exs`
- **Test specific line:** `mix test test/path/to/test.exs:123`
- **Format code:** `mix format`
- **Pre-commit check:** `mix precommit` (compile with warnings as errors, format, run tests)

### Database
- **Create DB:** `mix ecto.create`
- **Run migrations:** `mix ecto.migrate`
- **Reset DB:** `mix ecto.reset`
- **Generate migration:** `mix ecto.gen.migration migration_name`

### Assets
- **Build assets:** `mix assets.build`
- **Deploy assets:** `mix assets.deploy` (minified for production)

### Documentation & Search
- **Search docs:** `mix usage_rules.search_docs "query"` or `mix usage_rules.search_docs "query" -p package_name`
- **View module docs:** `mix usage_rules.docs ModuleName` or `mix usage_rules.docs ModuleName.function`

## Architecture Overview

### Technology Stack
- **Phoenix 1.8.1** with LiveView 1.1.0
- **Ecto 3.13** with PostgreSQL
- **Argon2** for password hashing
- **Tailwind CSS v4** for styling (uses new `@import` syntax in app.css, no config file)
- **DaisyUI** for UI components
- **esbuild** for JavaScript bundling
- **Phoenix SEO** for SEO/Open Graph tags

### Key Dependencies
- `nimble_publisher` - Content publishing
- `mdex` - Markdown processing
- `atomex` - Atom feed generation
- `yaml_elixir` - YAML parsing
- `phoenix_test` + `phoenix_test_playwright` - Testing with Playwright
- `req` - HTTP client (preferred over httpoison/tesla)
- `credo` - Code analysis
- `tidewave` - Dev tools

### Core Architecture

This is a **scoped multi-user blog application** with the following structure:

#### Scoping Pattern (CRITICAL)
**This app uses a Scope-based architecture** defined in `config/config.exs`:

```elixir
config :homesite, :scopes,
  user: [
    default: true,
    module: Homesite.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id
  ]
```

**All context functions MUST receive a `%Scope{}` as first argument:**
```elixir
# Correct
Content.list_posts(scope)
Content.get_post!(scope, id)
Content.create_post(scope, attrs)

# Wrong - never call without scope
Content.list_posts()  # This will fail
```

**In templates, always access the user via:**
- `@current_scope.user` (NOT `@current_user`)
- `@current_scope.user.email`

**Always pass `current_scope` to `<Layouts.app>`:**
```elixir
<Layouts.app flash={@flash} current_scope={@current_scope}>
  <!-- content -->
</Layouts.app>
```

#### Context Boundaries
1. **Homesite.Accounts** - User authentication and management
   - Uses custom Scope pattern for multi-tenancy
   - Location: `lib/homesite/accounts/`

2. **Homesite.Content** - Blog posts and tags
   - All operations are scoped to the current user
   - Uses PubSub for real-time updates
   - Location: `lib/homesite/content/`

#### Data Models
- **User** (`users` table) - Has many posts and tags
- **Post** (`posts` table) - Belongs to user, has many tags through post_tags
  - Fields: title, body, slug, published_at, user_id
  - Auto-generates slug from title with timestamp
- **Tag** (`tags` table) - Belongs to user, has many posts through post_tags
- **PostTag** (`post_tags` table) - Join table for posts and tags

#### Router Organization
The router (`lib/homesite_web/router.ex`) has three key pipelines:

1. **`:browser`** - Includes `:fetch_current_scope_for_user` plug
2. **`:require_authenticated_user`** - For authenticated routes
3. **`live_session :require_authenticated_user`** - For authenticated LiveViews
   - `/posts/*` - Post CRUD operations
   - `/tags/*` - Tag CRUD operations
   - `/users/settings` - User settings

4. **`live_session :current_user`** - For public/optional auth LiveViews
   - `/users/register`, `/users/log-in` - Authentication flows

#### LiveView Structure
- **PostLive.Index** - List and manage posts
- **PostLive.Show** - View single post
- **PostLive.Form** - Form component for post creation/editing
- **TagLive.Index** - List and manage tags
- **TagLive.Show** - View single tag
- **TagLive.Form** - Form component for tag creation/editing
- **UserLive.Settings** - User settings management
- **UserLive.Login/Registration** - Authentication flows

#### SEO Configuration
The app uses `phoenix_seo` with configuration in `lib/homesite_web/seo.ex`:
- Finnish locale (`fi_FI`)
- Configures Open Graph and site metadata
- Uses `@current_url` and `@page_title` assigns

## Important Guidelines

### Authentication & Routing (See AGENTS.md for full details)
- **Always place authenticated LiveViews in the existing `live_session :require_authenticated_user` block**
- **Never duplicate `live_session` names** - add to existing blocks
- **Pass `current_scope` to all context functions** as first argument
- **Use `@current_scope.user` in templates**, never `@current_user`

### Phoenix 1.8 Specifics (See AGENTS.md)
- Start templates with `<Layouts.app flash={@flash} current_scope={@current_scope}>`
- Use `<.icon name="hero-x-mark">` for heroicons (imported component)
- Use `<.input>` from core_components for form inputs
- Use `<.link navigate={...}>` not deprecated `live_redirect`

### UI/UX with DaisyUI
- **Use DaisyUI components** for UI elements alongside Tailwind CSS
- DaisyUI provides pre-built component classes that work with Tailwind
- Combine DaisyUI utility classes with custom Tailwind for polished designs

### Tailwind v4
- No `tailwind.config.js` file - uses `@import "tailwindcss"` in `app.css`
- Import sources in CSS: `@source "../css"; @source "../js"; @source "../../lib/homesite_web"`
- Never use `@apply` directive

### Forms & LiveView (See AGENTS.md for complete guide)
- Always use `to_form/2` in LiveView: `assign(socket, form: to_form(changeset))`
- Access in templates: `<.form for={@form} id="unique-id">`
- Use `@form[:field]` syntax, never `@changeset[:field]`
- Give forms unique DOM IDs for testing

### Elixir Patterns (See AGENTS.md for full list)
- No `else if` - use `cond` or `case` for multiple conditions
- Lists don't support bracket access - use `Enum.at/2`
- Can't index into structs with `[]` - use dot notation
- Variables are immutable but rebindable - assign results of `if/case/cond`

### Content Management
The Content context uses PubSub for real-time updates:
- Subscribe with `Content.subscribe_posts(scope)` or `Content.subscribe_tags(scope)`
- Broadcasts: `{:created, item}`, `{:updated, item}`, `{:deleted, item}`

### Testing (See AGENTS.md for complete testing guide)
- Use `Phoenix.LiveViewTest` and `LazyHTML` for assertions
- Reference DOM IDs added in templates: `has_element?(view, "#post-form")`
- Use `render_submit/2` and `render_change/2` for form tests
- Never test raw HTML - use `element/2`, `has_element?/2`

### Code Quality
- Run `mix precommit` before committing (includes compile warnings as errors, format, test)
- Use `mix format` for consistent formatting
- Use `req` library for HTTP requests (already included)

## Project-Specific Notes

- This is a personal website/blog for "Juha Halmun kotisivu ja blogi" (Finnish)
- SEO configured for Finnish locale
- Uses scope-based multi-tenancy where each user has isolated posts/tags
- Slugs are auto-generated with timestamp for uniqueness
- All context operations enforce user ownership via `true = record.user_id == scope.user.id`

## Reference Documentation

For comprehensive guidelines on Phoenix, LiveView, Ecto, and Elixir patterns, **always consult AGENTS.md first**. It contains:
- Phoenix v1.8 guidelines
- LiveView patterns and best practices
- Form handling
- Authentication flow details
- Ecto guidelines
- Elixir core patterns
- Testing strategies
- Usage rules for all dependencies
