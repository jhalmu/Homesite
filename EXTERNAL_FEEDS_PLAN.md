# External Feeds Integration Plan

**Created:** 2025-11-28
**Status:** Planning
**Priority:** High - Frontpage feature

## Overview

Enable users to aggregate and display external content feeds on their homepage/profile in a block-based layout, including:
- Bluesky posts
- Mastodon toots
- YouTube videos (and other video platforms)
- Instagram posts
- GitHub/GitLab activity
- RSS/Atom/JSON feeds
- Own photo gallery
- Tech aggregators (like techtrib.es)

**Note:** Twitter/X is explicitly excluded from this plan.

## Goals

1. **Block-Based Layout** - Display feeds as individual blocks/sections on the frontpage
2. **Visual Feed Type Indicators** - Use icons to distinguish feed types (Bluesky, YouTube, Instagram, etc.)
3. **Per-User Configuration** - Each user can configure their own feeds
4. **Automatic Updates** - Periodically fetch new content
5. **Performance** - Cache feeds, don't fetch on every page load
6. **Graceful Degradation** - Handle API failures, rate limits, etc.

## Architecture

### Database Schema

#### `feed_sources` table
```elixir
- id (primary key)
- user_id (foreign key to users)
- feed_type (string: "bluesky", "mastodon", "youtube", "instagram", "github", "gitlab", "gallery", "rss", "atom", "json")
- name (string: display name, e.g., "My YouTube Channel")
- url (string: feed URL or API endpoint)
- username (string: for social media handles/channel IDs)
- enabled (boolean: default true)
- refresh_interval (integer: minutes, default 30)
- last_fetched_at (utc_datetime)
- last_error (text: nullable, last error message)
- display_order (integer: for controlling block order on frontpage)
- icon (string: emoji or icon identifier, e.g., "🦋", "▶️", "📷")
- metadata (jsonb: feed-specific config)
- inserted_at, updated_at
```

Indexes:
- `user_id`
- `feed_type`
- `enabled`
- `last_fetched_at` (for background jobs)
- `display_order` (for frontpage ordering)
- Composite: `(user_id, display_order)` (for efficient frontpage queries)

#### `feed_items` table
```elixir
- id (primary key)
- feed_source_id (foreign key to feed_sources, on_delete: delete_all)
- external_id (string: unique ID from source, e.g., post ID)
- title (string: nullable)
- content (text: post content/description)
- author_name (string)
- author_handle (string: @username)
- author_avatar_url (string: nullable)
- published_at (utc_datetime)
- url (string: link to original post)
- metadata (jsonb: likes, retweets, attachments, etc.)
- inserted_at, updated_at
```

Indexes:
- `feed_source_id`
- `external_id` (unique per feed_source)
- `published_at` (for sorting)
- Composite: `(feed_source_id, published_at DESC)`

### Context: `Homesite.Feeds`

```elixir
defmodule Homesite.Feeds do
  # Feed Source Management
  def create_feed_source(user, attrs)
  def update_feed_source(feed_source, attrs)
  def delete_feed_source(feed_source)
  def list_feed_sources(user)
  def get_feed_source!(id)
  def toggle_feed_source(feed_source, enabled)

  # Feed Items
  def list_feed_items(user, opts \\ [])
  def list_feed_items_for_source(feed_source, opts \\ [])
  def get_feed_item!(id)

  # Fetching
  def fetch_feed(feed_source)
  def fetch_all_feeds()
  def fetch_user_feeds(user)
end
```

### Feed Adapters (Strategy Pattern)

Create adapters for each feed type:

