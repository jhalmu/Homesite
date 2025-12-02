defmodule Homesite.Timeline do
  @moduledoc """
  The Timeline context - unified view of external feed items and own blog posts.

  Provides functions to retrieve and merge content from multiple sources:
  - External feed items (from ExternalFeeds context)
  - Own blog posts (from Content context)

  All items are sorted chronologically by published_at timestamp.
  """

  import Ecto.Query, warn: false

  alias Homesite.Accounts.Scope
  alias Homesite.Content
  alias Homesite.ExternalFeeds

  @doc """
  Lists all timeline items (feed items + own posts) in chronological order.

  ## Options
    * `:limit` - Maximum number of items to return (default: 50)
    * `:offset` - Number of items to skip (default: 0)
    * `:filter` - Filter items by type:
      * `:all` - Both external feeds and own posts (default)
      * `:external` - Only external feed items
      * `:own_posts` - Only own blog posts
    * `:unread_only` - Only show unread external feed items (default: false)

  Returns a list of timeline items sorted by published_at descending (newest first).
  Each item is a map with:
    * `:type` - Either `:feed_item` or `:post`
    * `:item` - The actual FeedItem or Post struct
    * `:published_at` - Timestamp for sorting
    * `:title` - Item title
    * `:url` - Item URL
    * `:source` - Source identifier (feed source name or "own")

  ## Examples

      iex> list_timeline_items(scope)
      [%{type: :post, item: %Post{...}, published_at: ~U[...], ...}, ...]

      iex> list_timeline_items(scope, filter: :external, limit: 20)
      [%{type: :feed_item, item: %FeedItem{...}, published_at: ~U[...], ...}, ...]

      iex> list_timeline_items(scope, filter: :own_posts)
      [%{type: :post, item: %Post{...}, published_at: ~U[...], ...}, ...]
  """
  def list_timeline_items(%Scope{} = scope, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)
    filter = Keyword.get(opts, :filter, :all)
    unread_only = Keyword.get(opts, :unread_only, false)

    # Fetch items based on filter
    external_items =
      if filter in [:all, :external] do
        fetch_external_items(scope, limit: limit * 2, unread_only: unread_only)
      else
        []
      end

    own_posts =
      if filter in [:all, :own_posts] do
        fetch_own_posts(scope, limit: limit * 2)
      else
        []
      end

    # Merge, sort, and paginate
    external_items
    |> Enum.concat(own_posts)
    |> Enum.sort_by(& &1.published_at, {:desc, DateTime})
    |> Enum.drop(offset)
    |> Enum.take(limit)
  end

  @doc """
  Gets the count of unread items in the timeline.

  Returns a map with:
    * `:external_unread` - Number of unread external feed items
    * `:total` - Total unread count

  ## Examples

      iex> get_unread_count(scope)
      %{external_unread: 42, total: 42}
  """
  def get_unread_count(%Scope{} = scope) do
    external_unread = ExternalFeeds.get_unread_count(scope)

    %{
      external_unread: external_unread,
      total: external_unread
    }
  end

  # Private helpers

  defp fetch_external_items(scope, opts) do
    limit = Keyword.get(opts, :limit, 50)
    unread_only = Keyword.get(opts, :unread_only, false)

    ExternalFeeds.list_feed_items_unified(scope,
      limit: limit,
      unread_only: unread_only
    )
    |> Enum.map(fn %{feed_item: feed_item} = _item_with_interaction ->
      %{
        type: :feed_item,
        item: feed_item,
        published_at: feed_item.published_at,
        title: feed_item.title,
        url: feed_item.url,
        source: get_feed_source_name(feed_item),
        metadata: feed_item.metadata
      }
    end)
  end

  defp fetch_own_posts(scope, opts) do
    limit = Keyword.get(opts, :limit, 50)

    # Note: All posts have published_at (required field in schema)
    Content.list_posts(scope)
    |> Enum.take(limit)
    |> Enum.map(fn post ->
      %{
        type: :post,
        item: post,
        published_at: post.published_at,
        title: post.title,
        url: "/posts/#{post.slug}",
        source: "own",
        metadata: %{}
      }
    end)
  end

  defp get_feed_source_name(%{feed_source: %{name: name}}), do: name
  defp get_feed_source_name(%{feed_source: nil}), do: "unknown"
  defp get_feed_source_name(_), do: "unknown"
end
