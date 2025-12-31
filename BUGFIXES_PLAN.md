# Bugfixes and Enhancements Plan

Created: 2024-12-31

This document tracks the implementation plan for bugs and enhancements identified in issues #73-#80.

---

## Priority Order

### HIGH Priority
1. **#73** - Blog post publicity toggle not working
2. **#76** - Page refresh/scroll issues when writing long text

### MEDIUM Priority
3. **#74** - Time field shows 12:00 default
4. **#78** - User following feature not accessible
5. **#79** - RSS feed limit per source
6. **#80** - Media library folders

### LOW Priority
7. **#75** - Show edited time on posts
8. **#77** - Author avatar in share template

---

## Detailed Solutions

### Issue #73: Blog Post Publicity Bug

**Root Cause (CONFIRMED):**
```elixir
# content.ex:386 - Only checks published_at, NOT is_public
def list_public_posts(nil) do
  from(p in Post,
    where: not is_nil(p.published_at),  # <-- Missing: and p.is_public == true
    ...
  )
```

**Solution:**
```elixir
def list_public_posts(nil) do
  from(p in Post,
    where: not is_nil(p.published_at) and p.is_public == true,
    order_by: [desc: p.published_at],
    preload: [:user, :tags]
  )
  |> Repo.all()
end
```

Also update `list_public_posts(%Scope{})` variant.

**Files to modify:**
- `lib/homesite/content.ex` - Add `is_public` check to all public listing functions

**Claude's Questions:**
- Should `published_at` imply public visibility, or are they independent controls? Publiced at if put in future, article is public then
- What's the intended workflow: draft → scheduled → published → can toggle visibility? Was there draft too? But in anytime article is visibilility_no it is not public
- Should we rename for clarity (`is_visible` or `visibility_status` enum)? If you see it is good, do it.

---

### Issue #74: Time Field Shows 12:00 Default

**Root Cause (CONFIRMED):**
```elixir
# form.ex:673
defp format_time(nil), do: "12:00"  # <-- Hardcoded default
```

**Investigation needed:**
1. Check why `published_at` is nil when loading existing post
2. Verify timezone conversion isn't stripping time
3. Check mount function logic

**Likely fix location:**
- `lib/homesite_web/live/post_live/form.ex` - mount/handle_params

**Claude's Questions:**
- Is the time being saved but not displayed?
- Or is it not being saved at all?
- What timezone is used for storage vs display?

---

### Issue #75: Show Edited Time

**Solution:**
```elixir
# In show.ex template
<%= if DateTime.diff(@post.updated_at, @post.published_at, :minute) > 5 do %>
  <span class="text-sm text-base-content/60">
    (edited <%= format_date(@post.updated_at) %>)
  </span>
<% end %>
```

**Files to modify:**
- `lib/homesite_web/live/post_live/show.ex` - Add edited indicator

---

### Issue #76: Page Refresh/Scroll with Long Text

**Suspected cause:** AutoGrow hook + LiveView re-renders

**Current hook (app.js:372-385):**
```javascript
AutoGrow: {
  mounted() {
    this.el.style.overflow = "hidden"
    this.resize()
    this.el.addEventListener("input", () => this.resize())
  },
  updated() {
    this.resize()  // <-- This triggers on every LiveView update
  },
  resize() {
    this.el.style.height = "auto"
    this.el.style.height = this.el.scrollHeight + "px"
  }
}
```

**Proposed fixes:**
1. Add `phx-update="ignore"` to textarea container to prevent DOM patching
2. Add `phx-debounce="500"` to textarea for less frequent validation
3. Store and restore scroll position in hook
4. Consider splitting editor into separate LiveComponent

**Claude's Questions:**
- At what text length does this start happening?
- Is it related to specific characters (newlines)?
- Does the issue occur without AutoGrow? Yes because it is not working?

**Claude's Ideas:**
- Split editor into separate LiveComponent to isolate re-renders
- Use CodeMirror or similar for better text editing
- Add autosave with debounce instead of real-time validation

---

### Issue #77: Author Avatar in Share Template

**Solution:**
1. Add OpenGraph meta tags to post layout
2. Set fallback image priority: featured_image > author_avatar > site_default

```heex
<meta property="og:image" content={@og_image_url} />
<meta property="og:image:width" content="1200" />
<meta property="og:image:height" content="630" />
```

**Files to modify:**
- `lib/homesite_web/components/layouts/root.html.heex` or post-specific layout
- `lib/homesite_web/live/post_live/show.ex` - Compute og_image_url

