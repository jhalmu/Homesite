defmodule Homesite.FeedCache do
  @moduledoc """
  ETS-based caching system for RSS/Atom/JSON feeds.

  Caches generated feeds to reduce database load and improve response times.
  Cache entries are automatically invalidated when posts are published, updated, or deleted.

  ## Configuration

  - **TTL**: 15 minutes (900 seconds)
  - **Backend**: ETS table
  - **Cache Keys**: Format `{feed_type, feed_format, identifier, page, full_content?}`

  ## Cache Invalidation

  Caches are automatically cleared when:
  - A post is published
  - A post is updated
  - A post is deleted
  - Manual cache clear is triggered

  ## Usage

      # Get from cache or generate
      FeedCache.fetch({:site_wide, :rss, nil, 1, false}, fn ->
        generate_rss_feed(...)
      end)

      # Clear specific feed
      FeedCache.invalidate({:site_wide, :rss, nil, 1, false})

      # Clear all caches
      FeedCache.clear_all()
  """

  use GenServer
  require Logger

  @table_name :feed_cache
  @ttl :timer.minutes(15)

  # Client API

  @doc """
  Starts the FeedCache GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Fetches a feed from cache or generates it using the provided function.

  ## Parameters

  - `key`: Cache key tuple (feed_type, format, identifier, page, full_content)
  - `generator_fun`: Function to generate feed content if cache miss

  ## Returns

  The cached or freshly generated feed content.
  """
  def fetch(key, generator_fun) do
    case get(key) do
      {:ok, value} ->
        Logger.debug("FeedCache: Cache hit for #{inspect(key)}")
        value

      :miss ->
        Logger.debug("FeedCache: Cache miss for #{inspect(key)}")
        value = generator_fun.()
        put(key, value)
        value
    end
  end

  @doc """
  Gets a value from the cache.

  Returns `{:ok, value}` if found and not expired, `:miss` otherwise.
  """
  def get(key) do
    case :ets.lookup(@table_name, key) do
      [{^key, value, expires_at}] ->
        if System.monotonic_time(:millisecond) < expires_at do
          {:ok, value}
        else
          :ets.delete(@table_name, key)
          :miss
        end

      [] ->
        :miss
    end
  end

  @doc """
  Puts a value into the cache with TTL.
  """
  def put(key, value) do
    expires_at = System.monotonic_time(:millisecond) + @ttl
    :ets.insert(@table_name, {key, value, expires_at})
    :ok
  end

  @doc """
  Invalidates a specific cache entry.
  """
  def invalidate(key) do
    :ets.delete(@table_name, key)
    :ok
  end

  @doc """
  Clears all site-wide feed caches (all formats, all pages).

  Used when a post is published, updated, or deleted.
  """
  def clear_site_wide_feeds do
    Logger.info("FeedCache: Clearing site-wide feed caches")

    # Match all site-wide feeds: {:site_wide, _format, _identifier, _page, _full}
    :ets.match_delete(@table_name, {{:site_wide, :_, :_, :_, :_}, :_, :_})
    :ok
  end

  @doc """
  Clears all user-specific feed caches for a given user.

  Used when a user's post is published, updated, or deleted.
  """
  def clear_user_feeds(user_id) do
    Logger.info("FeedCache: Clearing user feed caches for user #{user_id}")

    # Match all user feeds: {:user, _format, ^user_id, _page, _full}
    :ets.match_delete(@table_name, {{:user, :_, user_id, :_, :_}, :_, :_})
    :ok
  end

  @doc """
  Clears all tag-specific feed caches for a given tag slug.

  Used when a post with this tag is published, updated, or deleted.
  """
  def clear_tag_feeds(tag_slug) do
    Logger.info("FeedCache: Clearing tag feed caches for tag #{tag_slug}")

    # Match all tag feeds: {:tag, _format, ^tag_slug, _page, _full}
    :ets.match_delete(@table_name, {{:tag, :_, tag_slug, :_, :_}, :_, :_})
    :ok
  end

  @doc """
  Clears all caches.

  Used for manual cache invalidation or testing.
  """
  def clear_all do
    Logger.info("FeedCache: Clearing all feed caches")
    :ets.delete_all_objects(@table_name)
    :ok
  end

  @doc """
  Returns cache statistics.

  Returns a map with:
  - `:size` - Number of cached entries
  - `:memory` - Memory usage in words
  """
  def stats do
    size = :ets.info(@table_name, :size)
    memory = :ets.info(@table_name, :memory)

    %{
      size: size,
      memory: memory,
      memory_kb: div(memory * :erlang.system_info(:wordsize), 1024)
    }
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    # Create ETS table for cache storage
    :ets.new(@table_name, [
      :named_table,
      :set,
      :public,
      read_concurrency: true,
      write_concurrency: true
    ])

    Logger.info("FeedCache: Initialized ETS cache table")

    # Schedule cleanup job every 5 minutes
    schedule_cleanup()

    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_expired_entries()
    schedule_cleanup()
    {:noreply, state}
  end

  # Private Functions

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, :timer.minutes(5))
  end

  defp cleanup_expired_entries do
    now = System.monotonic_time(:millisecond)
    expired_count = :ets.select_delete(@table_name, [{{:_, :_, :"$1"}, [{:<, :"$1", now}], [true]}])

    if expired_count > 0 do
      Logger.info("FeedCache: Cleaned up #{expired_count} expired entries")
    end
  end
end
