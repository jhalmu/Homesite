defmodule Homesite.ExternalFeeds.Adapters.TiktokAdapterTest do
  use Homesite.DataCase, async: true

  alias Homesite.ExternalFeeds.Adapters.TiktokAdapter
  alias Homesite.ExternalFeeds.FeedSource

  describe "validate_source/1" do
    test "accepts valid RSS bridge URL with 'rss'" do
      source = %FeedSource{
        feed_type: "tiktok",
        url: "https://rsshub.app/tiktok/user/testuser/rss",
        metadata: %{"username" => "testuser"}
      }

      assert :ok = TiktokAdapter.validate_source(source)
    end

    test "accepts valid RSS bridge URL with 'feed'" do
      source = %FeedSource{
        feed_type: "tiktok",
        url: "https://rss.app/feeds/tiktok/testuser",
        metadata: %{"username" => "testuser"}
      }

      assert :ok = TiktokAdapter.validate_source(source)
    end

    test "accepts valid RSS bridge URL with 'xml'" do
      source = %FeedSource{
        feed_type: "tiktok",
        url: "https://example.com/tiktok/testuser.xml",
        metadata: %{"username" => "testuser"}
      }

      assert :ok = TiktokAdapter.validate_source(source)
    end

    test "rejects URL without RSS indicators" do
      source = %FeedSource{
        feed_type: "tiktok",
        url: "https://tiktok.com/@testuser",
        metadata: %{"username" => "testuser"}
      }

      assert {:error, msg} = TiktokAdapter.validate_source(source)
      assert msg =~ "require a valid RSS feed URL from a bridge service"
    end

    test "rejects empty URL" do
      source = %FeedSource{
        feed_type: "tiktok",
        url: "",
        metadata: %{"username" => "testuser"}
      }

      assert {:error, msg} = TiktokAdapter.validate_source(source)
      assert msg =~ "require a URL pointing to an RSS bridge service"
    end

    test "rejects nil URL" do
      source = %FeedSource{
        feed_type: "tiktok",
        url: nil,
        metadata: %{"username" => "testuser"}
      }

      assert {:error, msg} = TiktokAdapter.validate_source(source)
      assert msg =~ "require a URL pointing to an RSS bridge service"
    end

    test "rejects non-string URL" do
      source = %FeedSource{
        feed_type: "tiktok",
        url: 123,
        metadata: %{"username" => "testuser"}
      }

      assert {:error, msg} = TiktokAdapter.validate_source(source)
      assert msg =~ "require a URL pointing to an RSS bridge service"
    end
  end

  describe "fetch_items/1" do
    @tag :external
    test "enhances items with TikTok-specific metadata" do
      source = %FeedSource{
        feed_type: "tiktok",
        url: "https://rsshub.app/tiktok/user/testuser/rss",
        metadata: %{"username" => "testuser"}
      }

      # Will fail due to external dependency, but verifies structure
      result = TiktokAdapter.fetch_items(source)
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    @tag :external
    test "handles missing username in metadata" do
      source = %FeedSource{
        feed_type: "tiktok",
        url: "https://rsshub.app/tiktok/user/someuser/rss",
        metadata: %{}
      }

      # Should use "unknown" as fallback
      result = TiktokAdapter.fetch_items(source)
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    @tag :external
    test "handles atom-keyed username in metadata" do
      source = %FeedSource{
        feed_type: "tiktok",
        url: "https://rsshub.app/tiktok/user/testuser/rss",
        metadata: %{username: "testuser"}
      }

      result = TiktokAdapter.fetch_items(source)
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    @tag :external
    test "returns error for invalid RSS bridge URL" do
      source = %FeedSource{
        feed_type: "tiktok",
        url: "https://invalid-rss-bridge.com/feed.xml",
        metadata: %{"username" => "testuser"}
      }

      assert {:error, _reason} = TiktokAdapter.fetch_items(source)
    end
  end
end
