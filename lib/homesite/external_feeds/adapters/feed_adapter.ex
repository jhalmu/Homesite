defmodule Homesite.ExternalFeeds.Adapters.FeedAdapter do
  @moduledoc """
  Behaviour for feed adapters.
  Each adapter implements the logic to fetch and parse a specific feed type.
  """

  alias Homesite.ExternalFeeds.FeedSource

  @doc """
  Fetches and parses items from a feed source.
  Returns {:ok, [feed_items]} or {:error, reason}.
  """
  @callback fetch_items(feed_source :: FeedSource.t()) ::
              {:ok, [map()]} | {:error, String.t()}

  @doc """
  Validates that the feed source has all required fields for this adapter.
  Returns :ok or {:error, reason}.
  """
  @callback validate_source(feed_source :: FeedSource.t()) :: :ok | {:error, String.t()}
end
