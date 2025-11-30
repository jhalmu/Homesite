defmodule Homesite.ExternalFeeds.Adapters.YoutubeAdapter do
  @moduledoc """
  Adapter for fetching videos from YouTube channels.
  Uses YouTube's RSS feeds (no API key required).

  Feed source configuration:
  - `metadata.channel_id`: YouTube channel ID (e.g., "UCXuqSBlHAE6Xw-yeJA0Tunw")
  - `url`: Will be auto-generated from channel_id if not provided

  RSS feed URL format: https://www.youtube.com/feeds/videos.xml?channel_id={channel_id}
  """

  @behaviour Homesite.ExternalFeeds.Adapters.FeedAdapter

  alias Homesite.ExternalFeeds.FeedSource
  import SweetXml
  require Logger

  @impl true
  def validate_source(%FeedSource{metadata: metadata}) when is_map(metadata) do
    channel_id = Map.get(metadata, "channel_id") || Map.get(metadata, :channel_id)

    case channel_id do
      id when is_binary(id) and id != "" ->
        :ok

      _ ->
        {:error,
         "YouTube feeds require 'channel_id' in metadata (e.g., UCXuqSBlHAE6Xw-yeJA0Tunw)"}
    end
  end

  def validate_source(_), do: {:error, "YouTube feeds require metadata with channel_id"}

  @impl true
  def fetch_items(%FeedSource{metadata: metadata} = feed_source) do
    channel_id = Map.get(metadata, "channel_id") || Map.get(metadata, :channel_id)

    # Build RSS feed URL
    url = "https://www.youtube.com/feeds/videos.xml?channel_id=#{channel_id}"

    Logger.info("Fetching YouTube feed for channel: #{channel_id}")

    with {:ok, response} <- fetch_feed(url),
         {:ok, items} <- parse_youtube_feed(response.body, feed_source, channel_id) do
      Logger.info(
        "Successfully fetched #{length(items)} items from YouTube channel #{channel_id}"
      )

      {:ok, items}
    else
      {:error, reason} = error ->
        Logger.error("Failed to fetch YouTube feed for channel #{channel_id}: #{inspect(reason)}")
        error
    end
  end

  # Fetch the YouTube RSS feed
  defp fetch_feed(url) do
    case Req.get(url,
           headers: [{"user-agent", "HomesiteBot/1.0"}],
           max_retries: 2,
           retry_delay: 1000
         ) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, %{body: body}}

      {:ok, %{status: 404}} ->
        {:error, "Channel not found"}

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, exception} ->
        {:error, Exception.message(exception)}
    end
  end

  # Parse YouTube Atom feed
  defp parse_youtube_feed(xml_body, feed_source, channel_id) do
    try do
      items =
        xml_body
        |> xpath(~x"//entry"l,
          title: ~x"./title/text()"s,
          video_id: ~x"./yt:videoId/text()"s,
          link: ~x"./link[@rel='alternate']/@href"s,
          published: ~x"./published/text()"s,
          updated: ~x"./updated/text()"s,
          author_name: ~x"./author/name/text()"so,
          author_uri: ~x"./author/uri/text()"so,
          media_description: ~x"./media:group/media:description/text()"so,
          media_thumbnail: ~x"./media:group/media:thumbnail/@url"so
        )
        |> Enum.map(fn item ->
          video_id = item.video_id

          video_url =
            if video_id != "", do: "https://www.youtube.com/watch?v=#{video_id}", else: item.link

          %{
            external_id: video_id || generate_id_from_url(item.link),
            title: item.title || "Untitled Video",
            content: format_video_content(item),
            author_name: item.author_name || "Unknown",
            author_handle: nil,
            author_avatar_url: nil,
            published_at: parse_youtube_date(item.published || item.updated),
            url: video_url,
            metadata: %{
              feed_source_id: feed_source.id,
              feed_type: "youtube",
              video_id: video_id,
              channel_id: channel_id,
              thumbnail_url: item.media_thumbnail,
              embed_url:
                if(video_id != "", do: "https://www.youtube.com/embed/#{video_id}", else: nil)
            }
          }
        end)

      {:ok, items}
    rescue
      e ->
        {:error, "Failed to parse YouTube feed: #{Exception.message(e)}"}
    end
  end

  # Format video content with thumbnail and description
  defp format_video_content(item) do
    description = item.media_description || ""
    thumbnail = item.media_thumbnail

    content_parts = []

    content_parts =
      if thumbnail do
        [
          "<p><img src=\"#{thumbnail}\" alt=\"Video thumbnail\" style=\"max-width: 100%; height: auto;\" /></p>"
          | content_parts
        ]
      else
        content_parts
      end

    content_parts =
      if description != "" do
        ["<p>#{HtmlSanitizeEx.basic_html(description)}</p>" | content_parts]
      else
        content_parts
      end

    content_parts
    |> Enum.reverse()
    |> Enum.join("\n")
  end

  # Generate ID from URL if video_id is not available
  defp generate_id_from_url(url) when is_binary(url) and url != "" do
    :crypto.hash(:sha256, url) |> Base.encode16(case: :lower)
  end

  defp generate_id_from_url(_) do
    :crypto.hash(:sha256, :rand.bytes(16)) |> Base.encode16(case: :lower)
  end

  # Parse YouTube timestamp (ISO8601)
  defp parse_youtube_date(date_string) when is_binary(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _offset} -> datetime
      _ -> DateTime.utc_now()
    end
  end

  defp parse_youtube_date(_), do: DateTime.utc_now()
end
