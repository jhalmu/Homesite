# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Information Sources Priority

**CRITICAL**: When working in this codebase, consult information sources in this order:

1. **AGENTS.md** - Primary source for project guidelines, patterns, and best practices
2. **Context7 MCP** - For up-to-date library documentation (use `mcp__context7__*` tools)
3. **Internet search** - Only after consulting the above sources

Always check AGENTS.md first for project-specific patterns before making architectural decisions.

### Project Documentation Files

**IMPORTANT**: This project contains multiple Markdown (.md) files with essential information:

- **AGENTS.md** - Primary source for coding patterns, Phoenix/LiveView guidelines, testing
- **REGISTRATION_STRATEGY.md** - Authentication system documentation and strategy decisions
- **MODERN_CSS_GUIDE.md** - CSS/Tailwind patterns and responsive design guidelines (if exists)
- **MEMO.md** - Session notes and historical context

**When to read .md files:**
- Before making architectural decisions (check AGENTS.md)
- When working with authentication/registration (check REGISTRATION_STRATEGY.md)
- When implementing UI changes (check MODERN_CSS_GUIDE.md if it exists)
- At the start of each session (check MEMO.md for context)
- When encountering unfamiliar patterns or decisions

**Best practice:** Use `find . -name "*.md" -type f` to discover all documentation files in the project.

## 🤖 Claude Behavioral Rules (MANDATORY)

### Rule 1: Proactive EOD Reminder

**CRITICAL**: Claude MUST proactively remind user about End of Session Checklist in these scenarios:

**Trigger Conditions** (any of these):
1. After completing a feature AND all tests passing
2. After logging an insight via Insights Logger
3. When user asks "what's missing from documentation"
4. After fixing all test failures (0 failures achieved)
5. When uncommitted changes exist AND no active task in TodoWrite
6. After user says phrases indicating session wrap-up:
   - "Log this insight"
   - "What's missing from documentation"
   - "List latest updates"
   - "Fix all errors always" (meta-instruction)

**Required Response Format**:
```
✅ [Feature/Task] complete!

**Should I run the End of Session Checklist now?**

This will:
- Update MEMO.md with session summary
- Commit changes to Git
- Push to GitHub
- Update GitHub issues (if applicable)

Say **"EOD"** to start, or **"continue"** if more work planned.
```

**Never assume the session continues** - always ask if unsure.

### Rule 2: EOD Workflow is Mandatory, Not Optional

When user says "EOD", "End of session", or "End of session checklist":
1. **Don't ask for confirmation** - START IMMEDIATELY
2. Follow the 8-step Automated EOD Workflow (see below)
3. Don't skip steps unless user explicitly says "EOD skip [step]"
4. Execute git commands WITHOUT asking for permission:
   - `git add .`
   - `git commit -m "..."`
   - `git push`

**User has explicitly requested**: Never ask before running git commands during EOD workflow.

### Rule 3: Git Commit Message Format

All commit messages MUST follow this format:

```
[type]: Short description (50 chars max)

Detailed description:
- Bullet points for major changes
- Files created/modified with line counts
- Test coverage changes
- Security improvements (if applicable)

Fixes/Closes: #issue_number (if applicable)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Types**: feat, fix, docs, test, refactor, chore, security, perf

### Rule 4: Never Skip Documentation

After completing ANY coding work:
- ❌ Don't assume documentation will be updated later
- ✅ Proactively offer to run EOD checklist
- ✅ Treat missing MEMO.md entry as a bug
- ✅ Apply "fix all errors always" to documentation gaps

**Documentation is part of the feature**, not an afterthought.

---

## 🤖 Automated Workflows

### Insights Logger - Pattern Capture System

**Purpose**: Automatically capture reusable coding patterns, architectural decisions, and gotchas during development.

**Location**: `.claude/insights/`

**How to Use**:

1. **Manual Capture** (Primary Method):
   ```
   User: "Log this insight: Scope pattern enforcement"
   Claude: Creates formatted entry in today's session file
   ```

2. **Keyword Detection** (Automatic):
   - Say "Gotcha: [description]" → Auto-captures as insight
   - Say "Important pattern: [description]" → Auto-captures
   - Say "Tricky: [description]" → Auto-captures

3. **Session File Format**:
   - File: `.claude/insights/session-YYYY-MM-DD-HHMMSS.md`
   - Categories: Architecture, Database, Security, UI/UX, Performance, Bugs, Testing, Dependencies
   - Structure: Problem → Solution → Rationale → Why it matters

**What Gets Logged**:
- ✅ Reusable patterns applicable across features
- ✅ Security-critical patterns
- ✅ Performance optimizations
- ✅ Library-specific quirks and gotchas
- ✅ Non-obvious solutions
- ✅ Common mistakes to avoid

**What to Skip**:
- ❌ Feature-specific implementation details
- ❌ Obvious patterns already well-known
- ❌ Temporary workarounds
- ❌ Incomplete thoughts

**Review Later** (Manual):
```
User: "Review insights from sessions"
Claude: Reads all session files, categorizes, presents for selection
User: Selects valuable insights
Claude: Integrates into CLAUDE.md/AGENTS.md, archives processed files
```

---

### Automated EOD Workflow

**Purpose**: Fully automated end-of-session workflow - zero manual steps required.

**Trigger**: Say **"EOD"** or **"End of session"**

**What Happens Automatically**:

1. **Run Tests** 🧪
   - Executes: `mix test.all`
   - Shows results (pass/fail)
   - Stops if tests fail (won't commit broken code)

2. **Analyze Changes** 🔍
   - Runs: `git status` and `git diff`
   - Identifies modified files
   - Categorizes changes (new features, bug fixes, docs, etc.)

3. **Draft MEMO.md Entry** ✍️
   - Generates timestamp (ISO 8601 format)
   - Summarizes what was accomplished based on git changes
   - Identifies files created/modified
   - Notes test results
   - Appends to MEMO.md automatically

4. **Update GitHub Issues** 📋
   - Identifies issues mentioned in code/commits
   - Suggests which issues to close (looks for "fixes #", "closes #")
   - Updates issue comments with progress
   - Creates new issues for TODOs discovered in code

5. **Check for Insights** 💡
   - Asks: "Did we discover any patterns worth logging?"
   - If yes: Prompts for quick insight capture
   - If no: Continues to commit

6. **Generate Commit Message** 📝
   - Creates descriptive commit message from changes
   - Includes issue references
   - Adds standard footer:
     ```
     🤖 Generated with [Claude Code](https://claude.com/claude-code)

     Co-Authored-By: Claude <noreply@anthropic.com>
     ```

7. **Commit & Push** 🚀
   - Stages all changes: `git add .`
   - Commits with generated message
   - Pushes to GitHub: `git push`
   - Shows confirmation with commit hash

8. **Summary Report** 📊
   - Shows what was done:
     - ✅ Tests passed
     - ✅ MEMO.md updated
     - ✅ Issues updated (#X closed, #Y commented)
     - ✅ Committed: [hash]
     - ✅ Pushed to GitHub

**Manual Override**:
If you want to review before pushing, say:
```
"EOD with review"  → Stops before push for your approval
"EOD skip tests"   → Skips test run (use carefully!)
"EOD draft only"   → Only drafts MEMO, doesn't commit/push
```

**Safety Features**:
- ❌ Won't commit if tests fail
- ❌ Won't commit files with "SECRET" or "PASSWORD" in names
- ❌ Won't push to protected branches without confirmation
- ✅ Creates backup of MEMO.md before modifying
- ✅ Shows diff before final commit

---

## Git & GitHub Workflow

**CRITICAL**: Follow this workflow when working on the codebase:

### 🎯 End of Session Checklist (MANDATORY)

**Before ending ANY coding session, complete this checklist:**

1. **Update MEMO.md** ✍️
   - Add datetime stamp (ISO 8601 format: `2025-11-27 22:00:00`)
   - Summarize what was accomplished
   - Note any pending tasks or decisions needed
   - Document any blockers or issues encountered
   - Provide context for next session

2. **Update GitHub Issues** 📋
   - Close completed issues with summary: `gh issue close <number> --comment "summary"`
   - Update partial progress: `gh issue comment <number> --body "progress update"`
   - Create new issues for discovered work
   - Keep issues synchronized with reality

3. **Run Tests** 🧪
   - Execute: `mix test.all` (precompile + format + test + credo)
   - Fix any failures before committing
   - Verify: "211 tests, 0 failures"

4. **Review Changes** 👀
   - Check git status: `git status`
   - Review diff: `git diff`
   - Ensure only intended files modified

5. **Commit & Push** 🚀
   - Add files: `git add .` (or specific files)
   - Write descriptive commit message
   - Include issue references: `#123`
   - Push to GitHub: `git push`

6. **(Optional) Log Insights** 💡
   - If using Insights Logger, capture any reusable patterns discovered
   - Trigger: "Log this insight: [description]"

**To trigger this checklist, say:** "End of session checklist" or "EOD"

---

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

**MANDATORY - End of Session GitHub Issue Updates:**
At the end of EVERY coding session, update GitHub issues to reflect completed work:
1. **Close completed issues** - Use `gh issue close <number> --comment "summary"`
2. **Update partial progress** - Add comments to issues showing what was completed
3. **Create completion issues** - For new features not tracked, create and immediately close with summary
4. **Keep issues synchronized** - GitHub issues should always reflect the current project state

Example workflow:
```bash
# Close completed issue
gh issue close 12 --comment "Fixed RSS feed autodiscovery by changing to absolute URLs. Tested with RSS readers."

# Update partial progress
gh issue comment 15 --body "✅ Completed: Language switcher, locale persistence, homepage translations. Still needed: Full translation coverage."

# Create + close for untracked completed work
gh issue create --title "Public Post Viewing Without Authentication" --body "Implemented public access to /posts page..."
gh issue close <number> --comment "Completed in this session"
```

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
- **Test:** `mix test` (runs ExUnit tests)
- **Test specific file:** `mix test test/path/to/test.exs`
- **Test specific line:** `mix test test/path/to/test.exs:123`
- **Test all (recommended):** `mix test.all` (precommit + credo)
- **Format code:** `mix format`
- **Code quality:** `mix credo --strict`
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
   - **Invitation System** - Controlled user registration with invitation codes
   - Location: `lib/homesite/accounts/`

2. **Homesite.Content** - Blog posts and tags
   - All operations are scoped to the current user
   - Uses PubSub for real-time updates
   - Location: `lib/homesite/content/`

3. **Homesite.Faqs** - FAQ management system (database-driven)
   - Bilingual FAQs (English/Finnish) for admins and users
   - Admin-only CRUD operations
   - Location: `lib/homesite/faqs/`

4. **Homesite.DevFaqs** - Development documentation (markdown-based)
   - **Development environment only** - not available in production/test
   - Parsed at compile-time using NimblePublisher
   - Location: `lib/homesite/dev_faqs/`, files in `priv/dev_faqs/`

#### Data Models
- **User** (`users` table) - Has many posts, tags, and created invitations
- **Post** (`posts` table) - Belongs to user, has many tags through post_tags
  - Fields: title, body, slug, published_at, user_id
  - Auto-generates slug from title with timestamp
- **Tag** (`tags` table) - Belongs to user, has many posts through post_tags
- **PostTag** (`post_tags` table) - Join table for posts and tags
- **Invitation** (`invitations` table) - Invitation codes for user registration
  - Fields: code, max_uses, current_uses, expires_at, created_by_user_id, default_role
  - Auto-generates unique codes, tracks usage, supports expiration
- **Faq** (`faqs` table) - Bilingual FAQ entries
  - Fields: category (admin/user), question_en/fi, answer_en/fi, display_order, is_active, slug
  - Created/updated by admins, publicly viewable based on category

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

### Security (MANDATORY)

**CRITICAL**: Security testing and best practices are MANDATORY for all features.

#### Security Dependencies
- **Sobelow** - Static security analysis for Phoenix apps
- **mix_audit** - Dependency vulnerability scanner
- **Hammer** - Rate limiting library with ETS backend
- **Hammer.Plug** - Plug integration for Hammer

#### Rate Limiting (Hammer)
Configuration in `config/config.exs`:
```elixir
config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10]}
```

Rate limits applied to authentication routes:
- **Login**: 5 attempts per minute per IP (`/users/log-in`)
- **Registration**: 3 attempts per hour per IP (`/users/register`)

#### Scope Isolation (MANDATORY)
**All context functions MUST enforce scope isolation**:
- Use pattern matching: `true = record.user_id == scope.user.id`
- This raises `MatchError` when users try to access other users' data
- NEVER skip scope checks in context functions

Example:
```elixir
def update_post(%Scope{} = scope, %Post{} = post, attrs) do
  true = post.user_id == scope.user.id  # Security check - raises if mismatch
  # ... rest of function
end
```

#### Security Testing Requirements
**Every feature MUST include security tests** in `test/homesite_web/security_test.exs`:

1. **Scope Isolation Tests**:
   - User A cannot view User B's data
   - User A cannot update User B's data
   - User A cannot delete User B's data
   - List functions only return scoped data

2. **Authorization Tests**:
   - Protected routes require authentication
   - Unauthenticated users are redirected to login

3. **CSRF Protection**:
   - POST requests without CSRF token are rejected
   - Forms include CSRF tokens

#### Security Scanning
Run these commands before every commit:
```bash
mix sobelow --config         # Security analysis
mix deps.audit               # Check for vulnerable dependencies
```

Add to pre-commit workflow:
```bash
mix test.all                 # Runs precommit + credo
mix sobelow                  # Security scan
mix deps.audit               # Dependency audit
```

#### Built-in Security Features
- **CSRF Protection**: Automatic via `protect_from_forgery` plug in router
- **XSS Prevention**: Automatic HTML escaping in Phoenix templates
- **Password Hashing**: Argon2 for secure password storage
- **Secure Headers**: `put_secure_browser_headers` plug adds security headers

#### Security Best Practices
1. **Never skip scope checks** in context functions
2. **Always write security tests** for new features
3. **Rate limit authentication endpoints** to prevent brute force
4. **Validate all user input** at schema level
5. **Use prepared statements** (Ecto does this automatically)
6. **Keep dependencies updated** (run `mix deps.audit` regularly)
7. **Review Sobelow warnings** and fix high/medium severity issues

### Testing (See AGENTS.md for complete testing guide)
- Use `Phoenix.LiveViewTest` and `LazyHTML` for assertions
- Reference DOM IDs added in templates: `has_element?(view, "#post-form")`
- Use `render_submit/2` and `render_change/2` for form tests
- Never test raw HTML - use `element/2`, `has_element?/2`

### Testing & Code Quality

**CRITICAL**: Always follow this workflow when making changes:

1. **Write/Update Tests First** - When adding new features or fixing bugs:
   - Write unit tests for context functions
   - Write LiveView tests for UI interactions
   - Update existing tests if behavior changes

2. **Run Tests Before Committing**:
   ```bash
   mix test                    # Run ExUnit tests (unit + integration)
   mix test --failed           # Run only failed tests
   mix test --include playwright  # Run Playwright E2E tests (optional)
   mix credo --strict          # Run code quality analysis (separate from tests)
   ```

   **Note:** `mix test` does NOT run Credo or Playwright by default

3. **Testing Tools**:
   - `ExUnit` - Unit testing framework (built-in)
   - `Phoenix.LiveViewTest` - LiveView testing
   - `Phoenix.Test.Playwright` - End-to-end browser testing
   - `Credo` - Static code analysis for code quality
   - `LazyHTML` - HTML assertions in tests

4. **Before GitHub Update - Run ALL checks**:
   ```bash
   # RECOMMENDED: Run everything in one command
   mix test.all               # Runs: precommit + credo --strict

   # OR run separately:
   mix precommit              # Compile (warnings as errors), format, test
   mix credo --strict         # Code quality check
   ```

   **Optional:** Include Playwright tests for critical flows:
   ```bash
   mix test --include playwright
   ```

   **Exception**: If memory/context is running out, commit anyway to preserve work

5. **Test Organization**:
   - Context tests: `test/homesite/context_name_test.exs`
   - LiveView tests: `test/homesite_web/live/resource_live_test.exs`
   - Controller tests: `test/homesite_web/controllers/controller_name_test.exs`

6. **Edge Cases to Test**:
   - **Security**: Scope isolation, unauthorized access attempts
   - **Validation**: Min/max lengths, required fields, format validation
   - **Constraints**: Unique constraints, foreign key violations
   - **Boundary conditions**: Empty lists, null values, very long strings
   - **Concurrency**: Race conditions, simultaneous updates (when applicable)
   - **State**: Published vs draft, soft deletes, cascading deletes

### Code Quality Standards
- Run `mix format` for consistent formatting
- Use `mix credo --strict` for code analysis
- Fix all Credo warnings before committing
- Use `req` library for HTTP requests (already included)
- Follow Elixir style guide and AGENTS.md guidelines

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

## FAQ Systems

This application has TWO separate FAQ systems serving different purposes:

### 1. DEV FAQs (Development Documentation)

**Purpose**: Developer documentation accessible only in development environment.

**Location**: 
- Files: `priv/dev_faqs/*.md`
- Context: `lib/homesite/dev_faqs.ex`
- LiveView: `lib/homesite_web/live/dev_faqs_live/index.ex`
- Route: `/dev/faqs` (development only)

**Features**:
- Markdown files with YAML frontmatter
- Compile-time parsing using NimblePublisher
- Syntax highlighting for code blocks (Elixir)
- Category filtering
- English only (no i18n)
- Zero database overhead

**File Format**:
```markdown
---
title: "Test Users and Accounts"
order: 1
category: "authentication"
---

# Your content here

## Code examples with syntax highlighting
\`\`\`elixir
user = Repo.get(User, 1)
\`\`\`
```

**Adding New DEV FAQs**:
1. Create file in `priv/dev_faqs/` with pattern `NNN-slug.md`
2. Add YAML frontmatter with title, order, category
3. Write markdown content
4. Recompile app (automatic in dev with file watching)

**Access**:
- Development: `http://localhost:4000/dev/faqs`
- Test/Production: Route doesn't exist (404)

**Best for**:
- Test user credentials
- Database commands
- Common development tasks
- Known issues and gotchas
- Dev environment setup

### 2. Database FAQs (Production FAQ System)

**Purpose**: User-facing and admin FAQs with full internationalization.

**Location**:
- Context: `lib/homesite/faqs.ex`
- Schema: `lib/homesite/faqs/faq.ex`
- Tests: `test/homesite/faqs_test.exs`
- Table: `faqs`

**Features**:
- Bilingual support (English/Finnish)
- Two categories: "admin" and "user"
- Admin-only CRUD operations
- Display ordering
- Active/inactive toggle
- Auto-generated slugs
- Audit trail (created_by, updated_by)

**Usage**:
```elixir
# List user FAQs (public, no auth required)
faqs = Faqs.list_user_faqs("en")

# List admin FAQs (requires admin scope)
faqs = Faqs.list_admin_faqs(admin_scope, "fi")

# Create FAQ (requires admin scope)
{:ok, faq} = Faqs.create_faq(admin_scope, %{
  category: "user",
  question_en: "How do I...?",
  question_fi: "Miten voin...?",
  answer_en: "You can...",
  answer_fi: "Voit...",
  display_order: 10
})

# Get FAQ by slug
faq = Faqs.get_user_faq_by_slug!("how-to-do-something", "en")
```

**Best for**:
- Public user documentation
- Admin-specific documentation
- Multilingual content
- Frequently updated content

## Invitation System

**Purpose**: Controlled user registration with trackable invitation codes.

**Location**:
- Schema: `lib/homesite/accounts/invitation.ex`
- Functions in: `lib/homesite/accounts.ex`
- Table: `invitations`

**Features**:
- Auto-generated unique codes (format: `XXXX-XXXX-XXXX`)
- Usage tracking (current_uses vs max_uses)
- Expiration dates (optional)
- Default role assignment
- Audit trail (who created the invitation)

**Creating Invitations**:
```elixir
# Unlimited uses, never expires
{:ok, invitation} = Accounts.create_invitation(admin_user, %{
  default_role: "user"
})

# Limited uses with expiration
{:ok, invitation} = Accounts.create_invitation(admin_user, %{
  max_uses: 10,
  expires_at: DateTime.add(DateTime.utc_now(:second), 7, :day),
  default_role: "user"
})

# Custom code
{:ok, invitation} = Accounts.create_invitation(admin_user, %{
  code: "SPECIAL-INVITE-2025",
  max_uses: 5,
  default_role: "user"
})
```

**Validation**:
```elixir
# During registration
case Accounts.validate_invitation(code) do
  {:ok, invitation} -> 
    # Proceed with registration, code is valid and consumed
  {:error, reason} ->
    # "invitation code is invalid"
    # "invitation code has expired"
    # "invitation code has reached maximum uses"
end
```

**Test Invitation**:
- Code: `TEST-INVITE`
- Auto-created in test environment by `DataCase.ensure_test_invitation/0`
- Unlimited uses, never expires
- Used by all test fixtures via `AccountsFixtures.valid_user_attributes/1`

**Edge Cases Handled**:
1. Concurrent usage with max_uses (atomic increment)
2. Expired invitations
3. Maximum uses reached
4. Invalid/nonexistent codes
5. Nil or empty codes

## Test Infrastructure

### Test Invitation System

**Purpose**: Provide consistent invitation code for all tests.

**Implementation** (`test/support/data_case.ex:48`):
```elixir
def ensure_test_invitation do
  # Creates test admin if needed
  test_admin = case Repo.get_by(User, email: "test-admin@example.com") do
    nil -> Accounts.register_admin(%{...})
    existing -> existing
  end

  # Creates TEST-INVITE code if needed
  case Repo.get_by(Invitation, code: "TEST-INVITE") do
    nil -> Repo.insert!(%Invitation{code: "TEST-INVITE", ...})
    existing -> existing
  end
end
```

**Usage**:
- Automatically called in `DataCase` and `ConnCase` setup
- All test fixtures use "TEST-INVITE" by default
- Runs in each test's sandbox transaction (isolated per-test)

### Test Fixtures

**AccountsFixtures** (`test/support/fixtures/accounts_fixtures.ex`):
```elixir
# Creates confirmed user with password
user = user_fixture()

# Creates unconfirmed user with password
user = unconfirmed_user_fixture()

# Creates unconfirmed user WITHOUT password (for magic-link tests)
user = unconfirmed_user_fixture_no_password()

# Custom attributes (invitation_code always added)
user = user_fixture(%{email: "custom@example.com"})
```

**Important**: 
- `user_fixture/1` creates CONFIRMED users (manually sets `confirmed_at`)
- `unconfirmed_user_fixture_no_password/1` bypasses invitation system (direct DB insert)
- All regular fixtures use password-based auth with "TEST-INVITE"

### Test Organization

**Edge Case Tests**:
- DEV FAQs: `test/homesite/dev_faqs_test.exs` (22 tests)
  - Environment restrictions
  - Empty states
  - Category filtering
  - HTML safety
- LiveView: `test/homesite_web/live/dev_faqs_live/index_test.exs` (6 tests)
  - Route availability (404 in test)
  - Parameter handling
  - XSS protection

**Test Coverage**: 276 total tests (as of 2025-11-28)
- DEV FAQs added 22 new tests
- All tests passing in test environment
- DEV FAQ routes correctly return 404 in test environment (expected behavior)
