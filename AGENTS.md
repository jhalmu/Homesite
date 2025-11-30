This is a web application written using the Phoenix web framework.

## Project guidelines

- Use `mix precommit` alias when you are done with all changes and fix any pending issues
- Use the already included and available `:req` (`Req`) library for HTTP requests, **avoid** `:httpoison`, `:tesla`, and `:httpc`. Req is included by default and is the preferred HTTP client for Phoenix apps

### Session Workflow

**CRITICAL**: Follow this workflow for every coding session:

#### Starting a Session
1. **Read MEMO.md** - Review the latest session notes to understand:
   - What was accomplished in previous sessions
   - Any pending tasks or decisions needed
   - Known blockers or issues
   - Context for continuing work

2. **Check GitHub Issues** - Review issues to see:
   - What has been completed (closed issues)
   - What needs to be done (open issues)
   - Current priorities and planned features
   - Any bugs or technical debt

#### During a Session
- Work on tasks systematically
- Update code following project guidelines
- Write/update tests as you go
- Run `mix test` and `mix test.all` frequently

#### Ending a Session
1. **Update MEMO.md** - Add a new entry with:
   - Datetime stamp (ISO 8601 format: `2025-11-21 14:30:00`)
   - Summary of what was accomplished
   - Files created or modified
   - Any pending tasks or decisions needed
   - Known blockers or issues encountered
   - Context for next session

2. **Update GitHub Issues**:
   - Create issues for completed work (close immediately with summary)
   - Create issues for planned features or improvements
   - Create issues for known bugs or technical debt
   - Reference issue numbers in commit messages: `Fix user scope issue #123`

3. **Commit and Push**:
   - Run `mix test.all` before committing
   - Write descriptive commit messages
   - Push to GitHub to preserve work

**Note:** If memory/context is running out, commit anyway to preserve work

---

## Patterns from Practice

The following patterns have been discovered and validated through actual development sessions. These are project-specific best practices that extend the general guidelines below.

### Architecture Patterns

#### Pattern: Context Separation for Analytics

**Rule**: Create dedicated contexts for features that will need analytics or reporting, even if they could be added to existing contexts.

**Why**: Separating concerns like social sharing, activity logging, or metrics into their own contexts provides:
- **Clean boundaries**: New features don't mix with core domain logic
- **Analytics foundation**: Share logs and event tracking ready for future dashboards
- **Flexibility**: Can track events for multiple entity types without coupling
- **Privacy controls**: Optional tracking fields (IP, user agent) in one place

**Example** (`lib/homesite/social.ex`):
```elixir
defmodule Homesite.Social do
  # Core function - log share events
  def log_share(attrs \\ %{}) do
    %ShareLog{}
    |> ShareLog.changeset(attrs)
    |> Repo.insert()
  end

  # Analytics functions
  def get_post_share_stats(post_id)  # Per-post stats
  def get_all_share_stats()          # Site-wide rankings
  def list_recent_shares(limit)       # Activity feed
end
```

**When to use**: Creating features for social actions, notifications, activity feeds, usage tracking, or any feature that will benefit from historical data and analytics.

<!-- Integrated from .claude/insights sessions on 2025-11-30 -->

---

#### Pattern: Database Filtering Requires Separate Function Calls

**Rule**: When you need different database WHERE clauses, call different context functions instead of filtering query results in Elixir.

**Why**: Database filtering (WHERE clauses) happens before Elixir receives the data. You cannot filter out results that were already excluded by the query.

**Example** (FAQ category loading):
```elixir
# WRONG - Trying to filter already-filtered results
def load_faqs(socket, category) do
  Faqs.list_admin_faqs(scope, locale)
  |> Enum.filter(&(&1.category == category))  # Won't work if category="user"!
end

# CORRECT - Call the right function for the category
defp load_faqs(socket, category) do
  case category do
    "admin" -> Faqs.list_admin_faqs(socket.assigns.current_scope, socket.assigns.locale)
    "user" -> Faqs.list_user_faqs(socket.assigns.locale)
    _ -> []
  end
end
```

**Reference**: `lib/homesite_web/live/faq_live/index.ex:120-134`

<!-- Integrated from .claude/insights sessions on 2025-11-30 -->

---

### Database Patterns

#### Pattern: Dual Search Strategy (Trigram + ILIKE)

**Rule**: Combine PostgreSQL trigram similarity with ILIKE fallback for robust full-text search that handles both typos and exact matches.

**Implementation**:
```elixir
# Migration - Enable pg_trgm and create GIN indexes
execute "CREATE EXTENSION IF NOT EXISTS pg_trgm"
execute "CREATE INDEX posts_title_trgm_idx ON posts USING gin (title gin_trgm_ops)"
execute "CREATE INDEX posts_body_trgm_idx ON posts USING gin (body gin_trgm_ops)"

# Query - Dual matching strategy
from(p in Post,
  where: not is_nil(p.published_at) and p.is_public == true,
  where:
    fragment("similarity(?, ?) > 0.1", p.title, ^query) or
    fragment("similarity(?, ?) > 0.1", p.body, ^query) or
    fragment("? ILIKE ?", p.title, ^"%#{query}%") or
    fragment("? ILIKE ?", p.body, ^"%#{query}%"),
  order_by: [
    desc: fragment(
      "greatest(similarity(?, ?), similarity(?, ?))",
      p.title, ^query, p.body, ^query
    )
  ]
)
```

**Why this works**:
- **Trigram similarity (0.1 threshold)**: Catches typos, partial matches, fuzzy queries
- **ILIKE fallback**: Ensures exact substring matches are never missed
- **GIN indexes**: Fast for both similarity and ILIKE operations
- **Ordered by similarity**: Most relevant results first

**When to use**: Any text search scenario. Works for titles, content, names, descriptions, etc.

**Reference**: `lib/homesite/content.ex:724-764`, `priv/repo/migrations/20251129081009_add_search_index_to_posts.exs`

