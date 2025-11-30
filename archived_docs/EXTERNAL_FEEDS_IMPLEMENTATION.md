# External Feeds Implementation - Complete Documentation

**Status:** Phase 1, 2, 5 Complete (RSS/Atom fully automated)
**Last Updated:** 2025-11-28
**Commits:** ef13d99, 3607744, 6a9537a

## Overview

Multi-user RSS/Atom feed aggregation system with automatic background refresh. Each user can configure their own feed sources, and the system automatically fetches and caches items every 30 minutes.

## Architecture

### Database Schema

#### feed_sources
Stores user feed configurations.

```elixir
schema "feed_sources" do
  field :feed_type, :string          # "rss", "atom", "json", "bluesky", "mastodon"
  field :name, :string
  field :url, :string                # For RSS/Atom/JSON
  field :username, :string           # For Bluesky/Mastodon
  field :enabled, :boolean
  field :display_order, :integer
  field :icon, :string               # Emoji (📰, 🦋, 🐘)
  field :refresh_interval, :integer  # Minutes (default: 30)
  field :last_fetched_at, :utc_datetime
  field :last_error, :text
  field :allow_embedding, :boolean
  field :view_count, :integer
  field :share_count, :integer
  field :metadata, :map

  belongs_to :user, User
  has_many :feed_items, FeedItem
  timestamps()
end
```

#### feed_items
Cached feed content.

```elixir
schema "feed_items" do
  field :external_id, :string        # GUID or hash
  field :title, :string
  field :content, :text              # HTML sanitized
  field :author_name, :string
  field :author_handle, :string
  field :author_avatar_url, :string
  field :published_at, :utc_datetime
  field :url, :string
  field :metadata, :map              # Categories, enclosures, etc.

  belongs_to :feed_source, FeedSource
  timestamps()
end
```

**Indexes:**
- `feed_sources`: user_id, feed_type, enabled, last_fetched_at
- `feed_items`: feed_source_id, published_at, UNIQUE(feed_source_id, external_id)

### Code Organization

```
lib/homesite/
├── external_feeds.ex                    # Main context
├── external_feeds/
│   ├── feed_source.ex                   # Schema
│   ├── feed_item.ex                     # Schema
│   ├── feed_fetcher.ex                  # Orchestration
│   └── adapters/
│       ├── feed_adapter.ex              # Behaviour
│       └── rss_adapter.ex               # RSS/Atom implementation
└── workers/
    └── feed_refresh_worker.ex           # Oban background job

test/homesite/
├── external_feeds_test.exs              # Context tests (21)
├── external_feeds/
│   ├── adapters/
│   │   └── rss_adapter_test.exs         # Adapter tests (3)
│   └── feed_fetcher_test.exs            # Fetcher tests (3)
└── workers/
    └── feed_refresh_worker_test.exs     # Worker tests (9)
```

## Implementation Details

### Phase 1: Foundation

**Database & Schemas:**
- Migrations for feed_sources and feed_items
- FeedSource schema with validation for 5 feed types
- FeedItem schema for cached content
- User relationship: `has_many :feed_sources`

**Context (Scoped):**
```elixir
# All operations scoped to current user
ExternalFeeds.list_feed_sources(scope)
ExternalFeeds.create_feed_source(scope, attrs)
ExternalFeeds.update_feed_source(scope, feed_source, attrs)
ExternalFeeds.delete_feed_source(scope, feed_source)

# Feed items
ExternalFeeds.list_feed_items(scope, opts)
ExternalFeeds.list_feed_items_for_source(scope, feed_source_id, opts)
```

**Security:**
- Scope isolation enforced: `true = record.user_id == scope.user.id`
- Prevents users accessing other users' feeds

### Phase 2: RSS/Atom Adapter

**Parser (sweet_xml):**
```elixir
# RSS 2.0
xpath(~x"//item"l,
  title: ~x"./title/text()"s,
  link: ~x"./link/text()"s,
  description: ~x"./description/text()"s,
  pub_date: ~x"./pubDate/text()"s,
  guid: ~x"./guid/text()"s
)

# Atom 1.0
xpath(~x"//entry"l,
  title: ~x"./title/text()"s,
  link: ~x"./link[@rel='alternate']/@href"s,
  content: ~x"./content/text()"s,
  published: ~x"./published/text()"s,
  id: ~x"./id/text()"s
)
```

