# RSS/Atom/JSON Feed Implementation Guide

## Feed Formats Overview

### RSS 2.0
- **Most widely supported** by feed readers
- **XML-based**: `application/rss+xml`
- **URL Convention**: `/rss.xml`
- **Use case**: Maximum compatibility with traditional feed readers
- **Status**: ✅ Implemented

### Atom
- **Modern XML format** with better structure
- **Type**: `application/atom+xml`
- **URL Convention**: `/feed.xml` or `/atom.xml`
- **Use case**: Standards compliance, better metadata support
- **Status**: ✅ Already implemented

### JSON Feed
- **Modern JSON format** - easy to parse
- **Type**: `application/feed+json`
- **URL Convention**: `/feed.json`
- **Use case**: Modern frontends, APIs, headless CMS scenarios
- **Status**: ✅ Implemented

## Available Feed URLs

### Site-wide Feeds
- RSS: `http://yourdomain.com/rss.xml`
- Atom: `http://yourdomain.com/feed.xml`
- JSON: `http://yourdomain.com/feed.json`

### Per-User Feeds
- RSS: `http://yourdomain.com/users/:id/rss.xml`
- Atom: `http://yourdomain.com/users/:id/feed.xml`
- JSON: `http://yourdomain.com/users/:id/feed.json`

### Per-Tag Feeds
- RSS: `http://yourdomain.com/tags/:slug/rss.xml`
- Atom: `http://yourdomain.com/tags/:slug/feed.xml`
- JSON: `http://yourdomain.com/tags/:slug/feed.json`

## Implementation Details

### Controller: `lib/homesite_web/controllers/feed_controller.ex`

The FeedController handles all three formats:
- `index/2` - Site-wide feeds
- `user/2` - Per-user feeds
- `tag/2` - Per-tag feeds

Each action accepts a `format` parameter (rss, atom, json) via the route.

### Routes: `lib/homesite_web/router.ex`

```elixir
# RSS Feeds
get "/rss.xml", FeedController, :index, as: :rss_feed
get "/feed.xml", FeedController, :index, as: :atom_feed
get "/feed.json", FeedController, :index, as: :json_feed

get "/users/:id/rss.xml", FeedController, :user
get "/users/:id/feed.xml", FeedController, :user
get "/users/:id/feed.json", FeedController, :user

get "/tags/:slug/rss.xml", FeedController, :tag
get "/tags/:slug/feed.xml", FeedController, :tag
get "/tags/:slug/feed.json", FeedController, :tag
```

### Autodiscovery Links

In `lib/homesite_web/components/layouts/root.html.heex`:

```html
<!-- Atom Feed -->
<link rel="alternate" type="application/atom+xml"
      title="Homesite - Atom Feed" href={url(~p"/feed.xml")} />

<!-- RSS Feed -->
<link rel="alternate" type="application/rss+xml"
      title="Homesite - RSS Feed" href={url(~p"/rss.xml")} />

<!-- JSON Feed -->
<link rel="alternate" type="application/feed+json"
      title="Homesite - JSON Feed" href={url(~p"/feed.json")} />
```

### Footer Icons

Added RSS icon links in the footer for easy discovery:
- RSS icon → `/rss.xml`
- Located in footer alongside social links

## Feed Content

All feeds include:
- **20 most recent** published posts
- **Full post content** (with HTML sanitization for RSS/Atom)
- **Author information**
- **Publication dates**
- **Post URLs** (permalinks)
- **Tags** (categories in RSS, tags in JSON)

## Testing Feeds

### Development (Command Line)
```bash
# Test RSS
curl http://localhost:4000/rss.xml

# Test Atom
curl http://localhost:4000/feed.xml

# Test JSON
curl http://localhost:4000/feed.json
```

### Testing with Feed Readers

**⚠️ Important Localhost Limitations:**

Most feed readers (including Unread, Feedly, NetNewsWire, etc.) **do not support localhost URLs**. They expect public domains with valid SSL certificates.

**Option 1: Direct Feed URL** (May work for some readers)
- Try entering the direct feed URL: `http://localhost:4000/rss.xml`
- Some desktop feed readers may support this

**Option 2: Use ngrok for Testing** (Recommended)
```bash
# Install ngrok from https://ngrok.com
# Then run:
ngrok http 4000

# Use the generated URL (e.g., https://abc123.ngrok.io)
# with your feed reader
```

**Option 3: Deploy to Production**
- Deploy to a server with a real domain
- Feed readers will then work with autodiscovery
- Example: `https://yourdomain.com` → autodiscovers `/rss.xml`

**Autodiscovery Testing:**
- Feed readers look for `<link rel="alternate">` tags in HTML `<head>`
- Navigate to your homepage in the feed reader
- It should automatically detect all available feeds (RSS, Atom, JSON)

### Validation Tools
- RSS: https://validator.w3.org/feed/
- JSON Feed: https://validator.jsonfeed.org/

## Future Enhancements

From `lib/homesite_web/controllers/feed_controller.ex` TODO comments:

1. **Pagination**: Add `?page=2` support for large blogs
2. **Full content option**: Add `?full=true` to include complete post body
3. **Feed caching**: Implement ETS or Phoenix.Cache for better performance
4. **Feed images**: Add featured images/thumbnails to entries
5. **Multiple formats**: Consider adding JSON Feed format

## Dependencies

- **atomex**: Atom feed generation (`~> 0.5`)
- **floki**: HTML parsing and sanitization for RSS (`~> 0.36`)

## Notes

- All feeds show only **public** posts (published_at is set)
- Feeds are generated on-demand (no caching yet)
- RSS format uses HTML content (not plain text)
- JSON Feed follows the v1.1 specification
- Tag feeds use tag slug, not ID