**Claude's Questions:**
- What size should avatar be for social sharing? (Twitter recommends 1200x630)
- Generate a card with avatar + title + site branding?
- Or just use avatar directly? Avatar should be just little avatar, but if there is image, then use best size 

**Claude's Ideas:**
- Create a share card generator endpoint that composites avatar + title
- Cache generated images Yes.
- Use image service like Cloudinary for dynamic transformations

Do something stylish but simple. Avatar should be just little avatar, but if there is image, then use best size. 
---

### Issue #78: User Following Not Accessible

**Status:** Backend COMPLETE, UI missing

**Existing routes (router.ex:287-288):**
```elixir
live "/users/:user_identifier/followers", UserLive.Followers, :followers
live "/users/:user_identifier/following", UserLive.Followers, :following
```

**Solution:**
1. Add "Followers/Following" link to user profile page
2. Add follow/unfollow button to user cards
3. Show follower count on profile

**Files to modify:**
- User profile template (add links)
- User card component (add follow button)
- Navigation (optional - show follower count)

**Claude's Questions:**
- Where should the follow button appear? Profile page? User cards? Both? Profile page and user cards.
- Should there be notifications for new followers? In notifications page Yes.
- Show follower count in navigation? No. In Profile page yes

---

### Issue #79: RSS Feed Limit Per Source

**Solution - SQL window function:**
```elixir
def list_feed_items_limited_per_source(scope, limit_per_source \\ 3) do
  subquery =
    from(fi in FeedItem,
      join: fs in FeedSource, on: fi.feed_source_id == fs.id,
      where: fs.enabled == true,
      select: %{
        fi | row_num: over(row_number(), partition_by: fi.feed_source_id, order_by: [desc: fi.published_at])
      }
    )

  from(fi in subquery(subquery),
    where: fi.row_num <= ^limit_per_source,
    order_by: [desc: fi.published_at]
  )
  |> Repo.all()
end
```

**Files to modify:**
- `lib/homesite/external_feeds.ex` - Add new query function
- `lib/homesite_web/live/feed_live/index.ex` - Use new function

**Claude's Questions:**
- Should limit be configurable per source? Yes.
- Exempt bookmarked items from limit? Yes.
- Should unread items have higher priority? Yes.

**Claude's Ideas:**
- Add "Show all from this source" expansion Yes.
- Configurable limit in feed source settings Yes.
- "Trending" algorithm based on engagement Yes.
- Add "Show all from this source" expansion Yes.
- Configurable limit in feed source settings Yes.
- "Trending" algorithm based on engagement Yes.

---

### Issue #80: Media Library Folders

**Recommendation:** Start with orphan filter, defer folders

**Quick win - Orphan filter:**
```elixir
def list_orphaned_media_items(scope) do
  from(m in MediaItem,
    left_join: pmi in ProjectMediaItem, on: m.id == pmi.media_item_id,
    where: m.user_id == ^scope.user.id and is_nil(pmi.id),
    order_by: [desc: m.inserted_at]
  )
  |> Repo.all()
end
```

**Folder options (for later):**
- **Option A: Tags** - Add `folder` field to media_items (LOW effort)
- **Option B: True folders** - New `media_folders` table (HIGH effort)
- **Option C: Global collections** - Cross-project collections (MEDIUM effort)

**Files to modify:**
- `lib/homesite/media.ex` - Add `list_orphaned_media_items/1`
- `lib/homesite_web/live/media_live/index.ex` - Add filter button

**Claude's Questions:**
- How many images are expected? 100s? 1000s? 10000s? In future... 100000s?
- Is the current project/collection system insufficient? Don't know yet.
- Would tags/categories be enough instead of folders? Yes.
- Should folders be flat or nested? Flat.

---

## Implementation Notes

### Testing Strategy
After each fix:
1. Run `mix test` - verify no regressions
2. Run `mix credo --strict` - code quality
3. Manual testing of affected feature

### Commit Strategy
One commit per issue, format:
```
fix: Description of fix

Fixes: #XX

...
```

---

## Questions for Product Owner

1. **Publicity workflow:** Should `published_at` imply public visibility, or are they truly independent controls?

2. **Following feature:** Where should follow buttons appear? Just profiles, or also on user cards throughout the app?

3. **RSS limits:** Should the per-source limit be configurable by users, or a fixed system setting?

4. **Media organization:** For the expected image volume, would simple tags suffice, or is true folder hierarchy needed?

5. **Share cards:** Should we generate dynamic share cards with author info and branding, or just use the featured image/avatar directly?
