defmodule Homesite.ExternalFeedsTest do
  use Homesite.DataCase

  alias Homesite.ExternalFeeds
  alias Homesite.Accounts

  describe "feed_sources" do
    alias Homesite.ExternalFeeds.FeedSource

    import Homesite.AccountsFixtures

    @valid_rss_attrs %{
      feed_type: "rss",
      name: "Tech Blog",
      url: "https://example.com/feed.xml",
      enabled: true
    }
    @valid_bluesky_attrs %{
      feed_type: "bluesky",
      name: "My Bluesky",
      username: "user.bsky.social",
      enabled: true
    }
    @update_attrs %{
      name: "Updated Feed Name",
      enabled: false
    }
    @invalid_attrs %{feed_type: nil, name: nil}

    setup do
      user = user_fixture()
      scope = Accounts.Scope.for_user(user)
      %{user: user, scope: scope}
    end

    test "list_feed_sources/1 returns all feed sources for a user", %{scope: scope} do
      {:ok, feed1} = ExternalFeeds.create_feed_source(scope, @valid_rss_attrs)
      {:ok, feed2} = ExternalFeeds.create_feed_source(scope, @valid_bluesky_attrs)

      feed_sources = ExternalFeeds.list_feed_sources(scope)
      assert length(feed_sources) == 2
      assert Enum.any?(feed_sources, &(&1.id == feed1.id))
      assert Enum.any?(feed_sources, &(&1.id == feed2.id))
    end

    test "list_feed_sources/1 does not return other users' feed sources", %{scope: scope} do
      other_user = user_fixture(email: "other@example.com")
      other_scope = Accounts.Scope.for_user(other_user)

      {:ok, _feed} = ExternalFeeds.create_feed_source(other_scope, @valid_rss_attrs)

      feed_sources = ExternalFeeds.list_feed_sources(scope)
      assert feed_sources == []
    end

    test "list_enabled_feed_sources/1 returns only enabled feed sources", %{scope: scope} do
      {:ok, enabled} = ExternalFeeds.create_feed_source(scope, @valid_rss_attrs)

      {:ok, _disabled} =
        ExternalFeeds.create_feed_source(scope, %{@valid_bluesky_attrs | enabled: false})

      feed_sources = ExternalFeeds.list_enabled_feed_sources(scope)
      assert length(feed_sources) == 1
      assert hd(feed_sources).id == enabled.id
    end

    test "get_feed_source!/2 returns the feed source with given id", %{scope: scope} do
      {:ok, feed} = ExternalFeeds.create_feed_source(scope, @valid_rss_attrs)
      assert ExternalFeeds.get_feed_source!(scope, feed.id).id == feed.id
    end

    test "get_feed_source!/2 raises when accessing other user's feed source", %{scope: scope} do
      other_user = user_fixture(email: "other@example.com")
      other_scope = Accounts.Scope.for_user(other_user)

      {:ok, feed} = ExternalFeeds.create_feed_source(other_scope, @valid_rss_attrs)

      assert_raise MatchError, fn ->
        ExternalFeeds.get_feed_source!(scope, feed.id)
      end
    end

    test "create_feed_source/2 with valid data creates a feed source", %{scope: scope} do
      assert {:ok, %FeedSource{} = feed} =
               ExternalFeeds.create_feed_source(scope, @valid_rss_attrs)

      assert feed.feed_type == "rss"
      assert feed.name == "Tech Blog"
      assert feed.url == "https://example.com/feed.xml"
      assert feed.enabled == true
      assert feed.user_id == scope.user.id
      assert feed.icon == "📰"
    end

    test "create_feed_source/2 sets default icon based on feed type", %{scope: scope} do
      assert {:ok, %FeedSource{} = feed} =
               ExternalFeeds.create_feed_source(scope, @valid_bluesky_attrs)

      assert feed.icon == "🦋"
    end

    test "create_feed_source/2 with invalid data returns error changeset", %{scope: scope} do
      assert {:error, %Ecto.Changeset{}} =
               ExternalFeeds.create_feed_source(scope, @invalid_attrs)
    end

    test "create_feed_source/2 validates RSS feed has URL", %{scope: scope} do
      invalid = %{@valid_rss_attrs | url: nil}
      assert {:error, changeset} = ExternalFeeds.create_feed_source(scope, invalid)
      assert "can't be blank" in errors_on(changeset).url
    end

    test "create_feed_source/2 validates Bluesky feed has username", %{scope: scope} do
      invalid = %{@valid_bluesky_attrs | username: nil}
      assert {:error, changeset} = ExternalFeeds.create_feed_source(scope, invalid)
      assert "can't be blank" in errors_on(changeset).username
    end

    test "update_feed_source/3 with valid data updates the feed source", %{scope: scope} do
      {:ok, feed} = ExternalFeeds.create_feed_source(scope, @valid_rss_attrs)

      assert {:ok, %FeedSource{} = updated} =
               ExternalFeeds.update_feed_source(scope, feed, @update_attrs)

      assert updated.name == "Updated Feed Name"
      assert updated.enabled == false
    end

    test "update_feed_source/3 prevents updating other user's feed source", %{scope: scope} do
      other_user = user_fixture(email: "other@example.com")
      other_scope = Accounts.Scope.for_user(other_user)

      {:ok, feed} = ExternalFeeds.create_feed_source(other_scope, @valid_rss_attrs)

      assert_raise MatchError, fn ->
        ExternalFeeds.update_feed_source(scope, feed, @update_attrs)
      end
    end

    test "delete_feed_source/2 deletes the feed source", %{scope: scope} do
      {:ok, feed} = ExternalFeeds.create_feed_source(scope, @valid_rss_attrs)
      assert {:ok, %FeedSource{}} = ExternalFeeds.delete_feed_source(scope, feed)
      assert_raise Ecto.NoResultsError, fn -> ExternalFeeds.get_feed_source!(scope, feed.id) end
    end

    test "delete_feed_source/2 prevents deleting other user's feed source", %{scope: scope} do
      other_user = user_fixture(email: "other@example.com")
      other_scope = Accounts.Scope.for_user(other_user)

      {:ok, feed} = ExternalFeeds.create_feed_source(other_scope, @valid_rss_attrs)

      assert_raise MatchError, fn ->
        ExternalFeeds.delete_feed_source(scope, feed)
      end
    end

    test "change_feed_source/1 returns a feed source changeset", %{scope: scope} do
      {:ok, feed} = ExternalFeeds.create_feed_source(scope, @valid_rss_attrs)
      assert %Ecto.Changeset{} = ExternalFeeds.change_feed_source(feed)
    end
  end

  describe "feed_items" do
    alias Homesite.ExternalFeeds.FeedItem

    import Homesite.AccountsFixtures

    @valid_item_attrs %{
      external_id: "post-123",
      title: "Great Post",
      content: "This is a great post about tech.",
      author_name: "John Doe",
      author_handle: "@johndoe",
      published_at: ~U[2025-11-28 10:00:00Z],
      url: "https://example.com/post/123"
    }

    setup do
      user = user_fixture()
      scope = Accounts.Scope.for_user(user)

      {:ok, feed_source} =
        ExternalFeeds.create_feed_source(scope, %{
          feed_type: "rss",
          name: "Test Feed",
          url: "https://example.com/feed.xml"
        })

      %{user: user, scope: scope, feed_source: feed_source}
    end

    test "list_feed_items/2 returns feed items for user's feed sources", %{
      scope: scope,
      feed_source: feed_source
    } do
      {:ok, item1} = ExternalFeeds.upsert_feed_item(feed_source.id, @valid_item_attrs)

      {:ok, item2} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          @valid_item_attrs
          | external_id: "post-456"
        })

      items = ExternalFeeds.list_feed_items(scope)
      assert length(items) == 2
      assert Enum.any?(items, &(&1.id == item1.id))
      assert Enum.any?(items, &(&1.id == item2.id))
    end

    test "list_feed_items/2 does not return items from disabled feed sources", %{
      scope: scope,
      feed_source: feed_source
    } do
      {:ok, _item} = ExternalFeeds.upsert_feed_item(feed_source.id, @valid_item_attrs)

      # Disable the feed source
      ExternalFeeds.update_feed_source(scope, feed_source, %{enabled: false})

      items = ExternalFeeds.list_feed_items(scope)
      assert items == []
    end

    test "list_feed_items/2 respects limit option", %{scope: scope, feed_source: feed_source} do
      # Create 10 items
      for i <- 1..10 do
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          @valid_item_attrs
          | external_id: "post-#{i}"
        })
      end

      items = ExternalFeeds.list_feed_items(scope, limit: 5)
      assert length(items) == 5
    end

    test "upsert_feed_item/2 creates a new feed item", %{feed_source: feed_source} do
      assert {:ok, %FeedItem{} = item} =
               ExternalFeeds.upsert_feed_item(feed_source.id, @valid_item_attrs)

      assert item.external_id == "post-123"
      assert item.title == "Great Post"
      assert item.content == "This is a great post about tech."
      assert item.feed_source_id == feed_source.id
    end

    test "upsert_feed_item/2 updates existing item with same external_id", %{
      feed_source: feed_source
    } do
      {:ok, item1} = ExternalFeeds.upsert_feed_item(feed_source.id, @valid_item_attrs)

      updated_attrs = %{@valid_item_attrs | title: "Updated Title"}
      {:ok, item2} = ExternalFeeds.upsert_feed_item(feed_source.id, updated_attrs)

      assert item1.id == item2.id
      assert item2.title == "Updated Title"
    end

    test "delete_old_feed_items/1 deletes items older than specified days" do
      user = user_fixture()
      scope = Accounts.Scope.for_user(user)

      {:ok, feed_source} =
        ExternalFeeds.create_feed_source(scope, %{
          feed_type: "rss",
          name: "Test Feed",
          url: "https://example.com/feed.xml"
        })

      old_date = DateTime.add(DateTime.utc_now(), -40 * 24 * 60 * 60, :second)

      {:ok, _old_item} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          @valid_item_attrs
          | published_at: old_date
        })

      {:ok, _new_item} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          @valid_item_attrs
          | external_id: "post-456"
        })

      {deleted_count, _} = ExternalFeeds.delete_old_feed_items(30)
      assert deleted_count == 1

      items = ExternalFeeds.list_feed_items(scope)
      assert length(items) == 1
    end
  end
end