**Features:**
- HTTP fetching with Req (2 retries, 1s delay)
- Multiple date format support (ISO8601, RFC1123, RFC2822)
- HTML sanitization with HtmlSanitizeEx
- Stable external IDs (GUID → link hash → fallback)
- Graceful error handling

**FeedFetcher:**
```elixir
# Single feed
FeedFetcher.fetch_and_store(feed_source)

# All enabled feeds
FeedFetcher.fetch_all_enabled()
```

### Phase 5: Oban Background Jobs

**Worker Configuration:**
```elixir
use Oban.Worker,
  queue: :feeds,
  max_attempts: 3,
  priority: 1
```

**Job Modes:**

1. **Single Feed Refresh:**
```elixir
%{feed_source_id: 123}
```
- Respects `refresh_interval`
- Skips recently refreshed feeds
- Handles disabled feeds
- Cancels for non-existent feeds

2. **Batch Refresh All:**
```elixir
%{refresh_all: true}
```
- Refreshes all enabled feeds
- Returns summary with counts
- Scheduled via cron every 30 minutes

**Scheduling:**
```elixir
# Manual refresh
ExternalFeeds.schedule_refresh(feed_source_id)

# Batch refresh
ExternalFeeds.schedule_refresh_all()

# Individual parallel jobs
ExternalFeeds.schedule_individual_refreshes()
```

**Cron Configuration (config/config.exs):**
```elixir
config :homesite, Oban,
  repo: Homesite.Repo,
  queues: [default: 10, feeds: 5, analytics: 2],
  plugins: [
    Oban.Plugins.Pruner,
    {Oban.Plugins.Cron,
     crontab: [
       {"*/30 * * * *", Homesite.Workers.FeedRefreshWorker,
        args: %{refresh_all: true}}
     ]}
  ]
```

## Usage Examples

### Creating a Feed Source

```elixir
# Get user scope
user = Accounts.get_user!(user_id)
scope = Accounts.Scope.for_user(user)

# Create RSS feed
{:ok, feed_source} = ExternalFeeds.create_feed_source(scope, %{
  feed_type: "rss",
  name: "Elixir Forum",
  url: "https://elixirforum.com/latest.rss",
  enabled: true,
  refresh_interval: 30,  # minutes
  icon: "📰"
})

# Manually trigger first fetch
ExternalFeeds.schedule_refresh(feed_source.id)
```

### Listing Feed Items

```elixir
# All items from user's feeds
items = ExternalFeeds.list_feed_items(scope, limit: 50)

# Items from specific feed
items = ExternalFeeds.list_feed_items_for_source(scope, feed_source_id, limit: 20)

# Items are sorted by published_at DESC (newest first)
# Each item includes preloaded feed_source
```

### Managing Feeds

```elixir
# Update feed
{:ok, updated} = ExternalFeeds.update_feed_source(scope, feed_source, %{
  enabled: false,
  refresh_interval: 60
})

# Delete feed (cascade deletes feed_items)
{:ok, deleted} = ExternalFeeds.delete_feed_source(scope, feed_source)

# Cleanup old items (runs automatically)
{deleted_count, _} = ExternalFeeds.delete_old_feed_items(30)  # 30 days
```

## Testing

### Test Coverage: 36 tests (313 total)

**Context Tests (21):**
- Scope isolation (users can't access others' feeds)
- CRUD operations
- Feed type validation
- Feed item caching
- Cleanup operations

**Adapter Tests (3):**
- Validation
- Error handling (invalid URLs, malformed XML)
- Integration tests (marked `:external`)

**Fetcher Tests (3):**
- Single feed refresh
- Batch refresh
- Error recording

**Worker Tests (9):**
- All job modes
- Scheduling validation
- Interval-based refresh
- Disabled feed handling
- Error scenarios

### Running Tests

```bash
# All tests (excluding external network calls)
mix test --exclude external --exclude playwright

# Specific test file
mix test test/homesite/external_feeds_test.exs

# With external network tests (may fail if feeds change)
mix test --exclude playwright
```

## Production Deployment

### Prerequisites
1. PostgreSQL database
2. Oban configured (already done)
3. Environment variables (if needed for API keys)

### Deployment Steps

1. **Run Migrations:**
```bash
mix ecto.migrate
```

2. **Verify Oban Configuration:**
```elixir
# config/runtime.exs or config/prod.exs
config :homesite, Oban,
  repo: Homesite.Repo,
  queues: [default: 10, feeds: 5, analytics: 2],
  plugins: [
    Oban.Plugins.Pruner,
    {Oban.Plugins.Cron,
     crontab: [
       {"*/30 * * * *", Homesite.Workers.FeedRefreshWorker,
        args: %{refresh_all: true}}
     ]}
  ]
```

