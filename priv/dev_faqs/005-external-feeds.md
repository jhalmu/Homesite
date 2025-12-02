---
title: "External Feeds System"
order: 5
category: "features"
---

# External Feeds System

## Overview

Comprehensive feed aggregation system supporting **10 platform adapters** with read tracking, bookmarking, folder organization, and analytics.

## Supported Platforms

### RSS/Atom (P0 - Core)
- Standard RSS 2.0 and Atom feeds
- Auto-discovery from any website
- Fallback adapter for all feeds

### Social Media Adapters (P1 - High Priority)
1. **Bluesky** - AT Protocol public API
2. **Mastodon/Fediverse** - Public API (instance + username)
3. **YouTube** - Channel RSS feeds (no API key needed)
4. **Reddit** - Subreddit/user RSS feeds

### Bridge-Based Adapters (P2)
5. **Instagram** - Via RSS bridge services
6. **Twitter/X** - Via Nitter instances (dormant status)

### Special Adapters (P2)
7. **TikTok** - Via RSS bridge services

## Feed Source Management

### Creating Feed Sources

```elixir
# In IEx
alias Homesite.ExternalFeeds
scope = Accounts.Scope.for_user(user)

# RSS/Atom feed
{:ok, feed} = ExternalFeeds.create_feed_source(scope, %{
  feed_type: "rss",
  url: "https://example.com/feed.xml",
  name: "Example Blog"
})

# Bluesky user
{:ok, feed} = ExternalFeeds.create_feed_source(scope, %{
  feed_type: "bluesky",
  username: "dril.bsky.social",
  name: "dril on Bluesky"
})

# Mastodon user
{:ok, feed} = ExternalFeeds.create_feed_source(scope, %{
  feed_type: "mastodon",
  username: "Gargron",
  instance_url: "https://mastodon.social",
  name: "Mastodon Creator"
})

# YouTube channel
{:ok, feed} = ExternalFeeds.create_feed_source(scope, %{
  feed_type: "youtube",
  channel_id: "UCXuqSBlHAE6Xw-yeJA0Tunw",
  name: "Linus Tech Tips"
})
```

### Manual Feed Refresh

```bash
# Refresh all active feeds
mix feeds.refresh

# Refresh specific feed
iex> ExternalFeeds.refresh_feed_source(feed_id)
```

## Database Schema

### Core Tables
- `feed_sources` - User's subscribed feeds (platform, credentials, refresh settings)
- `feed_items` - Individual posts/items from feeds (unified schema)
- `feed_item_interactions` - Read/bookmark/archive tracking (per-user)
- `feed_folders` - Folder organization (user-created categories)

### Key Fields (feed_sources)
- `feed_type` - Platform identifier (rss, bluesky, mastodon, etc.)
- `url` - Feed URL (for RSS) or constructed API URL
- `username` - Platform-specific username (Bluesky, Mastodon, YouTube)
- `instance_url` - For federated platforms (Mastodon)
- `refresh_frequency_minutes` - Auto-refresh interval (default: 60)
- `last_refreshed_at` - Last successful fetch timestamp
- `error_count` - Consecutive fetch failures (auto-disable at 5)

### Key Fields (feed_items)
- `external_id` - Platform-specific ID (prevents duplicates)
- `author`, `content`, `url`, `published_at` - Standardized fields
- `platform_data` - JSON field for platform-specific metadata

## Feed Item Interactions

### Read Tracking

```elixir
# Mark item as read
ExternalFeeds.mark_item_as_read(scope, item_id)

# Get unread count
count = ExternalFeeds.get_unread_count(scope)

# List unread items
items = ExternalFeeds.list_feed_items_unified(scope, %{unread_only: true})
```

### Bookmarks

```elixir
# Bookmark an item
{:ok, _interaction} = ExternalFeeds.bookmark_item(scope, item_id)

# Un-bookmark
{:ok, _interaction} = ExternalFeeds.unbookmark_item(scope, item_id)

# List bookmarked items
items = ExternalFeeds.list_feed_items_unified(scope, %{bookmarked_only: true})
```

## Folder Organization

### Creating Folders

```elixir
{:ok, folder} = ExternalFeeds.create_feed_folder(scope, %{
  name: "Tech News",
  icon: "📰",
  color: "#3B82F6",
  display_order: 1
})
```

### Assigning Feeds to Folders

```elixir
# Assign feed to folder
{:ok, feed} = ExternalFeeds.assign_feed_to_folder(scope, feed_id, folder_id)

# Unassign (move to root)
{:ok, feed} = ExternalFeeds.assign_feed_to_folder(scope, feed_id, nil)
```

### Filtering by Folder

```elixir
# Get items from specific folder
items = ExternalFeeds.list_feed_items_by_folder(scope, folder_id, %{limit: 20})

# Get all items (unified view)
items = ExternalFeeds.list_feed_items_unified(scope, %{folder_id: folder_id})
```