<!-- Integrated from .claude/insights sessions on 2025-11-30 -->

---

### Security Patterns

#### Pattern: Admin Authorization Requires Dedicated on_mount Hook

**Rule**: Create a separate `on_mount(:require_admin)` hook for admin-only LiveViews. Don't rely on `:require_authenticated` alone.

**Implementation**:
```elixir
# In lib/homesite_web/user_auth.ex
def on_mount(:require_admin, _params, session, socket) do
  socket = mount_current_scope(socket, session)

  if socket.assigns.current_scope && Homesite.Accounts.Scope.admin?(socket.assigns.current_scope) do
    {:cont, socket}
  else
    socket =
      socket
      |> Phoenix.LiveView.put_flash(:error, "You must be an administrator to access this page.")
      |> Phoenix.LiveView.redirect(to: ~p"/")

    {:halt, socket}
  end
end

# In router.ex
live_session :require_admin,
  on_mount: [
    {HomesiteWeb.UserAuth, :require_authenticated},
    {HomesiteWeb.UserAuth, :require_admin},  # Layered security
    {HomesiteWeb.SetLocaleHook, :default}
  ] do
  live "/faqs/new", FaqLive.Index, :new
  live "/faqs/:id/edit", FaqLive.Index, :edit
end
```

**Why**: LiveView `on_mount` hooks run before every mount. Multiple hooks can be chained for layered security: first check auth, then check role.

**Security test**:
```elixir
test "regular users cannot access FAQ creation form", %{conn: conn} do
  user = user_fixture()
  conn = log_in_user(conn, user)

  assert {:error, {:redirect, %{to: _}}} = live(conn, ~p"/faqs/new")
end
```

**Reference**: `lib/homesite_web/user_auth.ex:251-264`

<!-- Integrated from .claude/insights sessions on 2025-11-30 -->

---

#### Pattern: Empty Query Validation Prevents DoS

**Rule**: Validate search queries before database access. Return empty results for empty/whitespace queries and validate numeric parameters.

**Implementation**:
```elixir
def search_posts(query, opts \\ []) when is_binary(query) do
  # Return empty list for empty or whitespace-only queries
  case String.trim(query) do
    "" -> []
    trimmed_query ->
      limit = Keyword.get(opts, :limit, 20)
      limit = max(limit, 0)  # Ensure non-negative

      # ... perform search with trimmed_query and validated limit
  end
end
```

**Why**:
- **Security**: Prevents returning entire database on empty query (DoS vector)
- **Performance**: Avoids expensive queries for meaningless input
- **UX**: Empty search = no results is intuitive behavior
- **Database safety**: PostgreSQL raises error on negative LIMIT

**Always validate**:
1. Empty/whitespace queries → return []
2. Numeric parameters (limits, offsets) → ensure non-negative
3. Special characters → proper escaping (Ecto does this automatically for params)

**Reference**: `lib/homesite/content.ex:726-728`

<!-- Integrated from .claude/insights sessions on 2025-11-30 -->

---

#### Pattern: Scope Isolation Testing is Mandatory

**Rule**: Every new feature that uses scopes MUST have dedicated security tests verifying users cannot access other users' data.

**Implementation**:
```elixir
describe "Search Security: Scope isolation in search results" do
  test "user search only returns their own posts" do
    # Create posts for two users with same keyword
    {:ok, post_a} = Content.create_post(scope_a, %{title: "Secret Post"})
    {:ok, _post_b} = Content.create_post(scope_b, %{title: "Secret Post"})

    # User A searches
    results_a = Content.search_user_posts(scope_a, "Secret")

    # Should only see their own post
    assert length(results_a) == 1
    assert hd(results_a).id == post_a.id
    assert Enum.all?(results_a, fn p -> p.user_id == user_a.id end)
  end

  test "search does not leak data between scopes" do
    # Create posts with sensitive data
    {:ok, _post_a} = Content.create_post(scope_a, %{title: "API Key: sk-1234"})
    {:ok, _post_b} = Content.create_post(scope_b, %{title: "API Key: sk-5678"})

    # User A searches
    results_a = Content.search_user_posts(scope_a, "API Key")

    # Should only see their own API key
    assert hd(results_a).title =~ "sk-1234"
    refute hd(results_a).title =~ "sk-5678"
  end
end
```

**Security testing checklist for new features**:
1. ✅ Users cannot access other users' data
2. ✅ SQL injection is prevented (test with `'; DROP TABLE --`)
3. ✅ XSS payloads are handled safely (test with `<script>alert('xss')</script>`)
4. ✅ Scope checks exist in context functions (`true = record.user_id == scope.user.id`)
5. ✅ Public vs private data is correctly filtered

**Why**: Search features are particularly prone to cross-user data leaks. Testing with realistic sensitive data (API keys, passwords) ensures isolation works.

**Reference**: `test/homesite_web/security_test.exs:338-468`

<!-- Integrated from .claude/insights sessions on 2025-11-30 -->

---

### Testing Patterns

#### Pattern: Zero-Tolerance Testing Policy

**Rule**: Fix ALL failing tests immediately before considering a feature complete. Never commit code with failing tests.

**Workflow**:
```bash
# After implementing feature
mix test test/path/to/feature_test.exs  # Run feature tests
# If failures: FIX THEM IMMEDIATELY
# Repeat until: 0 failures
mix test  # Run full suite
# If failures: FIX THEM IMMEDIATELY
# Only then: git commit
```

**Exception**: Only commit with failing tests if running out of context/memory and need to preserve work. Must fix in next session.

**Why this matters**:
- **Quality**: Failing tests indicate broken functionality
- **Regression Prevention**: Unfixed errors compound over time
- **Code Health**: Each skipped error makes the next one easier to ignore
- **Trust**: Test suite must be trusted to catch real issues
- **Documentation**: Tests document expected behavior - failures are lies

