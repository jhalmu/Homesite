defmodule Homesite.ExternalFeeds.Adapters.TwitterAdapterTest do
  use Homesite.DataCase

  alias Homesite.ExternalFeeds.Adapters.TwitterAdapter
  alias Homesite.ExternalFeeds.FeedSource

  describe "validate_source/1" do
    test "validates feed source with RSS bridge URL (dormant mode)" do
      feed_source = %FeedSource{
        feed_type: "twitter",
        name: "Test Twitter",
        url: "https://nitter.net/elixirlang/rss",
        metadata: %{"username" => "elixirlang"}
      }

      assert :ok = TwitterAdapter.validate_source(feed_source)
    end

    test "validates feed source with rsshub URL" do
      feed_source = %FeedSource{
        feed_type: "twitter",
        name: "Test Twitter",
        url: "https://rsshub.app/twitter/user/elixirlang",
        metadata: %{"username" => "elixirlang"}
      }

      assert :ok = TwitterAdapter.validate_source(feed_source)
    end

    test "returns error when URL doesn't look like RSS bridge" do
      feed_source = %FeedSource{
        feed_type: "twitter",
        name: "Test Twitter",
        url: "https://twitter.com/elixirlang",
        metadata: %{"username" => "elixirlang"}
      }

      assert {:error, msg} = TwitterAdapter.validate_source(feed_source)
      assert msg =~ "bridge service"
    end

    test "returns error when URL is missing" do
      feed_source = %FeedSource{
        feed_type: "twitter",
        name: "Test Twitter",
        url: nil,
        metadata: %{"username" => "elixirlang"}
      }

      assert {:error, msg} = TwitterAdapter.validate_source(feed_source)
      assert msg =~ "DORMANT"
    end
  end

  describe "fetch_items/1" do
    test "handles invalid RSS bridge URL gracefully (dormant mode)" do
      feed_source = %FeedSource{
        id: 1,
        feed_type: "twitter",
        name: "Test Twitter",
        url: "https://invalid-nitter-instance.com/feed.rss",
        metadata: %{"username" => "testuser"}
      }

      # Should return error since the bridge doesn't exist
      assert {:error, _reason} = TwitterAdapter.fetch_items(feed_source)
    end
  end
end
