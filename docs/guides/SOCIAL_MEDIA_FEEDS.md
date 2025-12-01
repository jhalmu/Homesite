# Social Media Feed Adapters - Usage Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Platform-Specific Configuration](#platform-specific-configuration)
4. [Configuration Options](#configuration-options)
5. [Managing Feeds](#managing-feeds)
6. [Viewing Feed Items](#viewing-feed-items)
7. [Background Refresh System](#background-refresh-system)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)
10. [API Access (For Developers)](#api-access-for-developers)

---

## Introduction

The Social Media Feed Adapters system allows you to aggregate content from multiple platforms into a single unified feed. This makes it easy to follow your favorite creators, blogs, and social media accounts in one place.

### Supported Platforms

The system currently supports **6 platforms**:

- **RSS/Atom/JSON** 📰 - Standard web feeds from blogs and websites
- **Mastodon** 🦣 - Fediverse social network (public posts)
- **Bluesky** 🦋 - AT Protocol social network (public posts)
- **YouTube** 📺 - Video content from channels
- **Twitter/X** 🐦 - Dormant (requires RSS bridge services)
- **Instagram** 📷 - Functional (requires RSS bridge services)

### Use Cases

- Personal feed aggregation from multiple platforms
- Content curation for research or monitoring
- Cross-platform content discovery
- Centralized reading experience

---

## Getting Started

### Quick Start Guide

1. **Navigate to Feeds**: Go to `/feeds` (requires authentication)
2. **Add New Feed**: Click the "New Feed Source" button
3. **Select Platform**: Choose feed type from dropdown
4. **Configure**: Fill in required fields (URL or username)
5. **Customize**: Set refresh interval and display options
6. **Save**: Click "Save" to activate the feed

Your feed will begin fetching content automatically based on the refresh interval you set.

---

## Platform-Specific Configuration

Each platform has different requirements. Choose the platform you want to add and follow the instructions below.

### RSS/Atom/JSON Feeds

**Best for:** Blogs, news sites, podcasts, and any website with a feed

**Required Fields:**
- **Feed URL**: The direct URL to the feed file

**Example:**
```
https://elixirforum.com/latest.rss
```

**Supported Formats:**
- RSS 2.0 (`.rss`, `.xml`)
- Atom (`.atom`, `.xml`)
- JSON Feed (`.json`)

**Notes:**
- Auto-detects feed format
- HTML content is sanitized for security
- Most blogs have feed links in their footer or header

### Mastodon (Fediverse)

**Best for:** Following people on Mastodon and Fediverse networks

**Required Fields:**
- **Username**: Full username with @ prefix and instance
- **Metadata**: Instance URL (auto-extracted from username)

**Example:**
```
Username: @elixirlang@fosstodon.org
```

**Optional Configuration:**
```json
{
  "instance": "fosstodon.org",
  "limit": 20
}
```

**Notes:**
- Uses public API (no authentication needed)
- Default limit: 20 posts
- Only fetches public posts
- Account must not be private/protected

### Bluesky (AT Protocol)

**Best for:** Following people on Bluesky social network

**Required Fields:**
- **Username**: User handle (e.g., `user.bsky.social`)

**Example:**
```
Username: user.bsky.social
```

**Optional Configuration:**
```json
{
  "limit": 25
}
```

**Notes:**
- Uses public API (no authentication needed)
- Default limit: 25 posts
- Fetches author feed (posts + reposts)
- Includes embeds (images, links, quoted posts)

### YouTube

**Best for:** Following YouTube channels for new videos

**Required Fields:**
- **Metadata**: Channel ID

**Example:**
```json
{
  "channel_id": "UCXuqSBlHAE6Xw-yeJA0Tunw"
}
```

**Finding Your Channel ID:**
1. Go to the YouTube channel
2. View page source (Ctrl+U or Cmd+Option+U)
3. Search for `channelId`
4. Copy the ID (format: `UCxxxxxxxxxxxxxxxxxx`)

**Notes:**
- Uses RSS feed (no API key needed)
- Includes video thumbnails
- Embeds video player URL
- No views/likes count (RSS limitation)

### Twitter/X

**Status:** ⚠️ Dormant (requires third-party RSS bridge)

**Required Fields:**
- **URL**: RSS bridge URL
- **Metadata**: Username

**Example:**
```
URL: https://rsshub.app/twitter/user/username
Metadata: {"username": "username"}
```

**Notes:**
- Not using official Twitter API
- Depends on third-party RSS bridge services
- Bridge services may be unreliable or rate-limited
- Consider alternatives (Mastodon, Bluesky)

### Instagram

**Status:** ✅ Functional (requires third-party RSS bridge)

**Required Fields:**
- **URL**: RSS bridge URL

**Example:**
```
URL: https://rsshub.app/instagram/user/username
```

**Notes:**
- Similar to Twitter, uses RSS bridge services
- Bridge services may be unreliable
- No official API integration
- Public accounts only

---

## Configuration Options

### Common Settings

These settings apply to all feed types:

#### Name (Required)
**Purpose:** Display name for the feed in your list

**Example:** "Elixir Forum Latest", "My YouTube Subscriptions"

#### Icon (Optional)
**Purpose:** Emoji icon for visual identification

**Default Icons:**
- 📰 RSS/Atom/JSON
- 🦣 Mastodon
- 🦋 Bluesky
- 📺 YouTube
- 🐦 Twitter
- 📷 Instagram

**Example:** `📰`, `🦣`, `🎵`, `📚`

#### Refresh Interval (Required)
**Purpose:** How often to fetch new content (in minutes)

**Default:** 30 minutes

**Recommended:**
- Personal blogs: 60-120 minutes
- News feeds: 15-30 minutes
- Social media: 30-60 minutes

#### Display Order (Optional)
**Purpose:** Sort order in your feed list

**Default:** 0

**Usage:** Lower numbers appear first (0, 10, 20...)

#### Enabled (Optional)
**Purpose:** Toggle feed fetching on/off

**Default:** Enabled (true)

**Usage:** Disable feeds temporarily without deleting them

### Advanced Settings

#### Metadata Field

The metadata field accepts JSON configuration specific to each platform:

**Bluesky:**
```json
{
  "limit": 25
}
```

**Mastodon:**
```json
{
  "instance": "mastodon.social",
  "limit": 20
}
```

**YouTube:**
```json
{
  "channel_id": "UCXuqSBlHAE6Xw-yeJA0Tunw"
}
```

---

## Managing Feeds

### Feed List Interface

Access your feeds at: `/feeds`

The feed list shows:
- 📰 Icon and name
- Feed type badge
- Status indicator
- Last updated time
- Available actions

### Status Indicators

- 🟢 **Green Badge (Enabled)**: Feed is active and working
- ⚪ **Gray Badge (Disabled)**: Feed is paused
- 🔴 **Red Badge (Error)**: Last fetch failed (hover for details)

### Last Updated

Shows relative time since last successful fetch:
- "2 hours ago"
- "1 day ago"
- "Just now"

### Available Actions

#### Refresh Now
Manually trigger an immediate fetch, bypassing the scheduled interval.

**Use when:**
- You know new content is available
- Testing feed configuration
- Recovering from errors

#### Enable/Disable Toggle
Pause or resume feed fetching without deleting the feed.

**Use when:**
- Taking a break from certain sources
- Temporarily over capacity
- Testing other feeds

#### Edit
Modify feed configuration (name, URL, interval, etc.).

**Use when:**
- Feed URL changed
- Adjusting refresh interval
- Updating display settings

#### Delete
Permanently remove feed and all associated items.

**Warning:** This cannot be undone. All fetched items will be deleted.

**Use when:**
- No longer following this source
- Feed is permanently broken
- Consolidating duplicate feeds

---

## Viewing Feed Items

Access individual feed details at: `/feeds/:id`

### Feed Information Display

- Feed source details (name, icon, type)
- Configuration summary (URL or username)
- Status and last updated time
- Total items fetched

### Feed Item Display

Each item shows:
- **Author Information**
  - Name
  - Handle (@username)
  - Avatar image
- **Content**
  - Title (if available)
  - Body text (HTML sanitized)
  - Published date (relative)
- **Interaction**
  - Link to original post
  - Platform-specific metadata

### Item Deduplication

The system prevents duplicates using:
- Unique `external_id` per source
- Updates overwrite existing items
- No duplicate posts in your feed

---

## Background Refresh System

### Automatic Refresh

Feeds are automatically refreshed based on your configured interval:

**How it works:**
1. Oban background job scheduler manages all feeds
2. Each feed has its own schedule
3. Fetches run in parallel (doesn't block other feeds)
4. Retry logic handles transient errors

**Default Interval:** 30 minutes

**Customizable:** Set any interval in minutes (minimum: 15 minutes recommended)

### Manual Refresh

Click "Refresh Now" button to:
- Bypass scheduled interval
- Fetch content immediately
- Test feed configuration
- Show loading state during fetch

**Note:** Respects platform rate limits

### Error Handling

When a fetch fails:
1. Error is logged in `last_error` field
2. Red badge appears in feed list
3. Feed automatically retries on next scheduled run
4. You can manually retry with "Refresh Now"

**Common Error Types:**
- Network timeouts
- Invalid feed format
- Rate limiting
- Server downtime

**Persistent Errors:**
If a feed fails repeatedly:
1. Check feed URL/username
2. Verify account is public
3. Test URL in browser or RSS reader
4. Check platform API status
5. Disable feed if permanently broken

---

## Troubleshooting

### "Invalid URL" Error

**Symptoms:** Feed creation fails with URL validation error

**Solutions:**
- ✅ Ensure URL starts with `http://` or `https://`
- ✅ Test URL in browser first
- ✅ Check for typos in URL
- ✅ Verify feed exists at URL
- ✅ Copy URL directly from browser address bar

### "User Not Found" (Mastodon/Bluesky)

**Symptoms:** Cannot find user on platform

**Solutions:**
- ✅ Verify username format:
  - Mastodon: `@username@instance.social`
  - Bluesky: `username.bsky.social`
- ✅ Check user exists on platform
- ✅ Ensure account is public (not private/protected)
- ✅ Try accessing user's profile in browser first
- ✅ Check for typos in username

### "No Items Fetched"

**Symptoms:** Feed created successfully but shows 0 items

**Possible Causes:**
- Feed may be genuinely empty
- Published date filters may exclude items
- Feed format not supported
- Content parsing failed

**Solutions:**
- ✅ Check feed in RSS reader (Feedly, Inoreader)
- ✅ Verify feed has recent content
- ✅ Wait for next scheduled refresh
- ✅ Check error logs for parsing issues

### "Rate Limited"

**Symptoms:** Red badge, error message about rate limiting

**Solutions:**
- ✅ Reduce refresh interval (increase minutes)
- ✅ Wait 15-30 minutes before retrying
- ✅ Check platform API status
- ✅ Distribute requests (don't refresh all feeds at once)

### YouTube "Channel Not Found"

**Symptoms:** Cannot fetch YouTube channel feed

**Solutions:**
- ✅ Double-check channel ID in metadata
- ✅ Ensure channel is public (not private/unlisted)
- ✅ Use channel ID, not channel username
- ✅ Find channel ID from channel page source
- ✅ Test feed URL directly:
  ```
  https://www.youtube.com/feeds/videos.xml?channel_id=YOUR_CHANNEL_ID
  ```

### Getting More Help

If problems persist:
1. Check feed status badge for specific error message
2. Review feed source URL/username for accuracy
3. Test feed URL in external RSS reader
4. Check platform API status pages
5. Verify your internet connection
6. Contact support with error details

---

## Best Practices

### Refresh Interval Guidelines

**Personal Blogs & Long-Form Content:**
- Recommended: 60-120 minutes
- These update infrequently
- Lower intervals waste resources

**News Feeds & Aggregators:**
- Recommended: 15-30 minutes
- Updates frequently
- Balance freshness with politeness

**Social Media (Mastodon, Bluesky):**
- Recommended: 30-60 minutes
- Balance real-time needs with API limits
- Avoid < 15 minutes unless critical

**General Rule:**
- ❌ Don't set intervals too low (< 15 min)
- ✅ Respect platform rate limits
- ✅ Consider your actual usage patterns
- ✅ Balance freshness vs. resource usage

### Feed Organization Tips

**Use Meaningful Names:**
- ❌ "Feed 1", "New Feed"
- ✅ "Elixir Forum Latest", "Phoenix Blog Updates"

**Assign Display Orders:**
- Priority feeds: 0-10
- Regular feeds: 20-50
- Archive/low-priority: 60+

**Use Emojis to Categorize:**
- 📰 News & Blogs
- 🎵 Music & Podcasts
- 📺 Video Content
- 💻 Tech & Dev
- 🎨 Art & Design

**Disable Instead of Delete:**
- Keep feed configuration
- Re-enable when needed
- Preserve historical settings

### Performance Optimization

**Monitor Feed Health:**
- Check for repeated errors (red badges)
- Disable or fix broken feeds
- Remove feeds you rarely check

**Refresh Interval Strategy:**
- Start with default (30 min)
- Increase for low-traffic sources
- Decrease only for critical sources
- Monitor system load

**Feed Limits:**
- No hard limit on number of feeds
- Consider reducing if performance degrades
- Prioritize quality over quantity
- Archive inactive feeds

### Content Quality

**Choose Quality Sources:**
- Verify feed quality before adding
- Test in RSS reader first
- Check content format and completeness
- Avoid spammy or low-quality feeds

**Regular Maintenance:**
- Review feed list monthly
- Remove outdated sources
- Update changed URLs
- Consolidate duplicate feeds

---

## API Access (For Developers)

### Programmatic Feed Management

The External Feeds context provides API functions for managing feeds programmatically.

#### Create RSS Feed

```elixir
alias Homesite.ExternalFeeds

ExternalFeeds.create_feed_source(scope, %{
  feed_type: "rss",
  name: "My Blog",
  url: "https://example.com/feed.xml",
  refresh_interval: 60,
  enabled: true
})
```

#### Create Mastodon Feed

```elixir
ExternalFeeds.create_feed_source(scope, %{
  feed_type: "mastodon",
  name: "Elixir Community",
  username: "@elixirlang@fosstodon.org",
  metadata: %{
    instance: "fosstodon.org",
    limit: 20
  },
  refresh_interval: 30
})
```

#### Create Bluesky Feed

```elixir
ExternalFeeds.create_feed_source(scope, %{
  feed_type: "bluesky",
  name: "Developer News",
  username: "user.bsky.social",
  metadata: %{limit: 25},
  refresh_interval: 45
})
```

#### Create YouTube Feed

```elixir
ExternalFeeds.create_feed_source(scope, %{
  feed_type: "youtube",
  name: "ElixirConf",
  metadata: %{
    channel_id: "UCXuqSBlHAE6Xw-yeJA0Tunw"
  },
  refresh_interval: 120
})
```

#### Trigger Manual Refresh

```elixir
# Refresh specific feed
ExternalFeeds.schedule_refresh(feed_source_id)

# Refresh all enabled feeds
ExternalFeeds.schedule_refresh_all()

# Schedule individual refreshes (parallel)
ExternalFeeds.schedule_individual_refreshes()
```

#### List Feed Items

```elixir
# Get all items for a feed
items = ExternalFeeds.list_feed_items(feed_source_id)

# Get items with limit
items = ExternalFeeds.list_feed_items(feed_source_id, limit: 50)
```

#### Update Feed Configuration

```elixir
ExternalFeeds.update_feed_source(feed_source, %{
  refresh_interval: 90,
  enabled: false
})
```

#### Delete Feed

```elixir
ExternalFeeds.delete_feed_source(feed_source)
```

### Background Job Integration

Feeds use Oban for background processing:

```elixir
# Schedule feed refresh job
%{feed_source_id: feed_source_id}
|> Homesite.Workers.FeedRefreshWorker.new()
|> Oban.insert()
```

### Adapter System

Create custom adapters by implementing the `FeedAdapter` behavior:

```elixir
defmodule MyApp.CustomAdapter do
  @behaviour Homesite.ExternalFeeds.Adapters.FeedAdapter

  @impl true
  def validate_source(%FeedSource{} = source) do
    # Validate required fields
    :ok
  end

  @impl true
  def fetch_items(%FeedSource{} = source) do
    # Fetch and parse items
    {:ok, items}
  end
end
```

---

## Additional Resources

- **Source Code:** `lib/homesite/external_feeds/`
- **Adapters:** `lib/homesite/external_feeds/adapters/`
- **Tests:** `test/homesite/external_feeds_test.exs`
- **LiveView Forms:** `lib/homesite_web/live/feed_source_live/`

## Support

For issues or feature requests:
- Check existing GitHub issues
- Create new issue with feed type and error details
- Include feed URL/username (redact if sensitive)
- Attach error messages and logs

---

**Last Updated:** December 1, 2025
**Version:** 1.0