```elixir
defmodule Homesite.Feeds.Adapters.Bluesky do
  @behaviour Homesite.Feeds.Adapter

  def fetch(feed_source)
  def parse_item(raw_post)
end

defmodule Homesite.Feeds.Adapters.Mastodon do
  @behaviour Homesite.Feeds.Adapter

  def fetch(feed_source)
  def parse_item(raw_toot)
end

defmodule Homesite.Feeds.Adapters.RSS do
  @behaviour Homesite.Feeds.Adapter

  def fetch(feed_source)
  def parse_item(raw_entry)
end

defmodule Homesite.Feeds.Adapters.Atom do
  @behaviour Homesite.Feeds.Adapter

  def fetch(feed_source)
  def parse_item(raw_entry)
end

defmodule Homesite.Feeds.Adapters.JSONFeed do
  @behaviour Homesite.Feeds.Adapter

  def fetch(feed_source)
  def parse_item(raw_item)
end

defmodule Homesite.Feeds.Adapters.YouTube do
  @behaviour Homesite.Feeds.Adapter

  def fetch(feed_source)
  def parse_item(raw_video)
end

defmodule Homesite.Feeds.Adapters.Instagram do
  @behaviour Homesite.Feeds.Adapter

  def fetch(feed_source)
  def parse_item(raw_post)
end

defmodule Homesite.Feeds.Adapters.GitHub do
  @behaviour Homesite.Feeds.Adapter

  def fetch(feed_source)
  def parse_item(raw_event)
end

defmodule Homesite.Feeds.Adapters.GitLab do
  @behaviour Homesite.Feeds.Adapter

  def fetch(feed_source)
  def parse_item(raw_event)
end

defmodule Homesite.Feeds.Adapters.Gallery do
  @behaviour Homesite.Feeds.Adapter

  def fetch(feed_source)
  def parse_item(raw_photo)
end
```

### Background Jobs (Oban)

```elixir
defmodule Homesite.Workers.FeedFetcher do
  use Oban.Worker, queue: :feeds, max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"feed_source_id" => id}}) do
    feed_source = Feeds.get_feed_source!(id)
    Feeds.fetch_feed(feed_source)
  end
end

# Cron job configuration in config/config.exs
config :homesite, Oban,
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       # Fetch feeds every 30 minutes
       {"*/30 * * * *", Homesite.Workers.FeedScheduler}
     ]}
  ]
```

## API Integration Details

### 1. Bluesky (AT Protocol)

**API:** https://docs.bsky.app/docs/api/

**Endpoint:** `GET /xrpc/app.bsky.feed.getAuthorFeed`
- Requires: DID or handle
- Returns: Posts in reverse chronological order
- Authentication: Optional (public feeds)

**Dependencies:**
- `req` (already included) or `atproto` Elixir library

**Example:**
```elixir
def fetch_bluesky(username) do
  Req.get!("https://public.api.bsky.app/xrpc/app.bsky.feed.getAuthorFeed",
    params: %{actor: username, limit: 50}
  )
end
```

### 2. Mastodon

**API:** https://docs.joinmastodon.org/client/intro/

**Endpoint:** `GET /api/v1/accounts/:id/statuses`
- Requires: Instance URL + Account ID
- Returns: Toots (posts)
- Authentication: Optional for public toots

**Challenges:**
- Need to resolve username to account ID first
- Different instances have different URLs

**Dependencies:**
- `req` for HTTP requests

**Example:**
```elixir
def fetch_mastodon(instance, username) do
  # First: Search for user to get account ID
  account = Req.get!("https://#{instance}/api/v2/search",
    params: %{q: username, type: "accounts", limit: 1}
  )

  account_id = hd(account.body["accounts"])["id"]

  # Then: Fetch statuses
  Req.get!("https://#{instance}/api/v1/accounts/#{account_id}/statuses",
    params: %{limit: 40, exclude_replies: false}
  )
end
```

### 3. RSS/Atom Feeds

**Libraries:**
- `feeder_ex` - RSS/Atom parser for Elixir
- Or use existing `atomex` (already included) + custom RSS parser

**Example:**
```elixir
def fetch_rss(url) do
  {:ok, response} = Req.get(url)
  {:ok, feed} = FeederEx.parse(response.body)
  feed.entries
end
```

### 4. JSON Feed

**Spec:** https://www.jsonfeed.org/version/1.1/

**Simple to parse** - just JSON:
```elixir
def fetch_json_feed(url) do
  response = Req.get!(url)
  response.body["items"]
end
```

### 5. YouTube

**API:** YouTube Data API v3 OR RSS feeds (simpler)

**Option A: RSS Feed (Recommended - No API Key Required)**
- URL: `https://www.youtube.com/feeds/videos.xml?channel_id=CHANNEL_ID`
- Returns: Standard Atom feed
- Free, no authentication needed

