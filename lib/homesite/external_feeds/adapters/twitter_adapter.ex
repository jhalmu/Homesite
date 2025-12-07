defmodule Homesite.ExternalFeeds.Adapters.TwitterAdapter do
  @moduledoc """
  Adapter for fetching posts from X (formerly Twitter).

  **Status:** DORMANT - Not actively used.

  **Note:** Twitter/X removed free API access and RSS feeds. This adapter is
  implemented but dormant. It can be activated when/if:
  - Paid API access is configured
  - Third-party RSS bridge services are available
  - Alternative scraping methods are approved

  Feed source configuration (when active):
  - `url`: RSS feed URL from a bridge service
  - `metadata.username`: Twitter/X username (e.g., "elixirlang")
  - `metadata.api_key`: API key (if using official API)
  - `metadata.api_secret`: API secret (if using official API)

  Example RSS bridge services (may require self-hosting):
  - https://rsshub.app/twitter/user/{username}
  - Self-hosted Nitter instance RSS
  - Self-hosted RSS Bridge instance
  """

  @behaviour Homesite.ExternalFeeds.Adapters.FeedAdapter

  require Logger

  alias Homesite.ExternalFeeds.Adapters.RssAdapter
  alias Homesite.ExternalFeeds.FeedSource

  @impl true
  def validate_source(%FeedSource{url: url}) when is_binary(url) and url != "" do
    Logger.warning("Twitter adapter is DORMANT. Feed validation skipped.")

    if String.contains?(url, ["rss", "feed", "xml", "nitter"]) do
      :ok
    else
      {:error,
       "Twitter feeds require a valid RSS feed URL from a bridge service (e.g., Nitter, RSS Bridge)"}
    end
  end

  def validate_source(_) do
    {:error,
     "Twitter feeds are DORMANT. Activation requires RSS bridge configuration or API credentials."}
  end

  @impl true
  def fetch_items(%FeedSource{metadata: metadata} = feed_source) do
    username = Map.get(metadata, "username") || Map.get(metadata, :username) || "unknown"

    Logger.warning("Twitter adapter is DORMANT. Fetching via RSS bridge for: @#{username}")

    # Delegate to RSS adapter since we're using RSS bridges
    case RssAdapter.fetch_items(feed_source) do
      {:ok, items} ->
        # Enhance items with Twitter-specific metadata
        enhanced_items =
          Enum.map(items, fn item ->
            Map.update!(item, :metadata, fn meta ->
              Map.merge(meta, %{
                feed_type: "twitter",
                twitter_username: username,
                source: "rss_bridge",
                dormant: true,
                note: "Fetched via RSS bridge - official API not used"
              })
            end)
          end)

        Logger.info(
          "Successfully fetched #{length(enhanced_items)} items from Twitter @#{username} (DORMANT MODE)"
        )

        {:ok, enhanced_items}

      {:error, reason} = error ->
        Logger.error("Failed to fetch Twitter feed for @#{username}: #{inspect(reason)}")
        error
    end
  end
end