**This principle applies to ALL features**:
- Security tests MUST pass (auth, scope isolation)
- Edge case tests MUST pass (empty states, validation)
- Integration tests MUST pass (LiveView interactions)

<!-- Integrated from .claude/insights sessions on 2025-11-30 -->

---

#### Pattern: Verify Implementation Before Closing GitHub Issues

**Rule**: Before closing any GitHub issue, verify the feature actually exists in the codebase.

**Verification steps**:
1. Search codebase for expected files/routes
2. Check database for expected tables/schemas
3. Verify functionality actually exists
4. Use git log to find implementation commits
5. Only close if verified

**Example verification**:
```bash
# Check if route exists
grep -r "/admin/users" lib/homesite_web/router.ex

# Check if module exists
find lib -name "*admin*users*"

# Check if table exists
grep "create table(:activities" priv/repo/migrations/*

# Check git history
git log --all --grep="user management"
```

**Why**: GitHub issues should accurately reflect reality. Closing without verification leads to confusion and wasted time in future sessions when you discover the feature was never actually implemented.

<!-- Integrated from .claude/insights sessions on 2025-11-30 -->

---

#### Pattern: Database Constraints Require assert_raise

**Rule**: When testing database constraints (VARCHAR limits, NOT NULL, etc.), use `assert_raise` instead of expecting changeset errors.

**Implementation**:
```elixir
test "handles very long URLs" do
  # URLs longer than 255 chars will fail due to database constraint
  long_url = "https://example.com/" <> String.duplicate("a", 300)

  attrs = %{
    platform: "twitter",
    shared_url: long_url,
    post_id: post.id
  }

  # Should raise database error (URL column is VARCHAR(255))
  assert_raise Postgrex.Error, fn ->
    Social.log_share(attrs)
  end
end
```

**Why the difference**:
- **Changeset validations** (`validate_length`) → Returns `{:error, changeset}`
- **Database constraints** (VARCHAR, NOT NULL) → Raises exceptions
- Test assertions must match actual error handling

**Validation layers**:
1. **Schema validation**: `validates_length(:field, max: 255)` → Changeset error
2. **Database constraint**: `VARCHAR(255)` → Exception
3. **Foreign key constraint**: `references(:table)` → Can use `foreign_key_constraint/3` for changeset error

**Reference**: `test/homesite/social_test.exs:113-127`

<!-- Integrated from .claude/insights sessions on 2025-11-30 -->

---

#### Pattern: Comprehensive Edge Case Testing

**Rule**: Test edge cases, injection attempts, and boundary conditions for every public-facing feature.

**Edge cases to always test**:
- Empty/whitespace input
- Very long strings (1000+ chars)
- SQL injection attempts (`'; DROP TABLE posts; --`)
- XSS payloads (`<script>alert('xss')</script>`)
- Unicode characters (`héllo`, `你好`)
- Special characters, newlines, tabs
- Single character input
- Boundary values (0, -1, negative numbers, MAX values)
- Invalid foreign keys
- Empty required fields

**Example**:
```elixir
test "handles SQL injection safely" do
  results = Content.search_posts("'; DROP TABLE posts; --")
  assert is_list(results)  # Doesn't crash

  # Verify posts still exist
  all_posts = Content.list_posts(scope)
  assert length(all_posts) >= 1
end

test "handles very long URLs" do
  long_url = "https://example.com/" <> String.duplicate("a", 300)

  # Should raise database error (VARCHAR(255) constraint)
  assert_raise Postgrex.Error, fn ->
    Social.log_share(%{platform: "twitter", shared_url: long_url})
  end
end
```

**Why**: Edge case testing catches issues before production. In practice, these tests found 3 bugs before deployment:
1. Empty queries returned all posts (fixed)
2. Negative limits crashed (fixed)
3. Missing required assigns (fixed)

**Reference**: `test/homesite/content_search_test.exs:142-268`, `test/homesite/social_test.exs:105-285`

<!-- Integrated from .claude/insights sessions on 2025-11-30 -->

---

### Common Mistakes

#### Mistake: DaisyUI Button Component Has Limited Variant Support

**Problem**: The Phoenix `<.button>` component only supports `variant="primary"` or `variant=nil`. Using other variants like `ghost`, `outline`, `link` will cause a KeyError.

**Wrong**:
```heex
<.button variant="ghost" navigate={~p"/faqs?category=user"}>
  {gettext("User FAQs")}
</.button>
```

**Error**:
```
KeyError at GET /faqs
key "ghost" not found in: %{nil => "btn-primary btn-soft", "primary" => "btn-primary"}
```

**Correct**:
```heex
<.link navigate={~p"/faqs?category=user"} class="btn btn-ghost">
  {gettext("User FAQs")}
</.link>
```

**Rule**:
- Check `lib/homesite_web/components/core_components.ex` for supported variants
- Use `<.button>` only for primary CTAs (call-to-action buttons)
- Use `<.link class="btn btn-{variant}">` for all DaisyUI button variants

**Reference**: `lib/homesite_web/live/faq_live/index.ex:21-26`

<!-- Integrated from .claude/insights sessions on 2025-11-30 -->

---

#### Mistake: Context Functions Require Scope-First Argument Order

**Problem**: Scope-first is the pattern for ALL context functions in this app. Pipe operator changes natural argument flow and causes function clause errors.

**Wrong**:
```elixir
# Piped faq becomes first argument
socket.assigns.faq
|> Faqs.change_faq(socket.assigns.current_scope, faq_params)

# But function expects: change_faq(scope, faq, attrs)
```

**Error**:
```
** (FunctionClauseError) no function clause matching in Homesite.Faqs.change_faq/3
```

**Correct**:
```elixir
# Scope is always first
Faqs.change_faq(socket.assigns.current_scope, socket.assigns.faq, faq_params)
```

