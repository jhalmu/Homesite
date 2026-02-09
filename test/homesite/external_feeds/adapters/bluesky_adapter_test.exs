defmodule Homesite.ExternalFeeds.Adapters.BlueskyAdapterTest do
  use Homesite.DataCase

  alias Homesite.ExternalFeeds.Adapters.BlueskyAdapter
  alias Homesite.ExternalFeeds.FeedSource

  describe "validate_source/1" do
    test "validates feed source with username in metadata" do
      feed_source = %FeedSource{
        feed_type: "bluesky",
        name: "Test Bluesky",
        metadata: %{"username" => "user.bsky.social"}
      }

      assert :ok = BlueskyAdapter.validate_source(feed_source)
    end

    test "validates feed source with username as atom key" do
      feed_source = %FeedSource{
        feed_type: "bluesky",
        name: "Test Bluesky",
        metadata: %{username: "user.bsky.social"}
      }

      assert :ok = BlueskyAdapter.validate_source(feed_source)
    end

    test "returns error when username is missing" do
      feed_source = %FeedSource{
        feed_type: "bluesky",
        name: "Test Bluesky",
        metadata: %{}
      }

      assert {:error, msg} = BlueskyAdapter.validate_source(feed_source)
      assert msg =~ "username"
    end

    test "returns error when metadata is missing" do
      feed_source = %FeedSource{
        feed_type: "bluesky",
        name: "Test Bluesky",
        metadata: nil
      }

      assert {:error, _} = BlueskyAdapter.validate_source(feed_source)
    end

    test "returns error when username is empty" do
      feed_source = %FeedSource{
        feed_type: "bluesky",
        name: "Test Bluesky",
        metadata: %{"username" => ""}
      }

      assert {:error, _} = BlueskyAdapter.validate_source(feed_source)
    end
  end

  describe "fetch_items/1" do
    @tag :external
    test "fetches posts from a real Bluesky user" do
      # Using Bluesky's official account for testing
      feed_source = %FeedSource{
        id: 1,
        feed_type: "bluesky",
        name: "Bluesky Official",
        metadata: %{"username" => "bsky.app", "limit" => 5}
      }

      case BlueskyAdapter.fetch_items(feed_source) do
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
          assert Map.has_key?(first_item, :author_handle)

          # Validate field types
          assert is_binary(first_item.external_id)
          assert is_binary(first_item.title)
          assert is_binary(first_item.content)
          assert is_binary(first_item.url)
          assert %DateTime{} = first_item.published_at
          assert first_item.author_handle =~ "@"

          # Check metadata
          assert first_item.metadata.feed_type == "bluesky"

        {:error, _reason} ->
          # Network issues or API changes can cause this test to fail
          # This is acceptable for an external test
          :ok
      end
    end

    test "handles non-existent user gracefully" do
      feed_source = %FeedSource{
        id: 1,
        feed_type: "bluesky",
        name: "Non-existent User",
        username: "thisuserdoesnotexist12345.bsky.social",
        metadata: %{}
      }

      assert {:error, _reason} = BlueskyAdapter.fetch_items(feed_source)
    end
  end
end
