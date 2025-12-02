# Feed Refresh Strategy & Optimization

**Created:** 2025-12-02
**Status:** Current implementation working, optimizations for future scale

---

## Current Implementation

### Architecture
- **Job Queue:** Oban with dedicated `feeds` queue
- **Concurrency:** 5 workers max (prevents server overload)
- **Schedule:** Cron job every 30 minutes (`*/30 * * * *`)
- **Worker:** `Homesite.Workers.FeedRefreshWorker`

### How It Works

```elixir
# config/config.exs
config :homesite, Oban,
  queues: [feeds: 5],  # Max 5 concurrent feed fetches
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       {"*/30 * * * *", FeedRefreshWorker, args: %{refresh_all: true}}
     ]}
  ]
```

**Flow:**
1. Cron triggers every 30 minutes
2. `FeedRefreshWorker` with `refresh_all: true` executes
3. Fetches all enabled feed sources from database
4. Processes 5 feeds concurrently (queue limit)
5. Each feed checks `last_fetched_at` vs `refresh_interval`
6. Skips recently refreshed feeds (respects individual intervals)

### Smart Features Already Implemented

✅ **Individual Refresh Intervals**
- Each feed source has `refresh_interval` (minutes)
- Worker respects this: `should_refresh?/1` checks before fetching

✅ **Queue-Based Concurrency**
- Max 5 concurrent HTTP requests
- Prevents thundering herd problem
- Natural rate limiting

✅ **Retry Logic**
- Oban retries failed fetches (max 3 attempts)
- Exponential backoff between retries

✅ **Error Isolation**
- One failing feed doesn't block others
- Errors logged individually

---

## Performance Analysis

### Current Scale (< 100 feeds)
- **Processing time:** ~100 feeds = 1-2 minutes
- **Server load:** Negligible (5 concurrent workers)
- **Database:** 5 connections max
- **Network:** 5 concurrent HTTP requests
- **Verdict:** ✅ No optimization needed

### Medium Scale (100-500 feeds)
- **Processing time:** ~500 feeds = 8-10 minutes every 30 min
- **Server load:** Moderate (16-20 min/hour of CPU time)
- **Database:** Same (5 connections)
- **Network:** Same (5 concurrent requests)
- **Verdict:** ✅ Current design handles this well

### Large Scale (500-5000 feeds)
- **Processing time:** Could exceed 30 min window
- **Server load:** High (continuous processing)
- **Database:** Bottleneck if queries slow
- **Network:** Risk of rate limiting from external sites
- **Verdict:** ⚠️ Optimizations needed

---

## The "Refrigerator Light" Question

**Q:** Do feeds refresh even when not being viewed?

**A:** Yes. The cron job runs server-side regardless of user activity.

### Why This Approach?

**Pros:**
- ✅ Fresh content ready instantly when user opens page
- ✅ No delays waiting for fetch on page load
- ✅ Better UX - data is pre-cached
- ✅ Consistent, predictable update schedule
- ✅ Works well for active users

**Cons:**
- ❌ Refreshes feeds nobody is viewing
- ❌ Uses server resources for potentially unused data
- ❌ Makes HTTP requests to external sites unnecessarily
- ❌ Wastes bandwidth on abandoned feeds

---

## Future Optimization Strategies

### Strategy 1: Activity-Based Refresh (Recommended)

**Track feed usage and only refresh active feeds.**

#### Implementation

```elixir
# Migration: Add last_viewed_at to feed_sources
add :last_viewed_at, :utc_datetime

# Update on view
def list_feed_items(scope, opts) do
  # Touch all viewed feed sources
  touch_feed_sources_viewed(scope)

  # Return items
end

# Only refresh recently viewed feeds
def fetch_all_enabled do
  FeedSource
  |> where([f], f.enabled == true)
  |> where([f], f.last_viewed_at > ago(7, "day"))
  |> Repo.all()
  |> Enum.map(&fetch_and_store/1)
end
```

