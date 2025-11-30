defmodule Mix.Tasks.Feeds.Refresh do
  @moduledoc """
  Manually trigger a refresh of all feed sources.

  This task will:
  1. Fetch all enabled feed sources
  2. Download and parse their RSS/Atom feeds
  3. Store feed items in the database

  ## Examples

      # Refresh all feeds
      mix feeds.refresh

      # Refresh a specific feed by ID
      mix feeds.refresh 123
  """
  @shortdoc "Refresh external feed sources"

  use Mix.Task

  alias Homesite.ExternalFeeds.FeedFetcher
  alias Homesite.Repo

  @requirements ["app.start"]

  @impl Mix.Task
  def run([]) do
    Mix.shell().info("🔄 Refreshing all enabled feed sources...")

    result = FeedFetcher.fetch_all_enabled()

    Mix.shell().info("""

    ✅ Feed refresh completed!

    📊 Results:
      - Total sources: #{result.total_sources}
      - Successful: #{result.successful}
      - Errors: #{result.errors}
      - Total items fetched: #{result.total_items}
    """)

    if result.errors > 0 do
      Mix.shell().info("⚠️  Some feeds failed to refresh. Check logs for details.")
    end
  end

  def run([feed_source_id]) do
    id = String.to_integer(feed_source_id)

    Mix.shell().info("🔄 Refreshing feed source ID #{id}...")

    case Repo.get(Homesite.ExternalFeeds.FeedSource, id) do
      nil ->
        Mix.shell().error("❌ Feed source #{id} not found")
        exit({:shutdown, 1})

      feed_source ->
        case FeedFetcher.fetch_and_store(feed_source) do
          {:ok, items_count} ->
            Mix.shell().info("""

            ✅ Feed refreshed successfully!

            📊 Results:
              - Feed: #{feed_source.name}
              - Items fetched: #{items_count}
            """)

          {:error, reason} ->
            Mix.shell().error("❌ Failed to refresh feed: #{inspect(reason)}")
            exit({:shutdown, 1})
        end
    end
  end
end
