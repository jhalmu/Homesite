defmodule Homesite.PortfolioImageCache do
  @moduledoc """
  ETS-based caching system for watermarked portfolio images.

  Caches watermarked medium-resolution images to reduce ImageMagick processing
  load and improve response times for public portfolio image serving.

  ## Configuration

  - **TTL**: 1 hour (3600 seconds)
  - **Backend**: ETS table
  - **Cache Keys**: Media item ID

  ## Cache Invalidation

  Caches are automatically cleared when:
  - A media item is updated or deleted
  - A user's display_name changes (watermark text changes)
  - Manual cache clear is triggered
  """

  use GenServer
  require Logger

  @table_name :portfolio_image_cache
  @ttl :timer.hours(1)

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Fetches a watermarked image from cache or generates it using the provided function.

  Returns the cached or freshly generated value.
  """
  def fetch(media_item_id, generator_fun) do
    case get(media_item_id) do
      {:ok, value} ->
        Logger.debug("PortfolioImageCache: Cache hit for media #{media_item_id}")
        value

      :miss ->
        Logger.debug("PortfolioImageCache: Cache miss for media #{media_item_id}")
        value = generator_fun.()
        put(media_item_id, value)
        value
    end
  end

  @doc """
  Gets a value from the cache.

  Returns `{:ok, value}` if found and not expired, `:miss` otherwise.
  """
  def get(media_item_id) do
    case :ets.lookup(@table_name, media_item_id) do
      [{^media_item_id, value, expires_at}] ->
        if System.system_time(:millisecond) < expires_at do
          {:ok, value}
        else
          :ets.delete(@table_name, media_item_id)
          :miss
        end

      [] ->
        :miss
    end
  end

  @doc """
  Puts a value in the cache with TTL.
  """
  def put(media_item_id, value) do
    expires_at = System.system_time(:millisecond) + @ttl
    :ets.insert(@table_name, {media_item_id, value, expires_at})
    :ok
  end

  @doc """
  Invalidates (deletes) a specific cache entry.
  """
  def invalidate(media_item_id) do
    :ets.delete(@table_name, media_item_id)
    Logger.debug("PortfolioImageCache: Invalidated cache for media #{media_item_id}")
    :ok
  end

  @doc """
  Clears all cache entries.
  """
  def clear_all do
    :ets.delete_all_objects(@table_name)
    Logger.info("PortfolioImageCache: Cleared all cache entries")
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
    Logger.info("PortfolioImageCache: Started with table #{inspect(table)}")
    {:ok, %{}}
  end
end
