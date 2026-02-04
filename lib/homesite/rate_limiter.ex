defmodule Homesite.RateLimiter do
  @moduledoc """
  Rate limiting using Hammer 7.x with threat-aware adjustments.

  Provides rate limiting for various operations:
  - `:auth` - Login attempts: 5 per minute
  - `:registration` - Registration attempts: 10 per 15 minutes
  - `:search` - Search requests: 30 per minute
  - `:feeds` - Feed requests: 20 per minute
  - `:geo` - Geo lookup (ip-api.com): 45 per minute

  ## Usage

      case RateLimiter.check_rate(:auth, user_ip) do
        {:allow, _count} -> # proceed
        {:deny, retry_after} -> # rate limited
      end

      # Or use the convenience function
      if RateLimiter.allowed?(:auth, user_ip) do
        # proceed
      end

  ## Threat-Aware Rate Limiting

      case RateLimiter.check_rate_with_threat(:auth, user_ip) do
        {:allow, _count} -> # proceed
        {:deny, retry_after} -> # rate limited
        {:blocked, expires_at} -> # IP is blocked
      end

  """

  use Hammer, backend: :ets

  alias Homesite.ThreatReputation
  alias Homesite.ThreatReputation.ScoreCalculator

  # Rate limit configurations: {scale_ms, limit}
  @limits %{
    # Login: 5 attempts per minute
    auth: {60_000, 5},
    # Registration: 10 attempts per 15 minutes
    registration: {900_000, 10},
    # Search: 30 requests per minute
    search: {60_000, 30},
    # Feeds: 20 requests per minute
    feeds: {60_000, 20},
    # Geo lookups (ip-api.com): 45 per minute
    geo: {60_000, 45},
    # User reports: 5 per hour
    report: {3_600_000, 5}
  }

  @doc """
  Check rate limit for a given limiter type and key.

  Returns `{:allow, count}` if allowed, or `{:deny, retry_after_ms}` if rate limited.

  ## Examples

      iex> RateLimiter.check_rate(:auth, "192.168.1.1")
      {:allow, 1}

      # After exceeding limit:
      iex> RateLimiter.check_rate(:auth, "192.168.1.1")
      {:deny, 58000}

  """
  @spec check_rate(atom(), String.t()) :: {:allow, non_neg_integer()} | {:deny, non_neg_integer()}
  def check_rate(limiter_type, key) when is_atom(limiter_type) and is_binary(key) do
    {scale, limit} = Map.fetch!(@limits, limiter_type)
    full_key = "#{limiter_type}:#{key}"
    hit(full_key, scale, limit)
  end

  @doc """
  Check if a request is allowed without incrementing the counter.

  Returns `true` if under the rate limit, `false` otherwise.

  Note: This actually increments the counter, so use `check_rate/2` if you need
  the count or retry_after value.

  ## Examples

      iex> RateLimiter.allowed?(:auth, "192.168.1.1")
      true

  """
  @spec allowed?(atom(), String.t()) :: boolean()
  def allowed?(limiter_type, key) do
    case check_rate(limiter_type, key) do
      {:allow, _count} -> true
      {:deny, _retry_after} -> false
    end
  end

  @doc """
  Get the configuration for a limiter type.

  Returns `{scale_ms, limit}` tuple.
  """
  @spec get_config(atom()) :: {non_neg_integer(), non_neg_integer()}
  def get_config(limiter_type) do
    Map.fetch!(@limits, limiter_type)
  end

  @doc """
  Check rate limit with threat reputation awareness.

  Returns:
  - `{:allow, count}` if allowed
  - `{:deny, retry_after_ms}` if rate limited
  - `{:blocked, expires_at}` if IP is blocked

  Threat scoring adjusts rate limits:
  - Score 0-30: Normal limits (100%)
  - Score 31-60: 50% of normal limits
  - Score 61-79: 25% of normal limits + alert
  - Score 80+: Blocked
  """
  @spec check_rate_with_threat(atom(), String.t()) ::
          {:allow, non_neg_integer()}
          | {:deny, non_neg_integer()}
          | {:blocked, DateTime.t() | nil}
  def check_rate_with_threat(limiter_type, ip_address)
      when is_atom(limiter_type) and is_binary(ip_address) do
    # Check if IP is blocked first
    status = ThreatReputation.check_ip_status(ip_address)

    if status.blocked do
      {:blocked, status.block_expires_at}
    else
      # Apply threat-adjusted rate limit
      {scale, base_limit} = Map.fetch!(@limits, limiter_type)
      multiplier = ScoreCalculator.rate_limit_multiplier(status.action)

      # Minimum limit of 1 to prevent division by zero
      adjusted_limit = max(1, round(base_limit * multiplier))

      full_key = "#{limiter_type}:threat:#{ip_address}"
      hit(full_key, scale, adjusted_limit)
    end
  end

  @doc """
  Get threat-adjusted rate limit configuration.

  Returns `{scale_ms, adjusted_limit}` tuple based on IP threat score.
  """
  @spec get_threat_adjusted_config(atom(), String.t()) :: {non_neg_integer(), non_neg_integer()}
  def get_threat_adjusted_config(limiter_type, ip_address) do
    {scale, base_limit} = Map.fetch!(@limits, limiter_type)
    status = ThreatReputation.check_ip_status(ip_address)
    multiplier = ScoreCalculator.rate_limit_multiplier(status.action)
    adjusted_limit = max(1, round(base_limit * multiplier))
    {scale, adjusted_limit}
  end
end