**Rule**: Scope-first pattern applies to ALL context functions:
```elixir
# Correct pattern throughout app
Content.get_post!(scope, id)
Content.create_post(scope, attrs)
Content.update_post(scope, post, attrs)
Content.change_post(scope, post, attrs)

Faqs.get_faq!(scope, id)
Faqs.create_faq(scope, attrs)
Faqs.update_faq(scope, faq, attrs)
Faqs.change_faq(scope, faq, attrs)
```

**Avoid pipe-first when context functions need scope**:
```elixir
# Don't do this
post |> Content.update_post(scope, attrs)

# Do this
Content.update_post(scope, post, attrs)
```

**Reference**: `lib/homesite_web/live/faq_live/form.ex:141`

<!-- Integrated from .claude/insights sessions on 2025-11-30 -->

---

### UI/UX Patterns

#### Pattern: Responsive Social Share Buttons with Platform-Specific URLs

**Rule**: Build reusable components with platform-specific URL builders, mobile-first responsive design, and proper security attributes.

**Implementation**:
```elixir
def social_share_buttons(assigns) do
  ~H"""
  <div class={"#{@class} flex flex-wrap gap-2"}>
    <.share_button platform="bluesky" url={@url} title={@title} />
    <.share_button platform="mastodon" url={@url} title={@title} />
    <.share_button platform="twitter" url={@url} title={@title} />
    <!-- ... more platforms -->
  </div>
  """
end

defp share_button(assigns) do
  ~H"""
  <a href={@share_url} target="_blank" rel="noopener noreferrer"
     class="btn btn-sm btn-outline gap-2">
    <.icon name={@icon_name} class="h-4 w-4" />
    <span class="hidden sm:inline">{@label}</span>
  </a>
  """
end

# Platform-specific URL construction
defp build_share_url("bluesky", url, title) do
  text = URI.encode_www_form("#{title} #{url}")
  "https://bsky.app/intent/compose?text=#{text}"
end

defp build_share_url("mastodon", url, title) do
  text = URI.encode_www_form("#{title} #{url}")
  "https://mastodonshare.com/?text=#{text}"  # Universal Mastodon share
end
```

**Key principles**:
1. **Mobile-first**: `hidden sm:inline` shows labels only on larger screens (icons-only on mobile)
2. **Security**: `noopener noreferrer` prevents window.opener attacks
3. **Flexibility**: Easy to add new platforms (just add URL builder)
4. **Encoding**: Proper URL encoding prevents injection
5. **Decentralized social**: Mastodon uses mastodonshare.com for instance selection

**Usage anywhere**:
```heex
<.social_share_buttons url={@current_url} title={@post.title} />
```

**Reference**: `lib/homesite_web/components/social_components.ex`

<!-- Integrated from .claude/insights sessions on 2025-11-30 -->

---

### Dependency Patterns

#### Pattern: GitHub CLI for Issue Management

**Rule**: Use GitHub CLI (`gh`) for all issue operations instead of the web interface.

**Commands**:
```bash
# Close with comment
gh issue close 22 --comment "Fixed RSS feed autodiscovery. Tested with multiple readers."

# Reopen with comment
gh issue reopen 10 --comment "Found regression in user scope isolation."

# Create new issue
gh issue create --title "title" --body "body"
gh issue create --title "title" --body-file file.md

# List all issues
gh issue list --limit 50 --json number,title,state

# Add comment to existing issue
gh issue comment 15 --body "✅ Completed: Language switcher, locale persistence."
```

**Why**:
- **Scriptable**: CLI commands can be automated in EOD workflow
- **Faster**: No context switching to browser
- **Better documentation**: Commands appear in MEMO.md showing exact actions
- **Batch operations**: Can script multiple issue updates

**Integration**: All issue operations in EOD workflow and during development use `gh` commands.

<!-- Integrated from .claude/insights sessions on 2025-11-30 -->

---

### Phoenix v1.8 guidelines

- **Always** begin your LiveView templates with `<Layouts.app flash={@flash} ...>` which wraps all inner content
- The `MyAppWeb.Layouts` module is aliased in the `my_app_web.ex` file, so you can use it without needing to alias it again
- Anytime you run into errors with no `current_scope` assign:
  - You failed to follow the Authenticated Routes guidelines, or you failed to pass `current_scope` to `<Layouts.app>`
  - **Always** fix the `current_scope` error by moving your routes to the proper `live_session` and ensure you pass `current_scope` as needed
- Phoenix v1.8 moved the `<.flash_group>` component to the `Layouts` module. You are **forbidden** from calling `<.flash_group>` outside of the `layouts.ex` module
- Out of the box, `core_components.ex` imports an `<.icon name="hero-x-mark" class="w-5 h-5"/>` component for for hero icons. **Always** use the `<.icon>` component for icons, **never** use `Heroicons` modules or similar
- **Always** use the imported `<.input>` component for form inputs from `core_components.ex` when available. `<.input>` is imported and using it will will save steps and prevent errors
- If you override the default input classes (`<.input class="myclass px-2 py-1 rounded-lg">)`) class with your own values, no default classes are inherited, so your
custom classes must fully style the input

### JS and CSS guidelines

- **Use Tailwind CSS classes and custom CSS rules** to create polished, responsive, and visually stunning interfaces.
- Tailwindcss v4 **no longer needs a tailwind.config.js** and uses a new import syntax in `app.css`:

      @import "tailwindcss" source(none);
      @source "../css";
      @source "../js";
      @source "../../lib/my_app_web";

- **Always use and maintain this import syntax** in the app.css file for projects generated with `phx.new`
- **Never** use `@apply` when writing raw css
- **Always** manually write your own tailwind-based components instead of using daisyUI for a unique, world-class design
- Out of the box **only the app.js and app.css bundles are supported**
  - You cannot reference an external vendor'd script `src` or link `href` in the layouts
  - You must import the vendor deps into app.js and app.css to use them
  - **Never write inline <script>custom js</script> tags within templates**

