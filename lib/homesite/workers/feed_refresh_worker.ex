defmodule Homesite.Workers.FeedRefreshWorker do
  @moduledoc """
  Oban worker for refreshing individual feed sources.
  Scheduled to run periodically via cron or triggered manually.
  """
  use Oban.Worker,
    queue: :feeds,
    max_attempts: 3,
    priority: 1

  alias Homesite.ExternalFeeds.{FeedFetcher, FeedSource}
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"feed_source_id" => feed_source_id}}) do
    Logger.info("FeedRefreshWorker: Starting refresh for feed_source_id=#{feed_source_id}")

    case Homesite.Repo.get(FeedSource, feed_source_id) do
      nil ->
        Logger.warning("FeedRefreshWorker: Feed source #{feed_source_id} not found")
        {:cancel, :not_found}

      %FeedSource{enabled: false} = _feed_source ->
        Logger.info(
          "FeedRefreshWorker: Feed source #{feed_source_id} is disabled, skipping refresh"
        )

        {:ok, :disabled}

      feed_source ->
        case should_refresh?(feed_source) do
          true ->
            refresh_feed(feed_source)

          false ->
            Logger.debug(
              "FeedRefreshWorker: Feed source #{feed_source_id} was recently refreshed, skipping"
            )

            {:ok, :skipped}
        end
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"refresh_all" => true}}) do
    Logger.info("FeedRefreshWorker: Refreshing all enabled feeds")

    result = FeedFetcher.fetch_all_enabled()

    Logger.info("""
    FeedRefreshWorker: Batch refresh completed
      - Total sources: #{result.total_sources}
      - Successful: #{result.successful}
      - Errors: #{result.errors}
      - Total items: #{result.total_items}
    """)

    {:ok, result}
  end

  # Schedule refresh for a specific feed source
  @doc """
  Schedules a refresh job for a specific feed source.
  """
  def schedule_refresh(feed_source_id) when is_integer(feed_source_id) do
    %{feed_source_id: feed_source_id}
    |> new()
    |> Oban.insert()
  end

  @doc """
  Schedules a refresh job for all enabled feeds.
  """
  def schedule_refresh_all do
    %{refresh_all: true}
    |> new()
    |> Oban.insert()
  end

  @doc """
  Schedules refresh jobs for all enabled feed sources individually.
  This allows for parallel processing and better error isolation.
  """
  def schedule_individual_refreshes do
    import Ecto.Query

    feed_source_ids =
      Homesite.Repo.all(
        from f in FeedSource,
          where: f.enabled == true,
          select: f.id
      )

    jobs =
      Enum.map(feed_source_ids, fn id ->
        new(%{feed_source_id: id})
      end)

    Oban.insert_all(jobs)
  end

  # Check if feed should be refreshed based on refresh_interval
  defp should_refresh?(%FeedSource{last_fetched_at: nil}), do: true

  defp should_refresh?(%FeedSource{
         last_fetched_at: last_fetched_at,
         refresh_interval: interval_minutes
       }) do
    now = DateTime.utc_now()
    interval_seconds = interval_minutes * 60

    DateTime.diff(now, last_fetched_at, :second) >= interval_seconds
  end

  # Refresh a single feed source
  defp refresh_feed(feed_source) do
    case FeedFetcher.fetch_and_store(feed_source) do
      {:ok, count} ->
        Logger.info(
          "FeedRefreshWorker: Successfully refreshed feed #{feed_source.id}, stored #{count} items"
        )

        {:ok, %{feed_source_id: feed_source.id, items_count: count}}

      {:error, reason} = error ->
        Logger.error(
          "FeedRefreshWorker: Failed to refresh feed #{feed_source.id}: #{inspect(reason)}"
        )

        # Return error to trigger Oban retry
        error
    end
  end
end
