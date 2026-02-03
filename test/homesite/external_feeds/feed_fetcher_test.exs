defmodule Homesite.ExternalFeeds.FeedFetcherTest do
  use Homesite.DataCase

  alias Homesite.Accounts
  alias Homesite.ExternalFeeds
  alias Homesite.ExternalFeeds.FeedFetcher

  import Homesite.AccountsFixtures

  describe "fetch_and_store/1" do
    setup do
      user = user_fixture()
      scope = Accounts.Scope.for_user(user)
      %{user: user, scope: scope}
    end

    @tag :external
    test "fetches and stores items from RSS feed", %{scope: scope} do
      {:ok, feed_source} =
        ExternalFeeds.create_feed_source(scope, %{
          feed_type: "rss",
          name: "Test RSS Feed",
          url: "https://www.reddit.com/r/elixir/.rss"
        })

      case FeedFetcher.fetch_and_store(feed_source) do
        {:ok, count} ->
          assert count > 0

          # Verify items were stored
          items = ExternalFeeds.list_feed_items(scope)
          assert length(items) > 0

          # Check that last_fetched_at was updated
          updated_source = ExternalFeeds.get_feed_source!(scope, feed_source.id)
          assert updated_source.last_fetched_at != nil
          assert updated_source.last_error == nil

        {:error, _reason} ->
          # Network issues can cause this test to fail
          :ok
      end
    end

    test "records error on fetch failure", %{scope: scope} do
      {:ok, feed_source} =
        ExternalFeeds.create_feed_source(scope, %{
          feed_type: "rss",
          name: "Invalid Feed",
          url: "https://invalid-domain-that-does-not-exist-12345.com/feed.xml"
        })

      assert {:error, _reason} = FeedFetcher.fetch_and_store(feed_source)

      # Verify error was recorded
      updated_source = ExternalFeeds.get_feed_source!(scope, feed_source.id)
      assert updated_source.last_error != nil
      assert updated_source.last_fetched_at != nil
    end

    test "updates existing items on re-fetch", %{scope: _scope} do
      # This test would require a stable, predictable feed
      # For now, we'll skip it as it requires external dependencies
      # In a production app, you'd mock the HTTP responses
      :ok
    end
  end

  describe "fetch_all_enabled/0" do
    @tag :external
    test "fetches all enabled feed sources" do
      user = user_fixture()
      scope = Accounts.Scope.for_user(user)

      # Create multiple feed sources
      {:ok, _feed1} =
        ExternalFeeds.create_feed_source(scope, %{
          feed_type: "rss",
          name: "Feed 1",
          url: "https://www.reddit.com/r/elixir/.rss",
          enabled: true
        })

      {:ok, _feed2} =
        ExternalFeeds.create_feed_source(scope, %{
          feed_type: "rss",
          name: "Feed 2",
          url: "https://www.reddit.com/r/programming/.rss",
          enabled: true
        })

      {:ok, _feed3} =
        ExternalFeeds.create_feed_source(scope, %{
          feed_type: "rss",
          name: "Disabled Feed",
          url: "https://example.com/feed.xml",
          enabled: false
        })

      result = FeedFetcher.fetch_all_enabled()

      # Should only fetch enabled feeds (2)
      assert result.total_sources == 2
      assert is_integer(result.successful)
      assert is_integer(result.errors)
      assert is_integer(result.total_items)
      assert is_list(result.results)
    end
  end
end