### UI/UX & design guidelines

- **Produce world-class UI designs** with a focus on usability, aesthetics, and modern design principles
- Implement **subtle micro-interactions** (e.g., button hover effects, and smooth transitions)
- Ensure **clean typography, spacing, and layout balance** for a refined, premium look
- Focus on **delightful details** like hover effects, loading states, and smooth page transitions


<!-- phoenix-gen-auth-start -->
## Authentication

- **Always** handle authentication flow at the router level with proper redirects
- **Always** be mindful of where to place routes. `phx.gen.auth` creates multiple router plugs and `live_session` scopes:
  - A plug `:fetch_current_scope_for_user` that is included in the default browser pipeline
  - A plug `:require_authenticated_user` that redirects to the log in page when the user is not authenticated
  - A `live_session :current_user` scope - for routes that need the current user but don't require authentication, similar to `:fetch_current_scope_for_user`
  - A `live_session :require_authenticated_user` scope - for routes that require authentication, similar to the plug with the same name
  - In both cases, a `@current_scope` is assigned to the Plug connection and LiveView socket
  - A plug `redirect_if_user_is_authenticated` that redirects to a default path in case the user is authenticated - useful for a registration page that should only be shown to unauthenticated users
- **Always let the user know in which router scopes, `live_session`, and pipeline you are placing the route, AND SAY WHY**
- `phx.gen.auth` assigns the `current_scope` assign - it **does not assign a `current_user` assign**
- Always pass the assign `current_scope` to context modules as first argument. When performing queries, use `current_scope.user` to filter the query results
- To derive/access `current_user` in templates, **always use the `@current_scope.user`**, never use **`@current_user`** in templates or LiveViews
- **Never** duplicate `live_session` names. A `live_session :current_user` can only be defined __once__ in the router, so all routes for the `live_session :current_user`  must be grouped in a single block
- Anytime you hit `current_scope` errors or the logged in session isn't displaying the right content, **always double check the router and ensure you are using the correct plug and `live_session` as described below**

### Routes that require authentication

LiveViews that require login should **always be placed inside the __existing__ `live_session :require_authenticated_user` block**:

    scope "/", AppWeb do
      pipe_through [:browser, :require_authenticated_user]

      live_session :require_authenticated_user,
        on_mount: [{HomesiteWeb.UserAuth, :require_authenticated}] do
        # phx.gen.auth generated routes
        live "/users/settings", UserLive.Settings, :edit
        live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
        # our own routes that require logged in user
        live "/", MyLiveThatRequiresAuth, :index
      end
    end

Controller routes must be placed in a scope that sets the `:require_authenticated_user` plug:

    scope "/", AppWeb do
      pipe_through [:browser, :require_authenticated_user]

      get "/", MyControllerThatRequiresAuth, :index
    end

### Routes that work with or without authentication

LiveViews that can work with or without authentication, **always use the __existing__ `:current_user` scope**, ie:

    scope "/", MyAppWeb do
      pipe_through [:browser]

      live_session :current_user,
        on_mount: [{HomesiteWeb.UserAuth, :mount_current_scope}] do
        # our own routes that work with or without authentication
        live "/", PublicLive
      end
    end

Controllers automatically have the `current_scope` available if they use the `:browser` pipeline.

<!-- phoenix-gen-auth-end -->

<!-- usage-rules-start -->
<!-- usage-rules-header -->
# Usage Rules

**IMPORTANT**: Consult these usage rules early and often when working with the packages listed below.
Before attempting to use any of these packages or to discover if you should use them, review their
usage rules to understand the correct patterns, conventions, and best practices.
<!-- usage-rules-header-end -->


<!-- phoenix:elixir-start -->
## phoenix:elixir usage
## Elixir guidelines

- Elixir lists **do not support index based access via the access syntax**

  **Never do this (invalid)**:

      i = 0
      mylist = ["blue", "green"]
      mylist[i]

  Instead, **always** use `Enum.at`, pattern matching, or `List` for index based list access, ie:

      i = 0
      mylist = ["blue", "green"]
      Enum.at(mylist, i)

- Elixir variables are immutable, but can be rebound, so for block expressions like `if`, `case`, `cond`, etc
  you *must* bind the result of the expression to a variable if you want to use it and you CANNOT rebind the result inside the expression, ie:

      # INVALID: we are rebinding inside the `if` and the result never gets assigned
      if connected?(socket) do
        socket = assign(socket, :val, val)
      end

      # VALID: we rebind the result of the `if` to a new variable
      socket =
        if connected?(socket) do
          assign(socket, :val, val)
        end

- **Never** nest multiple modules in the same file as it can cause cyclic dependencies and compilation errors
- **Never** use map access syntax (`changeset[:field]`) on structs as they do not implement the Access behaviour by default. For regular structs, you **must** access the fields directly, such as `my_struct.field` or use higher level APIs that are available on the struct if they exist, `Ecto.Changeset.get_field/2` for changesets
- Elixir's standard library has everything necessary for date and time manipulation. Familiarize yourself with the common `Time`, `Date`, `DateTime`, and `Calendar` interfaces by accessing their documentation as necessary. **Never** install additional dependencies unless asked or for date/time parsing (which you can use the `date_time_parser` package)
- Don't use `String.to_atom/1` on user input (memory leak risk)
- Predicate function names should not start with `is_` and should end in a question mark. Names like `is_thing` should be reserved for guards
- Elixir's builtin OTP primitives like `DynamicSupervisor` and `Registry`, require names in the child spec, such as `{DynamicSupervisor, name: MyApp.MyDynamicSup}`, then you can use `DynamicSupervisor.start_child(MyApp.MyDynamicSup, child_spec)`
- Use `Task.async_stream(collection, callback, options)` for concurrent enumeration with back-pressure. The majority of times you will want to pass `timeout: :infinity` as option

