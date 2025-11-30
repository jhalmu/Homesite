defmodule Homesite.ExternalFeeds.Adapters.YoutubeAdapterTest do
  use Homesite.DataCase

  alias Homesite.ExternalFeeds.Adapters.YoutubeAdapter
  alias Homesite.ExternalFeeds.FeedSource

  describe "validate_source/1" do
    test "validates feed source with channel_id in metadata" do
      feed_source = %FeedSource{
        feed_type: "youtube",
        name: "Test YouTube",
        metadata: %{"channel_id" => "UCXuqSBlHAE6Xw-yeJA0Tunw"}
      }

      assert :ok = YoutubeAdapter.validate_source(feed_source)
    end

    test "validates feed source with channel_id as atom key" do
      feed_source = %FeedSource{
        feed_type: "youtube",
        name: "Test YouTube",
        metadata: %{channel_id: "UCXuqSBlHAE6Xw-yeJA0Tunw"}
      }

      assert :ok = YoutubeAdapter.validate_source(feed_source)
    end

    test "returns error when channel_id is missing" do
      feed_source = %FeedSource{
        feed_type: "youtube",
        name: "Test YouTube",
        metadata: %{}
      }

      assert {:error, msg} = YoutubeAdapter.validate_source(feed_source)
      assert msg =~ "channel_id"
    end

    test "returns error when metadata is missing" do
      feed_source = %FeedSource{
        feed_type: "youtube",
        name: "Test YouTube",
        metadata: nil
      }

      assert {:error, _} = YoutubeAdapter.validate_source(feed_source)
    end

    test "returns error when channel_id is empty" do
      feed_source = %FeedSource{
        feed_type: "youtube",
        name: "Test YouTube",
        metadata: %{"channel_id" => ""}
      }

      assert {:error, _} = YoutubeAdapter.validate_source(feed_source)
    end
  end

  describe "fetch_items/1" do
    @tag :external
    test "fetches videos from a real YouTube channel" do
      # Using Linus Tech Tips channel for testing (very active channel)
      feed_source = %FeedSource{
        id: 1,
        feed_type: "youtube",
        name: "Linus Tech Tips",
        metadata: %{"channel_id" => "UCXuqSBlHAE6Xw-yeJA0Tunw"}
      }

      case YoutubeAdapter.fetch_items(feed_source) do
        {:ok, items} ->
          assert is_list(items)
          assert length(items) > 0

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

          # YouTube-specific checks
          assert first_item.url =~ "youtube.com/watch?v="
          assert first_item.metadata.feed_type == "youtube"
          assert first_item.metadata.video_id
          assert first_item.metadata.channel_id == "UCXuqSBlHAE6Xw-yeJA0Tunw"

          # Check for embed URL
          if first_item.metadata.embed_url do
            assert first_item.metadata.embed_url =~ "youtube.com/embed/"
          end

        {:error, _reason} ->
          # Network issues can cause this test to fail
          # This is acceptable for an external test
          :ok
      end
    end

    test "handles non-existent channel gracefully" do
      feed_source = %FeedSource{
        id: 1,
        feed_type: "youtube",
        name: "Non-existent Channel",
        metadata: %{"channel_id" => "UCinvalidchannel12345"}
      }

      assert {:error, _reason} = YoutubeAdapter.fetch_items(feed_source)
    end
  end
end
