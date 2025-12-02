defmodule Homesite.ExternalFeeds.Analytics do
  @moduledoc """
  Analytics and metrics for feed consumption tracking.

  Provides functions to analyze feed usage patterns, engagement metrics,
  and consumption trends for a given user scope.
  """

  import Ecto.Query, warn: false

  alias Homesite.Accounts.Scope
  alias Homesite.ExternalFeeds
  alias Homesite.Repo

  @doc """
  Gets comprehensive analytics summary for the user's feed consumption.

  Returns a map with:
  - `total_feeds` - Number of active feed sources
  - `total_items` - Total feed items across all sources
  - `unread_count` - Number of unread items
  - `read_today` - Items read today
  - `read_this_week` - Items read in last 7 days
  - `read_this_month` - Items read in last 30 days
  - `bookmarked_count` - Total bookmarked items
  - `top_sources` - List of top feed sources by engagement
  - `reading_trend` - Daily reading activity (last 30 days)

  ## Examples

      iex> get_analytics_summary(scope)
      %{
        total_feeds: 15,
        total_items: 1234,
        unread_count: 42,
        read_today: 10,
        read_this_week: 75,
        read_this_month: 320,
        bookmarked_count: 28,
        top_sources: [...],
        reading_trend: [...]
      }
  """
  def get_analytics_summary(%Scope{} = scope) do
    %{
      total_feeds: count_active_feeds(scope),
      total_items: count_total_items(scope),
      unread_count: ExternalFeeds.get_unread_count(scope),
      read_today: count_read_in_period(scope, days: 1),
      read_this_week: count_read_in_period(scope, days: 7),
      read_this_month: count_read_in_period(scope, days: 30),
      bookmarked_count: count_bookmarked_items(scope),
      top_sources: get_top_sources(scope, limit: 10),
      reading_trend: get_reading_trend(scope, days: 30)
    }
  end

  @doc """
  Gets top feed sources ranked by engagement (read + bookmarked).

  Returns a list of maps with:
  - `source` - FeedSource struct
  - `total_items` - Total items from this source
  - `read_count` - Number of items read
  - `bookmark_count` - Number of items bookmarked
  - `engagement_score` - Combined metric (read * 1 + bookmark * 3)

  ## Options
    * `:limit` - Maximum number of sources to return (default: 10)

  ## Examples

      iex> get_top_sources(scope, limit: 5)
      [
        %{
          source: %FeedSource{name: "TechCrunch", ...},
          total_items: 120,
          read_count: 85,
          bookmark_count: 12,
          engagement_score: 121
        },
        ...
      ]
  """
  def get_top_sources(%Scope{} = scope, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)

    feed_sources = ExternalFeeds.list_feed_sources(scope)

    feed_sources
    |> Enum.map(fn source ->
      stats = get_source_stats(scope, source.id)

      %{
        source: source,
        total_items: stats.total_items,
        read_count: stats.read_count,
        bookmark_count: stats.bookmark_count,
        engagement_score: calculate_engagement_score(stats)
      }
    end)
    |> Enum.filter(fn source_stats -> source_stats.engagement_score > 0 end)
    |> Enum.sort_by(& &1.engagement_score, :desc)
    |> Enum.take(limit)
  end

  @doc """
  Gets daily reading trend for the specified period.

  Returns a list of maps with:
  - `date` - Date (YYYY-MM-DD)
  - `read_count` - Number of items read on that date
  - `bookmark_count` - Number of items bookmarked on that date

  ## Options
    * `:days` - Number of days to include (default: 30)

  ## Examples

      iex> get_reading_trend(scope, days: 7)
      [
        %{date: "2025-12-02", read_count: 15, bookmark_count: 3},
        %{date: "2025-12-01", read_count: 20, bookmark_count: 5},
        ...
      ]
  """
  def get_reading_trend(%Scope{} = scope, opts \\ []) do
    days = Keyword.get(opts, :days, 30)

    end_date = Date.utc_today()
    start_date = Date.add(end_date, -days)

    # Generate all dates in range
    date_range = Date.range(start_date, end_date) |> Enum.to_list()

    # Get read counts by date
    read_by_date = get_read_counts_by_date(scope, start_date, end_date)
    bookmarks_by_date = get_bookmark_counts_by_date(scope, start_date, end_date)

    # Merge into daily trend
    Enum.map(date_range, fn date ->
      date_str = Date.to_string(date)

      %{
        date: date_str,
        read_count: Map.get(read_by_date, date_str, 0),
        bookmark_count: Map.get(bookmarks_by_date, date_str, 0)
      }
    end)
  end

  @doc """
  Gets feed source performance statistics.

  Returns metrics for a specific feed source including fetch success rate,
  average item count per fetch, and engagement metrics.

  ## Examples

      iex> get_source_performance(scope, feed_source_id)
      %{
        total_items: 145,
        items_per_fetch: 12.5,
        read_rate: 0.68,
        bookmark_rate: 0.15,
        avg_time_to_read_minutes: 1440
      }
  """
  def get_source_performance(%Scope{} = scope, feed_source_id) do
    stats = get_source_stats(scope, feed_source_id)

    read_rate =
      if stats.total_items > 0 do
        stats.read_count / stats.total_items
      else
        0.0
      end

    bookmark_rate =
      if stats.total_items > 0 do
        stats.bookmark_count / stats.total_items
      else
        0.0
      end

    %{
      total_items: stats.total_items,
      read_count: stats.read_count,
      bookmark_count: stats.bookmark_count,
      unread_count: stats.total_items - stats.read_count,
      read_rate: Float.round(read_rate, 2),
      bookmark_rate: Float.round(bookmark_rate, 2)
    }
  end

  # Private helpers

  defp count_active_feeds(%Scope{user: %{id: user_id}}) do
    from(fs in ExternalFeeds.FeedSource,
      where: fs.user_id == ^user_id and fs.enabled == true,
      select: count(fs.id)
    )
    |> Repo.one()
  end

  defp count_total_items(%Scope{user: %{id: user_id}}) do
    from(fi in ExternalFeeds.FeedItem,
      join: fs in ExternalFeeds.FeedSource,
      on: fi.feed_source_id == fs.id,
      where: fs.user_id == ^user_id,
      select: count(fi.id)
    )
    |> Repo.one()
  end

  defp count_read_in_period(%Scope{user: %{id: user_id}}, opts) do
    days = Keyword.get(opts, :days, 1)
    cutoff = DateTime.utc_now() |> DateTime.add(-days, :day)

    from(inter in ExternalFeeds.FeedItemInteraction,
      where: inter.user_id == ^user_id,
      where: not is_nil(inter.read_at),
      where: inter.read_at >= ^cutoff,
      select: count(inter.id)
    )
    |> Repo.one()
  end

  defp count_bookmarked_items(%Scope{user: %{id: user_id}}) do
    from(inter in ExternalFeeds.FeedItemInteraction,
      where: inter.user_id == ^user_id,
      where: not is_nil(inter.bookmarked_at),
      select: count(inter.id)
    )
    |> Repo.one()
  end

  defp get_source_stats(%Scope{user: %{id: user_id}}, feed_source_id) do
    # Get total items for this source
    total_items =
      from(fi in ExternalFeeds.FeedItem,
        where: fi.feed_source_id == ^feed_source_id,
        select: count(fi.id)
      )
      |> Repo.one()

    # Get read count
    read_count =
      from(inter in ExternalFeeds.FeedItemInteraction,
        join: fi in ExternalFeeds.FeedItem,
        on: inter.feed_item_id == fi.id,
        where: inter.user_id == ^user_id,
        where: fi.feed_source_id == ^feed_source_id,
        where: not is_nil(inter.read_at),
        select: count(inter.id)
      )
      |> Repo.one()

    # Get bookmark count
    bookmark_count =
      from(inter in ExternalFeeds.FeedItemInteraction,
        join: fi in ExternalFeeds.FeedItem,
        on: inter.feed_item_id == fi.id,
        where: inter.user_id == ^user_id,
        where: fi.feed_source_id == ^feed_source_id,
        where: not is_nil(inter.bookmarked_at),
        select: count(inter.id)
      )
      |> Repo.one()

    %{
      total_items: total_items,
      read_count: read_count,
      bookmark_count: bookmark_count
    }
  end

  defp calculate_engagement_score(%{read_count: read, bookmark_count: bookmarks}) do
    # Bookmarks weighted 3x higher than reads
    read * 1 + bookmarks * 3
  end

  defp get_read_counts_by_date(%Scope{user: %{id: user_id}}, start_date, end_date) do
    start_datetime = DateTime.new!(start_date, ~T[00:00:00])
    end_datetime = DateTime.new!(end_date, ~T[23:59:59])

    from(inter in ExternalFeeds.FeedItemInteraction,
      where: inter.user_id == ^user_id,
      where: not is_nil(inter.read_at),
      where: inter.read_at >= ^start_datetime,
      where: inter.read_at <= ^end_datetime,
      group_by: fragment("DATE(?)", inter.read_at),
      select: {fragment("DATE(?)", inter.read_at), count(inter.id)}
    )
    |> Repo.all()
    |> Map.new(fn {date, count} ->
      {Date.to_string(date), count}
    end)
  end

  defp get_bookmark_counts_by_date(%Scope{user: %{id: user_id}}, start_date, end_date) do
    start_datetime = DateTime.new!(start_date, ~T[00:00:00])
    end_datetime = DateTime.new!(end_date, ~T[23:59:59])

    from(inter in ExternalFeeds.FeedItemInteraction,
      where: inter.user_id == ^user_id,
      where: not is_nil(inter.bookmarked_at),
      where: inter.bookmarked_at >= ^start_datetime,
      where: inter.bookmarked_at <= ^end_datetime,
      group_by: fragment("DATE(?)", inter.bookmarked_at),
      select: {fragment("DATE(?)", inter.bookmarked_at), count(inter.id)}
    )
    |> Repo.all()
    |> Map.new(fn {date, count} ->
      {Date.to_string(date), count}
    end)
  end
end
