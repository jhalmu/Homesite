defmodule Homesite.Analytics do
  @moduledoc """
  The Analytics context for tracking search queries and activity logs.
  """

  import Ecto.Query, warn: false
  alias Homesite.Analytics.{ActivityLog, Geo, SearchQuery}
  alias Homesite.Repo

  ## Search Analytics

  @doc """
  Records a search query with results and performance metrics.
  """
  def record_search(query, results, duration_ms, opts \\ []) do
    ip = Keyword.get(opts, :ip_address)
    geo = Geo.lookup(ip)

    attrs = %{
      query: query,
      result_count: results.total_count,
      posts_count: length(results.posts),
      tags_count: length(results.tags),
      faqs_count: length(results.faqs),
      duration_ms: duration_ms,
      user_id: Keyword.get(opts, :user_id),
      ip_address: ip,
      user_agent: Keyword.get(opts, :user_agent),
      country: geo.country,
      city: geo.city
    }

    %SearchQuery{}
    |> SearchQuery.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns popular search queries within a time period.
  """
  def popular_searches(opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)
    days = Keyword.get(opts, :days, 7)
    cutoff = DateTime.add(DateTime.utc_now(), -days, :day)

    from(s in SearchQuery,
      where: s.inserted_at >= ^cutoff,
      group_by: s.query,
      select: %{
        query: s.query,
        count: count(s.id),
        avg_results: avg(s.result_count),
        avg_duration: avg(s.duration_ms)
      },
      order_by: [desc: count(s.id)],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Returns searches with no results (to identify gaps in content).
  """
  def no_result_searches(opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)
    days = Keyword.get(opts, :days, 7)
    cutoff = DateTime.add(DateTime.utc_now(), -days, :day)

    from(s in SearchQuery,
      where: s.inserted_at >= ^cutoff and s.result_count == 0,
      group_by: s.query,
      select: %{
        query: s.query,
        count: count(s.id)
      },
      order_by: [desc: count(s.id)],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Returns search performance metrics.
  """
  def search_performance_stats(days \\ 7) do
    cutoff = DateTime.add(DateTime.utc_now(), -days, :day)

    from(s in SearchQuery,
      where: s.inserted_at >= ^cutoff,
      select: %{
        total_searches: count(s.id),
        avg_duration_ms: avg(s.duration_ms),
        avg_results: avg(s.result_count),
        zero_results_pct:
          fragment(
            "ROUND(100.0 * SUM(CASE WHEN ? = 0 THEN 1 ELSE 0 END) / COUNT(*), 2)",
            s.result_count
          )
      }
    )
    |> Repo.one()
  end

  ## Activity Logs / Audit Trail

  @doc """
  Logs an activity/action performed by a user.
  """
  def log_activity(action, resource_type, opts \\ []) do
    ip = Keyword.get(opts, :ip_address)

    # Allow manual country/city override (for tests), otherwise use geo lookup
    {country, city} =
      case {Keyword.get(opts, :country), Keyword.get(opts, :city)} do
        {nil, nil} ->
          geo = Geo.lookup(ip)
          {geo.country, geo.city}

        {country, city} ->
          {country, city}
      end

    attrs = %{
      user_id: Keyword.fetch!(opts, :user_id),
      action: to_string(action),
      resource_type: to_string(resource_type),
      resource_id: Keyword.get(opts, :resource_id),
      changes: Keyword.get(opts, :changes, %{}),
      ip_address: ip,
      user_agent: Keyword.get(opts, :user_agent),
      country: country,
      city: city,
      metadata: Keyword.get(opts, :metadata, %{})
    }

    %ActivityLog{}
    |> ActivityLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Lists recent activity logs with optional filtering.
  """
  def list_activity_logs(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    user_id = Keyword.get(opts, :user_id)
    resource_type = Keyword.get(opts, :resource_type)
    action = Keyword.get(opts, :action)

    query =
      from(a in ActivityLog,
        order_by: [desc: a.inserted_at],
        limit: ^limit,
        preload: [:user]
      )

    query =
      if user_id do
        from(a in query, where: a.user_id == ^user_id)
      else
        query
      end

    query =
      if resource_type do
        from(a in query, where: a.resource_type == ^to_string(resource_type))
      else
        query
      end

    query =
      if action do
        from(a in query, where: a.action == ^to_string(action))
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Returns activity statistics for a time period.
  """
  def activity_stats(days \\ 7) do
    cutoff = DateTime.add(DateTime.utc_now(), -days, :day)

    from(a in ActivityLog,
      where: a.inserted_at >= ^cutoff,
      group_by: [a.action, a.resource_type],
      select: %{
        action: a.action,
        resource_type: a.resource_type,
        count: count(a.id)
      },
      order_by: [desc: count(a.id)]
    )
    |> Repo.all()
  end

  @doc """
  Returns user activity summary.
  """
  def user_activity_summary(user_id, days \\ 30) do
    cutoff = DateTime.add(DateTime.utc_now(), -days, :day)

    from(a in ActivityLog,
      where: a.user_id == ^user_id and a.inserted_at >= ^cutoff,
      group_by: a.action,
      select: %{
        action: a.action,
        count: count(a.id)
      },
      order_by: [desc: count(a.id)]
    )
    |> Repo.all()
  end

  ## Trend Analytics

  @doc """
  Returns daily activity counts for the specified number of days.
  Returns a list of {date, count} tuples for charting.
  """
  def activity_trend(days \\ 30) do
    cutoff = DateTime.add(DateTime.utc_now(), -days, :day)

    from(a in ActivityLog,
      where: a.inserted_at >= ^cutoff,
      group_by: fragment("DATE(?)", a.inserted_at),
      select: %{
        date: fragment("DATE(?)", a.inserted_at),
        count: count(a.id)
      },
      order_by: [asc: fragment("DATE(?)", a.inserted_at)]
    )
    |> Repo.all()
  end

  @doc """
  Returns activity counts grouped by action type.
  """
  def activity_by_action(days \\ 30) do
    cutoff = DateTime.add(DateTime.utc_now(), -days, :day)

    from(a in ActivityLog,
      where: a.inserted_at >= ^cutoff,
      group_by: a.action,
      select: %{
        action: a.action,
        count: count(a.id)
      },
      order_by: [desc: count(a.id)]
    )
    |> Repo.all()
  end

  @doc """
  Returns daily search counts for the specified number of days.
  """
  def search_trend(days \\ 30) do
    cutoff = DateTime.add(DateTime.utc_now(), -days, :day)

    from(s in SearchQuery,
      where: s.inserted_at >= ^cutoff,
      group_by: fragment("DATE(?)", s.inserted_at),
      select: %{
        date: fragment("DATE(?)", s.inserted_at),
        count: count(s.id),
        avg_duration: avg(s.duration_ms)
      },
      order_by: [asc: fragment("DATE(?)", s.inserted_at)]
    )
    |> Repo.all()
  end

  ## Geo Analytics

  @doc """
  Returns visitor statistics by country.
  """
  def visitors_by_country(days \\ 7, limit \\ 10) do
    cutoff = DateTime.add(DateTime.utc_now(), -days, :day)

    from(a in ActivityLog,
      where: a.inserted_at >= ^cutoff and not is_nil(a.country),
      group_by: a.country,
      select: %{
        country: a.country,
        count: count(a.id),
        unique_users: count(a.user_id, :distinct)
      },
      order_by: [desc: count(a.id)],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Returns visitor statistics by city.
  """
  def visitors_by_city(days \\ 7, limit \\ 10) do
    cutoff = DateTime.add(DateTime.utc_now(), -days, :day)

    from(a in ActivityLog,
      where: a.inserted_at >= ^cutoff and not is_nil(a.city),
      group_by: [a.country, a.city],
      select: %{
        country: a.country,
        city: a.city,
        count: count(a.id),
        unique_users: count(a.user_id, :distinct)
      },
      order_by: [desc: count(a.id)],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Returns search statistics by country.
  """
  def searches_by_country(days \\ 7, limit \\ 10) do
    cutoff = DateTime.add(DateTime.utc_now(), -days, :day)

    from(s in SearchQuery,
      where: s.inserted_at >= ^cutoff and not is_nil(s.country),
      group_by: s.country,
      select: %{
        country: s.country,
        count: count(s.id),
        avg_results: avg(s.result_count)
      },
      order_by: [desc: count(s.id)],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Returns geo statistics summary.
  """
  def geo_stats(days \\ 7) do
    cutoff = DateTime.add(DateTime.utc_now(), -days, :day)

    activity_geo =
      from(a in ActivityLog,
        where: a.inserted_at >= ^cutoff,
        select: %{
          total: count(a.id),
          with_country: count(a.country),
          with_city: count(a.city),
          unique_countries: count(a.country, :distinct),
          unique_cities: count(a.city, :distinct)
        }
      )
      |> Repo.one()

    search_geo =
      from(s in SearchQuery,
        where: s.inserted_at >= ^cutoff,
        select: %{
          total: count(s.id),
          with_country: count(s.country),
          with_city: count(s.city)
        }
      )
      |> Repo.one()

    %{
      activity_logs: activity_geo,
      search_queries: search_geo
    }
  end
end
