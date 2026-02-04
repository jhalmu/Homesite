defmodule Homesite.Analytics.Geo do
  @moduledoc """
  IP geolocation service for analytics.

  Supports two backends:
  1. **MaxMind GeoLite2-City** (recommended) - Offline database, requires free license key
  2. **ip-api.com** (fallback) - Free HTTP API, rate limited, HTTP only

  ## Configuration

  To use MaxMind GeoLite2, set the environment variable:

      MAXMIND_LICENSE_KEY=your_license_key

  Get a free license key at: https://www.maxmind.com/en/geolite2/signup

  If no license key is configured, falls back to ip-api.com.
  """

  require Logger

  @cache_table :geo_cache
  @cache_ttl_seconds 86400
  @database_id :geolite2_city

  @type geo_result :: %{
          country: String.t() | nil,
          city: String.t() | nil
        }

  @doc """
  Start the MaxMind GeoLite2-City database loader.

  Call this from application startup. Returns :ok if started or :skip if no license key.
  """
  def start_loader do
    case get_maxmind_license_key() do
      nil ->
        Logger.info("MaxMind license key not configured, using ip-api.com fallback")
        :skip

      license_key ->
        Logger.info("Starting MaxMind GeoLite2-City database loader")

        case :locus.start_loader(@database_id, {:maxmind, "GeoLite2-City"},
               license_key: license_key
             ) do
          :ok ->
            Logger.info("MaxMind GeoLite2-City loader started")
            :ok

          {:error, reason} ->
            Logger.error("Failed to start MaxMind loader: #{inspect(reason)}")
            {:error, reason}
        end
    end
  end

  @doc """
  Stop the MaxMind database loader.
  """
  def stop_loader do
    :locus.stop_loader(@database_id)
  end

  @doc """
  Initialize the ETS cache for geo lookups (used for ip-api.com fallback).
  """
  def init_cache do
    if :ets.info(@cache_table) == :undefined do
      :ets.new(@cache_table, [:named_table, :public, read_concurrency: true])
    end

    :ok
  end

  @doc """
  Look up geographic location for an IP address.

  Returns a map with country code and city name, or nil values if lookup fails.

  Uses MaxMind GeoLite2-City if available, otherwise falls back to ip-api.com.

  ## Examples

      iex> lookup("8.8.8.8")
      %{country: "US", city: "Mountain View"}

      iex> lookup(nil)
      %{country: nil, city: nil}

      iex> lookup("127.0.0.1")
      %{country: nil, city: nil}

  """
  @spec lookup(String.t() | nil) :: geo_result()
  def lookup(nil), do: %{country: nil, city: nil}
  def lookup(""), do: %{country: nil, city: nil}

  def lookup(ip) when is_binary(ip) do
    if private_ip?(ip) do
      %{country: nil, city: nil}
    else
      lookup_with_backend(ip)
    end
  end

  @doc """
  Look up country code for an IP address.

  Returns ISO 3166-1 alpha-2 country code (e.g., "FI", "US") or nil if lookup fails.

  ## Examples

      iex> lookup_country("8.8.8.8")
      "US"

      iex> lookup_country(nil)
      nil

  """
  def lookup_country(ip) do
    lookup(ip).country
  end

  @doc """
  Look up city name for an IP address.

  Returns city name in English or nil if lookup fails.

  ## Examples

      iex> lookup_city("8.8.8.8")
      "Mountain View"

      iex> lookup_city(nil)
      nil

  """
  def lookup_city(ip) do
    lookup(ip).city
  end

  defp lookup_with_backend(ip) do
    case :locus.get_info(@database_id) do
      {:ok, _info} ->
        # MaxMind database is loaded
        lookup_maxmind(ip)

      {:error, _} ->
        # Fall back to ip-api.com
        lookup_ipapi(ip)
    end
  end

  defp lookup_maxmind(ip) do
    case :locus.lookup(@database_id, ip) do
      {:ok, data} ->
        country = get_in(data, [:country, :iso_code])
        city = get_in(data, [:city, :names, "en"])
        %{country: country, city: city}

      {:error, _reason} ->
        %{country: nil, city: nil}
    end
  end

  defp lookup_ipapi(ip) do
    # Check rate limit first
    case check_rate_limit() do
      :ok ->
        case get_cached(ip) do
          {:ok, result} -> result
          :miss -> fetch_and_cache_ipapi(ip)
        end

      :rate_limited ->
        Logger.debug("Geo lookup rate limited for #{ip}")
        %{country: nil, city: nil}
    end
  end

  defp check_rate_limit do
    case Homesite.RateLimiter.check_rate(:geo, "ipapi") do
      {:allow, _count} -> :ok
      {:deny, _retry_after} -> :rate_limited
    end
  end

  defp get_cached(ip) do
    if :ets.info(@cache_table) != :undefined do
      case :ets.lookup(@cache_table, ip) do
        [{^ip, result, expires_at}] ->
          if System.system_time(:second) < expires_at do
            {:ok, result}
          else
            :miss
          end

        [] ->
          :miss
      end
    else
      :miss
    end
  end

  defp cache_result(ip, result) do
    if :ets.info(@cache_table) != :undefined do
      expires_at = System.system_time(:second) + @cache_ttl_seconds
      :ets.insert(@cache_table, {ip, result, expires_at})
    end

    result
  end

  defp fetch_and_cache_ipapi(ip) do
    case fetch_geo_ipapi(ip) do
      {:ok, result} ->
        cache_result(ip, result)

      {:error, reason} ->
        Logger.debug("Geo lookup failed for #{ip}: #{inspect(reason)}")
        cache_result(ip, %{country: nil, city: nil})
    end
  end

  defp fetch_geo_ipapi(ip) do
    # ip-api.com free tier only supports HTTP
    url = "http://ip-api.com/json/#{ip}?fields=status,countryCode,city"

    case :httpc.request(:get, {to_charlist(url), []}, [{:timeout, 5000}], []) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        case Jason.decode(to_string(body)) do
          {:ok, %{"status" => "success", "countryCode" => code, "city" => city}} ->
            {:ok, %{country: code, city: city}}

          {:ok, %{"status" => "success", "countryCode" => code}} ->
            {:ok, %{country: code, city: nil}}

          {:ok, %{"status" => "fail"}} ->
            {:error, :ip_not_found}

          _ ->
            {:error, :invalid_response}
        end

      {:ok, {{_, status, _}, _, _}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp private_ip?(ip) do
    case :inet.parse_address(to_charlist(ip)) do
      {:ok, {127, _, _, _}} -> true
      {:ok, {10, _, _, _}} -> true
      {:ok, {172, b, _, _}} when b >= 16 and b <= 31 -> true
      {:ok, {192, 168, _, _}} -> true
      {:ok, {0, 0, 0, 0}} -> true
      {:ok, {_, _, _, _, _, _, _, _}} -> true
      _ -> false
    end
  end

  defp get_maxmind_license_key do
    System.get_env("MAXMIND_LICENSE_KEY")
  end

  @doc """
  Check which geo backend is currently active.

  Returns :maxmind or :ipapi.
  """
  def active_backend do
    case :locus.get_info(@database_id) do
      {:ok, _} -> :maxmind
      {:error, _} -> :ipapi
    end
  end

  @doc """
  Get statistics about the geo lookup service.
  """
  def stats do
    case :locus.get_info(@database_id) do
      {:ok, info} ->
        %{
          backend: :maxmind,
          database: "GeoLite2-City",
          database_version: info[:version],
          database_date: info[:metadata][:build_epoch]
        }

      {:error, _} ->
        cache_size =
          if :ets.info(@cache_table) != :undefined do
            :ets.info(@cache_table, :size)
          else
            0
          end

        %{
          backend: :ipapi,
          cache_size: cache_size
        }
    end
  end
end
