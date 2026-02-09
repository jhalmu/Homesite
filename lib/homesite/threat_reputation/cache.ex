defmodule Homesite.ThreatReputation.Cache do
  @moduledoc """
  ETS-based cache for threat reputation data.

  Provides fast lookups for IP/country scores and block status
  to avoid database queries on every request.

  Cache entries expire after 5 minutes and are refreshed on access.
  """

  use GenServer

  require Logger

  @cache_table :threat_reputation_cache
  @cache_ttl_seconds 300
  @watchlist_cache_table :threat_watchlist_cache
  @watchlist_ttl_seconds 600

  # Client API

  @doc """
  Starts the cache GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets cached IP score data.

  Returns `{:ok, data}` if found and not expired, `:miss` otherwise.
  """
  def get_ip_score(ip_address) do
    get_cached(@cache_table, {:ip, ip_address})
  end

  @doc """
  Caches IP score data.
  """
  def put_ip_score(ip_address, data) do
    put_cached(@cache_table, {:ip, ip_address}, data, @cache_ttl_seconds)
  end

  @doc """
  Gets cached IP block status.

  Returns `{:ok, blocked?}` if found and not expired, `:miss` otherwise.
  """
  def get_ip_blocked(ip_address) do
    get_cached(@cache_table, {:ip_blocked, ip_address})
  end

  @doc """
  Caches IP block status.
  """
  def put_ip_blocked(ip_address, blocked?) do
    put_cached(@cache_table, {:ip_blocked, ip_address}, blocked?, @cache_ttl_seconds)
  end

  @doc """
  Gets cached country score data.

  Returns `{:ok, data}` if found and not expired, `:miss` otherwise.
  """
  def get_country_score(country_code) do
    get_cached(@cache_table, {:country, country_code})
  end

  @doc """
  Caches country score data.
  """
  def put_country_score(country_code, data) do
    put_cached(@cache_table, {:country, country_code}, data, @cache_ttl_seconds)
  end

  @doc """
  Gets cached IP watchlist entry.
  """
  def get_ip_watchlist(ip_address) do
    get_cached(@watchlist_cache_table, {:ip_watchlist, ip_address})
  end

  @doc """
  Caches IP watchlist entry.
  """
  def put_ip_watchlist(ip_address, entry) do
    put_cached(@watchlist_cache_table, {:ip_watchlist, ip_address}, entry, @watchlist_ttl_seconds)
  end

  @doc """
  Gets cached country watchlist entry.
  """
  def get_country_watchlist(country_code) do
    get_cached(@watchlist_cache_table, {:country_watchlist, country_code})
  end

  @doc """
  Caches country watchlist entry.
  """
  def put_country_watchlist(country_code, entry) do
    put_cached(
      @watchlist_cache_table,
      {:country_watchlist, country_code},
      entry,
      @watchlist_ttl_seconds
    )
  end

  @doc """
  Invalidates all cache entries for an IP address.
  """
  def invalidate_ip(ip_address) do
    if :ets.info(@cache_table) != :undefined do
      :ets.delete(@cache_table, {:ip, ip_address})
      :ets.delete(@cache_table, {:ip_blocked, ip_address})
    end

    if :ets.info(@watchlist_cache_table) != :undefined do
      :ets.delete(@watchlist_cache_table, {:ip_watchlist, ip_address})
    end

    :ok
  end

  @doc """
  Invalidates all cache entries for a country.
  """
  def invalidate_country(country_code) do
    if :ets.info(@cache_table) != :undefined do
      :ets.delete(@cache_table, {:country, country_code})
    end

    if :ets.info(@watchlist_cache_table) != :undefined do
      :ets.delete(@watchlist_cache_table, {:country_watchlist, country_code})
    end

    :ok
  end

  @doc """
  Clears all cached data.
  """
  def clear_all do
    if :ets.info(@cache_table) != :undefined do
      :ets.delete_all_objects(@cache_table)
    end

    if :ets.info(@watchlist_cache_table) != :undefined do
      :ets.delete_all_objects(@watchlist_cache_table)
    end

    :ok
  end

  @doc """
  Returns cache statistics.
  """
  def stats do
    cache_size =
      if :ets.info(@cache_table) != :undefined do
        :ets.info(@cache_table, :size)
      else
        0
      end

    watchlist_size =
      if :ets.info(@watchlist_cache_table) != :undefined do
        :ets.info(@watchlist_cache_table, :size)
      else
        0
      end

    %{
      cache_entries: cache_size,
      watchlist_entries: watchlist_size
    }
  end

  # GenServer callbacks

  @impl true
  def init(_opts) do
    create_table(@cache_table)
    create_table(@watchlist_cache_table)
    Logger.info("ThreatReputation cache initialized")
    {:ok, %{}}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # Private helpers

  defp create_table(name) do
    if :ets.info(name) == :undefined do
      :ets.new(name, [:named_table, :public, read_concurrency: true])
    end
  end

  defp get_cached(table, key) do
    if :ets.info(table) != :undefined do
      lookup_cached_entry(table, key)
    else
      :miss
    end
  end

  defp lookup_cached_entry(table, key) do
    case :ets.lookup(table, key) do
      [{^key, data, expires_at}] ->
        if System.system_time(:second) < expires_at do
          {:ok, data}
        else
          :ets.delete(table, key)
          :miss
        end

      [] ->
        :miss
    end
  end

  defp put_cached(table, key, data, ttl_seconds) do
    if :ets.info(table) != :undefined do
      expires_at = System.system_time(:second) + ttl_seconds
      :ets.insert(table, {key, data, expires_at})
    end

    :ok
  end
end
