# CLAUDE.md

## Information Sources Priority

1. **AGENTS.md** - Primary source for project guidelines, patterns, and best practices
2. **Context7 MCP** - For up-to-date library documentation
3. **Internet search** - Only after consulting the above sources

## Essential Commands

```bash
# Development
mix setup              # Initial setup
mix phx.server         # Start server (localhost:4000)
mix test               # Run tests
mix test.all           # Full check (precommit + credo)
mix format             # Format code
mix credo --strict     # Code quality

# Database
mix ecto.migrate       # Run migrations
mix ecto.reset         # Reset database
```

## Architecture Overview

**Phoenix 1.8.1** + **LiveView 1.1.0** + **Ecto 3.13** + **PostgreSQL**
**Tailwind CSS v4** + **DaisyUI** (no tailwind.config.js, uses `@import "tailwindcss"` in app.css)

### Scoping Pattern (CRITICAL)

All context functions MUST receive `%Scope{}` as first argument:
```elixir
Content.list_posts(scope)
Content.get_post!(scope, id)
```

In templates: `@current_scope.user` (NOT `@current_user`)

### Context Boundaries
- **Homesite.Accounts** - Users, authentication, invitations
- **Homesite.Content** - Posts, tags (scoped per user)
- **Homesite.Faqs** - Bilingual FAQs (admin-managed)
- **Homesite.DevFaqs** - Dev documentation (dev environment only)

## Claude Behavioral Rules

### EOD Workflow

When user says **"EOD"**: Execute immediately without confirmation:
1. Run `mix test.all`
2. Sync GitHub issues (`gh issue list/close/comment`)
3. Update MEMO.md
4. Commit & push

Commands allowed without asking: `git`, `gh`, `mix test`, `mix format`, `mix credo`

### Commit Message Format
```
[type]: Short description

- Bullet points for changes
Fixes: #issue

🤖 Generated with [Claude Code](https://claude.com/claude-code)
Co-Authored-By: Claude <noreply@anthropic.com>
```
Types: feat, fix, docs, test, refactor, chore, security, perf

### Test Failures = STOP

Fix immediately. Never defer, document as "known issue", or work around.

## Security (MANDATORY)

All context functions enforce scope isolation:
```elixir
true = post.user_id == scope.user.id  # Raises MatchError if mismatch
```

Run before commits:
```bash
mix sobelow --config   # Security analysis
mix deps.audit         # Vulnerability scan
```

## Key Patterns

- **Forms**: Use `to_form/2`, access as `@form[:field]`
- **LiveViews**: Place in existing `live_session` blocks, never duplicate names
- **Heroicons**: `<.icon name="hero-x-mark">`
- **Links**: `<.link navigate={...}>` (not deprecated `live_redirect`)
- **No `else if`**: Use `cond` or `case`

## Documentation Files

- **AGENTS.md** - Full coding patterns, Phoenix/LiveView guidelines
- **MODERN_CSS_GUIDE.md** - CSS/Tailwind patterns
- **DESIGN_SYSTEM_MIGRATION_GUIDE.md** - Design token migration
- **MEMO.md** - Session notes

## Project Notes

- Finnish personal blog ("Juha Halmun kotisivu ja blogi")
- Invitation-based registration (codes like `XXXX-XXXX-XXXX`)
- Two FAQ systems: DevFaqs (markdown, dev-only) and Faqs (database, bilingual)
- Test invitation code: `TEST-INVITE`