#### Benefits
- Reduces unnecessary refreshes by 30-70% (typical inactive rate)
- Scales better to large feed counts
- Still refreshes feeds user cares about

#### Trade-offs
- Slightly more complex
- Needs `last_viewed_at` tracking
- 7-day grace period (configurable)

---

### Strategy 2: Tiered Refresh Rates

**Adjust refresh frequency based on popularity.**

```elixir
popular_feeds (viewed daily)     → every 30 min
normal_feeds (viewed weekly)     → every 2 hours
inactive_feeds (viewed monthly)  → every 12 hours
abandoned_feeds (not viewed 30d) → on-demand only
```

#### Implementation

```elixir
def determine_refresh_interval(feed_source) do
  days_since_view = days_since_last_view(feed_source)

  cond do
    days_since_view <= 1  -> 30  # Daily active: 30 min
    days_since_view <= 7  -> 120 # Weekly: 2 hours
    days_since_view <= 30 -> 720 # Monthly: 12 hours
    true                  -> nil # On-demand only
  end
end
```

#### Benefits
- Fine-grained control
- Optimizes for user behavior patterns
- Reduces load proportionally to usage

#### Trade-offs
- More complex logic
- Requires view analytics
- May need manual override for time-sensitive feeds

---

### Strategy 3: On-Demand + Background Hybrid

**Combine background refresh for active feeds with on-demand for stale feeds.**

```elixir
# Background: Only recently viewed feeds
{"*/30 * * * *", FeedRefreshWorker, args: %{recent_only: true}}

# On page load: Trigger refresh for stale feeds
def mount(_params, _session, socket) do
  items = list_feed_items(scope)

  # Async refresh stale feeds in background
  refresh_stale_feeds_async(scope)

  {:ok, assign(socket, items: items)}
end
```

#### Benefits
- Best UX (always shows data immediately)
- Refreshes intelligently on access
- Background keeps active feeds fresh

#### Trade-offs
- Possible delays for first view after long absence
- Need loading indicators for on-demand fetches
- More complex state management

---

### Strategy 4: Distributed/Staggered Refresh

**Spread refresh load evenly across time window.**

```elixir
# Instead of batch refresh every 30 min,
# schedule individual feeds with random delays

def schedule_staggered_refreshes do
  feed_sources = list_enabled_feeds()

  Enum.each(feed_sources, fn feed ->
    delay_seconds = :rand.uniform(1800)  # 0-30 min

    %{feed_source_id: feed.id}
    |> new(schedule_in: delay_seconds)
    |> Oban.insert()
  end)
end
```

#### Benefits
- Smoother server load (no spikes)
- Better distribution of network requests
- Reduces risk of rate limiting

#### Trade-offs
- More complex scheduling
- Less predictable refresh times
- Needs tracking to avoid duplicate jobs

---

## Monitoring & Metrics

### Key Metrics to Track

1. **Refresh Duration**
   - Time to process all feeds in queue
   - Alert if exceeds 25 minutes (approaching 30 min window)

2. **Success Rate**
   - % of successful vs failed fetches
   - Track by feed source (identify problematic sources)

3. **Active Feed Ratio**
   - % of feeds viewed in last 7/30 days
   - Helps estimate optimization potential

4. **Queue Depth**
   - Number of pending jobs
   - Alert if queue consistently backing up

5. **Resource Usage**
   - Database connections during refresh
   - Memory usage of Oban workers
   - HTTP timeout rate

### Implementation

```elixir
# Add to FeedRefreshWorker
defp refresh_feed(feed_source) do
  start_time = System.monotonic_time(:millisecond)

  result = FeedFetcher.fetch_and_store(feed_source)

  duration = System.monotonic_time(:millisecond) - start_time

  # Log metrics
  :telemetry.execute(
    [:feed_refresh, :complete],
    %{duration: duration},
    %{
      feed_source_id: feed_source.id,
      success: match?({:ok, _}, result)
    }
  )

  result
end
```

