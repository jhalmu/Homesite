defmodule Homesite.ThreatReputation.ExternalReputation do
  @moduledoc """
  External IP reputation service integration.

  Integrates with external threat intelligence feeds to provide
  pre-scoring for unknown IPs before any local activity is observed.

  Currently supports:
  - AbuseIPDB (https://www.abuseipdb.com) - Primary source

  ## Configuration

  Set the environment variable:

      ABUSEIPDB_API_KEY=your_api_key

  Get a free API key at: https://www.abuseipdb.com/account/api

  ## Rate Limits

  AbuseIPDB free tier: 1,000 checks/day
  Results are cached for 24 hours to minimize API usage.
  """

  require Logger

  @cache_table :external_reputation_cache
  @cache_ttl_seconds 86_400
  @api_base_url "https://api.abuseipdb.com/api/v2"
  @max_age_days 90
  @request_timeout 5_000

  @type reputation_result :: %{
          source: atom(),
          abuse_score: integer(),
          total_reports: integer(),
          country_code: String.t() | nil,
          isp: String.t() | nil,
          is_whitelisted: boolean(),
          last_reported_at: DateTime.t() | nil,
          categories: [integer()],
          raw_data: map()
        }

  @doc """
  Initializes the ETS cache for external reputation lookups.

  Call this from application startup.
  """
  def init_cache do
    if :ets.info(@cache_table) == :undefined do
      :ets.new(@cache_table, [:named_table, :public, read_concurrency: true])
    end

    :ok
  end

  @doc """
  Looks up the external reputation for an IP address.

  Returns a reputation result map or nil if lookup fails or no API key configured.

  Results are cached for 24 hours to minimize API usage.

  ## Examples

      iex> lookup("1.2.3.4")
      %{
        source: :abuseipdb,
        abuse_score: 85,
        total_reports: 42,
        country_code: "CN",
        ...
      }

      iex> lookup("127.0.0.1")
      nil

  """
  @spec lookup(String.t()) :: reputation_result() | nil
  def lookup(ip_address) when is_binary(ip_address) do
    if private_ip?(ip_address) do
      nil
    else
      case get_cached(ip_address) do
        {:ok, result} ->
          result

        :miss ->
          fetch_and_cache(ip_address)
      end
    end
  end

  def lookup(_), do: nil

  @doc """
  Converts the external abuse score (0-100) to our internal score contribution (0-20).

  AbuseIPDB's "Confidence of Abuse" score is scaled to contribute
  up to 20 points to our threat score.

  Score mapping:
  - 0-20 abuse score → 0 points (low risk)
  - 21-50 abuse score → 5 points (moderate)
  - 51-75 abuse score → 10 points (elevated)
  - 76-90 abuse score → 15 points (high)
  - 91-100 abuse score → 20 points (critical)
  """
  @spec score_contribution(reputation_result() | nil) :: integer()
  def score_contribution(nil), do: 0

  def score_contribution(%{abuse_score: score}) when score <= 20, do: 0
  def score_contribution(%{abuse_score: score}) when score <= 50, do: 5
  def score_contribution(%{abuse_score: score}) when score <= 75, do: 10
  def score_contribution(%{abuse_score: score}) when score <= 90, do: 15
  def score_contribution(%{abuse_score: _score}), do: 20

  @doc """
  Checks if the external reputation service is available.

  Returns true if an API key is configured.
  """
  @spec available?() :: boolean()
  def available? do
    get_api_key() != nil
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

    %{
      cache_entries: cache_size,
      api_configured: available?(),
      cache_ttl_hours: div(@cache_ttl_seconds, 3600)
    }
  end

  @doc """
  Clears the external reputation cache.
  """
  def clear_cache do
    if :ets.info(@cache_table) != :undefined do
      :ets.delete_all_objects(@cache_table)
    end

    :ok
  end

  @doc """
  Invalidates the cache entry for a specific IP.
  """
  def invalidate(ip_address) do
    if :ets.info(@cache_table) != :undefined do
      :ets.delete(@cache_table, ip_address)
    end

    :ok
  end

  # Private functions

  defp fetch_and_cache(ip_address) do
    case fetch_abuseipdb(ip_address) do
      {:ok, result} ->
        cache_result(ip_address, result)
        result

      {:error, reason} ->
        Logger.debug("External reputation lookup failed for #{ip_address}: #{inspect(reason)}")
        # Cache the nil result to avoid repeated failed lookups
        cache_result(ip_address, nil)
        nil
    end
  end

  defp fetch_abuseipdb(ip_address) do
    case get_api_key() do
      nil ->
        {:error, :no_api_key}

      api_key ->
        url =
          "#{@api_base_url}/check?ipAddress=#{URI.encode(ip_address)}&maxAgeInDays=#{@max_age_days}"

        headers = [
          {~c"Key", String.to_charlist(api_key)},
          {~c"Accept", ~c"application/json"}
        ]

        case :httpc.request(
               :get,
               {String.to_charlist(url), headers},
               [{:timeout, @request_timeout}],
               []
             ) do
          {:ok, {{_, 200, _}, _headers, body}} ->
            parse_abuseipdb_response(body)

          {:ok, {{_, 429, _}, _headers, _body}} ->
            Logger.warning("AbuseIPDB rate limit exceeded")
            {:error, :rate_limited}

          {:ok, {{_, status, _}, _headers, body}} ->
            Logger.warning("AbuseIPDB API error: status #{status}, body: #{body}")
            {:error, {:http_error, status}}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp parse_abuseipdb_response(body) do
    case Jason.decode(to_string(body)) do
      {:ok, %{"data" => data}} ->
        result = %{
          source: :abuseipdb,
          abuse_score: data["abuseConfidenceScore"] || 0,
          total_reports: data["totalReports"] || 0,
          country_code: data["countryCode"],
          isp: data["isp"],
          is_whitelisted: data["isWhitelisted"] || false,
          last_reported_at: parse_datetime(data["lastReportedAt"]),
          categories: extract_categories(data),
          raw_data: data
        }

        {:ok, result}

      {:ok, %{"errors" => errors}} ->
        Logger.warning("AbuseIPDB API returned errors: #{inspect(errors)}")
        {:error, {:api_error, errors}}

      {:error, reason} ->
        {:error, {:json_decode_error, reason}}
    end
  end

  defp parse_datetime(nil), do: nil

  defp parse_datetime(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _offset} -> datetime
      _ -> nil
    end
  end

  defp extract_categories(%{"reports" => reports}) when is_list(reports) do
    reports
    |> Enum.flat_map(fn report -> report["categories"] || [] end)
    |> Enum.uniq()
  end

  defp extract_categories(_), do: []

  defp get_cached(ip_address) do
    if :ets.info(@cache_table) != :undefined do
      case :ets.lookup(@cache_table, ip_address) do
        [{^ip_address, result, expires_at}] ->
          if System.system_time(:second) < expires_at do
            {:ok, result}
          else
            :ets.delete(@cache_table, ip_address)
            :miss
          end

        [] ->
          :miss
      end
    else
      :miss
    end
  end

  defp cache_result(ip_address, result) do
    if :ets.info(@cache_table) != :undefined do
      expires_at = System.system_time(:second) + @cache_ttl_seconds
      :ets.insert(@cache_table, {ip_address, result, expires_at})
    end

    result
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

  defp get_api_key do
    System.get_env("ABUSEIPDB_API_KEY")
  end

  @doc """
  Returns human-readable category names for AbuseIPDB category codes.

  See: https://www.abuseipdb.com/categories
  """
  def category_name(code) do
    categories = %{
      1 => "DNS Compromise",
      2 => "DNS Poisoning",
      3 => "Fraud Orders",
      4 => "DDoS Attack",
      5 => "FTP Brute-Force",
      6 => "Ping of Death",
      7 => "Phishing",
      8 => "Fraud VoIP",
      9 => "Open Proxy",
      10 => "Web Spam",
      11 => "Email Spam",
      12 => "Blog Spam",
      13 => "VPN IP",
      14 => "Port Scan",
      15 => "Hacking",
      16 => "SQL Injection",
      17 => "Spoofing",
      18 => "Brute-Force",
      19 => "Bad Web Bot",
      20 => "Exploited Host",
      21 => "Web App Attack",
      22 => "SSH",
      23 => "IoT Targeted"
    }

    Map.get(categories, code, "Unknown (#{code})")
  end
end