## Analytics

### Feed Consumption Metrics

```elixir
alias Homesite.ExternalFeeds.Analytics

# Get dashboard summary
summary = Analytics.get_analytics_summary(scope)
# Returns: %{
#   total_items: 1250,
#   unread_count: 42,
#   read_today: 15,
#   read_this_week: 87,
#   bookmark_count: 23,
#   total_sources: 12
# }

# Top sources by engagement
top_sources = Analytics.get_top_sources(scope, limit: 10)
# Sorted by engagement score (reads * 1 + bookmarks * 3)

# Reading trend (last 30 days)
trend = Analytics.get_reading_trend(scope, days: 30)
# Returns: [%{date: ~D[2025-12-01], count: 15}, ...]

# Per-source performance
performance = Analytics.get_source_performance(scope, days: 7)
```

## Platform-Specific Notes

### Bluesky
- Uses AT Protocol public API (no authentication needed)
- Username format: `user.bsky.social` or custom domains
- Supports posts, replies, reposts (all rendered as feed items)

### Mastodon
- Requires both username and instance URL
- Two-step fetch: account lookup → fetch statuses
- Supports HTML content, media attachments, boosts

### YouTube
- Uses RSS feeds (no API key required!)
- Channel ID format: `UCXuqSBlHAE6Xw-yeJA0Tunw`
- Includes video metadata (views, thumbnails)

### Reddit
- RSS feeds: `https://reddit.com/r/subreddit/.rss`
- User feeds: `https://reddit.com/user/username/.rss`
- Includes karma, comments count

### Twitter/X (Dormant)
- **Status**: Fully implemented but inactive
- Uses Nitter instances for RSS feeds
- Recommended instances configured in `config/config.exs`
- Format: `https://{instance}/username/rss`

## Testing

### External API Tests

Tests that hit real APIs are tagged `:external`:

```bash
# Skip external tests (default)
mix test

# Include external tests (requires internet)
mix test --include external
```

### Scope Isolation Tests

All feed operations enforce user isolation:

```elixir
# User A cannot see User B's feeds
test "user cannot list other user's feed sources", %{user_a_scope: a, user_b_scope: b} do
  {:ok, feed_b} = ExternalFeeds.create_feed_source(b, valid_attrs())

  list = ExternalFeeds.list_feed_sources(a)
  refute Enum.any?(list, fn f -> f.id == feed_b.id end)
end
```

## Routes

### Feed Display
- `/feed` - Unified chronological feed view
- `/feeds/:id` - Individual feed source view
- `/feed/bookmarks` - Bookmarked items

### Feed Management (future UI)
- `/feeds` - Manage feed sources
- `/feeds/new` - Add new feed
- `/feeds/:id/edit` - Edit feed settings

## Oban Workers

### FeedRefreshWorker
- **Queue**: `:default`
- **Schedule**: Every 1 hour (or per-feed `refresh_frequency_minutes`)
- **Job**: Refresh all active feed sources
- **Error Handling**: Increments `error_count`, disables after 5 failures

### FeedCleanupWorker (future)
- **Queue**: `:default`
- **Schedule**: Daily at 3 AM
- **Job**: Delete old feed items (>90 days, configurable)

## Configuration

In `config/config.exs`:

```elixir
config :homesite, :external_feeds,
  # Nitter instances for Twitter/X feeds
  nitter_instances: [
    "https://nitter.net",
    "https://nitter.privacydev.net",
    # ... more instances
  ],
  # Cleanup settings
  retention_days: 90,
  max_items_per_feed: 500
```

## Common Issues

### "Fetch failed" errors
- Check `error_count` in feed_sources table
- Feeds auto-disable after 5 consecutive failures
- Re-enable with `update_feed_source(scope, feed, %{is_active: true, error_count: 0})`

### Missing feed items
- Check `last_refreshed_at` timestamp
- Manually refresh: `ExternalFeeds.refresh_feed_source(feed_id)`
- Verify platform credentials (Mastodon instance, YouTube channel ID)

### Duplicate items
- Prevented by unique index on `[feed_source_id, external_id]`
- Each platform provides unique ID (post ID, video ID, etc.)

## Security

- ✅ All operations enforce scope isolation
- ✅ Feed URLs validated before fetching
- ✅ Rate limiting on feed fetches (future)
- ✅ XSS protection via HTML sanitization
- ✅ CSRF tokens on all feed management forms

## Performance

- **Indexes**: feed_source_id, published_at, external_id
- **Pagination**: 20 items per page (configurable)
- **Caching**: Feed items cached for 1 hour (future)
- **Background jobs**: All refreshes via Oban workers

## Documentation

- `EXTERNAL_FEEDS.md` - Comprehensive system docs
- `/dev/faqs` - This document (development only)
- Admin dashboard - Analytics and monitoring
