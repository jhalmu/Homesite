defmodule Homesite.ThreatReputation.ScoreCalculator do
  @moduledoc """
  Calculates threat scores for IPs and countries.

  Score components (0-100% total):
  - Failed login ratio: max 30 points
  - Suspicious activity: max 25 points
  - External reputation: max 20 points (AbuseIPDB)
  - Request volume anomaly: max 10 points
  - Historical violations: max 10 points
  - Watchlist boost: max 15 points

  Auto-defense thresholds:
  - 0-30: Normal rate limits
  - 31-60: 50% stricter rate limits
  - 61-79: 75% stricter + alert admins
  - 80+: Auto-block IP
  """

  import Ecto.Query

  alias Homesite.Accounts.AuthLog
  alias Homesite.Repo
  alias Homesite.ThreatReputation.ExternalReputation

  # Score component maximums (adjusted to make room for external score)
  @max_failed_login_score 30
  @max_suspicious_score 25
  @max_external_score 20
  @max_volume_score 10
  @max_violation_score 10
  @max_watchlist_score 15

  # Thresholds for scoring
  @failed_login_threshold 5
  @suspicious_activity_threshold 3
  @volume_threshold 100
  @violation_threshold 3

  # Time windows
  @failed_login_window_hours 24
  @suspicious_window_hours 24
  @volume_window_minutes 60

  @doc """
  Calculates the total threat score for an IP address.

  Returns a map with individual component scores and total.

  Options:
  - `:watchlist_boost` - Manual IP watchlist boost (0-15)
  - `:country_watchlist_boost` - Country watchlist boost (0-15)
  - `:skip_external` - Skip external reputation lookup (default: false)
  """
  def calculate_ip_score(ip_address, opts \\ []) do
    watchlist_boost = Keyword.get(opts, :watchlist_boost, 0)
    country_watchlist_boost = Keyword.get(opts, :country_watchlist_boost, 0)
    skip_external = Keyword.get(opts, :skip_external, false)

    failed_login_score = calculate_failed_login_score(ip_address)
    suspicious_score = calculate_suspicious_score(ip_address)
    external_score = if skip_external, do: 0, else: calculate_external_score(ip_address)
    volume_score = calculate_volume_score(ip_address)
    violation_score = calculate_violation_score(ip_address)
    total_watchlist_boost = min(watchlist_boost + country_watchlist_boost, @max_watchlist_score)

    total =
      min(
        failed_login_score + suspicious_score + external_score + volume_score + violation_score +
          total_watchlist_boost,
        100
      )

    %{
      total: total,
      failed_login_score: failed_login_score,
      suspicious_score: suspicious_score,
      external_score: external_score,
      volume_score: volume_score,
      violation_score: violation_score,
      watchlist_boost: total_watchlist_boost,
      threshold_action: threshold_action(total)
    }
  end

  @doc """
  Determines the action threshold based on score.
  """
  def threshold_action(score) when score <= 30, do: :normal
  def threshold_action(score) when score <= 60, do: :stricter_50
  def threshold_action(score) when score <= 79, do: :stricter_75_alert
  def threshold_action(_score), do: :auto_block

  @doc """
  Returns the rate limit multiplier based on threat action.
  """
  def rate_limit_multiplier(:normal), do: 1.0
  def rate_limit_multiplier(:stricter_50), do: 0.5
  def rate_limit_multiplier(:stricter_75_alert), do: 0.25
  def rate_limit_multiplier(:auto_block), do: 0.0

  @doc """
  Calculates the external reputation score component (max 20 points).

  Uses AbuseIPDB or other external threat intelligence feeds.
  Results are cached for 24 hours to minimize API usage.
  """
  def calculate_external_score(ip_address) do
    case ExternalReputation.lookup(ip_address) do
      nil -> 0
      result -> min(ExternalReputation.score_contribution(result), @max_external_score)
    end
  end

  @doc """
  Calculates the failed login score component (max 30 points).

  Based on failed login attempts in the last 24 hours.
  """
  def calculate_failed_login_score(ip_address) do
    window_start = DateTime.add(DateTime.utc_now(), -@failed_login_window_hours, :hour)

    failed_count =
      from(l in AuthLog,
        where: l.ip_address == ^ip_address,
        where: l.success == false,
        where: l.event_type in ["login_failure", "magic_link_failure"],
        where: l.inserted_at >= ^window_start,
        select: count(l.id)
      )
      |> Repo.one()

    # Scale: 0 failures = 0 points, 5+ failures = 30 points (linear)
    min(
      round(failed_count / @failed_login_threshold * @max_failed_login_score),
      @max_failed_login_score
    )
  end

  @doc """
  Calculates the suspicious activity score component (max 25 points).

  Based on suspicious activity events in the last 24 hours.
  """
  def calculate_suspicious_score(ip_address) do
    window_start = DateTime.add(DateTime.utc_now(), -@suspicious_window_hours, :hour)

    suspicious_count =
      from(l in AuthLog,
        where: l.ip_address == ^ip_address,
        where: l.event_type == "suspicious_activity",
        where: l.inserted_at >= ^window_start,
        select: count(l.id)
      )
      |> Repo.one()

    # Scale: 0 events = 0 points, 3+ events = 25 points (linear)
    min(
      round(suspicious_count / @suspicious_activity_threshold * @max_suspicious_score),
      @max_suspicious_score
    )
  end

  @doc """
  Calculates the request volume anomaly score (max 10 points).

  Based on total requests in the last hour.
  """
  def calculate_volume_score(ip_address) do
    window_start = DateTime.add(DateTime.utc_now(), -@volume_window_minutes, :minute)

    request_count =
      from(l in AuthLog,
        where: l.ip_address == ^ip_address,
        where: l.inserted_at >= ^window_start,
        select: count(l.id)
      )
      |> Repo.one()

    # Scale: 0 requests = 0 points, 100+ requests = 15 points (linear)
    min(round(request_count / @volume_threshold * @max_volume_score), @max_volume_score)
  end

  @doc """
  Calculates the historical violation score (max 10 points).

  Based on past violations from the user_violations table.
  """
  def calculate_violation_score(ip_address) do
    # Check if there are any users associated with this IP who have violations
    violation_count =
      from(l in AuthLog,
        where: l.ip_address == ^ip_address,
        where: not is_nil(l.user_id),
        join: v in "user_violations",
        on: v.user_id == l.user_id,
        select: count(v.id, :distinct)
      )
      |> Repo.one()

    # Scale: 0 violations = 0 points, 3+ violations = 15 points (linear)
    min(
      round(violation_count / @violation_threshold * @max_violation_score),
      @max_violation_score
    )
  end

  @doc """
  Calculates country-level threat score by aggregating IP scores.
  """
  def calculate_country_score(country_code, opts \\ []) do
    watchlist_boost = Keyword.get(opts, :watchlist_boost, 0)

    # Get aggregate stats for the country
    stats =
      from(r in "ip_reputations",
        where: r.country_code == ^country_code,
        select: %{
          total_ips: count(r.id),
          blocked_ips: sum(fragment("CASE WHEN ? THEN 1 ELSE 0 END", r.blocked)),
          avg_score: avg(r.score)
        }
      )
      |> Repo.one()

    base_score =
      if is_nil(stats) or stats.total_ips == 0 do
        0
      else
        # Weight: 60% average IP score, 40% blocked ratio
        avg_score = stats.avg_score || 0
        blocked_ratio = (stats.blocked_ips || 0) / stats.total_ips * 100
        round(avg_score * 0.6 + blocked_ratio * 0.4)
      end

    total = min(base_score + watchlist_boost, 100)

    %{
      total: total,
      base_score: base_score,
      watchlist_boost: watchlist_boost,
      total_ips: stats[:total_ips] || 0,
      blocked_ips: stats[:blocked_ips] || 0
    }
  end

  @doc """
  Determines if an IP should be auto-blocked based on its score.
  """
  def should_auto_block?(score) when score >= 80, do: true
  def should_auto_block?(_score), do: false

  @doc """
  Determines if admins should be alerted based on score.
  """
  def should_alert_admins?(score) when score >= 61, do: true
  def should_alert_admins?(_score), do: false
end