**Option B: YouTube Data API**
- Requires API key (Google Cloud)
- More metadata available
- Rate limits apply

**Recommendation:** Start with RSS feeds - simpler, no API keys

**Example:**
```elixir
def fetch_youtube_rss(channel_id) do
  url = "https://www.youtube.com/feeds/videos.xml?channel_id=#{channel_id}"
  {:ok, response} = Req.get(url)
  FeederEx.parse(response.body)  # Atom feed
end
```

### 6. Instagram

**Challenge:** Instagram deprecated public API for basic access

**Options:**
1. **Instagram Basic Display API** (requires OAuth, limited to user's own content)
2. **Third-party scrapers** (fragile, against ToS)
3. **RSS Bridge** (self-hosted proxy service)

**Recommendation:**
- Start with Instagram Basic Display API for authenticated users
- Consider RSS Bridge as fallback
- Warn users this integration is limited

**Note:** This is the most challenging integration due to Instagram's closed API

### 7. GitHub

**API:** GitHub REST API v3 (public events)

**Endpoint:** `GET /users/:username/events/public`
- No authentication required for public events
- Rate limit: 60 requests/hour (unauthenticated)
- Returns: User's public activity (commits, PRs, issues, stars, etc.)

**Dependencies:**
- `req` for HTTP requests

**Example:**
```elixir
def fetch_github_activity(username) do
  Req.get!("https://api.github.com/users/#{username}/events/public",
    headers: %{"Accept" => "application/vnd.github.v3+json"}
  )
end
```

### 8. GitLab

**API:** GitLab REST API (user events)

**Endpoint:** `GET /users/:username/events`
- Works with gitlab.com or self-hosted instances
- No authentication required for public events
- Returns: User's public activity

**Example:**
```elixir
def fetch_gitlab_activity(instance \\ "gitlab.com", username) do
  Req.get!("https://#{instance}/api/v4/users/#{username}/events")
end
```

### 9. Own Photo Gallery

**Integration:** Internal content type, not external feed

**Approach:**
- Treat as special feed type that reads from internal photo storage
- Could be existing photos in `/priv/static/uploads` or dedicated photo schema
- Display in same block format as external feeds

**Questions to resolve:**
- Do you have an existing photo schema/storage?
- Should this be a new Content context (like Posts/Tags)?
- File upload handling?

**Placeholder implementation:**
```elixir
def fetch_gallery(feed_source) do
  # Read from internal photo storage
  # Could query a Photos schema or scan filesystem
  user_id = feed_source.user_id
  Photos.list_recent_photos(user_id, limit: 20)
end
```

### 10. Other Video Platforms

**Platforms to consider:**
- **Vimeo** - Has RSS feeds (similar to YouTube)
- **PeerTube** - Decentralized, has Atom/RSS feeds
- **TikTok** - No public API (very limited)
- **Twitch** - Has API (requires OAuth)

**Recommendation:** Start with Vimeo and PeerTube (both support RSS/Atom)

## UI/UX Design

### User Settings Page (`/users/settings/feeds`)

**Sections:**

1. **Feed Sources List**
   - Table showing all configured feeds
   - Columns: Name, Type, Status, Last Fetched, Actions
   - Enable/Disable toggle
   - Edit/Delete buttons

2. **Add New Feed Form**
   - Feed Type selector (Bluesky, Mastodon, RSS, etc.)
   - Dynamic form fields based on type:
     - **Bluesky:** Username/Handle
     - **Mastodon:** Instance + Username
     - **RSS/Atom/JSON:** Feed URL
   - Display name (optional, auto-filled from feed metadata)
   - Refresh interval slider (15min - 24hrs)

3. **Test Feed Button**
   - Validate URL/credentials before saving
   - Show preview of latest items

### Frontpage Display (`/` or user profile)

**Layout:** Block-based layout where each feed source gets its own section/card

```
┌─────────────────────────────────────────────────────────┐
│                     MY HOMEPAGE                          │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────────────────────────────────────┐      │
│  │ 📝 Latest Blog Posts                          │      │
│  │ ─────────────────────────────────────────────│      │
│  │ • Getting Started with Elixir    (2h ago)   │      │
│  │ • Phoenix LiveView Tips          (1d ago)    │      │
│  │                              [View all posts →] │      │
│  └──────────────────────────────────────────────┘      │
│                                                          │
│  ┌──────────────────────────────────────────────┐      │
│  │ 🦋 Bluesky Feed                               │      │
│  │ ─────────────────────────────────────────────│      │
│  │ @username: Just shipped a new feature!       │      │
│  │ @username: Working on Elixir project...      │      │
│  │                          [View on Bluesky →] │      │
│  └──────────────────────────────────────────────┘      │
│                                                          │
│  ┌──────────────────────────────────────────────┐      │
│  │ ▶️ YouTube - My Channel                       │      │
│  │ ─────────────────────────────────────────────│      │
│  │ 🎬 Tutorial: Phoenix LiveView (3d ago)       │      │
│  │ 🎬 Building a Blog in Elixir (1w ago)        │      │
│  │                         [View on YouTube →]  │      │
│  └──────────────────────────────────────────────┘      │
│                                                          │
│  ┌──────────────────────────────────────────────┐      │
│  │ 📷 Photo Gallery                              │      │
│  │ ─────────────────────────────────────────────│      │
│  │ [img] [img] [img] [img]                      │      │
│  │                           [View gallery →]   │      │
│  └──────────────────────────────────────────────┘      │
│                                                          │
│  ┌──────────────────────────────────────────────┐      │
│  │ 💻 GitHub Activity                            │      │
│  │ ─────────────────────────────────────────────│      │
│  │ ⭐ Starred elixir/phoenix                    │      │
│  │ 🔀 Opened PR in user/repo                    │      │
│  │                          [View on GitHub →]  │      │
│  └──────────────────────────────────────────────┘      │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

**Key Features:**

1. **Separate Blocks** - Each feed source is a distinct card/section
2. **Visual Icons** - Each block has an icon identifying the feed type
3. **User-Controlled Order** - Users can reorder blocks via drag-and-drop or settings
4. **Expandable/Collapsible** - Blocks can be collapsed to save space
5. **Consistent Layout** - All blocks follow same structure (header, content preview, "view more" link)
6. **Responsive** - Blocks stack vertically on mobile, may go multi-column on desktop

**Implementation Approach:**

- Use `display_order` field to control block positioning
- DaisyUI cards for consistent block styling
- Icons from feed_sources.icon field
- Show 3-5 most recent items per block
- "View all" links to dedicated pages or external sources

### Icon System

**Feed Type Icons** (stored in `feed_sources.icon` field):

| Feed Type  | Icon | Emoji Alternative |
|------------|------|-------------------|
| Blog Posts | 📝   | hero-document-text |
| Bluesky    | 🦋   | (custom SVG)      |
| Mastodon   | 🐘   | (custom SVG)      |
| YouTube    | ▶️   | hero-play         |
| Instagram  | 📷   | hero-camera       |
| GitHub     | 💻   | hero-code-bracket |
| GitLab     | 🦊   | (custom SVG)      |
| Gallery    | 🖼️   | hero-photo        |
| RSS        | 📰   | hero-rss          |
| Atom       | ⚛️   | hero-rss          |
| JSON Feed  | { }  | hero-code-bracket |

**Implementation:**
- Default to emoji for simplicity
- Allow custom SVG icons via metadata
- Use DaisyUI icon classes where applicable
- Fallback to heroicons for consistency

### Feed Block Component

```heex
<div class="feed-block card bg-base-100 shadow-xl mb-6">
  <div class="card-body">
    <!-- Block Header with Icon -->
    <h2 class="card-title flex items-center gap-2">
      <span class="text-2xl">{@feed_source.icon}</span>
      <span>{@feed_source.name}</span>
      <%= if not @feed_source.enabled do %>
        <span class="badge badge-ghost">Disabled</span>
      <% end %>
    </h2>

    <!-- Feed Items Preview (3-5 items) -->
    <div class="space-y-3 mt-4">
      <%= for item <- Enum.take(@items, 5) do %>
        <div class="flex items-start gap-3 p-3 bg-base-200 rounded-lg hover:bg-base-300 transition">
          <%= if item.author_avatar_url do %>
            <img src={item.author_avatar_url} class="w-10 h-10 rounded-full" />
          <% end %>
          <div class="flex-1 min-w-0">
            <p class="font-medium truncate">{item.title || item.content}</p>
            <p class="text-sm text-base-content/60">
              {item.author_name} · {time_ago(item.published_at)}
            </p>
          </div>
        </div>
      <% end %>
    </div>

    <!-- Footer: View More Link -->
    <div class="card-actions justify-end mt-4">
      <a href={@feed_source.url} target="_blank" class="btn btn-sm btn-outline gap-2">
        View on {@feed_source.feed_type |> String.capitalize()}
        <.icon name="hero-arrow-top-right-on-square" class="w-4 h-4" />
      </a>
    </div>
  </div>
</div>
```

## Implementation Phases

### Phase 1: Foundation (4-6 hours)
- [ ] Database migrations for `feed_sources` and `feed_items`
  - [ ] Add `display_order` and `icon` fields
- [ ] `Feeds` context with basic CRUD
- [ ] `FeedSource` and `FeedItem` schemas
- [ ] Adapter behaviour definition
- [ ] Settings page UI (list feeds, add/edit/delete, reorder)

### Phase 2: Simple Feeds (RSS/Atom/JSON) (3-4 hours)
- [ ] Install `feeder_ex` dependency
- [ ] Implement RSS adapter
- [ ] Implement Atom adapter
- [ ] Implement JSON Feed adapter
- [ ] Test with real feeds (e.g., Hacker News, tech blogs)

### Phase 3: Social Media - Bluesky & Mastodon (4-5 hours)
- [ ] Implement Bluesky adapter (AT Protocol)
- [ ] Implement Mastodon adapter (with instance resolution)
- [ ] Handle API rate limits
- [ ] Test with real accounts

### Phase 4: Video Platforms - YouTube (2-3 hours)
- [ ] Implement YouTube RSS adapter (channel feeds)
- [ ] Parse video metadata
- [ ] Add Vimeo support (similar RSS approach)
- [ ] Test with real channels

### Phase 5: Developer Platforms - GitHub & GitLab (3-4 hours)
- [ ] Implement GitHub activity adapter
- [ ] Implement GitLab activity adapter
- [ ] Support self-hosted GitLab instances
- [ ] Parse event types (commits, PRs, stars, etc.)
- [ ] Test with real users

### Phase 6: Instagram Integration (4-6 hours)
- [ ] Research current Instagram API options
- [ ] Implement Instagram Basic Display API (OAuth flow)
- [ ] Or implement RSS Bridge integration
- [ ] Warning UI about limitations
- [ ] Test with authenticated users

### Phase 7: Photo Gallery Integration (3-4 hours)
- [ ] Define photo storage approach (schema vs filesystem)
- [ ] Implement gallery adapter
- [ ] File upload handling (if needed)
- [ ] Display in feed blocks
- [ ] Test photo display

### Phase 8: Background Jobs (2-3 hours)
- [ ] Install and configure Oban
- [ ] Create FeedFetcher worker
- [ ] Create FeedScheduler for cron
- [ ] Error handling and retry logic
- [ ] Monitor API rate limits

### Phase 9: Block-Based Frontpage (5-6 hours)
- [ ] Update homepage LiveView with block layout
- [ ] Implement feed block component
- [ ] Drag-and-drop reordering (Phoenix LiveView hooks)
- [ ] Collapsible blocks
- [ ] Responsive design (mobile-first)
- [ ] Loading states per block
- [ ] Empty states

### Phase 10: Icon System (1-2 hours)
- [ ] Default icon mappings (emoji)
- [ ] Custom icon support via metadata
- [ ] SVG icon assets for platforms
- [ ] Icon picker in settings UI

### Phase 11: Polish & Testing (4-5 hours)
- [ ] Write tests for all adapters
- [ ] Test error scenarios (network failures, invalid feeds)
- [ ] Performance optimization (caching, DB indexes)
- [ ] Rate limiting protection
- [ ] Security (sanitize HTML content, SSRF prevention)
- [ ] E2E tests with Playwright

**Total Estimate:** 35-48 hours (~5-6 days)

**Note:** Instagram integration is most uncertain due to API limitations. May need to adjust approach or defer.

## Dependencies to Add

```elixir
# mix.exs
defp deps do
  [
    # ... existing deps
    {:oban, "~> 2.17"},           # Background jobs
    {:feeder_ex, "~> 1.1"},       # RSS/Atom parsing
    {:html_sanitize_ex, "~> 1.4"} # Sanitize external HTML
  ]
end
```

## Security Considerations

1. **HTML Sanitization**
   - Use `html_sanitize_ex` to clean external content
   - Strip dangerous tags (script, iframe, etc.)
   - Allow safe formatting (b, i, a, p, etc.)

2. **Rate Limiting**
   - Respect API rate limits (Bluesky: 3000/5min, Mastodon: varies)
   - Implement exponential backoff on failures
   - Cache responses to reduce API calls

3. **URL Validation**
   - Validate feed URLs before fetching
   - Prevent SSRF attacks (no internal IPs, localhost)
   - Use timeout on HTTP requests

4. **Error Handling**
   - Gracefully handle API downtime
   - Don't crash if one feed fails
   - Store error messages for debugging

## Configuration

```elixir
# config/config.exs
config :homesite, Homesite.Feeds,
  default_refresh_interval: 30,  # minutes
  max_items_per_feed: 50,
  fetch_timeout: 10_000,          # 10 seconds
  user_agent: "Homesite/1.0 (+https://yoursite.com)"

# Oban configuration
config :homesite, Oban,
  repo: Homesite.Repo,
  queues: [default: 10, feeds: 5],
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       {"*/30 * * * *", Homesite.Workers.FeedScheduler}
     ]}
  ]
