defmodule Homesite.OGImageCache do
  @moduledoc """
  ETS-based caching system for generated OG (Open Graph) images.

  Caches generated PNG images to reduce ImageMagick processing load
  and improve response times for social media previews.

  ## Configuration

  - **TTL**: 1 hour (3600 seconds)
  - **Backend**: ETS table
  - **Cache Keys**: Post ID

  ## Cache Invalidation

  Caches are automatically cleared when:
  - A post is updated (title or user changes)
  - A post is deleted
  - Manual cache clear is triggered

  ## Usage

      # Get from cache or generate
      OGImageCache.fetch(post_id, fn ->
        generate_og_image(...)
      end)

      # Clear specific image
      OGImageCache.invalidate(post_id)

      # Clear all caches
      OGImageCache.clear_all()
  """

  use GenServer
  require Logger

  @table_name :og_image_cache
  @ttl :timer.hours(1)

  # Client API

  @doc """
  Starts the OGImageCache GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Fetches an OG image from cache or generates it using the provided function.

  ## Parameters

  - `post_id`: The post ID to use as cache key
  - `generator_fun`: Function to generate image data if cache miss

  ## Returns

  The cached or freshly generated image binary data.
  """
  def fetch(post_id, generator_fun) do
    case get(post_id) do
      {:ok, value} ->
        Logger.debug("OGImageCache: Cache hit for post #{post_id}")
        value

      :miss ->
        Logger.debug("OGImageCache: Cache miss for post #{post_id}")
        value = generator_fun.()
        put(post_id, value)
        value
    end
  end

  @doc """
  Gets a value from the cache.

  Returns `{:ok, value}` if found and not expired, `:miss` otherwise.
  """
  def get(post_id) do
    case :ets.lookup(@table_name, post_id) do
      [{^post_id, value, expires_at}] ->
        if System.system_time(:millisecond) < expires_at do
          {:ok, value}
        else
          :ets.delete(@table_name, post_id)
          :miss
        end

      [] ->
        :miss
    end
  end

  @doc """
  Puts a value in the cache with TTL.
  """
  def put(post_id, value) do
    expires_at = System.system_time(:millisecond) + @ttl
    :ets.insert(@table_name, {post_id, value, expires_at})
    :ok
  end

  @doc """
  Invalidates (deletes) a specific cache entry.
  """
  def invalidate(post_id) do
    :ets.delete(@table_name, post_id)
    Logger.debug("OGImageCache: Invalidated cache for post #{post_id}")
    :ok
  end

  @doc """
  Clears all cache entries.
  """
  def clear_all do
    :ets.delete_all_objects(@table_name)
    Logger.info("OGImageCache: Cleared all cache entries")
    :ok
  end

  @doc """
  Returns cache statistics.
  """
  def stats do
    size = :ets.info(@table_name, :size)
    memory = :ets.info(@table_name, :memory) * :erlang.system_info(:wordsize)
    %{size: size, memory_bytes: memory}
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:set, :public, :named_table, read_concurrency: true])
    Logger.info("OGImageCache: Started with table #{inspect(table)}")
    {:ok, %{}}
  end
end