## Mix guidelines

- Read the docs and options before using tasks (by using `mix help task_name`)
- To debug test failures, run tests in a specific file with `mix test test/my_test.exs` or run all previously failed tests with `mix test --failed`
- `mix deps.clean --all` is **almost never needed**. **Avoid** using it unless you have good reason

<!-- phoenix:elixir-end -->

<!-- phoenix:phoenix-start -->
## phoenix:phoenix usage
## Phoenix guidelines

- Remember Phoenix router `scope` blocks include an optional alias which is prefixed for all routes within the scope. **Always** be mindful of this when creating routes within a scope to avoid duplicate module prefixes.

- You **never** need to create your own `alias` for route definitions! The `scope` provides the alias, ie:

      scope "/admin", AppWeb.Admin do
        pipe_through :browser

        live "/users", UserLive, :index
      end

  the UserLive route would point to the `AppWeb.Admin.UserLive` module

- `Phoenix.View` no longer is needed or included with Phoenix, don't use it

<!-- phoenix:phoenix-end -->

<!-- phoenix:ecto-start -->
## phoenix:ecto usage
## Ecto Guidelines

- **Always** preload Ecto associations in queries when they'll be accessed in templates, ie a message that needs to reference the `message.user.email`
- Remember `import Ecto.Query` and other supporting modules when you write `seeds.exs`
- `Ecto.Schema` fields always use the `:string` type, even for `:text`, columns, ie: `field :name, :string`
- `Ecto.Changeset.validate_number/2` **DOES NOT SUPPORT the `:allow_nil` option**. By default, Ecto validations only run if a change for the given field exists and the change value is not nil, so such as option is never needed
- You **must** use `Ecto.Changeset.get_field(changeset, :field)` to access changeset fields
- Fields which are set programatically, such as `user_id`, must not be listed in `cast` calls or similar for security purposes. Instead they must be explicitly set when creating the struct

<!-- phoenix:ecto-end -->

<!-- phoenix:html-start -->
## phoenix:html usage
## Phoenix HTML guidelines

- Phoenix templates **always** use `~H` or .html.heex files (known as HEEx), **never** use `~E`
- **Always** use the imported `Phoenix.Component.form/1` and `Phoenix.Component.inputs_for/1` function to build forms. **Never** use `Phoenix.HTML.form_for` or `Phoenix.HTML.inputs_for` as they are outdated
- When building forms **always** use the already imported `Phoenix.Component.to_form/2` (`assign(socket, form: to_form(...))` and `<.form for={@form} id="msg-form">`), then access those forms in the template via `@form[:field]`
- **Always** add unique DOM IDs to key elements (like forms, buttons, etc) when writing templates, these IDs can later be used in tests (`<.form for={@form} id="product-form">`)
- For "app wide" template imports, you can import/alias into the `my_app_web.ex`'s `html_helpers` block, so they will be available to all LiveViews, LiveComponent's, and all modules that do `use MyAppWeb, :html` (replace "my_app" by the actual app name)

- Elixir supports `if/else` but **does NOT support `if/else if` or `if/elsif`. **Never use `else if` or `elseif` in Elixir**, **always** use `cond` or `case` for multiple conditionals.

  **Never do this (invalid)**:

      <%= if condition do %>
        ...
      <% else if other_condition %>
        ...
      <% end %>

  Instead **always** do this:

      <%= cond do %>
        <% condition -> %>
          ...
        <% condition2 -> %>
          ...
        <% true -> %>
          ...
      <% end %>

- HEEx require special tag annotation if you want to insert literal curly's like `{` or `}`. If you want to show a textual code snippet on the page in a `<pre>` or `<code>` block you *must* annotate the parent tag with `phx-no-curly-interpolation`:

      <code phx-no-curly-interpolation>
        let obj = {key: "val"}
      </code>

  Within `phx-no-curly-interpolation` annotated tags, you can use `{` and `}` without escaping them, and dynamic Elixir expressions can still be used with `<%= ... %>` syntax

- HEEx class attrs support lists, but you must **always** use list `[...]` syntax. You can use the class list syntax to conditionally add classes, **always do this for multiple class values**:

      <a class={[
        "px-2 text-white",
        @some_flag && "py-5",
        if(@other_condition, do: "border-red-500", else: "border-blue-100"),
        ...
      ]}>Text</a>

  and **always** wrap `if`'s inside `{...}` expressions with parens, like done above (`if(@other_condition, do: "...", else: "...")`)

  and **never** do this, since it's invalid (note the missing `[` and `]`):

      <a class={
        "px-2 text-white",
        @some_flag && "py-5"
      }> ...
      => Raises compile syntax error on invalid HEEx attr syntax

- **Never** use `<% Enum.each %>` or non-for comprehensions for generating template content, instead **always** use `<%= for item <- @collection do %>`
- HEEx HTML comments use `<%!-- comment --%>`. **Always** use the HEEx HTML comment syntax for template comments (`<%!-- comment --%>`)
- HEEx allows interpolation via `{...}` and `<%= ... %>`, but the `<%= %>` **only** works within tag bodies. **Always** use the `{...}` syntax for interpolation within tag attributes, and for interpolation of values within tag bodies. **Always** interpolate block constructs (if, cond, case, for) within tag bodies using `<%= ... %>`.

  **Always** do this:

      <div id={@id}>
        {@my_assign}
        <%= if @some_block_condition do %>
          {@another_assign}
        <% end %>
      </div>

  and **Never** do this – the program will terminate with a syntax error:

      <%!-- THIS IS INVALID NEVER EVER DO THIS --%>
      <div id="<%= @invalid_interpolation %>">
        {if @invalid_block_construct do}
        {end}
      </div>

<!-- phoenix:html-end -->

<!-- phoenix:liveview-start -->
## phoenix:liveview usage
## Phoenix LiveView guidelines

