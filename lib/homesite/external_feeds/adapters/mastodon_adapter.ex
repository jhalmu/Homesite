defmodule Homesite.ExternalFeeds.Adapters.MastodonAdapter do
  @moduledoc """
  Adapter for fetching posts from Mastodon and compatible fediverse instances.
  Uses the public Mastodon API to fetch a user's posts.

  Feed source configuration:
  - `metadata.instance`: Mastodon instance URL (e.g., "mastodon.social")
  - `metadata.username`: Username/account ID
  - `url`: Full profile URL (optional, can be derived from instance + username)
  """

  @behaviour Homesite.ExternalFeeds.Adapters.FeedAdapter

  alias Homesite.ExternalFeeds.FeedSource
  require Logger

  @default_limit 20

  @impl true
  def validate_source(%FeedSource{username: username, metadata: metadata})
      when is_binary(username) and username != "" and is_map(metadata) do
    instance = Map.get(metadata, "instance") || Map.get(metadata, :instance)

    if is_nil(instance) or instance == "" do
      {:error,
       "Mastodon feeds require 'instance' in metadata (e.g., mastodon.social, fosstodon.org)"}
    else
      :ok
    end
  end

  def validate_source(%FeedSource{metadata: metadata}) when is_map(metadata) do
    # Fallback: check metadata for backwards compatibility
    instance = Map.get(metadata, "instance") || Map.get(metadata, :instance)
    username = Map.get(metadata, "username") || Map.get(metadata, :username)

    cond do
      is_nil(instance) or instance == "" ->
        {:error,
         "Mastodon feeds require 'instance' in metadata (e.g., mastodon.social, fosstodon.org)"}

      is_nil(username) or username == "" ->
        {:error, "Mastodon feeds require 'username' field (e.g., @user or user)"}

      true ->
        :ok
    end
  end

  def validate_source(_), do: {:error, "Mastodon feeds require username and instance"}

  @impl true
  def fetch_items(%FeedSource{username: username, metadata: metadata} = feed_source)
      when is_binary(username) do
    instance = Map.get(metadata || %{}, "instance") || Map.get(metadata || %{}, :instance)

    limit =
      Map.get(metadata || %{}, "limit") || Map.get(metadata || %{}, :limit) || @default_limit

    # Clean username (remove @ if present)
    clean_username = String.trim_leading(username, "@")

    Logger.info("Fetching Mastodon feed for @#{clean_username}@#{instance}")

    with {:ok, account_id} <- get_account_id(instance, clean_username),
         {:ok, response} <- fetch_account_statuses(instance, account_id, limit),
         {:ok, items} <- parse_mastodon_statuses(response, feed_source, instance) do
      Logger.info(
        "Successfully fetched #{length(items)} items from Mastodon @#{clean_username}@#{instance}"
      )

      {:ok, items}
    else
      {:error, reason} = error ->
        Logger.error(
          "Failed to fetch Mastodon feed for @#{clean_username}@#{instance}: #{inspect(reason)}"
        )

        error
    end
  end

  # Get account ID from username using Mastodon search API
  defp get_account_id(instance, username) do
    url = "https://#{instance}/api/v2/search"

    params = [
      q: "@#{username}@#{instance}",
      type: "accounts",
      resolve: true,
      limit: 1
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
      {:ok, %{status: 200, body: %{"accounts" => [account | _]}}} ->
        {:ok, account["id"]}

      {:ok, %{status: 200, body: %{"accounts" => []}}} ->
        {:error, "Account not found"}

      {:ok, %{status: 404}} ->
        {:error, "Instance or account not found"}

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, exception} ->
        {:error, Exception.message(exception)}
    end
  end

  # Fetch account statuses using Mastodon accounts API
  defp fetch_account_statuses(instance, account_id, limit) do
    url = "https://#{instance}/api/v1/accounts/#{account_id}/statuses"

    params = [
      limit: limit,
      exclude_replies: true,
      exclude_reblogs: false
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
      {:ok, %{status: 200, body: body}} when is_list(body) ->
        {:ok, body}

      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        case Jason.decode(body) do
          {:ok, decoded} when is_list(decoded) -> {:ok, decoded}
          _ -> {:error, "Invalid JSON response"}
        end

      {:ok, %{status: 404}} ->
        {:error, "Account not found"}

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, exception} ->
        {:error, Exception.message(exception)}
    end
  end

  # Parse Mastodon statuses
  defp parse_mastodon_statuses(statuses, feed_source, instance) when is_list(statuses) do
    items =
      statuses
      |> Enum.filter(&valid_status?/1)
      |> Enum.map(&parse_status(&1, feed_source, instance))
      |> Enum.reject(&is_nil/1)

    {:ok, items}
  end

  defp parse_mastodon_statuses(_, _, _), do: {:error, "Invalid Mastodon statuses format"}

  # Check if status is valid
  defp valid_status?(%{"content" => content}) when is_binary(content), do: true
  defp valid_status?(_), do: false

  # Parse a single Mastodon status
  defp parse_status(status, feed_source, instance) do
    account = status["account"] || %{}
    content = status["content"] || ""

    %{
      external_id: status["id"] || generate_random_id(),
      title: truncate_text(strip_html(content), 100),
      content: build_full_content(content, status["media_attachments"] || []),
      author_name: account["display_name"] || account["username"],
      author_handle: "@#{account["acct"]}",
      author_avatar_url: account["avatar"],
      published_at: parse_mastodon_date(status["created_at"]),
      url: status["url"] || build_status_url(instance, account, status),
      metadata: build_status_metadata(status, feed_source)
    }
  rescue
    e ->
      Logger.warning("Failed to parse Mastodon status: #{Exception.message(e)}")
      nil
  end

  defp build_full_content(content, media_attachments) do
    case extract_media_text(media_attachments) do
      "" -> content
      media_text -> "#{content}\n\n#{media_text}"
    end
  end

  defp build_status_url(instance, account, status) do
    "https://#{instance}/@#{account["username"]}/#{status["id"]}"
  end

  defp build_status_metadata(status, feed_source) do
    %{
      feed_source_id: feed_source.id,
      feed_type: "mastodon",
      visibility: status["visibility"],
      replies_count: status["replies_count"] || 0,
      reblogs_count: status["reblogs_count"] || 0,
      favourites_count: status["favourites_count"] || 0,
      sensitive: status["sensitive"] || false,
      spoiler_text: status["spoiler_text"],
      language: status["language"]
    }
  end

  # Strip HTML tags from content
  defp strip_html(html) when is_binary(html) do
    html
    |> String.replace(~r/<[^>]+>/, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp strip_html(_), do: ""

  # Extract media attachments info
  defp extract_media_text([]), do: ""

  defp extract_media_text(attachments) when is_list(attachments) do
    Enum.map_join(attachments, "\n", fn attachment ->
      type = attachment["type"] || "unknown"
      description = attachment["description"] || ""

      case type do
        "image" -> "[Image: #{description}]"
        "video" -> "[Video: #{description}]"
        "gifv" -> "[GIF: #{description}]"
        "audio" -> "[Audio: #{description}]"
        _ -> "[Media: #{description}]"
      end
    end)
  end

  defp extract_media_text(_), do: ""

  # Parse Mastodon timestamp (ISO8601)
  defp parse_mastodon_date(date_string) when is_binary(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _offset} -> datetime
      _ -> DateTime.utc_now()
    end
  end

  defp parse_mastodon_date(_), do: DateTime.utc_now()

  # Truncate text to specified length
  defp truncate_text(text, max_length) when is_binary(text) do
    if String.length(text) > max_length do
      String.slice(text, 0, max_length) <> "..."
    else
      text
    end
  end

  # Generate random ID as fallback
  defp generate_random_id do
    :crypto.hash(:sha256, :rand.bytes(16)) |> Base.encode16(case: :lower)
  end
end
