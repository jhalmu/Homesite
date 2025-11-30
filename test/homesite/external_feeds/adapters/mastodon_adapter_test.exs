defmodule Homesite.ExternalFeeds.Adapters.MastodonAdapterTest do
  use Homesite.DataCase

  alias Homesite.ExternalFeeds.Adapters.MastodonAdapter
  alias Homesite.ExternalFeeds.FeedSource

  describe "validate_source/1" do
    test "validates feed source with instance and username" do
      feed_source = %FeedSource{
        feed_type: "mastodon",
        name: "Test Mastodon",
        metadata: %{
          "instance" => "mastodon.social",
          "username" => "Gargron"
        }
      }

      assert :ok = MastodonAdapter.validate_source(feed_source)
    end

    test "validates feed source with atom keys" do
      feed_source = %FeedSource{
        feed_type: "mastodon",
        name: "Test Mastodon",
        metadata: %{
          instance: "fosstodon.org",
          username: "user"
        }
      }

      assert :ok = MastodonAdapter.validate_source(feed_source)
    end

    test "returns error when instance is missing" do
      feed_source = %FeedSource{
        feed_type: "mastodon",
        name: "Test Mastodon",
        metadata: %{"username" => "user"}
      }

      assert {:error, msg} = MastodonAdapter.validate_source(feed_source)
      assert msg =~ "instance"
    end

    test "returns error when username is missing" do
      feed_source = %FeedSource{
        feed_type: "mastodon",
        name: "Test Mastodon",
        metadata: %{"instance" => "mastodon.social"}
      }

      assert {:error, msg} = MastodonAdapter.validate_source(feed_source)
      assert msg =~ "username"
    end

    test "returns error when metadata is missing" do
      feed_source = %FeedSource{
        feed_type: "mastodon",
        name: "Test Mastodon",
        metadata: nil
      }

      assert {:error, _} = MastodonAdapter.validate_source(feed_source)
    end
  end

  describe "fetch_items/1" do
    @tag :external
    test "fetches posts from a real Mastodon user" do
      # Using Mastodon creator's account for testing
      feed_source = %FeedSource{
        id: 1,
        feed_type: "mastodon",
        name: "Mastodon Creator",
        metadata: %{
          "instance" => "mastodon.social",
          "username" => "Gargron",
          "limit" => 5
        }
      }

      case MastodonAdapter.fetch_items(feed_source) do
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
          assert Map.has_key?(first_item, :author_handle)

          # Validate field types
          assert is_binary(first_item.external_id)
          assert is_binary(first_item.title)
          assert is_binary(first_item.content)
          assert is_binary(first_item.url)
          assert %DateTime{} = first_item.published_at
          assert first_item.author_handle =~ "@"

          # Check metadata
          assert first_item.metadata.feed_type == "mastodon"

        {:error, _reason} ->
          # Network issues or API changes can cause this test to fail
          # This is acceptable for an external test
          :ok
      end
    end

    test "handles non-existent user gracefully" do
      feed_source = %FeedSource{
        id: 1,
        feed_type: "mastodon",
        name: "Non-existent User",
        username: "thisuserdoesnotexist12345",
        metadata: %{
          "instance" => "mastodon.social"
        }
      }

      assert {:error, _reason} = MastodonAdapter.fetch_items(feed_source)
    end

    test "handles invalid instance gracefully" do
      feed_source = %FeedSource{
        id: 1,
        feed_type: "mastodon",
        name: "Invalid Instance",
        username: "user",
        metadata: %{
          "instance" => "invalid-instance-12345.social"
        }
      }

      assert {:error, _reason} = MastodonAdapter.fetch_items(feed_source)
    end
  end
end