- **Never** use the deprecated `live_redirect` and `live_patch` functions, instead **always** use the `<.link navigate={href}>` and  `<.link patch={href}>` in templates, and `push_navigate` and `push_patch` functions LiveViews
- **Avoid LiveComponent's** unless you have a strong, specific need for them
- LiveViews should be named like `AppWeb.WeatherLive`, with a `Live` suffix. When you go to add LiveView routes to the router, the default `:browser` scope is **already aliased** with the `AppWeb` module, so you can just do `live "/weather", WeatherLive`
- Remember anytime you use `phx-hook="MyHook"` and that js hook manages its own DOM, you **must** also set the `phx-update="ignore"` attribute
- **Never** write embedded `<script>` tags in HEEx. Instead always write your scripts and hooks in the `assets/js` directory and integrate them with the `assets/js/app.js` file

### LiveView streams

- **Always** use LiveView streams for collections for assigning regular lists to avoid memory ballooning and runtime termination with the following operations:
  - basic append of N items - `stream(socket, :messages, [new_msg])`
  - resetting stream with new items - `stream(socket, :messages, [new_msg], reset: true)` (e.g. for filtering items)
  - prepend to stream - `stream(socket, :messages, [new_msg], at: -1)`
  - deleting items - `stream_delete(socket, :messages, msg)`

- When using the `stream/3` interfaces in the LiveView, the LiveView template must 1) always set `phx-update="stream"` on the parent element, with a DOM id on the parent element like `id="messages"` and 2) consume the `@streams.stream_name` collection and use the id as the DOM id for each child. For a call like `stream(socket, :messages, [new_msg])` in the LiveView, the template would be:

      <div id="messages" phx-update="stream">
        <div :for={{id, msg} <- @streams.messages} id={id}>
          {msg.text}
        </div>
      </div>

- LiveView streams are *not* enumerable, so you cannot use `Enum.filter/2` or `Enum.reject/2` on them. Instead, if you want to filter, prune, or refresh a list of items on the UI, you **must refetch the data and re-stream the entire stream collection, passing reset: true**:

      def handle_event("filter", %{"filter" => filter}, socket) do
        # re-fetch the messages based on the filter
        messages = list_messages(filter)

        {:noreply,
        socket
        |> assign(:messages_empty?, messages == [])
        # reset the stream with the new messages
        |> stream(:messages, messages, reset: true)}
      end

- LiveView streams *do not support counting or empty states*. If you need to display a count, you must track it using a separate assign. For empty states, you can use Tailwind classes:

      <div id="tasks" phx-update="stream">
        <div class="hidden only:block">No tasks yet</div>
        <div :for={{id, task} <- @stream.tasks} id={id}>
          {task.name}
        </div>
      </div>

  The above only works if the empty state is the only HTML block alongside the stream for-comprehension.

- **Never** use the deprecated `phx-update="append"` or `phx-update="prepend"` for collections

### LiveView tests

- `Phoenix.LiveViewTest` module and `LazyHTML` (included) for making your assertions
- Form tests are driven by `Phoenix.LiveViewTest`'s `render_submit/2` and `render_change/2` functions
- Come up with a step-by-step test plan that splits major test cases into small, isolated files. You may start with simpler tests that verify content exists, gradually add interaction tests
- **Always reference the key element IDs you added in the LiveView templates in your tests** for `Phoenix.LiveViewTest` functions like `element/2`, `has_element/2`, selectors, etc
- **Never** tests again raw HTML, **always** use `element/2`, `has_element/2`, and similar: `assert has_element?(view, "#my-form")`
- Instead of relying on testing text content, which can change, favor testing for the presence of key elements
- Focus on testing outcomes rather than implementation details
- Be aware that `Phoenix.Component` functions like `<.form>` might produce different HTML than expected. Test against the output HTML structure, not your mental model of what you expect it to be
- When facing test failures with element selectors, add debug statements to print the actual HTML, but use `LazyHTML` selectors to limit the output, ie:

      html = render(view)
      document = LazyHTML.from_fragment(html)
      matches = LazyHTML.filter(document, "your-complex-selector")
      IO.inspect(matches, label: "Matches")

### Form handling

#### Creating a form from params

If you want to create a form based on `handle_event` params:

    def handle_event("submitted", params, socket) do
      {:noreply, assign(socket, form: to_form(params))}
    end

When you pass a map to `to_form/1`, it assumes said map contains the form params, which are expected to have string keys.

You can also specify a name to nest the params:

    def handle_event("submitted", %{"user" => user_params}, socket) do
      {:noreply, assign(socket, form: to_form(user_params, as: :user))}
    end

#### Creating a form from changesets

When using changesets, the underlying data, form params, and errors are retrieved from it. The `:as` option is automatically computed too. E.g. if you have a user schema:

    defmodule MyApp.Users.User do
      use Ecto.Schema
      ...
    end

And then you create a changeset that you pass to `to_form`:

    %MyApp.Users.User{}
    |> Ecto.Changeset.change()
    |> to_form()

Once the form is submitted, the params will be available under `%{"user" => user_params}`.

In the template, the form form assign can be passed to the `<.form>` function component:

    <.form for={@form} id="todo-form" phx-change="validate" phx-submit="save">
      <.input field={@form[:field]} type="text" />
    </.form>

Always give the form an explicit, unique DOM ID, like `id="todo-form"`.

#### Avoiding form errors

**Always** use a form assigned via `to_form/2` in the LiveView, and the `<.input>` component in the template. In the template **always access forms this**:

    <%!-- ALWAYS do this (valid) --%>
    <.form for={@form} id="my-form">
      <.input field={@form[:field]} type="text" />
    </.form>

And **never** do this:

    <%!-- NEVER do this (invalid) --%>
    <.form for={@changeset} id="my-form">
      <.input field={@changeset[:field]} type="text" />
    </.form>

