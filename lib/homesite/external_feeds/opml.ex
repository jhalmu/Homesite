defmodule Homesite.ExternalFeeds.OPML do
  @moduledoc """
  OPML (Outline Processor Markup Language) import/export for feed sources.

  Provides functions to export feed subscriptions to OPML format and import
  OPML files from other RSS readers (Feedly, Inoreader, NewsBlur, etc.).

  OPML is an XML-based format standard for exchanging lists of web feeds.
  """

  import Ecto.Query, warn: false
  import SweetXml

  alias Homesite.Accounts.Scope
  alias Homesite.ExternalFeeds

  @opml_version "2.0"

  @doc """
  Exports user's feed sources to OPML format.

  Returns an XML string in OPML 2.0 format containing all feed sources
  for the given scope. The OPML includes:
  - Feed titles and URLs
  - Folder structure (via categories)
  - Feed type metadata

  ## Examples

      iex> export_to_opml(scope)
      {:ok, "<?xml version=\\"1.0\\" encoding=\\"UTF-8\\"?>\\n<opml version=\\"2.0\\">..."}
  """
  def export_to_opml(%Scope{} = scope) do
    feed_sources = ExternalFeeds.list_feed_sources(scope)
    folders = ExternalFeeds.list_feed_folders(scope)

    opml_content = build_opml(scope.user.email, feed_sources, folders)

    {:ok, opml_content}
  end

  @doc """
  Imports feed sources from OPML content.

  Parses OPML XML and creates feed sources for the given scope.
  Supports both flat and hierarchical (folder) structures.

  Returns:
  - `{:ok, %{imported: count, errors: [...]}}` on success
  - `{:error, reason}` on parse failure

  ## Options
    * `:create_folders` - Create folders from OPML categories (default: true)
    * `:skip_duplicates` - Skip feeds with duplicate URLs (default: true)

  ## Examples

      iex> opml = ~s[<?xml version="1.0"?><opml version="2.0">...</opml>]
      iex> import_from_opml(scope, opml)
      {:ok, %{imported: 15, skipped: 2, errors: []}}

      iex> import_from_opml(scope, "invalid xml")
      {:error, "Failed to parse OPML: ..."}
  """
  def import_from_opml(%Scope{} = scope, opml_content, opts \\ []) do
    create_folders = Keyword.get(opts, :create_folders, true)
    skip_duplicates = Keyword.get(opts, :skip_duplicates, true)

    with {:ok, parsed} <- parse_opml(opml_content),
         {:ok, result} <- import_feeds(scope, parsed, create_folders, skip_duplicates) do
      {:ok, result}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Private helpers

  defp build_opml(user_email, feed_sources, folders) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()

    feeds_by_folder = Enum.group_by(feed_sources, & &1.folder_id)

    # Build folder outlines
    folder_outlines =
      folders
      |> Enum.sort_by(& &1.display_order)
      |> Enum.map(fn folder ->
        folder_feeds = Map.get(feeds_by_folder, folder.id, [])
        build_folder_outline(folder, folder_feeds)
      end)

    # Build top-level feeds (no folder)
    top_level_feeds =
      feeds_by_folder
      |> Map.get(nil, [])
      |> Enum.map(&build_feed_outline/1)

    all_outlines = folder_outlines ++ top_level_feeds

    ~s"""
    <?xml version="1.0" encoding="UTF-8"?>
    <opml version="#{@opml_version}">
      <head>
        <title>Homesite Feed Subscriptions</title>
        <dateCreated>#{now}</dateCreated>
        <ownerEmail>#{escape_xml(user_email)}</ownerEmail>
      </head>
      <body>
    #{Enum.join(all_outlines, "\n")}
      </body>
    </opml>
    """
    |> String.trim()
  end

  defp build_folder_outline(folder, feeds) do
    feed_outlines =
      feeds
      |> Enum.sort_by(& &1.display_order)
      |> Enum.map(&build_feed_outline/1)
      |> Enum.map(&("      " <> &1))

    folder_title = escape_xml(folder.name)

    """
        <outline text="#{folder_title}" title="#{folder_title}">
    #{Enum.join(feed_outlines, "\n")}
        </outline>
    """
    |> String.trim_trailing()
  end

  defp build_feed_outline(feed) do
    title = escape_xml(feed.name)
    xml_url = escape_xml(feed.url)
    feed_type_attr = feed_type_to_opml_type(feed.feed_type)

    ~s[    <outline type="#{feed_type_attr}" text="#{title}" title="#{title}" xmlUrl="#{xml_url}"/>]
  end

  defp feed_type_to_opml_type("rss"), do: "rss"
  defp feed_type_to_opml_type("atom"), do: "atom"
  defp feed_type_to_opml_type(_), do: "rss"

  # Returns nil for empty strings, otherwise returns the string
  defp non_empty(""), do: nil
  defp non_empty(nil), do: nil
  defp non_empty(str) when is_binary(str), do: str

  defp escape_xml(nil), do: ""

  defp escape_xml(str) do
    str
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end

  defp parse_opml(opml_content) when is_binary(opml_content) do
    try do
      # Parse top-level outlines with their nested children
      top_level_outlines =
        opml_content
        |> xpath(~x"//body/outline"l,
          text: ~x"./@text"s,
          title: ~x"./@title"s,
          xml_url: ~x"./@xmlUrl"s,
          type: ~x"./@type"s,
          children: [
            ~x"./outline"l,
            text: ~x"./@text"s,
            title: ~x"./@title"s,
            xml_url: ~x"./@xmlUrl"s,
            type: ~x"./@type"s
          ]
        )

      # Flatten the hierarchy, assigning category from parent folder
      outlines = flatten_outlines(top_level_outlines)

      {:ok, outlines}
    rescue
      e ->
        {:error, "Failed to parse OPML: #{inspect(e)}"}
    catch
      :exit, reason ->
        {:error, "Failed to parse OPML: #{inspect(reason)}"}
    end
  end

  # Flatten hierarchical outlines, assigning category based on parent folder
  defp flatten_outlines(top_level_outlines) do
    Enum.flat_map(top_level_outlines, fn outline ->
      children = Map.get(outline, :children, [])
      xml_url = Map.get(outline, :xml_url)
      folder_name = non_empty(Map.get(outline, :text)) || non_empty(Map.get(outline, :title))

      if is_nil(xml_url) or xml_url == "" do
        # This is a folder - add category to children
        Enum.map(children, fn child ->
          Map.put(child, :category, folder_name || "")
        end)
      else
        # This is a direct feed (no folder)
        [Map.put(outline, :category, "") |> Map.delete(:children)]
      end
    end)
  end

  defp import_feeds(scope, outlines, create_folders, skip_duplicates) do
    existing_urls =
      if skip_duplicates do
        ExternalFeeds.list_feed_sources(scope)
        |> Enum.map(& &1.url)
        |> MapSet.new()
      else
        MapSet.new()
      end

    folder_cache = %{}
    imported = []
    skipped = []
    errors = []

    {imported, skipped, errors, _folder_cache} =
      Enum.reduce(outlines, {imported, skipped, errors, folder_cache}, fn outline,
                                                                          {imp, skip, err,
                                                                           folders} ->
        import_outline(scope, outline, existing_urls, create_folders, folders, imp, skip, err)
      end)

    {:ok,
     %{
       imported: length(imported),
       skipped: length(skipped),
       errors: errors
     }}
  end

  defp import_outline(
         scope,
         outline,
         existing_urls,
         create_folders,
         folder_cache,
         imported,
         skipped,
         errors
       ) do
    xml_url = Map.get(outline, :xml_url)
    # Handle empty strings from SweetXml (which returns "" for missing attributes)
    title =
      non_empty(Map.get(outline, :title)) || non_empty(Map.get(outline, :text)) || "Untitled Feed"

    category = Map.get(outline, :category)

    cond do
      # Skip if no xmlUrl (likely a folder/category outline)
      is_nil(xml_url) or xml_url == "" ->
        {imported, skipped, errors, folder_cache}

      # Skip if duplicate URL
      MapSet.member?(existing_urls, xml_url) ->
        {imported, [xml_url | skipped], errors, folder_cache}

      # Import feed
      true ->
        {folder_id, updated_cache} =
          if create_folders and category != nil and category != "" do
            get_or_create_folder(scope, category, folder_cache)
          else
            {nil, folder_cache}
          end

        attrs = %{
          name: title,
          url: xml_url,
          feed_type: detect_feed_type(xml_url),
          enabled: true,
          folder_id: folder_id
        }

        case ExternalFeeds.create_feed_source(scope, attrs) do
          {:ok, _feed} ->
            {[xml_url | imported], skipped, errors, updated_cache}

          {:error, changeset} ->
            error_msg = "#{title}: #{format_changeset_errors(changeset)}"
            {imported, skipped, [error_msg | errors], updated_cache}
        end
    end
  end

  defp get_or_create_folder(scope, category_name, folder_cache) do
    case Map.get(folder_cache, category_name) do
      nil ->
        # Try to find existing folder
        existing =
          ExternalFeeds.list_feed_folders(scope)
          |> Enum.find(fn f -> f.name == category_name end)

        case existing do
          nil ->
            # Create new folder
            case ExternalFeeds.create_feed_folder(scope, %{name: category_name}) do
              {:ok, folder} ->
                {folder.id, Map.put(folder_cache, category_name, folder.id)}

              {:error, _} ->
                {nil, folder_cache}
            end

          folder ->
            {folder.id, Map.put(folder_cache, category_name, folder.id)}
        end

      folder_id ->
        {folder_id, folder_cache}
    end
  end

  # Detect feed type from URL - for OPML imports, we only detect simple RSS-compatible types
  # Platform-specific types (youtube, bluesky, etc.) require additional fields (username)
  # that aren't available in OPML, so we import them as RSS feeds
  defp detect_feed_type(url) do
    cond do
      # Only detect RSS-compatible feed types that don't require extra fields
      String.contains?(url, "youtube.com/feeds") -> "rss"
      String.contains?(url, "reddit.com") and String.contains?(url, ".rss") -> "rss"
      String.contains?(url, "bsky.app") -> "rss"
      String.contains?(url, "atom") -> "atom"
      true -> "rss"
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map_join("; ", fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
  end
end