3. **Start Application:**
- Oban cron will automatically start
- First refresh happens within 30 minutes
- Or manually trigger: `ExternalFeeds.schedule_refresh_all()`

### Monitoring

**Check Oban Jobs:**
```elixir
# In IEx console
Oban.Job |> Repo.all()

# Failed jobs
Oban.Job |> where([j], j.state == "retryable") |> Repo.all()
```

**Check Feed Status:**
```elixir
# Feeds with errors
FeedSource |> where([f], not is_nil(f.last_error)) |> Repo.all()

# Recently fetched
FeedSource |> where([f], f.last_fetched_at > ago(1, "hour")) |> Repo.all()
```

**Phoenix LiveDashboard:**
- Access at `/dev/dashboard` (dev) or configure for production
- Monitor Oban jobs, queues, and stats

## Known Limitations

### Current Implementation
1. ✅ RSS/Atom/JSON feeds supported
2. ❌ Bluesky adapter not yet implemented
3. ❌ Mastodon adapter not yet implemented
4. ❌ LiveView UI not yet implemented

### External Network Tests
- Tests marked `:external` depend on live RSS feeds
- May fail if external feeds change/block requests
- Excluded by default in CI

### Performance
- sweet_xml parses entire feed (no streaming)
- Large feeds (1000+ items) may be slow
- Consider adding pagination for very large feeds

## Next Phases

### Phase 3: Bluesky Adapter (OPTIONAL, 3-4h)
- AT Protocol API integration
- Public feed fetching
- Parse Bluesky posts

### Phase 4: Mastodon Adapter (OPTIONAL, 3-4h)
- ActivityPub/Mastodon API
- Public timeline fetching
- Parse toots

### Phase 6: LiveView UI (PRIORITY, 4-5h)
- Feed source CRUD interface
- Unified timeline display
- Filtering & sorting
- Manual refresh buttons
- Error display

### Phase 7: Polish (3-4h)
- Security audit
- Performance optimization
- Documentation
- Error handling improvements

## Troubleshooting

### Feeds not refreshing
1. Check Oban is running: `Oban.check_queue(:feeds)`
2. Check cron plugin: Look for scheduled jobs
3. Manually trigger: `ExternalFeeds.schedule_refresh_all()`
4. Check logs for errors

### Feed errors
1. Check `feed_source.last_error` field
2. Verify URL is accessible
3. Test XML parsing manually
4. Check Req timeout settings

### Duplicate items
- Should not happen (unique constraint on feed_source_id + external_id)
- If duplicates appear, check external_id generation logic

### Performance issues
1. Reduce refresh_interval for less critical feeds
2. Adjust Oban queue concurrency (`:feeds` queue)
3. Add indexes if needed (already optimized)
4. Consider cleanup of old items more frequently

## References

- **Oban Documentation:** https://hexdocs.pm/oban/
- **sweet_xml:** https://hexdocs.pm/sweet_xml/
- **RSS 2.0 Spec:** https://www.rssboard.org/rss-specification
- **Atom 1.0 Spec:** https://www.ietf.org/rfc/rfc4287.txt
- **Issue #29:** https://github.com/jhalmu/Homesite/issues/29

## File Manifest

**Migrations:**
- `priv/repo/migrations/*_create_feed_sources.exs`
- `priv/repo/migrations/*_create_feed_items.exs`

**Schemas:**
- `lib/homesite/external_feeds/feed_source.ex`
- `lib/homesite/external_feeds/feed_item.ex`

**Context:**
- `lib/homesite/external_feeds.ex`

**Adapters:**
- `lib/homesite/external_feeds/adapters/feed_adapter.ex`
- `lib/homesite/external_feeds/adapters/rss_adapter.ex`
- `lib/homesite/external_feeds/feed_fetcher.ex`

**Workers:**
- `lib/homesite/workers/feed_refresh_worker.ex`

**Tests:**
- `test/homesite/external_feeds_test.exs` (21 tests)
- `test/homesite/external_feeds/adapters/rss_adapter_test.exs` (3 tests)
- `test/homesite/external_feeds/feed_fetcher_test.exs` (3 tests)
- `test/homesite/workers/feed_refresh_worker_test.exs` (9 tests)

**Total: 36 tests, 313 passing (all core tests)**
