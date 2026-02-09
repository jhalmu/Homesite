defmodule Homesite.ExternalFeeds.Adapters.InstagramAdapter do
  @moduledoc """
  Adapter for fetching posts from Instagram.

  **Note:** Instagram does not provide public RSS feeds and their official API
  requires authentication and app approval. This adapter uses third-party RSS
  bridge services or requires manual RSS feed URL configuration.

  Feed source configuration:
  - `url`: RSS feed URL from a bridge service (e.g., RSS Bridge, Instagram-to-RSS)
  - `metadata.username`: Instagram username (for reference/display)

  Example RSS bridge services:
  - https://rss.app/feeds/instagram/...
  - https://rsshub.app/instagram/user/{username}
  - Self-hosted RSS Bridge instance
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
       "Instagram feeds require a valid RSS feed URL from a bridge service (e.g., RSS Bridge, rsshub.app)"}
    end
  end

  def validate_source(_) do
    {:error,
     "Instagram feeds require a URL pointing to an RSS bridge service. Instagram does not provide public RSS feeds."}
  end

  @impl true
  def fetch_items(%FeedSource{metadata: metadata} = feed_source) do
    username = Map.get(metadata, "username") || Map.get(metadata, :username) || "unknown"

    Logger.info("Fetching Instagram feed via RSS bridge for: @#{username}")

    # Delegate to RSS adapter since we're using RSS bridges
    case RssAdapter.fetch_items(feed_source) do
      {:ok, items} ->
        extra_metadata = %{
          feed_type: "instagram",
          instagram_username: username,
          source: "rss_bridge"
        }

        enhanced_items = enhance_items_metadata(items, extra_metadata)

        Logger.info(
          "Successfully fetched #{length(enhanced_items)} items from Instagram @#{username}"
        )

        {:ok, enhanced_items}

      {:error, reason} = error ->
        Logger.error("Failed to fetch Instagram feed for @#{username}: #{inspect(reason)}")
        error
    end
  end

  defp enhance_items_metadata(items, extra_metadata) do
    Enum.map(items, fn item ->
      Map.update!(item, :metadata, &Map.merge(&1, extra_metadata))
    end)
  end
end
