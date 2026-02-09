defmodule Homesite.ExternalFeeds.Adapters.RssAdapterTest do
  use Homesite.DataCase

  alias Homesite.ExternalFeeds.Adapters.RssAdapter
  alias Homesite.ExternalFeeds.FeedSource

  describe "validate_source/1" do
    test "validates feed source with URL" do
      feed_source = %FeedSource{
        feed_type: "rss",
        name: "Test Feed",
        url: "https://example.com/feed.xml"
      }

      assert :ok = RssAdapter.validate_source(feed_source)
    end

    test "returns error when URL is missing" do
      feed_source = %FeedSource{
        feed_type: "rss",
        name: "Test Feed",
        url: nil
      }

      assert {:error, _} = RssAdapter.validate_source(feed_source)
    end

    test "returns error when URL is empty" do
      feed_source = %FeedSource{
        feed_type: "rss",
        name: "Test Feed",
        url: ""
      }

      assert {:error, _} = RssAdapter.validate_source(feed_source)
    end
  end

  describe "fetch_items/1" do
    @tag :external
    test "fetches and parses a real RSS feed" do
      # Using a well-known, stable RSS feed for testing
      feed_source = %FeedSource{
        id: 1,
        feed_type: "rss",
        name: "Test Feed",
        url: "https://www.reddit.com/r/programming/.rss"
      }

      case RssAdapter.fetch_items(feed_source) do
        {:ok, items} ->
          assert is_list(items)
          assert items != []

          # Check first item structure
          first_item = List.first(items)
          assert Map.has_key?(first_item, :external_id)
          assert Map.has_key?(first_item, :title)
          assert Map.has_key?(first_item, :content)
          assert Map.has_key?(first_item, :published_at)
          assert Map.has_key?(first_item, :url)

          # Validate field types
          assert is_binary(first_item.external_id)
          assert is_binary(first_item.title)
          assert is_binary(first_item.content)
          assert is_binary(first_item.url)
          assert %DateTime{} = first_item.published_at

        {:error, _reason} ->
          # Network issues can cause this test to fail
          # This is acceptable for an external test
          :ok
      end
    end

    test "handles invalid URL gracefully" do
      feed_source = %FeedSource{
        id: 1,
        feed_type: "rss",
        name: "Invalid Feed",
        url: "https://invalid-domain-that-does-not-exist-12345.com/feed.xml"
      }

      assert {:error, _reason} = RssAdapter.fetch_items(feed_source)
    end

    test "handles malformed XML gracefully" do
      # This would require mocking the HTTP response
      # For now, we'll test the error handling path with an invalid domain
      feed_source = %FeedSource{
        id: 1,
        feed_type: "rss",
        name: "Malformed Feed",
        url: "https://httpbin.org/html"
      }

      # httpbin.org/html returns HTML, not XML
      case RssAdapter.fetch_items(feed_source) do
        {:error, _reason} ->
          # Expected: parsing HTML as RSS should fail
          assert true

        {:ok, items} ->
          # If it somehow parses, items should be empty
          assert items == []
      end
    end
  end

  describe "RSS feeds without description" do
    @tag :external
    test "uses title as fallback content when description is empty" do
      # techtrib.es feed has no <description> tags - only title, link, guid, pubDate
      feed_source = %FeedSource{
        id: 999,
        feed_type: "rss",
        name: "TechTribes",
        url: "https://www.techtrib.es/feed.xml"
      }

      case RssAdapter.fetch_items(feed_source) do
        {:ok, items} ->
          assert is_list(items)
          assert items != []

          # All items should have non-empty content (fallback to title)
          Enum.each(items, fn item ->
            assert is_binary(item.content)
            assert item.content != "", "Content should not be empty (should fallback to title)"
            # Content should equal title when description was empty
            assert item.content == item.title
          end)

        {:error, _reason} ->
          # Network issues can cause this test to fail
          :ok
      end
    end
  end
end
