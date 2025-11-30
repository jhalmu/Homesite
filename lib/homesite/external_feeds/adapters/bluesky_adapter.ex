defmodule Homesite.ExternalFeeds.Adapters.BlueskyAdapter do
  @moduledoc """
  Adapter for fetching posts from Bluesky (AT Protocol).
  Uses the public Bluesky API to fetch a user's posts.

  Feed source configuration:
  - `username`: Bluesky handle (e.g., "user.bsky.social" or DID)
  - `url`: Optional, defaults to public API endpoint
  """

  @behaviour Homesite.ExternalFeeds.Adapters.FeedAdapter

  alias Homesite.ExternalFeeds.FeedSource
  require Logger

  @public_api "https://public.api.bsky.app"
  @default_limit 25

  @impl true
  def validate_source(%FeedSource{username: username}) when is_binary(username) and username != "" do
    :ok
  end

  def validate_source(%FeedSource{metadata: metadata}) when is_map(metadata) do
    # Fallback: check metadata for backwards compatibility
    case Map.get(metadata, "username") || Map.get(metadata, :username) do
      username when is_binary(username) and username != "" ->
        :ok

      _ ->
        {:error, "Bluesky feeds require a 'username' field (e.g., user.bsky.social)"}
    end
  end

  def validate_source(_), do: {:error, "Bluesky feeds require a username"}

  @impl true
  def fetch_items(%FeedSource{username: username, metadata: metadata} = feed_source) when is_binary(username) do
    limit = Map.get(metadata || %{}, "limit") || Map.get(metadata || %{}, :limit) || @default_limit

    Logger.info("Fetching Bluesky feed for user: #{username}")

    with {:ok, response} <- fetch_author_feed(username, limit),
         {:ok, items} <- parse_bluesky_feed(response, feed_source) do
      Logger.info("Successfully fetched #{length(items)} items from Bluesky @#{username}")
      {:ok, items}
    else
      {:error, reason} = error ->
        Logger.error("Failed to fetch Bluesky feed for @#{username}: #{inspect(reason)}")
        error
    end
  end

  # Fetch author feed using Bluesky public API
  defp fetch_author_feed(actor, limit) do
    url = "#{@public_api}/xrpc/app.bsky.feed.getAuthorFeed"

    params = [
      actor: actor,
      limit: limit
    ]

    case Req.get(url,
           params: params,
           headers: [
             {"user-agent", "HomesiteBot/1.0"},
             {"accept", "application/json"}
           ],
           max_retries: 2,
           retry_delay: 1000
         ) do
      {:ok, %{status: 200, body: body}} when is_map(body) ->
        {:ok, body}

      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        case Jason.decode(body) do
          {:ok, decoded} -> {:ok, decoded}
          {:error, _} -> {:error, "Invalid JSON response"}
        end

      {:ok, %{status: 404}} ->
        {:error, "User not found"}

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, exception} ->
        {:error, Exception.message(exception)}
    end
  end

  # Parse Bluesky feed response
  defp parse_bluesky_feed(%{"feed" => feed_items}, feed_source) when is_list(feed_items) do
    items =
      feed_items
      |> Enum.filter(&valid_post?/1)
      |> Enum.map(&parse_post(&1, feed_source))
      |> Enum.reject(&is_nil/1)

    {:ok, items}
  end

  defp parse_bluesky_feed(_, _), do: {:error, "Invalid Bluesky feed format"}

  # Check if post is valid
  defp valid_post?(%{"post" => %{"record" => %{"text" => text}}}) when is_binary(text), do: true
  defp valid_post?(_), do: false

  # Parse a single Bluesky post
  defp parse_post(%{"post" => post}, feed_source) do
    record = post["record"] || %{}
    author = post["author"] || %{}
    uri = post["uri"] || ""
    cid = post["cid"] || ""

    # Extract text content
    text = record["text"] || ""

    # Extract embed content (images, links, etc.)
    embed_text = extract_embed_text(post["embed"])

    # Combine text and embed info
    content =
      if embed_text != "" do
        "#{text}\n\n#{embed_text}"
      else
        text
      end

    # Generate post URL
    post_url = generate_post_url(author["handle"], uri)

    %{
      external_id: cid || generate_id_from_uri(uri),
      title: truncate_text(text, 100),
      content: content,
      author_name: author["displayName"] || author["handle"],
      author_handle: "@#{author["handle"]}",
      author_avatar_url: author["avatar"],
      published_at: parse_bluesky_date(record["createdAt"]),
      url: post_url,
      metadata: %{
        feed_source_id: feed_source.id,
        feed_type: "bluesky",
        uri: uri,
        cid: cid,
        reply_count: post["replyCount"] || 0,
        repost_count: post["repostCount"] || 0,
        like_count: post["likeCount"] || 0,
        has_embed: !is_nil(post["embed"])
      }
    }
  rescue
    e ->
      Logger.warning("Failed to parse Bluesky post: #{Exception.message(e)}")
      nil
  end

  # Extract text from embeds (images, links, etc.)
  defp extract_embed_text(%{"$type" => "app.bsky.embed.images#view", "images" => images})
       when is_list(images) do
    count = length(images)
    "[#{count} image#{if count > 1, do: "s", else: ""}]"
  end

  defp extract_embed_text(%{"$type" => "app.bsky.embed.external#view", "external" => external}) do
    title = external["title"] || ""
    description = external["description"] || ""
    uri = external["uri"] || ""

    """
    🔗 Link: #{title}
    #{description}
    #{uri}
    """
    |> String.trim()
  end

  defp extract_embed_text(%{"$type" => "app.bsky.embed.record#view"}), do: "[Quoted post]"

  defp extract_embed_text(%{
         "$type" => "app.bsky.embed.recordWithMedia#view",
         "media" => media
       }) do
    media_text = extract_embed_text(media)
    "#{media_text} [Quoted post]"
  end

  defp extract_embed_text(_), do: ""

  # Generate post URL from handle and URI
  defp generate_post_url(handle, uri) do
    case String.split(uri, "/") do
      [_, _, _, "app.bsky.feed.post", rkey] ->
        "https://bsky.app/profile/#{handle}/post/#{rkey}"

      _ ->
        "https://bsky.app/profile/#{handle}"
    end
  end

  # Generate ID from URI if CID is not available
  defp generate_id_from_uri(uri) when is_binary(uri) and uri != "" do
    :crypto.hash(:sha256, uri) |> Base.encode16(case: :lower)
  end

  defp generate_id_from_uri(_) do
    :crypto.hash(:sha256, :rand.bytes(16)) |> Base.encode16(case: :lower)
  end

  # Parse Bluesky timestamp (ISO8601)
  defp parse_bluesky_date(date_string) when is_binary(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _offset} -> datetime
      _ -> DateTime.utc_now()
    end
  end

  defp parse_bluesky_date(_), do: DateTime.utc_now()

  # Truncate text to specified length
  defp truncate_text(text, max_length) when is_binary(text) do
    if String.length(text) > max_length do
      String.slice(text, 0, max_length) <> "..."
    else
      text
    end
  end

  defp truncate_text(_, _), do: "Untitled"
end
