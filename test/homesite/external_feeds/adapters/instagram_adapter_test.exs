defmodule Homesite.ExternalFeeds.Adapters.InstagramAdapterTest do
  use Homesite.DataCase

  alias Homesite.ExternalFeeds.Adapters.InstagramAdapter
  alias Homesite.ExternalFeeds.FeedSource

  describe "validate_source/1" do
    test "validates feed source with RSS bridge URL" do
      feed_source = %FeedSource{
        feed_type: "instagram",
        name: "Test Instagram",
        url: "https://rsshub.app/instagram/user/username",
        metadata: %{"username" => "username"}
      }

      assert :ok = InstagramAdapter.validate_source(feed_source)
    end

    test "validates feed source with rss in URL" do
      feed_source = %FeedSource{
        feed_type: "instagram",
        name: "Test Instagram",
        url: "https://rss.app/feeds/instagram/username.rss",
        metadata: %{"username" => "username"}
      }

      assert :ok = InstagramAdapter.validate_source(feed_source)
    end

    test "validates feed source with feed in URL" do
      feed_source = %FeedSource{
        feed_type: "instagram",
        name: "Test Instagram",
        url: "https://example.com/instagram/feed/username",
        metadata: %{"username" => "username"}
      }

      assert :ok = InstagramAdapter.validate_source(feed_source)
    end

    test "returns error when URL doesn't look like RSS bridge" do
      feed_source = %FeedSource{
        feed_type: "instagram",
        name: "Test Instagram",
        url: "https://instagram.com/username",
        metadata: %{"username" => "username"}
      }

      assert {:error, msg} = InstagramAdapter.validate_source(feed_source)
      assert msg =~ "bridge service"
    end

    test "returns error when URL is missing" do
      feed_source = %FeedSource{
        feed_type: "instagram",
        name: "Test Instagram",
        url: nil,
        metadata: %{"username" => "username"}
      }

      assert {:error, _} = InstagramAdapter.validate_source(feed_source)
    end

    test "returns error when URL is empty" do
      feed_source = %FeedSource{
        feed_type: "instagram",
        name: "Test Instagram",
        url: "",
        metadata: %{"username" => "username"}
      }

      assert {:error, _} = InstagramAdapter.validate_source(feed_source)
    end
  end

  describe "fetch_items/1" do
    test "handles invalid RSS bridge URL gracefully" do
      feed_source = %FeedSource{
        id: 1,
        feed_type: "instagram",
        name: "Test Instagram",
        url: "https://invalid-rss-bridge.com/feed.xml",
        metadata: %{"username" => "testuser"}
      }

      # Should return error since the bridge doesn't exist
      assert {:error, _reason} = InstagramAdapter.fetch_items(feed_source)
    end
  end
end
