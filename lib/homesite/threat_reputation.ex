defmodule Homesite.ThreatReputation do
  @moduledoc """
  Context for managing IP and country threat reputation.

  Provides automated threat detection and defense:
  - Calculates danger scores (0-100%) per IP and country
  - Auto-blocks IPs with >80% threat score
  - Progressive blocking: 15min → 1hr → 24hr → 7 days
  - Combines multiple signals for accurate scoring
  - Admin watchlist for manual overrides
  """

  import Ecto.Query

  alias Homesite.Accounts
  alias Homesite.Accounts.UserNotifier
  alias Homesite.Analytics.Geo
  alias Homesite.Notifications
  alias Homesite.Repo
  alias Homesite.Settings

  alias Homesite.ThreatReputation.{
    Cache,
    CountryReputation,
    CountryWatchlistEntry,
    ExternalReputation,
    IpReputation,
    IpWatchlistEntry,
    Monitor,
    ScoreCalculator,
    SecurityAuditLog,
    ThreatEvent
  }

  require Logger

  # Public API

  @doc """
  Checks the status of an IP address.

  Returns a map with:
  - `:blocked` - whether the IP is currently blocked
  - `:score` - current threat score (0-100)
  - `:action` - recommended action (:normal, :stricter_50, :stricter_75_alert, :auto_block)
  - `:block_expires_at` - when the block expires (if blocked)

  Results are cached for performance.
  """
  def check_ip_status(ip_address) do
    case Cache.get_ip_blocked(ip_address) do
      {:ok, result} ->
        result

      :miss ->
        result = do_check_ip_status(ip_address)
        Cache.put_ip_blocked(ip_address, result)
        result
    end
  end

  @doc """
  Calculates the current threat score for an IP address.

  Returns a map with component scores and total.
  Results are cached for 5 minutes.
  """
  def calculate_ip_score(ip_address) do
    case Cache.get_ip_score(ip_address) do
      {:ok, score_data} ->
        score_data

      :miss ->
        score_data = do_calculate_ip_score(ip_address)
        Cache.put_ip_score(ip_address, score_data)
        score_data
    end
  end

  @doc """
  Calculates the threat score for a country.

  Returns a map with aggregate country statistics.
  """
  def calculate_country_score(country_code) when is_binary(country_code) do
    case Cache.get_country_score(country_code) do
      {:ok, score_data} ->
        score_data

      :miss ->
        watchlist = get_country_watchlist_entry(country_code)

        watchlist_boost =
          if watchlist && CountryWatchlistEntry.active?(watchlist),
            do: watchlist.boost_score,
            else: 0

        score_data =
          ScoreCalculator.calculate_country_score(country_code, watchlist_boost: watchlist_boost)

        Cache.put_country_score(country_code, score_data)
        score_data
    end
  end

  def calculate_country_score(nil), do: %{total: 0, base_score: 0, watchlist_boost: 0}

  @doc """
  Records a threat event and updates IP reputation.

  Automatically recalculates the IP score and may trigger auto-blocking.
  """
  def record_threat_event(ip_address, event_type, opts \\ []) do
    country_code = opts[:country_code] || Geo.lookup_country(ip_address)
    user_id = opts[:user_id]
    details = opts[:details] || %{}
    severity = opts[:severity] || ThreatEvent.severity_for(event_type)
    score_impact = opts[:score_impact] || ThreatEvent.score_impact_for(event_type)

    # Insert threat event
    event_attrs = %{
      ip_address: ip_address,
      event_type: event_type,
      severity: severity,
      score_impact: score_impact,
      details: details,
      country_code: country_code,
      user_id: user_id
    }

    case %ThreatEvent{} |> ThreatEvent.changeset(event_attrs) |> Repo.insert() do
      {:ok, event} ->
        # Notify real-time monitor
        Monitor.record_event(event)

        # Update IP reputation
        update_ip_reputation_from_event(ip_address, event, country_code)

        # Check if auto-block needed
        score_data = calculate_ip_score(ip_address)

        if ScoreCalculator.should_auto_block?(score_data.total) do
          auto_block_ip(ip_address, "Auto-blocked due to threat score: #{score_data.total}")
        end

        if ScoreCalculator.should_alert_admins?(score_data.total) do
          alert_admins_high_threat(ip_address, score_data)
        end

        {:ok, event}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Automatically blocks an IP address with progressive duration.

  Block escalation:
  - 1st block: 15 minutes
  - 2nd block: 1 hour
  - 3rd block: 24 hours
  - 4th+ block: 7 days
  """
  def auto_block_ip(ip_address, reason \\ nil) do
    ip_rep = get_or_create_ip_reputation(ip_address)
    block_count = ip_rep.block_count
    duration_seconds = IpReputation.block_duration(block_count)
    block_expires_at = DateTime.add(DateTime.utc_now(), duration_seconds, :second)

    attrs = %{
      blocked: true,
      blocked_at: DateTime.utc_now(:second),
      block_expires_at: block_expires_at,
      block_count: block_count + 1
    }

    case ip_rep |> IpReputation.changeset(attrs) |> Repo.update() do
      {:ok, updated} ->
        # Invalidate cache
        Cache.invalidate_ip(ip_address)

        # Log the block event
        record_threat_event(ip_address, "auto_block",
          details: %{
            reason: reason,
            duration_seconds: duration_seconds,
            block_count: block_count + 1
          }
        )

        Logger.warning(
          "Auto-blocked IP #{ip_address} for #{div(duration_seconds, 60)} minutes (block ##{block_count + 1})"
        )

        # Send email alert
        country_code = updated.country_code || Geo.lookup_country(ip_address)
        alert_ip_auto_blocked(ip_address, updated.score, country_code, div(duration_seconds, 60))

        {:ok, updated}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Manually blocks an IP address.
  """
  def manual_block_ip(ip_address, admin_user, opts \\ []) do
    duration_seconds = Keyword.get(opts, :duration, 24 * 60 * 60)
    reason = Keyword.get(opts, :reason, "Manual admin block")
    request_ip = Keyword.get(opts, :request_ip)

    ip_rep = get_or_create_ip_reputation(ip_address)
    block_expires_at = DateTime.add(DateTime.utc_now(), duration_seconds, :second)

    attrs = %{
      blocked: true,
      blocked_at: DateTime.utc_now(:second),
      block_expires_at: block_expires_at,
      block_count: ip_rep.block_count + 1
    }

    case ip_rep |> IpReputation.changeset(attrs) |> Repo.update() do
      {:ok, updated} ->
        Cache.invalidate_ip(ip_address)

        record_threat_event(ip_address, "manual_block",
          details: %{
            reason: reason,
            duration_seconds: duration_seconds,
            admin_id: admin_user.id,
            admin_email: admin_user.email
          }
        )

        # Log audit action
        log_security_action(admin_user, "ip_manual_block", "ip_address", ip_address,
          details: %{reason: reason, duration_seconds: duration_seconds},
          ip_address: request_ip
        )

        {:ok, updated}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Unblocks an IP address.
  """
  def unblock_ip(ip_address, opts \\ []) do
    admin_user = Keyword.get(opts, :admin)
    request_ip = Keyword.get(opts, :request_ip)

    case get_ip_reputation(ip_address) do
      nil ->
        {:error, :not_found}

      ip_rep ->
        attrs = %{
          blocked: false,
          blocked_at: nil,
          block_expires_at: nil
        }

        case ip_rep |> IpReputation.changeset(attrs) |> Repo.update() do
          {:ok, updated} ->
            Cache.invalidate_ip(ip_address)

            details =
              if admin_user do
                %{admin_id: admin_user.id, admin_email: admin_user.email}
              else
                %{automatic: true}
              end

            record_threat_event(ip_address, "unblock", details: details)

            # Log audit action for manual unblock
            if admin_user do
              log_security_action(admin_user, "ip_manual_unblock", "ip_address", ip_address,
                ip_address: request_ip
              )
            end

            {:ok, updated}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  # IP Watchlist Management

  @doc """
  Adds an IP to the watchlist.
  """
  def add_ip_to_watchlist(ip_address, admin_user, opts \\ []) do
    boost_score = Keyword.get(opts, :boost_score, 15)
    reason = Keyword.get(opts, :reason)
    request_ip = Keyword.get(opts, :request_ip)

    attrs = %{
      ip_address: ip_address,
      boost_score: boost_score,
      reason: reason,
      notes: Keyword.get(opts, :notes),
      expires_at: Keyword.get(opts, :expires_at),
      added_by_id: admin_user.id
    }

    case %IpWatchlistEntry{} |> IpWatchlistEntry.changeset(attrs) |> Repo.insert() do
      {:ok, entry} ->
        Cache.invalidate_ip(ip_address)

        # Log audit action
        log_security_action(admin_user, "ip_watchlist_add", "ip_address", ip_address,
          details: %{boost_score: boost_score, reason: reason},
          ip_address: request_ip
        )

        {:ok, entry}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Removes an IP from the watchlist.
  """
  def remove_ip_from_watchlist(ip_address, admin_user \\ nil, opts \\ []) do
    request_ip = Keyword.get(opts, :request_ip)

    case get_ip_watchlist_entry(ip_address) do
      nil ->
        {:error, :not_found}

      entry ->
        case Repo.delete(entry) do
          {:ok, deleted} ->
            Cache.invalidate_ip(ip_address)

            # Log audit action
            if admin_user do
              log_security_action(admin_user, "ip_watchlist_remove", "ip_address", ip_address,
                ip_address: request_ip
              )
            end

            {:ok, deleted}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  @doc """
  Gets an IP watchlist entry.
  """
  def get_ip_watchlist_entry(ip_address) do
    Repo.get_by(IpWatchlistEntry, ip_address: ip_address)
  end

  @doc """
  Lists all IP watchlist entries.
  """
  def list_ip_watchlist do
    from(w in IpWatchlistEntry, order_by: [desc: w.inserted_at], preload: [:added_by])
    |> Repo.all()
  end

  # Country Watchlist Management

  @doc """
  Adds a country to the watchlist.
  """
  def add_country_to_watchlist(country_code, admin_user, opts \\ []) do
    boost_score = Keyword.get(opts, :boost_score, 15)
    reason = Keyword.get(opts, :reason)
    request_ip = Keyword.get(opts, :request_ip)

    attrs = %{
      country_code: country_code,
      boost_score: boost_score,
      reason: reason,
      notes: Keyword.get(opts, :notes),
      expires_at: Keyword.get(opts, :expires_at),
      added_by_id: admin_user.id
    }

    case %CountryWatchlistEntry{} |> CountryWatchlistEntry.changeset(attrs) |> Repo.insert() do
      {:ok, entry} ->
        Cache.invalidate_country(country_code)

        # Log audit action
        log_security_action(admin_user, "country_watchlist_add", "country_code", country_code,
          details: %{boost_score: boost_score, reason: reason},
          ip_address: request_ip
        )

        {:ok, entry}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Removes a country from the watchlist.
  """
  def remove_country_from_watchlist(country_code, admin_user \\ nil, opts \\ []) do
    request_ip = Keyword.get(opts, :request_ip)

    case get_country_watchlist_entry(country_code) do
      nil ->
        {:error, :not_found}

      entry ->
        case Repo.delete(entry) do
          {:ok, deleted} ->
            Cache.invalidate_country(country_code)

            # Log audit action
            if admin_user do
              log_security_action(
                admin_user,
                "country_watchlist_remove",
                "country_code",
                country_code,
                ip_address: request_ip
              )
            end

            {:ok, deleted}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  @doc """
  Gets a country watchlist entry.
  """
  def get_country_watchlist_entry(country_code) do
    Repo.get_by(CountryWatchlistEntry, country_code: country_code)
  end

  @doc """
  Lists all country watchlist entries.
  """
  def list_country_watchlist do
    from(w in CountryWatchlistEntry, order_by: [desc: w.inserted_at], preload: [:added_by])
    |> Repo.all()
  end

  # Reporting and Dashboard

  @doc """
  Gets dashboard statistics for threat reputation.
  """
  def get_dashboard_stats do
    now = DateTime.utc_now()
    day_ago = DateTime.add(now, -24, :hour)

    blocked_count =
      from(r in IpReputation,
        where: r.blocked == true,
        where: is_nil(r.block_expires_at) or r.block_expires_at > ^now,
        select: count(r.id)
      )
      |> Repo.one()

    high_risk_count =
      from(r in IpReputation,
        where: r.score >= 61,
        where: r.blocked == false,
        select: count(r.id)
      )
      |> Repo.one()

    events_24h =
      from(e in ThreatEvent, where: e.inserted_at >= ^day_ago, select: count(e.id))
      |> Repo.one()

    auto_blocks_24h =
      from(e in ThreatEvent,
        where: e.inserted_at >= ^day_ago,
        where: e.event_type == "auto_block",
        select: count(e.id)
      )
      |> Repo.one()

    watchlist_ip_count =
      from(w in IpWatchlistEntry, select: count(w.id))
      |> Repo.one()

    watchlist_country_count =
      from(w in CountryWatchlistEntry, select: count(w.id))
      |> Repo.one()

    external_stats = ExternalReputation.stats()

    %{
      blocked_ips: blocked_count,
      high_risk_ips: high_risk_count,
      threat_events_24h: events_24h,
      auto_blocks_24h: auto_blocks_24h,
      watchlist_ips: watchlist_ip_count,
      watchlist_countries: watchlist_country_count,
      external_reputation: external_stats
    }
  end

  @doc """
  Gets the top threat IPs.
  """
  def list_top_threats(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    from(r in IpReputation,
      where: r.score > 0,
      order_by: [desc: r.score, desc: r.updated_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Gets recently blocked IPs.
  """
  def list_recent_blocks(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    from(r in IpReputation,
      where: r.blocked == true,
      order_by: [desc: r.blocked_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Gets recent threat events.
  """
  def list_recent_events(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    from(e in ThreatEvent,
      order_by: [desc: e.inserted_at],
      limit: ^limit,
      preload: [:user]
    )
    |> Repo.all()
  end

  @doc """
  Gets threat events for a specific IP.
  """
  def list_events_for_ip(ip_address, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    from(e in ThreatEvent,
      where: e.ip_address == ^ip_address,
      order_by: [desc: e.inserted_at],
      limit: ^limit,
      preload: [:user]
    )
    |> Repo.all()
  end

  @doc """
  Gets country statistics ordered by threat score.
  """
  def list_country_stats(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    from(r in CountryReputation,
      order_by: [desc: r.score, desc: r.threat_events_count],
      limit: ^limit
    )
    |> Repo.all()
  end

  # Cleanup and maintenance

  @doc """
  Unblocks IPs whose block has expired.

  Called by ThreatCleanupWorker.
  """
  def unblock_expired do
    now = DateTime.utc_now()

    {count, _} =
      from(r in IpReputation,
        where: r.blocked == true,
        where: not is_nil(r.block_expires_at),
        where: r.block_expires_at <= ^now
      )
      |> Repo.update_all(set: [blocked: false, blocked_at: nil, block_expires_at: nil])

    # Clear cache for all unblocked IPs
    if count > 0 do
      Cache.clear_all()
      Logger.info("Unblocked #{count} expired IP blocks")
    end

    count
  end

  @doc """
  Deletes old threat events.

  Called by ThreatCleanupWorker.
  """
  def cleanup_old_events(days_to_keep \\ 90) do
    cutoff = DateTime.add(DateTime.utc_now(), -days_to_keep, :day)

    {count, _} =
      from(e in ThreatEvent, where: e.inserted_at < ^cutoff)
      |> Repo.delete_all()

    if count > 0 do
      Logger.info("Deleted #{count} threat events older than #{days_to_keep} days")
    end

    count
  end

  @doc """
  Decays threat scores over time.

  Called by ThreatScoreDecayWorker.
  Reduces scores by a percentage to allow recovery.
  """
  def decay_scores(decay_percentage \\ 5) do
    now = DateTime.utc_now(:second)
    decay_multiplier = (100 - decay_percentage) / 100

    query = from(r in IpReputation, where: r.score > 0)

    {count, _} =
      Repo.update_all(query,
        set: [updated_at: now],
        inc: []
      )

    # For score decay, use raw SQL since Ecto update_all doesn't support computed updates well
    if count > 0 do
      Repo.query!(
        "UPDATE ip_reputations SET score = GREATEST(0, FLOOR(score * $1)) WHERE score > 0",
        [decay_multiplier]
      )

      Cache.clear_all()
      Logger.debug("Decayed scores for #{count} IPs by #{decay_percentage}%")
    end

    count
  end

  @doc """
  Removes expired watchlist entries.
  """
  def cleanup_expired_watchlist do
    now = DateTime.utc_now()

    {ip_count, _} =
      from(w in IpWatchlistEntry, where: not is_nil(w.expires_at), where: w.expires_at <= ^now)
      |> Repo.delete_all()

    {country_count, _} =
      from(w in CountryWatchlistEntry,
        where: not is_nil(w.expires_at),
        where: w.expires_at <= ^now
      )
      |> Repo.delete_all()

    if ip_count > 0 or country_count > 0 do
      Cache.clear_all()

      Logger.info(
        "Removed #{ip_count} expired IP watchlist and #{country_count} country watchlist entries"
      )
    end

    {ip_count, country_count}
  end

  # Security Audit Logging

  @doc """
  Logs a security action performed by an admin.

  ## Parameters
  - `admin` - The admin user performing the action
  - `action_type` - Type of action (see SecurityAuditLog.action_types/0)
  - `target_type` - Type of target (ip_address, country_code, setting)
  - `target_value` - The target value (e.g., "1.2.3.4", "US", "auto_block_threshold")
  - `opts` - Optional details and IP address
  """
  def log_security_action(admin, action_type, target_type, target_value, opts \\ []) do
    attrs = %{
      admin_id: admin.id,
      action_type: action_type,
      target_type: target_type,
      target_value: target_value,
      details: Keyword.get(opts, :details, %{}),
      ip_address: Keyword.get(opts, :ip_address)
    }

    %SecurityAuditLog{}
    |> SecurityAuditLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Lists security audit logs with optional filters.

  ## Options
  - `:limit` - Maximum number of entries (default 50)
  - `:offset` - Offset for pagination
  - `:action_type` - Filter by action type
  - `:admin_id` - Filter by admin user
  """
  def list_security_audit_logs(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)
    action_type = Keyword.get(opts, :action_type)
    admin_id = Keyword.get(opts, :admin_id)

    query =
      from(l in SecurityAuditLog,
        order_by: [desc: l.inserted_at],
        limit: ^limit,
        offset: ^offset,
        preload: [:admin]
      )

    query =
      if action_type do
        from(l in query, where: l.action_type == ^action_type)
      else
        query
      end

    query =
      if admin_id do
        from(l in query, where: l.admin_id == ^admin_id)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Counts security audit logs with optional filters.
  """
  def count_security_audit_logs(opts \\ []) do
    action_type = Keyword.get(opts, :action_type)
    admin_id = Keyword.get(opts, :admin_id)

    query = from(l in SecurityAuditLog, select: count(l.id))

    query =
      if action_type do
        from(l in query, where: l.action_type == ^action_type)
      else
        query
      end

    query =
      if admin_id do
        from(l in query, where: l.admin_id == ^admin_id)
      else
        query
      end

    Repo.one(query)
  end

  # Email Alert Functions

  @doc """
  Sends a security alert email to all admins if alerts are enabled.

  Alert types: :attack_detected, :ip_auto_blocked, :threshold_exceeded, :ip_warning
  """
  def send_security_alert(alert_type, details) do
    if Settings.should_alert?(alert_type) do
      Task.Supervisor.async_nolink(Homesite.TaskSupervisor, fn ->
        for admin <- Accounts.list_admins() do
          UserNotifier.deliver_security_alert(admin, alert_type, details)
        end
      end)

      :ok
    else
      :skipped
    end
  end

  @doc """
  Sends an alert when an attack is detected.
  """
  def alert_attack_detected(attack_type, ip_address, event_count, country_code \\ nil) do
    send_security_alert(:attack_detected, %{
      attack_type: attack_type,
      ip_address: ip_address,
      event_count: event_count,
      country: country_code
    })
  end

  @doc """
  Sends an alert when an IP is auto-blocked.
  """
  def alert_ip_auto_blocked(ip_address, score, country_code, block_duration_minutes) do
    duration_str =
      cond do
        block_duration_minutes < 60 -> "#{block_duration_minutes} minutes"
        block_duration_minutes < 1440 -> "#{div(block_duration_minutes, 60)} hours"
        true -> "#{div(block_duration_minutes, 1440)} days"
      end

    send_security_alert(:ip_auto_blocked, %{
      ip_address: ip_address,
      score: score,
      country: country_code,
      block_duration: duration_str
    })
  end

  @doc """
  Sends an alert when an IP reaches warning level.
  """
  def alert_ip_warning(ip_address, score, country_code) do
    send_security_alert(:ip_warning, %{
      ip_address: ip_address,
      score: score,
      country: country_code
    })
  end

  # Private functions

  defp do_check_ip_status(ip_address) do
    case get_ip_reputation(ip_address) do
      nil ->
        %{blocked: false, score: 0, action: :normal, block_expires_at: nil}

      ip_rep ->
        blocked = IpReputation.blocked?(ip_rep)
        score_data = calculate_ip_score(ip_address)

        %{
          blocked: blocked,
          score: score_data.total,
          action: score_data.threshold_action,
          block_expires_at: ip_rep.block_expires_at
        }
    end
  end

  defp do_calculate_ip_score(ip_address) do
    # Get watchlist boosts
    ip_watchlist = get_ip_watchlist_entry(ip_address)

    ip_boost =
      if ip_watchlist && IpWatchlistEntry.active?(ip_watchlist),
        do: ip_watchlist.boost_score,
        else: 0

    country_code = Geo.lookup_country(ip_address)
    country_watchlist = if country_code, do: get_country_watchlist_entry(country_code), else: nil

    country_boost =
      if country_watchlist && CountryWatchlistEntry.active?(country_watchlist),
        do: country_watchlist.boost_score,
        else: 0

    ScoreCalculator.calculate_ip_score(ip_address,
      watchlist_boost: ip_boost,
      country_watchlist_boost: country_boost
    )
  end

  defp get_ip_reputation(ip_address) do
    Repo.get_by(IpReputation, ip_address: ip_address)
  end

  defp get_or_create_ip_reputation(ip_address) do
    case get_ip_reputation(ip_address) do
      nil ->
        country_code = Geo.lookup_country(ip_address)

        attrs = %{
          ip_address: ip_address,
          country_code: country_code,
          last_seen_at: DateTime.utc_now(:second)
        }

        %IpReputation{}
        |> IpReputation.changeset(attrs)
        |> Repo.insert!()

      ip_rep ->
        ip_rep
    end
  end

  defp update_ip_reputation_from_event(ip_address, _event, country_code) do
    ip_rep = get_or_create_ip_reputation(ip_address)

    # Recalculate score
    score_data = do_calculate_ip_score(ip_address)

    attrs = %{
      score: score_data.total,
      failed_login_count: score_data.failed_login_score,
      suspicious_activity_count: score_data.suspicious_score,
      request_volume_score: score_data.volume_score,
      watchlist_boost: score_data.watchlist_boost,
      country_code: country_code || ip_rep.country_code,
      last_seen_at: DateTime.utc_now(:second)
    }

    case ip_rep |> IpReputation.changeset(attrs) |> Repo.update() do
      {:ok, updated} ->
        Cache.invalidate_ip(ip_address)

        # Update country reputation if country is known
        if updated.country_code do
          update_country_reputation(updated.country_code)
        end

        {:ok, updated}

      {:error, changeset} ->
        Logger.error("Failed to update IP reputation: #{inspect(changeset.errors)}")
        {:error, changeset}
    end
  end

  defp update_country_reputation(country_code) do
    # Get aggregate stats
    stats =
      from(r in IpReputation,
        where: r.country_code == ^country_code,
        select: %{
          total_ips: count(r.id),
          blocked_ips: sum(fragment("CASE WHEN ? THEN 1 ELSE 0 END", r.blocked)),
          avg_score: avg(r.score)
        }
      )
      |> Repo.one()

    # Get threat events count
    events_count =
      from(e in ThreatEvent, where: e.country_code == ^country_code, select: count(e.id))
      |> Repo.one()

    # Get watchlist boost
    watchlist = get_country_watchlist_entry(country_code)

    watchlist_boost =
      if watchlist && CountryWatchlistEntry.active?(watchlist), do: watchlist.boost_score, else: 0

    # Calculate score
    base_score =
      cond do
        is_nil(stats) or stats.total_ips == 0 or is_nil(stats.total_ips) ->
          0

        true ->
          avg_score = normalize_decimal(stats.avg_score) || 0
          blocked_count = normalize_decimal(stats.blocked_ips) || 0
          total_count = normalize_decimal(stats.total_ips)
          blocked_ratio = blocked_count / total_count * 100
          round(avg_score * 0.6 + blocked_ratio * 0.4)
      end

    total_ips = if stats, do: stats.total_ips || 0, else: 0
    blocked_ips = if stats, do: normalize_decimal(stats.blocked_ips) || 0, else: 0

    attrs = %{
      country_code: country_code,
      score: min(base_score + watchlist_boost, 100),
      total_ips: total_ips,
      blocked_ips: round(blocked_ips),
      threat_events_count: events_count,
      watchlist_boost: watchlist_boost
    }

    case Repo.get_by(CountryReputation, country_code: country_code) do
      nil ->
        %CountryReputation{}
        |> CountryReputation.changeset(attrs)
        |> Repo.insert()

      country_rep ->
        country_rep
        |> CountryReputation.changeset(attrs)
        |> Repo.update()
    end

    Cache.invalidate_country(country_code)
  end

  defp normalize_decimal(nil), do: nil
  defp normalize_decimal(%Decimal{} = d), do: Decimal.to_float(d)
  defp normalize_decimal(n) when is_number(n), do: n

  defp alert_admins_high_threat(ip_address, score_data) do
    alias Homesite.Accounts

    country_code = Geo.lookup_country(ip_address)

    for admin <- Accounts.list_admins() do
      Notifications.create_notification(
        admin.id,
        "high_threat_ip",
        nil,
        %{
          "ip_address" => ip_address,
          "score" => score_data.total,
          "country" => country_code,
          "action" => to_string(score_data.threshold_action)
        }
      )
    end

    :ok
  end

  # External Reputation Integration

  @doc """
  Looks up the external reputation for an IP address.

  Returns a reputation result map from AbuseIPDB or nil if unavailable.
  Results are cached for 24 hours.
  """
  defdelegate lookup_external_reputation(ip_address), to: ExternalReputation, as: :lookup

  @doc """
  Checks if external reputation service (AbuseIPDB) is configured.
  """
  defdelegate external_reputation_available?(), to: ExternalReputation, as: :available?

  @doc """
  Gets external reputation service statistics.
  """
  defdelegate external_reputation_stats(), to: ExternalReputation, as: :stats

  @doc """
  Clears the external reputation cache.
  """
  defdelegate clear_external_reputation_cache(), to: ExternalReputation, as: :clear_cache

  @doc """
  Returns human-readable name for AbuseIPDB category codes.
  """
  defdelegate external_category_name(code), to: ExternalReputation, as: :category_name

  # Real-time Monitoring

  @doc """
  Gets real-time monitoring statistics.

  Returns stats about events in the sliding window (5 minutes):
  - events_in_window: Total events in window
  - unique_ips_in_window: Unique IPs seen
  - events_per_minute: Current rate
  - top_ips: Most active threat IPs
  """
  defdelegate get_monitor_stats(), to: Monitor, as: :get_stats

  @doc """
  Gets recently detected attacks from the monitor.
  """
  defdelegate get_recent_attacks(), to: Monitor, as: :get_recent_attacks

  @doc """
  Gets currently active threat IPs from the monitoring window.
  """
  defdelegate get_active_threats(), to: Monitor, as: :get_active_threats

  @doc """
  Returns the PubSub topic for real-time threat monitoring updates.

  Subscribe to receive:
  - {:threat_event, event} - New threat events
  - {:attack_detected, attack_info} - Detected attack patterns
  - {:stats_updated, stats} - Periodic stats updates
  """
  defdelegate monitor_topic(), to: Monitor, as: :topic
end