- You are FORBIDDEN from accessing the changeset in the template as it will cause errors
- **Never** use `<.form let={f} ...>` in the template, instead **always use `<.form for={@form} ...>`**, then drive all form references from the form assign as in `@form[:field]`. The UI should **always** be driven by a `to_form/2` assigned in the LiveView module that is derived from a changeset

<!-- phoenix:liveview-end -->

<!-- usage_rules-start -->
## usage_rules usage
_A dev tool for Elixir projects to gather LLM usage rules from dependencies_

## Using Usage Rules

Many packages have usage rules, which you should *thoroughly* consult before taking any
action. These usage rules contain guidelines and rules *directly from the package authors*.
They are your best source of knowledge for making decisions.

## Modules & functions in the current app and dependencies

When looking for docs for modules & functions that are dependencies of the current project,
or for Elixir itself, use `mix usage_rules.docs`

```
# Search a whole module
mix usage_rules.docs Enum

# Search a specific function
mix usage_rules.docs Enum.zip

# Search a specific function & arity
mix usage_rules.docs Enum.zip/1
```


## Searching Documentation

You should also consult the documentation of any tools you are using, early and often. The best 
way to accomplish this is to use the `usage_rules.search_docs` mix task. Once you have
found what you are looking for, use the links in the search results to get more detail. For example:

```
# Search docs for all packages in the current application, including Elixir
mix usage_rules.search_docs Enum.zip

# Search docs for specific packages
mix usage_rules.search_docs Req.get -p req

# Search docs for multi-word queries
mix usage_rules.search_docs "making requests" -p req

# Search only in titles (useful for finding specific functions/modules)
mix usage_rules.search_docs "Enum.zip" --query-by title
```


<!-- usage_rules-end -->
<!-- usage_rules:elixir-start -->
## usage_rules:elixir usage
# Elixir Core Usage Rules

## Pattern Matching
- Use pattern matching over conditional logic when possible
- Prefer to match on function heads instead of using `if`/`else` or `case` in function bodies
- `%{}` matches ANY map, not just empty maps. Use `map_size(map) == 0` guard to check for truly empty maps

## Error Handling
- Use `{:ok, result}` and `{:error, reason}` tuples for operations that can fail
- Avoid raising exceptions for control flow
- Use `with` for chaining operations that return `{:ok, _}` or `{:error, _}`

## Common Mistakes to Avoid
- Elixir has no `return` statement, nor early returns. The last expression in a block is always returned.
- Don't use `Enum` functions on large collections when `Stream` is more appropriate
- Avoid nested `case` statements - refactor to a single `case`, `with` or separate functions
- Don't use `String.to_atom/1` on user input (memory leak risk)
- Lists and enumerables cannot be indexed with brackets. Use pattern matching or `Enum` functions
- Prefer `Enum` functions like `Enum.reduce` over recursion
- When recursion is necessary, prefer to use pattern matching in function heads for base case detection
- Using the process dictionary is typically a sign of unidiomatic code
- Only use macros if explicitly requested
- There are many useful standard library functions, prefer to use them where possible

## Function Design
- Use guard clauses: `when is_binary(name) and byte_size(name) > 0`
- Prefer multiple function clauses over complex conditional logic
- Name functions descriptively: `calculate_total_price/2` not `calc/2`
- Predicate function names should not start with `is` and should end in a question mark.
- Names like `is_thing` should be reserved for guards

## Data Structures
- Use structs over maps when the shape is known: `defstruct [:name, :age]`
- Prefer keyword lists for options: `[timeout: 5000, retries: 3]`
- Use maps for dynamic key-value data
- Prefer to prepend to lists `[new | list]` not `list ++ [new]`

## Mix Tasks

- Use `mix help` to list available mix tasks
- Use `mix help task_name` to get docs for an individual task
- Read the docs and options fully before using tasks

## Testing
- Run tests in a specific file with `mix test test/my_test.exs` and a specific test with the line number `mix test path/to/test.exs:123`
- Limit the number of failed tests with `mix test --max-failures n`
- Use `@tag` to tag specific tests, and `mix test --only tag` to run only those tests
- Use `assert_raise` for testing expected exceptions: `assert_raise ArgumentError, fn -> invalid_function() end`
- Use `mix help test` to for full documentation on running tests

## Debugging

- Use `dbg/1` to print values while debugging. This will display the formatted value and other relevant information in the console.

<!-- usage_rules:elixir-end -->
<!-- usage_rules:otp-start -->
## usage_rules:otp usage
# OTP Usage Rules

## GenServer Best Practices
- Keep state simple and serializable
- Handle all expected messages explicitly
- Use `handle_continue/2` for post-init work
- Implement proper cleanup in `terminate/2` when necessary

## Process Communication
- Use `GenServer.call/3` for synchronous requests expecting replies
- Use `GenServer.cast/2` for fire-and-forget messages.
- When in doubt, use `call` over `cast`, to ensure back-pressure
- Set appropriate timeouts for `call/3` operations

## Fault Tolerance
- Set up processes such that they can handle crashing and being restarted by supervisors
- Use `:max_restarts` and `:max_seconds` to prevent restart loops

## Task and Async
- Use `Task.Supervisor` for better fault tolerance
- Handle task failures with `Task.yield/2` or `Task.shutdown/2`
- Set appropriate task timeouts
- Use `Task.async_stream/3` for concurrent enumeration with back-pressure

<!-- usage_rules:otp-end -->
<!-- igniter-start -->
## igniter usage
_A code generation and project patching framework_

[igniter usage rules](deps/igniter/usage-rules.md)
<!-- igniter-end -->
<!-- mdex-start -->
## mdex usage
_Fast and extensible Markdown for Elixir_

[mdex usage rules](deps/mdex/usage-rules.md)
<!-- mdex-end -->
<!-- usage-rules-end -->