---

## Decision Tree

### When to Optimize?

```
Is processing time exceeding 25 minutes?
├─ No → Keep current implementation ✅
└─ Yes → Continue

Are 30%+ of feeds inactive (not viewed in 30 days)?
├─ Yes → Implement Strategy 1 (Activity-Based) 🎯
└─ No → Continue

Are feeds time-sensitive (news, social media)?
├─ Yes → Implement Strategy 2 (Tiered Rates) 🎯
└─ No → Implement Strategy 3 (Hybrid) 🎯

Is server experiencing load spikes every 30 min?
├─ Yes → Implement Strategy 4 (Staggered) 🎯
└─ No → Increase queue size first
```

---

## Migration Path

### Phase 1: Add Tracking (No behavior change)
1. Add `last_viewed_at` column to `feed_sources`
2. Track views in `list_feed_items/2`
3. Collect 2 weeks of data
4. Analyze active feed ratio

### Phase 2: Implement Activity Filter (If needed)
1. Update `fetch_all_enabled/0` to check `last_viewed_at`
2. Set threshold (7 or 30 days)
3. Monitor impact on user experience
4. Adjust threshold if needed

### Phase 3: Add On-Demand Refresh (Optional)
1. Add "Refresh Now" button to feed UI
2. Implement `refresh_stale_feeds_async/1`
3. Show loading indicators
4. Track manual refresh rate

### Phase 4: Tiered Intervals (Advanced)
1. Implement dynamic interval calculation
2. Update cron to use calculated intervals
3. Monitor and tune thresholds
4. Consider per-user preferences

---

## Configuration

### Tunable Parameters

```elixir
# config/runtime.exs or environment-specific config

# Queue concurrency (adjust based on server capacity)
config :homesite, Oban,
  queues: [
    feeds: System.get_env("FEED_QUEUE_SIZE", "5") |> String.to_integer()
  ]

# Refresh thresholds
config :homesite, :feed_refresh,
  active_threshold_days: 7,      # Consider feed active if viewed in last N days
  inactive_grace_days: 30,       # Disable refresh after N days without views
  min_refresh_interval: 30,      # Minimum interval in minutes
  max_refresh_interval: 1440     # Maximum interval (24 hours)
```

---

## Recommendations

### For Current Scale (< 100 feeds)
✅ **Keep current implementation**
- Simple, reliable, proven
- Low overhead
- Easy to understand and maintain

### When Reaching 200-500 feeds
⚠️ **Consider Phase 1-2**
- Add `last_viewed_at` tracking
- Filter to active feeds only
- Should reduce load by 30-50%

### When Reaching 1000+ feeds
🚨 **Implement comprehensive optimization**
- Activity-based filtering (Strategy 1)
- Tiered refresh rates (Strategy 2)
- Staggered scheduling (Strategy 4)
- Dedicated monitoring dashboard

### Alternative: Increase Queue Size
**Quick win before complex optimizations:**

```elixir
# Increase from 5 to 10-20 workers
queues: [feeds: 15]
```

**Trade-offs:**
- ✅ Processes feeds 3x faster
- ✅ Simple config change
- ❌ Higher server load spikes
- ❌ More concurrent HTTP requests
- ❌ Risk of rate limiting from external sites

---

## Related Issues

- Performance monitoring: Track queue depth and processing time
- Rate limiting: Consider per-domain rate limits for external sites
- Error handling: Improve retry logic for specific error types (429, 503)
- User preferences: Allow users to set per-feed refresh intervals

---

## References

- Current implementation: `lib/homesite/workers/feed_refresh_worker.ex`
- Configuration: `config/config.exs` lines 31-44
- Oban docs: https://hexdocs.pm/oban/Oban.html
- Feed fetcher: `lib/homesite/external_feeds/feed_fetcher.ex`

---

**Last Updated:** 2025-12-02
**Next Review:** When feed count exceeds 200 or processing time exceeds 20 minutes
