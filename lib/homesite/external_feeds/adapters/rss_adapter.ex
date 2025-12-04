defmodule Homesite.ExternalFeeds.Adapters.RssAdapter do
  @moduledoc """
  Adapter for fetching and parsing RSS and Atom feeds.
  Uses sweet_xml for XML parsing and Req for HTTP requests.
  """

  @behaviour Homesite.ExternalFeeds.Adapters.FeedAdapter

  alias Homesite.ExternalFeeds.FeedSource
  import SweetXml
  require Logger

  @impl true
  def validate_source(%FeedSource{url: url}) when is_binary(url) and url != "", do: :ok
  def validate_source(_), do: {:error, "RSS/Atom feeds require a valid URL"}

  @impl true
  def fetch_items(%FeedSource{url: url, feed_type: feed_type} = feed_source) do
    Logger.info("Fetching #{feed_type} feed from: #{url}")

    with {:ok, response} <- fetch_feed(url),
         {:ok, items} <- parse_feed(response.body, feed_type, feed_source) do
      Logger.info("Successfully fetched #{length(items)} items from #{url}")
      {:ok, items}
    else
      {:error, reason} = error ->
        Logger.error("Failed to fetch feed from #{url}: #{inspect(reason)}")
        error
    end
  end

  # Fetch the feed using Req
  defp fetch_feed(url) do
    case Req.get(url,
           headers: [{"user-agent", "HomesiteBot/1.0"}],
           max_retries: 2,
           retry_delay: 1000
         ) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, %{body: body}}

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, exception} ->
        {:error, Exception.message(exception)}
    end
  end

  # Parse feed based on type - auto-detect if set to rss/atom
  defp parse_feed(body, feed_type, feed_source) do
    try do
      # Auto-detect feed type by checking XML structure
      detected_type = detect_feed_type(body, feed_type)

      items =
        case detected_type do
          "atom" -> parse_atom(body, feed_source)
          _ -> parse_rss(body, feed_source)
        end

      {:ok, items}
    rescue
      e ->
        {:error, "Failed to parse #{feed_type} feed: #{Exception.message(e)}"}
    end
  end

  # Auto-detect feed type from XML content
  defp detect_feed_type(body, configured_type) do
    cond do
      # Check for Atom namespace or feed element
      String.contains?(body, "xmlns=\"http://www.w3.org/2005/Atom\"") -> "atom"
      String.contains?(body, "<feed") && String.contains?(body, "<entry") -> "atom"
      # Check for RSS structure
      String.contains?(body, "<rss") -> "rss"
      String.contains?(body, "<channel>") && String.contains?(body, "<item>") -> "rss"
      # Fall back to configured type
      true -> configured_type
    end
  end

  # Parse RSS 2.0 feed
  defp parse_rss(xml_body, feed_source) do
    xml_body
    |> xpath(~x"//item"l,
      title: ~x"./title/text()"s,
      link: ~x"./link/text()"s,
      description: ~x"./description/text()"s,
      pub_date: ~x"./pubDate/text()"s,
      guid: ~x"./guid/text()"s,
      author: ~x"./author/text()"so,
      category: ~x"./category/text()"lo,
      # Image sources: enclosure, media:content, media:thumbnail
      enclosure_url: ~x"./enclosure/@url"so,
      enclosure_type: ~x"./enclosure/@type"so,
      media_content_url: ~x"./media:content/@url"so,
      media_thumbnail_url: ~x"./media:thumbnail/@url"so
    )
    |> Enum.map(fn item ->
      image_url = extract_image_url(item)

      %{
        external_id: generate_external_id(item.guid, item.link),
        title: item.title || "Untitled",
        content: sanitize_content(item.description) |> fallback_content(item.title),
        author_name: item.author,
        author_handle: nil,
        author_avatar_url: nil,
        published_at: parse_date(item.pub_date),
        url: item.link || "",
        metadata:
          %{
            feed_source_id: feed_source.id,
            feed_type: "rss",
            categories: item.category || []
          }
          |> maybe_add_image(image_url)
      }
    end)
  end

  # Parse Atom feed
  defp parse_atom(xml_body, feed_source) do
    xml_body
    |> xpath(~x"//entry"l,
      title: ~x"./title/text()"s,
      link: ~x"./link[@rel='alternate']/@href"s,
      content: ~x"./content/text()"s,
      summary: ~x"./summary/text()"s,
      published: ~x"./published/text()"s,
      updated: ~x"./updated/text()"s,
      id: ~x"./id/text()"s,
      author_name: ~x"./author/name/text()"so,
      category: ~x"./category/@term"lo,
      # Atom uses link with rel="enclosure" for media
      enclosure_url: ~x"./link[@rel='enclosure']/@href"so,
      media_content_url: ~x"./media:content/@url"so,
      media_thumbnail_url: ~x"./media:thumbnail/@url"so
    )
    |> Enum.map(fn item ->
      content = if item.content != "", do: item.content, else: item.summary
      image_url = extract_image_url(item)

      %{
        external_id: generate_external_id(item.id, item.link),
        title: item.title || "Untitled",
        content: sanitize_content(content) |> fallback_content(item.title),
        author_name: item.author_name,
        author_handle: nil,
        author_avatar_url: nil,
        published_at: parse_date(item.published || item.updated),
        url: item.link || "",
        metadata:
          %{
            feed_source_id: feed_source.id,
            feed_type: "atom",
            categories: item.category || []
          }
          |> maybe_add_image(image_url)
      }
    end)
  end

  # Generate external ID from guid or link
  defp generate_external_id(id, _link) when is_binary(id) and id != "" do
    # Use provided ID/GUID
    id
  end

  defp generate_external_id(_, link) when is_binary(link) and link != "" do
    # Hash the link to create a stable ID
    :crypto.hash(:sha256, link) |> Base.encode16(case: :lower)
  end

  defp generate_external_id(_, _) do
    # Generate random ID as last resort
    :crypto.hash(:sha256, :rand.bytes(16)) |> Base.encode16(case: :lower)
  end

  # Sanitize HTML content
  defp sanitize_content(content) when is_binary(content) and content != "" do
    case HtmlSanitizeEx.basic_html(content) do
      sanitized when is_binary(sanitized) -> String.trim(sanitized)
      _ -> String.trim(content)
    end
  end

  defp sanitize_content(_), do: ""

  # Fallback to title when content/description is empty
  # Many feeds (especially event feeds) don't have description content
  defp fallback_content("", title) when is_binary(title) and title != "", do: title
  defp fallback_content(content, _title), do: content

  # Extract image URL from various RSS/Atom image sources
  # Priority: media:thumbnail > media:content > enclosure (if image type) > embedded in content
  defp extract_image_url(item) do
    cond do
      is_binary(item.media_thumbnail_url) and item.media_thumbnail_url != "" ->
        item.media_thumbnail_url

      is_binary(item.media_content_url) and item.media_content_url != "" ->
        item.media_content_url

      is_binary(item.enclosure_url) and item.enclosure_url != "" and is_image_enclosure?(item) ->
        item.enclosure_url

      true ->
        # Try to extract from HTML content as fallback
        extract_image_from_html(item)
    end
  end

  # Extract first image URL from HTML content (for feeds that embed images in content)
  defp extract_image_from_html(%{description: desc}) when is_binary(desc) and desc != "" do
    extract_first_img_src(desc)
  end

  defp extract_image_from_html(%{content: content}) when is_binary(content) and content != "" do
    extract_first_img_src(content)
  end

  defp extract_image_from_html(%{summary: summary}) when is_binary(summary) and summary != "" do
    extract_first_img_src(summary)
  end

  defp extract_image_from_html(_), do: nil

  # Extract src attribute from first <img> tag in HTML
  defp extract_first_img_src(html) do
    case Regex.run(~r/<img[^>]+src=["']([^"']+)["']/i, html) do
      [_, src] -> src
      _ -> nil
    end
  end

  # Check if enclosure is an image type
  defp is_image_enclosure?(%{enclosure_type: type}) when is_binary(type) do
    String.starts_with?(type, "image/")
  end

  defp is_image_enclosure?(_), do: false

  # Add image URL to metadata if present
  defp maybe_add_image(metadata, nil), do: metadata
  defp maybe_add_image(metadata, ""), do: metadata
  defp maybe_add_image(metadata, image_url), do: Map.put(metadata, "image_url", image_url)

  # Parse date string to DateTime
  defp parse_date(""), do: DateTime.utc_now()
  defp parse_date(nil), do: DateTime.utc_now()

  defp parse_date(date_string) when is_binary(date_string) do
    # Try ISO8601 first (Atom feeds)
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _offset} ->
        datetime

      _ ->
        # Try RFC2822/RFC1123 (RSS feeds)
        case Timex.parse(date_string, "{RFC1123}") do
          {:ok, datetime} -> datetime
          _ -> DateTime.utc_now()
        end
    end
  rescue
    _ -> DateTime.utc_now()
  end

  defp parse_date(_), do: DateTime.utc_now()
end
