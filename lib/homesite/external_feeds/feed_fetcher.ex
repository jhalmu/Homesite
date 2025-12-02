defmodule Homesite.ExternalFeeds.FeedFetcher do
  @moduledoc """
  Orchestrates fetching feed items from various sources using adapters.
  """

  alias Homesite.ExternalFeeds
  alias Homesite.ExternalFeeds.FeedSource

  alias Homesite.ExternalFeeds.Adapters.{
    BlueskyAdapter,
    InstagramAdapter,
    MastodonAdapter,
    RedditAdapter,
    RssAdapter,
    TwitterAdapter,
    YoutubeAdapter
  }

  require Logger

  @doc """
  Fetches and stores items for a single feed source.
  Returns {:ok, count} where count is the number of new/updated items.
  """
  def fetch_and_store(%FeedSource{} = feed_source) do
    Logger.info("Fetching feed: #{feed_source.name} (ID: #{feed_source.id})")

    adapter = get_adapter(feed_source.feed_type)

    with :ok <- adapter.validate_source(feed_source),
         {:ok, items} <- adapter.fetch_items(feed_source),
         {:ok, count} <- store_items(feed_source.id, items) do
      ExternalFeeds.update_feed_source_fetch_time(feed_source.id)
      {:ok, count}
    else
      {:error, reason} = error ->
        ExternalFeeds.record_feed_source_error(feed_source.id, to_string(reason))
        error
    end
  end

  @doc """
  Fetches and stores items for all enabled feed sources.
  Returns a summary map with counts.
  """
  def fetch_all_enabled do
    import Ecto.Query
    # Get all enabled feed sources (not scoped to a specific user)
    feed_sources =
      Homesite.Repo.all(from f in FeedSource, where: f.enabled == true, order_by: [asc: f.id])

    results =
      Enum.map(feed_sources, fn feed_source ->
        case fetch_and_store(feed_source) do
          {:ok, count} -> {:ok, feed_source.id, count}
          {:error, reason} -> {:error, feed_source.id, reason}
        end
      end)

    success_count = Enum.count(results, fn {status, _, _} -> status == :ok end)
    error_count = Enum.count(results, fn {status, _, _} -> status == :error end)

    total_items =
      Enum.reduce(results, 0, fn
        {:ok, _, count}, acc -> acc + count
        _, acc -> acc
      end)

    Logger.info("""
    Feed fetch completed:
      - Total sources: #{length(feed_sources)}
      - Successful: #{success_count}
      - Errors: #{error_count}
      - Total items: #{total_items}
    """)

    %{
      total_sources: length(feed_sources),
      successful: success_count,
      errors: error_count,
      total_items: total_items,
      results: results
    }
  end

  # Get the appropriate adapter for a feed type
  defp get_adapter(feed_type) when feed_type in ["rss", "atom", "json"] do
    RssAdapter
  end

  defp get_adapter("bluesky") do
    BlueskyAdapter
  end

  defp get_adapter("mastodon") do
    MastodonAdapter
  end

  defp get_adapter("youtube") do
    YoutubeAdapter
  end

  defp get_adapter("instagram") do
    InstagramAdapter
  end

  defp get_adapter("twitter") do
    TwitterAdapter
  end

  defp get_adapter("reddit") do
    RedditAdapter
  end

  defp get_adapter(type) do
    raise "Unknown feed type: #{type}"
  end

  # Store fetched items in the database
  defp store_items(feed_source_id, items) do
    results =
      Enum.map(items, fn item ->
        ExternalFeeds.upsert_feed_item(feed_source_id, item)
      end)

    success_count =
      Enum.count(results, fn
        {:ok, _} -> true
        _ -> false
      end)

    {:ok, success_count}
  end
end
