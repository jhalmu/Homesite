defmodule Homesite.Moderation do
  @moduledoc """
  The Moderation context.

  Provides user-initiated moderation (mutes, reports) and admin-initiated
  moderation (suspensions, bans, banner warnings).

  ## User Features

  Users can:
  - Mute other users (hides their content globally)
  - Report other users for admin review

  ## Admin Features

  Admins can:
  - Create warning banners for specific users
  - Suspend users temporarily (prevents login)
  - Ban users permanently (prevents login)
  - Review and resolve user reports
  """

  import Ecto.Query, warn: false

  alias Homesite.Accounts
  alias Homesite.Accounts.Scope

  alias Homesite.Moderation.{
    ModerationActionLog,
    ModerationSetting,
    ReasonPreset,
    UserBan,
    UserBanner,
    UserMute,
    UserReport,
    UserSuspension,
    UserViolation
  }

  alias Homesite.Repo

  ## User Mutes (User-Initiated)

  @doc """
  Returns all users muted by the current user.

  ## Examples

      iex> list_muted_users(scope)
      [%UserMute{}, ...]

  """
  def list_muted_users(%Scope{} = scope) do
    from(m in UserMute,
      where: m.user_id == ^scope.user.id,
      order_by: [desc: m.inserted_at],
      preload: [:muted_user]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of user IDs that the current user has muted.
  """
  def muted_user_ids(%Scope{} = scope) do
    from(m in UserMute,
      where: m.user_id == ^scope.user.id,
      select: m.muted_user_id
    )
    |> Repo.all()
  end

  @doc """
  Checks if the current user has muted another user.

  ## Examples

      iex> muted?(scope, other_user_id)
      true

  """
  def muted?(%Scope{} = scope, other_user_id) do
    from(m in UserMute,
      where: m.user_id == ^scope.user.id and m.muted_user_id == ^other_user_id
    )
    |> Repo.exists?()
  end

  @doc """
  Mutes another user.

  Users can mute others to hide their content globally (posts, chat, etc.).
  Creates a moderation log entry.

  ## Options

    * `:reason` - Personal note for why you're muting (optional)

  ## Examples

      iex> mute_user(scope, other_user_id)
      {:ok, %UserMute{}}

      iex> mute_user(scope, scope.user.id)
      {:error, %Ecto.Changeset{}}

  """
  def mute_user(%Scope{} = scope, muted_user_id, opts \\ []) do
    reason = Keyword.get(opts, :reason)

    attrs = %{
      "user_id" => scope.user.id,
      "muted_user_id" => muted_user_id,
      "reason" => reason
    }

    case %UserMute{} |> UserMute.changeset(attrs) |> Repo.insert() do
      {:ok, mute} ->
        log_action(scope, muted_user_id, "mute_user", reason, nil, %{})
        {:ok, Repo.preload(mute, [:muted_user])}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Unmutes another user.

  Creates a moderation log entry.

  ## Examples

      iex> unmute_user(scope, other_user_id)
      {:ok, %UserMute{}}

      iex> unmute_user(scope, non_muted_user_id)
      {:error, :not_found}

  """
  def unmute_user(%Scope{} = scope, muted_user_id) do
    case Repo.get_by(UserMute, user_id: scope.user.id, muted_user_id: muted_user_id) do
      nil ->
        {:error, :not_found}

      mute ->
        case Repo.delete(mute) do
          {:ok, deleted_mute} ->
            log_action(scope, muted_user_id, "unmute_user", nil, nil, %{})
            {:ok, deleted_mute}

          error ->
            error
        end
    end
  end

  ## User Reports (User-Initiated)

  @doc """
  Creates a report for another user.

  Rate limited to 5 reports per hour per user to prevent abuse.
  Returns `{:error, :rate_limited}` if user exceeds the limit.
  Creates a moderation log entry on success.

  ## Examples

      iex> create_report(scope, reported_user_id, "This user is spamming")
      {:ok, %UserReport{}}

      iex> create_report(scope, reported_user_id, "spam")  # after 5 reports/hour
      {:error, :rate_limited}

  """
  def create_report(%Scope{} = scope, reported_user_id, reason, metadata \\ %{}) do
    # Rate limiting: 5 reports per hour per user
    case Homesite.RateLimiter.check_rate(:report, to_string(scope.user.id)) do
      {:allow, _count} ->
        do_create_report(scope, reported_user_id, reason, metadata)

      {:deny, _retry_after} ->
        {:error, :rate_limited}
    end
  end

  defp do_create_report(scope, reported_user_id, reason, metadata) do
    attrs = %{
      "reporter_id" => scope.user.id,
      "reported_user_id" => reported_user_id,
      "reason" => reason,
      "status" => "pending",
      "metadata" => metadata
    }

    case %UserReport{} |> UserReport.changeset(attrs) |> Repo.insert() do
      {:ok, report} ->
        log_action(scope, reported_user_id, "report_user", reason, nil, metadata)
        {:ok, Repo.preload(report, [:reporter, :reported_user])}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Returns all pending reports.

  ## Examples

      iex> list_pending_reports()
      [%UserReport{}, ...]

  """
  def list_pending_reports do
    from(r in UserReport,
      where: r.status == "pending",
      order_by: [asc: r.inserted_at],
      preload: [:reporter, :reported_user]
    )
    |> Repo.all()
  end

  @doc """
  Returns all reports with optional filtering.

  ## Options

    * `:status` - Filter by status (pending, reviewing, resolved, dismissed)
    * `:limit` - Maximum number to return (default: 50)

  """
  def list_reports(opts \\ []) do
    status = Keyword.get(opts, :status)
    limit = Keyword.get(opts, :limit, 50)

    query =
      from(r in UserReport,
        order_by: [desc: r.inserted_at],
        limit: ^limit,
        preload: [:reporter, :reported_user, :resolved_by]
      )

    query =
      if status do
        from(r in query, where: r.status == ^status)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Returns reports made against a specific user.
  """
  def list_reports_for_user(user_id) do
    from(r in UserReport,
      where: r.reported_user_id == ^user_id,
      order_by: [desc: r.inserted_at],
      preload: [:reporter, :reported_user, :resolved_by]
    )
    |> Repo.all()
  end

  @doc """
  Counts pending reports.
  """
  def count_pending_reports do
    from(r in UserReport, where: r.status == "pending")
    |> Repo.aggregate(:count)
  end

  @doc """
  Gets a single report.

  Raises `Ecto.NoResultsError` if the report does not exist.
  """
  def get_report!(id) do
    UserReport
    |> Repo.get!(id)
    |> Repo.preload([:reporter, :reported_user, :resolved_by])
  end

  @doc """
  Resolves a report.

  Requires admin scope. Creates a moderation log entry.

  ## Examples

      iex> resolve_report(admin_scope, report_id, "Warned the user")
      {:ok, %UserReport{}}

  """
  def resolve_report(%Scope{} = scope, report_id, resolution_notes) do
    # Require admin
    true = Accounts.Scope.admin?(scope)

    report = Repo.get!(UserReport, report_id)

    attrs = %{
      "status" => "resolved",
      "resolved_at" => DateTime.utc_now(:second),
      "resolved_by_user_id" => scope.user.id,
      "resolution_notes" => resolution_notes
    }

    case report |> UserReport.resolution_changeset(attrs) |> Repo.update() do
      {:ok, updated_report} ->
        log_action(scope, report.reported_user_id, "report_resolve", resolution_notes, nil, %{
          report_id: report_id
        })

        {:ok, Repo.preload(updated_report, [:reporter, :reported_user, :resolved_by])}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Dismisses a report.

  Requires admin scope. Creates a moderation log entry.

  ## Examples

      iex> dismiss_report(admin_scope, report_id, "No violation found")
      {:ok, %UserReport{}}

  """
  def dismiss_report(%Scope{} = scope, report_id, reason) do
    # Require admin
    true = Accounts.Scope.admin?(scope)

    report = Repo.get!(UserReport, report_id)

    attrs = %{
      "status" => "dismissed",
      "resolved_at" => DateTime.utc_now(:second),
      "resolved_by_user_id" => scope.user.id,
      "resolution_notes" => reason
    }

    case report |> UserReport.resolution_changeset(attrs) |> Repo.update() do
      {:ok, updated_report} ->
        log_action(scope, report.reported_user_id, "report_dismiss", reason, nil, %{
          report_id: report_id
        })

        {:ok, Repo.preload(updated_report, [:reporter, :reported_user, :resolved_by])}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  ## User Banners (Admin)

  @doc """
  Returns all active banners for a user.

  Active banners are not dismissed and not expired.

  ## Examples

      iex> list_active_banners(user_id)
      [%UserBanner{}, ...]

  """
  def list_active_banners(user_id) do
    now = DateTime.utc_now()

    from(b in UserBanner,
      where: b.user_id == ^user_id,
      where: is_nil(b.dismissed_at),
      where: is_nil(b.auto_dismiss_after) or b.auto_dismiss_after > ^now,
      order_by: [desc: b.inserted_at],
      preload: [:created_by]
    )
    |> Repo.all()
  end

  @doc """
  Returns all banners (for admin view).

  ## Options

    * `:limit` - Maximum number to return (default: 50)
    * `:user_id` - Filter by target user

  """
  def list_banners(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    user_id = Keyword.get(opts, :user_id)

    query =
      from(b in UserBanner,
        order_by: [desc: b.inserted_at],
        limit: ^limit,
        preload: [:user, :created_by]
      )

    query =
      if user_id do
        from(b in query, where: b.user_id == ^user_id)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Creates a warning banner for a user.

  Requires admin scope. Creates a moderation log entry.

  ## Options

    * `:severity` - Banner severity: "info", "warning", "error" (default: "warning")
    * `:auto_dismiss_after` - Auto-dismiss datetime (optional)

  ## Examples

      iex> create_banner(admin_scope, user_id, "Please follow the rules", severity: "warning")
      {:ok, %UserBanner{}}

  """
  def create_banner(%Scope{} = scope, user_id, message, opts \\ []) do
    # Require admin
    true = Accounts.Scope.admin?(scope)

    severity = Keyword.get(opts, :severity, "warning")
    auto_dismiss_after = Keyword.get(opts, :auto_dismiss_after)

    attrs = %{
      "user_id" => user_id,
      "created_by_user_id" => scope.user.id,
      "message" => message,
      "severity" => severity,
      "auto_dismiss_after" => auto_dismiss_after
    }

    case %UserBanner{} |> UserBanner.changeset(attrs) |> Repo.insert() do
      {:ok, banner} ->
        log_action(scope, user_id, "banner_create", message, auto_dismiss_after, %{
          severity: severity
        })

        {:ok, Repo.preload(banner, [:user, :created_by])}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Dismisses a banner (user action).

  ## Examples

      iex> dismiss_banner(user_id, banner_id)
      {:ok, %UserBanner{}}

  """
  def dismiss_banner(user_id, banner_id) do
    case Repo.get_by(UserBanner, id: banner_id, user_id: user_id) do
      nil ->
        {:error, :not_found}

      banner ->
        banner
        |> Ecto.Changeset.change(dismissed_at: DateTime.utc_now(:second))
        |> Repo.update()
    end
  end

  @doc """
  Deletes a banner (admin action).

  Requires admin scope.
  """
  def delete_banner(%Scope{} = scope, banner_id) do
    # Require admin
    true = Accounts.Scope.admin?(scope)

    case Repo.get(UserBanner, banner_id) do
      nil ->
        {:error, :not_found}

      banner ->
        log_action(scope, banner.user_id, "banner_dismiss", nil, nil, %{banner_id: banner_id})
        Repo.delete(banner)
    end
  end

  ## User Suspensions (Admin)

  @doc """
  Returns all active suspensions.

  ## Examples

      iex> list_active_suspensions()
      [%UserSuspension{}, ...]

  """
  def list_active_suspensions do
    now = DateTime.utc_now()

    from(s in UserSuspension,
      where: is_nil(s.lifted_at),
      where: s.expires_at > ^now,
      order_by: [desc: s.inserted_at],
      preload: [:user, :suspended_by]
    )
    |> Repo.all()
  end

  @doc """
  Returns all suspensions (for admin view).

  ## Options

    * `:limit` - Maximum number to return (default: 50)
    * `:active_only` - Only show active suspensions (default: false)

  """
  def list_suspensions(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    active_only = Keyword.get(opts, :active_only, false)

    query =
      from(s in UserSuspension,
        order_by: [desc: s.inserted_at],
        limit: ^limit,
        preload: [:user, :suspended_by, :lifted_by]
      )

    query =
      if active_only do
        now = DateTime.utc_now()
        from(s in query, where: is_nil(s.lifted_at), where: s.expires_at > ^now)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Gets an active suspension for a user.

  Returns nil if user is not suspended or suspension has expired.
  """
  def get_active_suspension(user_id) do
    now = DateTime.utc_now()

    from(s in UserSuspension,
      where: s.user_id == ^user_id,
      where: is_nil(s.lifted_at),
      where: s.expires_at > ^now,
      preload: [:suspended_by]
    )
    |> Repo.one()
  end

  @doc """
  Checks if a user is currently suspended.

  ## Examples

      iex> suspended?(user_id)
      true

  """
  def suspended?(user_id) do
    get_active_suspension(user_id) != nil
  end

  @doc """
  Suspends a user temporarily.

  Requires admin scope. Creates a moderation log entry.
  Replaces any existing suspension.

  ## Examples

      iex> suspend_user(admin_scope, user_id, "Violation of rules", ~U[2025-01-15 00:00:00Z])
      {:ok, %UserSuspension{}}

  """
  def suspend_user(%Scope{} = scope, user_id, reason, expires_at) do
    # Require admin
    true = Accounts.Scope.admin?(scope)

    attrs = %{
      "user_id" => user_id,
      "suspended_by_user_id" => scope.user.id,
      "reason" => reason,
      "expires_at" => expires_at
    }

    Repo.transaction(fn ->
      # Remove existing suspension if present
      from(s in UserSuspension, where: s.user_id == ^user_id)
      |> Repo.delete_all()

      case %UserSuspension{} |> UserSuspension.changeset(attrs) |> Repo.insert() do
        {:ok, suspension} ->
          log_action(scope, user_id, "suspend", reason, expires_at, %{})
          Repo.preload(suspension, [:user, :suspended_by])

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Lifts a suspension early.

  Requires admin scope. Creates a moderation log entry.

  ## Examples

      iex> unsuspend_user(admin_scope, user_id)
      {:ok, %UserSuspension{}}

  """
  def unsuspend_user(%Scope{} = scope, user_id) do
    # Require admin
    true = Accounts.Scope.admin?(scope)

    case get_active_suspension(user_id) do
      nil ->
        {:error, :not_found}

      suspension ->
        attrs = %{
          "lifted_at" => DateTime.utc_now(:second),
          "lifted_by_user_id" => scope.user.id
        }

        case suspension |> UserSuspension.lift_changeset(attrs) |> Repo.update() do
          {:ok, updated_suspension} ->
            log_action(scope, user_id, "unsuspend", nil, nil, %{})
            {:ok, Repo.preload(updated_suspension, [:user, :suspended_by, :lifted_by])}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  ## User Bans (Admin)

  @doc """
  Returns all active bans.

  ## Examples

      iex> list_active_bans()
      [%UserBan{}, ...]

  """
  def list_active_bans do
    from(b in UserBan,
      where: is_nil(b.lifted_at),
      order_by: [desc: b.inserted_at],
      preload: [:user, :banned_by]
    )
    |> Repo.all()
  end

  @doc """
  Returns all bans (for admin view).

  ## Options

    * `:limit` - Maximum number to return (default: 50)
    * `:active_only` - Only show active bans (default: false)

  """
  def list_bans(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    active_only = Keyword.get(opts, :active_only, false)

    query =
      from(b in UserBan,
        order_by: [desc: b.inserted_at],
        limit: ^limit,
        preload: [:user, :banned_by, :lifted_by]
      )

    query =
      if active_only do
        from(b in query, where: is_nil(b.lifted_at))
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Gets an active ban for a user.

  Returns nil if user is not banned or ban has been lifted.
  """
  def get_active_ban(user_id) do
    from(b in UserBan,
      where: b.user_id == ^user_id,
      where: is_nil(b.lifted_at),
      preload: [:banned_by]
    )
    |> Repo.one()
  end

  @doc """
  Checks if a user is currently banned.

  ## Examples

      iex> banned?(user_id)
      true

  """
  def banned?(user_id) do
    get_active_ban(user_id) != nil
  end

  @doc """
  Bans a user permanently.

  Requires admin scope. Creates a moderation log entry.
  Removes any existing ban or suspension first.

  ## Examples

      iex> ban_user(admin_scope, user_id, "Severe violation")
      {:ok, %UserBan{}}

  """
  def ban_user(%Scope{} = scope, user_id, reason) do
    # Require admin
    true = Accounts.Scope.admin?(scope)

    attrs = %{
      "user_id" => user_id,
      "banned_by_user_id" => scope.user.id,
      "reason" => reason
    }

    Repo.transaction(fn ->
      # Remove any existing ban/suspension first
      from(b in UserBan, where: b.user_id == ^user_id) |> Repo.delete_all()
      from(s in UserSuspension, where: s.user_id == ^user_id) |> Repo.delete_all()

      case %UserBan{} |> UserBan.changeset(attrs) |> Repo.insert() do
        {:ok, ban} ->
          log_action(scope, user_id, "ban", reason, nil, %{})
          Repo.preload(ban, [:user, :banned_by])

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Lifts a ban (rare).

  Requires admin scope. Creates a moderation log entry.

  ## Examples

      iex> unban_user(admin_scope, user_id)
      {:ok, %UserBan{}}

  """
  def unban_user(%Scope{} = scope, user_id) do
    # Require admin
    true = Accounts.Scope.admin?(scope)

    case get_active_ban(user_id) do
      nil ->
        {:error, :not_found}

      ban ->
        attrs = %{
          "lifted_at" => DateTime.utc_now(:second),
          "lifted_by_user_id" => scope.user.id
        }

        case ban |> UserBan.lift_changeset(attrs) |> Repo.update() do
          {:ok, updated_ban} ->
            log_action(scope, user_id, "unban", nil, nil, %{})
            {:ok, Repo.preload(updated_ban, [:user, :banned_by, :lifted_by])}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  ## Moderation Logs

  @doc """
  Returns moderation log entries.

  ## Options

    * `:limit` - Maximum number of entries (default: 50)
    * `:action` - Filter by action type
    * `:moderator_id` - Filter by moderator
    * `:target_user_id` - Filter by target user

  """
  def list_moderation_logs(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    action = Keyword.get(opts, :action)
    moderator_id = Keyword.get(opts, :moderator_id)
    target_user_id = Keyword.get(opts, :target_user_id)

    query =
      from(l in ModerationActionLog,
        order_by: [desc: l.inserted_at],
        limit: ^limit,
        preload: [:moderator, :target_user]
      )

    query = if action, do: from(l in query, where: l.action == ^action), else: query

    query =
      if moderator_id, do: from(l in query, where: l.moderator_id == ^moderator_id), else: query

    query =
      if target_user_id,
        do: from(l in query, where: l.target_user_id == ^target_user_id),
        else: query

    Repo.all(query)
  end

  @doc """
  Returns moderation history for a specific user.
  """
  def list_user_moderation_history(user_id, opts \\ []) do
    list_moderation_logs(Keyword.put(opts, :target_user_id, user_id))
  end

  ## Utilities

  @doc """
  Checks if a user can log in (not suspended or banned).

  Returns `:ok` or `{:error, reason}`.

  ## Examples

      iex> can_login?(user_id)
      :ok

      iex> can_login?(banned_user_id)
      {:error, :banned}

      iex> can_login?(suspended_user_id)
      {:error, :suspended, ~U[2025-01-15 00:00:00Z]}

  """
  def can_login?(user_id) do
    cond do
      banned?(user_id) ->
        {:error, :banned}

      suspension = get_active_suspension(user_id) ->
        {:error, :suspended, suspension.expires_at}

      true ->
        :ok
    end
  end

  @doc """
  Filters a list of items to exclude muted users' content.

  Items must have a `user_id` field.

  ## Examples

      iex> filter_muted_content(scope, posts)
      [%Post{}, ...]

  """
  def filter_muted_content(%Scope{} = scope, list) when is_list(list) do
    muted_ids = muted_user_ids(scope)
    Enum.reject(list, fn item -> item.user_id in muted_ids end)
  end

  @doc """
  Returns a query with muted users filtered out.

  The query's schema must have a `user_id` field.

  ## Examples

      iex> filter_muted_content_query(scope, Post)
      #Ecto.Query<...>

  """
  def filter_muted_content_query(%Scope{} = scope, queryable) do
    muted_ids = muted_user_ids(scope)
    from(q in queryable, where: q.user_id not in ^muted_ids)
  end

  ## Admin stats

  @doc """
  Returns moderation statistics for the admin dashboard.
  """
  def get_moderation_stats do
    %{
      pending_reports: count_pending_reports(),
      active_suspensions:
        Repo.aggregate(
          from(s in UserSuspension,
            where: is_nil(s.lifted_at) and s.expires_at > ^DateTime.utc_now()
          ),
          :count
        ),
      active_bans: Repo.aggregate(from(b in UserBan, where: is_nil(b.lifted_at)), :count),
      total_mutes: Repo.aggregate(UserMute, :count)
    }
  end

  ## Violation Tracking

  @doc """
  Records a violation against a user with appropriate weight.
  Admin actions automatically get 2x weight based on settings.

  ## Examples

      iex> record_violation(%{user_id: 1, action_type: "report", reason_text: "spam"}, reporter)
      {:ok, %UserViolation{}}

  """
  def record_violation(attrs, reporter \\ nil) do
    weight = calculate_violation_weight(reporter)

    attrs =
      attrs
      |> Map.put(:weight, weight)
      |> Map.put(:reporter_id, reporter && reporter.id)

    case %UserViolation{} |> UserViolation.changeset(attrs) |> Repo.insert() do
      {:ok, violation} ->
        check_alert_threshold(violation)
        {:ok, violation}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp calculate_violation_weight(nil), do: 1

  defp calculate_violation_weight(reporter) do
    if reporter.role == "admin" do
      get_admin_weight_multiplier()
    else
      1
    end
  end

  @doc """
  Gets the admin weight multiplier from settings (default: 2).
  """
  def get_admin_weight_multiplier do
    case get_setting("admin_multiplier") do
      %{value: %{"weight" => weight}} -> weight
      _ -> 2
    end
  end

  @doc """
  Gets the admin duration multiplier from settings (default: 2).
  """
  def get_admin_duration_multiplier do
    case get_setting("admin_multiplier") do
      %{value: %{"duration" => duration}} -> duration
      _ -> 2
    end
  end

  @doc """
  Calculates duration for mute/suspension with admin multiplier applied.
  """
  def calculate_duration(base_minutes, acting_user) do
    multiplier =
      if acting_user && acting_user.role == "admin" do
        get_admin_duration_multiplier()
      else
        1
      end

    base_minutes * multiplier
  end

  @doc """
  Checks if user has exceeded alert threshold and broadcasts alert if so.
  """
  def check_alert_threshold(%UserViolation{user_id: user_id}) do
    threshold = get_alert_threshold()
    window_start = DateTime.add(DateTime.utc_now(), -threshold.window_hours, :hour)

    query =
      from(v in UserViolation,
        where: v.user_id == ^user_id,
        where: is_nil(v.resolved_at),
        where: v.inserted_at >= ^window_start,
        select: %{
          total_weight: coalesce(sum(v.weight), 0),
          unique_reporters: count(v.reporter_id, :distinct)
        }
      )

    case Repo.one(query) do
      %{total_weight: weight, unique_reporters: reporters}
      when weight >= threshold.count and reporters >= 2 ->
        broadcast_violation_alert(user_id, weight, reporters)

      _ ->
        :ok
    end
  end

  defp get_alert_threshold do
    case get_setting("alert_threshold") do
      %{value: %{"count" => count, "window_hours" => hours}} ->
        %{count: count, window_hours: hours}

      _ ->
        %{count: 3, window_hours: 24}
    end
  end

  defp broadcast_violation_alert(user_id, weight, reporter_count) do
    Phoenix.PubSub.broadcast(
      Homesite.PubSub,
      "moderation:alerts",
      {:violation_threshold_reached,
       %{
         user_id: user_id,
         total_weight: weight,
         unique_reporters: reporter_count,
         timestamp: DateTime.utc_now()
       }}
    )
  end

  @doc """
  Lists violations for a user with optional filters.

  ## Options

    * `:unresolved_only` - Only return unresolved violations (default: false)
    * `:limit` - Maximum number to return (default: 50)

  """
  def list_user_violations(user_id, opts \\ []) do
    unresolved_only = Keyword.get(opts, :unresolved_only, false)
    limit = Keyword.get(opts, :limit, 50)

    query =
      from(v in UserViolation,
        where: v.user_id == ^user_id,
        preload: [:reporter, :resolved_by],
        order_by: [desc: v.inserted_at],
        limit: ^limit
      )

    query =
      if unresolved_only do
        from(v in query, where: is_nil(v.resolved_at))
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Gets violation statistics for a user.

  Returns a map with:
    * `:by_type` - Map of action_type => count
    * `:total_unresolved_weight` - Sum of weights for unresolved violations
    * `:total_count` - Total violation count

  """
  def get_user_violation_stats(user_id) do
    by_type_query =
      from(v in UserViolation,
        where: v.user_id == ^user_id,
        group_by: v.action_type,
        select: {v.action_type, count(v.id)}
      )

    stats = Repo.all(by_type_query) |> Enum.into(%{})

    total_weight =
      from(v in UserViolation,
        where: v.user_id == ^user_id,
        where: is_nil(v.resolved_at),
        select: coalesce(sum(v.weight), 0)
      )
      |> Repo.one() || 0

    %{
      by_type: stats,
      total_unresolved_weight: total_weight,
      total_count: Enum.reduce(stats, 0, fn {_, count}, acc -> acc + count end)
    }
  end

  @doc """
  Lists users with unresolved violations, sorted by total weight.

  ## Options

    * `:limit` - Maximum number of users to return (default: 50)

  """
  def list_users_with_violations(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    query =
      from(v in UserViolation,
        where: is_nil(v.resolved_at),
        group_by: v.user_id,
        select: %{
          user_id: v.user_id,
          total_weight: sum(v.weight),
          violation_count: count(v.id)
        },
        order_by: [desc: sum(v.weight)],
        limit: ^limit
      )

    results = Repo.all(query)

    # Preload user data
    user_ids = Enum.map(results, & &1.user_id)
    users = from(u in Accounts.User, where: u.id in ^user_ids) |> Repo.all()
    users_map = Map.new(users, &{&1.id, &1})

    Enum.map(results, fn result ->
      Map.put(result, :user, Map.get(users_map, result.user_id))
    end)
  end

  @doc """
  Resolves all violations for a user.

  ## Examples

      iex> resolve_all_violations(user_id, admin_id)
      {count, nil}

  """
  def resolve_all_violations(user_id, resolver_id) do
    from(v in UserViolation,
      where: v.user_id == ^user_id and is_nil(v.resolved_at)
    )
    |> Repo.update_all(
      set: [
        resolved_at: DateTime.utc_now(:second),
        resolved_by_id: resolver_id
      ]
    )
  end

  @doc """
  Creates a user report with tracking.
  Also records a violation for threshold tracking.

  ## Examples

      iex> create_report_with_tracking(attrs, reporter)
      {:ok, %UserReport{}}

  """
  def create_report_with_tracking(%Scope{} = scope, reported_user_id, reason, metadata \\ %{}) do
    # Rate limiting: 5 reports per hour per user
    case Homesite.RateLimiter.check_rate(:report, to_string(scope.user.id)) do
      {:allow, _count} ->
        do_create_report_with_tracking(scope, reported_user_id, reason, metadata)

      {:deny, _retry_after} ->
        {:error, :rate_limited}
    end
  end

  defp do_create_report_with_tracking(scope, reported_user_id, reason, metadata) do
    attrs = %{
      "reporter_id" => scope.user.id,
      "reported_user_id" => reported_user_id,
      "reason" => reason,
      "status" => "pending",
      "metadata" => metadata,
      "content_type" => metadata[:content_type] || metadata["content_type"],
      "content_id" => metadata[:content_id] || metadata["content_id"]
    }

    Repo.transaction(fn ->
      case %UserReport{} |> UserReport.changeset(attrs) |> Repo.insert() do
        {:ok, report} ->
          log_action(scope, reported_user_id, "report_user", reason, nil, metadata)

          # Record violation for threshold tracking
          record_violation(
            %{
              user_id: reported_user_id,
              action_type: "report",
              reason_category: metadata[:reason_category] || metadata["reason_category"],
              reason_text: reason,
              source: determine_source(metadata),
              content_type: metadata[:content_type] || metadata["content_type"],
              content_id: metadata[:content_id] || metadata["content_id"]
            },
            scope.user
          )

          Repo.preload(report, [:reporter, :reported_user])

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  defp determine_source(metadata) do
    content_type = metadata[:content_type] || metadata["content_type"]

    cond do
      content_type == "chat_message" -> "chat"
      content_type in ["post", "comment"] -> "content"
      true -> "admin_panel"
    end
  end

  ## Moderation Settings

  @doc """
  Gets a setting by key.

  ## Examples

      iex> get_setting("alert_threshold")
      %ModerationSetting{key: "alert_threshold", value: %{"count" => 3, "window_hours" => 24}}

  """
  def get_setting(key) do
    Repo.get_by(ModerationSetting, key: key)
  end

  @doc """
  Updates a setting.

  Requires admin scope.

  ## Examples

      iex> update_setting("alert_threshold", %{"count" => 5}, admin_user)
      {:ok, %ModerationSetting{}}

  """
  def update_setting(key, value, %Scope{} = scope) do
    true = Accounts.Scope.admin?(scope)

    case get_setting(key) do
      nil ->
        {:error, :not_found}

      setting ->
        setting
        |> ModerationSetting.changeset(%{value: value, updated_by_id: scope.user.id})
        |> Repo.update()
    end
  end

  @doc """
  Lists all moderation settings.
  """
  def list_settings do
    Repo.all(ModerationSetting)
  end

  ## Reason Presets

  @doc """
  Lists reason presets for a category.

  ## Examples

      iex> list_reason_presets("report")
      [%ReasonPreset{}, ...]

  """
  def list_reason_presets(category) when category in ["report", "mute", "suspend", "ban"] do
    from(p in ReasonPreset,
      where: p.category == ^category and p.is_active == true,
      order_by: p.display_order
    )
    |> Repo.all()
  end

  @doc """
  Gets a reason preset by ID.

  Raises `Ecto.NoResultsError` if not found.
  """
  def get_reason_preset!(id), do: Repo.get!(ReasonPreset, id)

  @doc """
  Gets a reason preset by ID, returns nil if not found.
  """
  def get_reason_preset(id), do: Repo.get(ReasonPreset, id)

  @doc """
  Creates a reason preset.

  Requires admin scope.
  """
  def create_reason_preset(%Scope{} = scope, attrs) do
    true = Accounts.Scope.admin?(scope)

    %ReasonPreset{}
    |> ReasonPreset.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a reason preset.

  Requires admin scope.
  """
  def update_reason_preset(%Scope{} = scope, %ReasonPreset{} = preset, attrs) do
    true = Accounts.Scope.admin?(scope)

    preset
    |> ReasonPreset.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a reason preset.

  Requires admin scope.
  """
  def delete_reason_preset(%Scope{} = scope, %ReasonPreset{} = preset) do
    true = Accounts.Scope.admin?(scope)
    Repo.delete(preset)
  end

  ## Private helpers

  defp log_action(scope, target_user_id, action, reason, expires_at, metadata) do
    moderator_id = if scope.user, do: scope.user.id, else: nil

    %ModerationActionLog{}
    |> ModerationActionLog.changeset(%{
      "moderator_id" => moderator_id,
      "target_user_id" => target_user_id,
      "action" => action,
      "reason" => reason,
      "expires_at" => expires_at,
      "metadata" => metadata
    })
    |> Repo.insert!()
  end
end
