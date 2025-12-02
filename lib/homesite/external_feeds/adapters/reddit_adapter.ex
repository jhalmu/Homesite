defmodule Homesite.ExternalFeeds.Adapters.RedditAdapter do
  @moduledoc """
  Adapter for fetching Reddit feeds using native RSS support.

  Reddit provides RSS feeds for:
  - Subreddits: https://www.reddit.com/r/{subreddit}/.rss
  - User posts: https://www.reddit.com/user/{username}/submitted/.rss

  This adapter builds the RSS URL and delegates to RssAdapter for parsing.
  No API key required.
  """

  @behaviour Homesite.ExternalFeeds.Adapters.FeedAdapter

  alias Homesite.ExternalFeeds.Adapters.RssAdapter
  alias Homesite.ExternalFeeds.FeedSource

  @impl true
  def validate_source(%FeedSource{metadata: metadata}) when is_map(metadata) do
    has_subreddit? = Map.has_key?(metadata, "subreddit")
    has_username? = Map.has_key?(metadata, "username")

    cond do
      has_subreddit? and has_username? ->
        {:error, "Cannot specify both subreddit and username"}

      has_subreddit? ->
        validate_subreddit(Map.get(metadata, "subreddit"))

      has_username? ->
        validate_username(Map.get(metadata, "username"))

      true ->
        {:error, "Must specify either subreddit or username in metadata"}
    end
  end

  def validate_source(_), do: {:error, "Metadata must be a map"}

  @impl true
  def fetch_items(%FeedSource{metadata: metadata} = source) do
    with {:ok, rss_url} <- build_rss_url(metadata) do
      # Create a temporary source with the RSS URL and delegate to RssAdapter
      temp_source = Map.put(source, :url, rss_url)
      RssAdapter.fetch_items(temp_source)
    end
  end

  # Private functions

  defp build_rss_url(metadata) do
    cond do
      Map.has_key?(metadata, "subreddit") ->
        subreddit = Map.get(metadata, "subreddit")
        {:ok, "https://www.reddit.com/r/#{subreddit}/.rss"}

      Map.has_key?(metadata, "username") ->
        username = Map.get(metadata, "username")
        {:ok, "https://www.reddit.com/user/#{username}/submitted/.rss"}

      true ->
        {:error, "Must specify either subreddit or username"}
    end
  end

  defp validate_subreddit(subreddit) when is_binary(subreddit) do
    if String.match?(subreddit, ~r/^[a-zA-Z0-9_]{1,21}$/) do
      :ok
    else
      {:error, "Invalid subreddit format. Must be 1-21 alphanumeric characters or underscores"}
    end
  end

  defp validate_subreddit(_), do: {:error, "Subreddit must be a string"}

  defp validate_username(username) when is_binary(username) do
    if String.match?(username, ~r/^[a-zA-Z0-9_-]{3,20}$/) do
      :ok
    else
      {:error,
       "Invalid username format. Must be 3-20 alphanumeric characters, underscores, or hyphens"}
    end
  end

  defp validate_username(_), do: {:error, "Username must be a string"}
end
