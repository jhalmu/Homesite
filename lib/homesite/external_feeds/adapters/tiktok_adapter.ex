defmodule Homesite.ExternalFeeds.Adapters.TiktokAdapter do
  @moduledoc """
  Adapter for fetching posts from TikTok.

  **Note:** TikTok does not provide public RSS feeds and their official API
  requires authentication and app approval. This adapter uses third-party RSS
  bridge services or requires manual RSS feed URL configuration.

  Feed source configuration:
  - `url`: RSS feed URL from a bridge service (e.g., RSS Bridge, RSS Hub)
  - `metadata.username`: TikTok username (for reference/display)

  Example RSS bridge services:
  - https://rsshub.app/tiktok/user/{username}
  - https://rss.app/feeds/tiktok/...
  - Self-hosted RSS Bridge instance

  Note: TikTok heavily rate-limits and blocks automated access. RSS bridges
  may be unreliable or require frequent URL updates.
  """

  @behaviour Homesite.ExternalFeeds.Adapters.FeedAdapter

  require Logger

  alias Homesite.ExternalFeeds.Adapters.RssAdapter
  alias Homesite.ExternalFeeds.FeedSource

  @impl true
  def validate_source(%FeedSource{url: url}) when is_binary(url) and url != "" do
    if String.contains?(url, ["rss", "feed", "xml"]) do
      :ok
    else
      {:error,
       "TikTok feeds require a valid RSS feed URL from a bridge service (e.g., RSS Bridge, rsshub.app)"}
    end
  end

  def validate_source(_) do
    {:error,
     "TikTok feeds require a URL pointing to an RSS bridge service. TikTok does not provide public RSS feeds."}
  end

  @impl true
  def fetch_items(%FeedSource{metadata: metadata} = feed_source) do
    username = Map.get(metadata, "username") || Map.get(metadata, :username) || "unknown"

    Logger.info("Fetching TikTok feed via RSS bridge for: @#{username}")

    # Delegate to RSS adapter since we're using RSS bridges
    case RssAdapter.fetch_items(feed_source) do
      {:ok, items} ->
        extra_metadata = %{
          feed_type: "tiktok",
          tiktok_username: username,
          source: "rss_bridge"
        }

        enhanced_items = enhance_items_metadata(items, extra_metadata)

        Logger.info(
          "Successfully fetched #{length(enhanced_items)} items from TikTok @#{username}"
        )

        {:ok, enhanced_items}

      {:error, reason} = error ->
        Logger.error("Failed to fetch TikTok feed for @#{username}: #{inspect(reason)}")
        error
    end
  end

  defp enhance_items_metadata(items, extra_metadata) do
    Enum.map(items, fn item ->
      Map.update!(item, :metadata, &Map.merge(&1, extra_metadata))
    end)
  end
end