```

## Future Enhancements

- **Feed filtering** (keywords, hashtags, content types)
- **Smart block sizing** (auto-adjust based on content/engagement)
- **Feed mixing within blocks** (combine related sources)
- **Export aggregated feed** as RSS/JSON
- **Mobile app support** (dedicated JSON API)
- **Feed templates** (pre-configured popular feeds for quick setup)
- **Cross-posting** (publish to multiple platforms from one interface)
- **Analytics** (track which feeds/blocks get most engagement)
- **Webhooks** (notify when new content appears in feeds)

## Open Questions

1. **Photo Gallery Implementation Details:**
   - Do you have an existing photo schema/storage system?
   - Should this be a new Content context (like Posts/Tags)?
   - File upload handling approach?
   - Storage location (S3, local filesystem, database)?

2. **Block Layout Preferences:**
   - Single column (mobile-first) or multi-column on desktop?
   - Should blocks be collapsible by default or always expanded?
   - Fixed height per block or variable based on content?

3. **Should users be able to share their aggregated feed?**
   - Generate public URL like `/users/:username/feed`?
   - Export as RSS/JSON for others to subscribe?

4. **Metadata Display:**
   - Show engagement metrics (likes, retweets, stars)?
   - Or keep blocks minimal with just content?

5. **Archive Policy:**
   - Delete feed items older than X days?
   - Or keep everything for search/history?

6. **Default Feed Sources:**
   - Should new users get pre-configured example feeds?
   - Or start with empty state?

## Monetization Considerations

**Status:** Deferred for future planning

Per user request, monetization strategy will be addressed separately as a site-wide plan. Key questions to revisit later:

- How many feed sources should free users get? (e.g., 5-10 sources)
- What's included in a paid tier? (unlimited feeds, priority refresh, advanced filtering)
- Pricing model (monthly subscription, one-time payment, freemium)
- Free tier sustainability (server costs for fetching/storing external feeds)
- Target audience (personal blogs, professional portfolios, small businesses)

**Action:** Create separate MONETIZATION_PLAN.md when ready to address this.

---

**Next Steps:**
1. Review plan and answer open questions (especially photo gallery details)
2. Create GitHub issue for this feature (#29 already exists)
3. Start with Phase 1 implementation once photo gallery approach is decided
