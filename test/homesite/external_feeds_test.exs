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

  describe "feed_item_interactions" do
    alias Homesite.ExternalFeeds.FeedItemInteraction

    import Homesite.AccountsFixtures

    @valid_item_attrs %{
      external_id: "interaction-test-1",
      title: "Interaction Test Post",
      content: "This is a test post for interactions.",
      url: "https://example.com/interaction-test",
      published_at: ~U[2025-12-02 10:00:00Z]
    }

    setup do
      user1 = user_fixture(email: "user1@example.com")
      user2 = user_fixture(email: "user2@example.com")
      scope1 = Accounts.Scope.for_user(user1)
      scope2 = Accounts.Scope.for_user(user2)

      # Create feed source for user1
      {:ok, feed_source1} =
        ExternalFeeds.create_feed_source(scope1, %{
          feed_type: "rss",
          name: "Test Feed 1",
          url: "https://example.com/feed.xml",
          enabled: true
        })

      # Create feed items for user1's source
      {:ok, item1} = ExternalFeeds.upsert_feed_item(feed_source1.id, @valid_item_attrs)

      {:ok, item2} =
        ExternalFeeds.upsert_feed_item(feed_source1.id, %{
          @valid_item_attrs
          | external_id: "interaction-test-2",
            published_at: DateTime.add(~U[2025-12-02 10:00:00Z], -3600, :second)
        })

      %{
        scope1: scope1,
        scope2: scope2,
        feed_source1: feed_source1,
        item1: item1,
        item2: item2
      }
    end

    test "list_feed_items_unified returns items with interaction data", %{scope1: scope1} do
      items = ExternalFeeds.list_feed_items_unified(scope1)

      assert length(items) == 2
      assert Enum.all?(items, fn item -> Map.has_key?(item, :feed_item) end)
      assert Enum.all?(items, fn item -> Map.has_key?(item, :interaction) end)
      # Initially, no interactions exist, so they should be nil
      assert Enum.all?(items, fn item -> is_nil(item.interaction) end)
    end

    test "list_feed_items_unified respects scope isolation", %{scope2: scope2} do
      # User2 has no feed sources, so should see no items
      items = ExternalFeeds.list_feed_items_unified(scope2)
      assert Enum.empty?(items)
    end

    test "mark_item_as_read creates interaction and marks as read", %{
      scope1: scope1,
      item1: item1
    } do
      {:ok, interaction} = ExternalFeeds.mark_item_as_read(scope1, item1.id)

      assert interaction.user_id == scope1.user.id
      assert interaction.feed_item_id == item1.id
      assert not is_nil(interaction.read_at)
      assert is_nil(interaction.bookmarked_at)
    end

    test "mark_item_as_unread removes read_at timestamp", %{scope1: scope1, item1: item1} do
      {:ok, _} = ExternalFeeds.mark_item_as_read(scope1, item1.id)
      {:ok, interaction} = ExternalFeeds.mark_item_as_unread(scope1, item1.id)

      assert is_nil(interaction.read_at)
    end

    test "bookmark_item toggles bookmark status", %{scope1: scope1, item1: item1} do
      # First bookmark
      {:ok, interaction1} = ExternalFeeds.bookmark_item(scope1, item1.id)
      assert not is_nil(interaction1.bookmarked_at)

      # Toggle off
      {:ok, interaction2} = ExternalFeeds.bookmark_item(scope1, item1.id)
      assert is_nil(interaction2.bookmarked_at)

      # Toggle back on
      {:ok, interaction3} = ExternalFeeds.bookmark_item(scope1, item1.id)
      assert not is_nil(interaction3.bookmarked_at)
    end

    test "get_unread_count returns correct count", %{scope1: scope1, item1: item1, item2: item2} do
      # Initially all items are unread
      assert ExternalFeeds.get_unread_count(scope1) == 2

      # Mark one as read
      {:ok, _} = ExternalFeeds.mark_item_as_read(scope1, item1.id)
      assert ExternalFeeds.get_unread_count(scope1) == 1

      # Mark another as read
      {:ok, _} = ExternalFeeds.mark_item_as_read(scope1, item2.id)
      assert ExternalFeeds.get_unread_count(scope1) == 0
    end

    test "list_feed_items_unified with unread_only filter", %{scope1: scope1, item1: item1} do
      # Mark one item as read
      {:ok, _} = ExternalFeeds.mark_item_as_read(scope1, item1.id)

      # List only unread items
      items = ExternalFeeds.list_feed_items_unified(scope1, unread_only: true)
      assert length(items) == 1
      assert hd(items).feed_item.id != item1.id
    end

    test "list_bookmarked_items returns only bookmarked items", %{scope1: scope1, item1: item1} do
      # Initially no bookmarks
      items = ExternalFeeds.list_bookmarked_items(scope1)
      assert Enum.empty?(items)

      # Bookmark one item
      {:ok, _} = ExternalFeeds.bookmark_item(scope1, item1.id)

      # Should return the bookmarked item
      items = ExternalFeeds.list_bookmarked_items(scope1)
      assert length(items) == 1
      assert hd(items).feed_item.id == item1.id
      assert not is_nil(hd(items).interaction.bookmarked_at)
    end

    test "mark_all_as_read_for_source marks all items as read", %{
      scope1: scope1,
      feed_source1: feed_source1
    } do
      # Initially all unread
      assert ExternalFeeds.get_unread_count(scope1) == 2

      # Mark all as read
      {:ok, count} = ExternalFeeds.mark_all_as_read_for_source(scope1, feed_source1.id)
      assert count == 2

      # Verify all are read
      assert ExternalFeeds.get_unread_count(scope1) == 0
    end

    test "archive_item archives a feed item", %{scope1: scope1, item1: item1} do
      {:ok, interaction} = ExternalFeeds.archive_item(scope1, item1.id)
      assert not is_nil(interaction.archived_at)
    end

    test "unarchive_item unarchives a feed item", %{scope1: scope1, item1: item1} do
      {:ok, _} = ExternalFeeds.archive_item(scope1, item1.id)
      {:ok, interaction} = ExternalFeeds.unarchive_item(scope1, item1.id)
      assert is_nil(interaction.archived_at)
    end

    test "user cannot interact with another user's feed items", %{
      scope2: scope2,
      item1: item1
    } do
      # User2 tries to mark User1's item as read
      # This should raise because get_feed_item! enforces scope ownership
      assert_raise MatchError, fn ->
        ExternalFeeds.mark_item_as_read(scope2, item1.id)
      end
    end

    test "pagination with limit and offset", %{scope1: scope1} do
      # Get first page (1 item)
      page1 = ExternalFeeds.list_feed_items_unified(scope1, limit: 1, offset: 0)
      assert length(page1) == 1

      # Get second page (1 item)
      page2 = ExternalFeeds.list_feed_items_unified(scope1, limit: 1, offset: 1)
      assert length(page2) == 1

      # Ensure they're different items
      assert hd(page1).feed_item.id != hd(page2).feed_item.id
    end

    test "list_feed_items_unified with filter by feed_source_id", %{
      scope1: scope1,
      feed_source1: feed_source1
    } do
      items =
        ExternalFeeds.list_feed_items_unified(scope1, feed_source_id: feed_source1.id)

      assert length(items) == 2
      assert Enum.all?(items, fn item -> item.feed_item.feed_source_id == feed_source1.id end)
    end
  end

  describe "feed_folders" do
    alias Homesite.ExternalFeeds.FeedFolder

    import Homesite.AccountsFixtures

    @valid_folder_attrs %{
      name: "Tech News",
      icon: "📰",
      color: "#3b82f6"
    }

    setup do
      user1 = user_fixture(email: "user1@example.com")
      user2 = user_fixture(email: "user2@example.com")
      scope1 = Accounts.Scope.for_user(user1)
      scope2 = Accounts.Scope.for_user(user2)

      %{scope1: scope1, scope2: scope2}
    end

    test "list_feed_folders/1 returns all folders for a user", %{scope1: scope1} do
      {:ok, folder1} = ExternalFeeds.create_feed_folder(scope1, @valid_folder_attrs)

      {:ok, folder2} =
        ExternalFeeds.create_feed_folder(scope1, %{@valid_folder_attrs | name: "Personal"})

      folders = ExternalFeeds.list_feed_folders(scope1)
      assert length(folders) == 2
      assert Enum.any?(folders, &(&1.id == folder1.id))
      assert Enum.any?(folders, &(&1.id == folder2.id))
    end

    test "list_feed_folders/1 respects scope isolation", %{scope1: scope1, scope2: scope2} do
      {:ok, _folder} = ExternalFeeds.create_feed_folder(scope1, @valid_folder_attrs)

      folders = ExternalFeeds.list_feed_folders(scope2)
      assert Enum.empty?(folders)
    end

    test "get_feed_folder!/2 returns the folder", %{scope1: scope1} do
      {:ok, folder} = ExternalFeeds.create_feed_folder(scope1, @valid_folder_attrs)
      assert ExternalFeeds.get_feed_folder!(scope1, folder.id).id == folder.id
    end

    test "get_feed_folder!/2 raises when accessing other user's folder", %{
      scope1: scope1,
      scope2: scope2
    } do
      {:ok, folder} = ExternalFeeds.create_feed_folder(scope1, @valid_folder_attrs)

      assert_raise MatchError, fn ->
        ExternalFeeds.get_feed_folder!(scope2, folder.id)
      end
    end

    test "create_feed_folder/2 with valid data creates a folder", %{scope1: scope1} do
      assert {:ok, %FeedFolder{} = folder} =
               ExternalFeeds.create_feed_folder(scope1, @valid_folder_attrs)

      assert folder.name == "Tech News"
      assert folder.icon == "📰"
      assert folder.color == "#3b82f6"
      assert folder.user_id == scope1.user.id
    end

    test "create_feed_folder/2 with invalid data returns error changeset", %{scope1: scope1} do
      assert {:error, %Ecto.Changeset{}} =
               ExternalFeeds.create_feed_folder(scope1, %{name: nil})
    end

    test "create_feed_folder/2 enforces unique names per user", %{scope1: scope1} do
      {:ok, _folder} = ExternalFeeds.create_feed_folder(scope1, @valid_folder_attrs)

      assert {:error, changeset} = ExternalFeeds.create_feed_folder(scope1, @valid_folder_attrs)
      assert "has already been taken" in errors_on(changeset).name
    end

    test "update_feed_folder/3 with valid data updates the folder", %{scope1: scope1} do
      {:ok, folder} = ExternalFeeds.create_feed_folder(scope1, @valid_folder_attrs)

      assert {:ok, %FeedFolder{} = updated} =
               ExternalFeeds.update_feed_folder(scope1, folder, %{name: "Updated Name"})

      assert updated.name == "Updated Name"
    end

    test "update_feed_folder/3 prevents updating other user's folder", %{
      scope1: scope1,
      scope2: scope2
    } do
      {:ok, folder} = ExternalFeeds.create_feed_folder(scope1, @valid_folder_attrs)

      assert_raise MatchError, fn ->
        ExternalFeeds.update_feed_folder(scope2, folder, %{name: "Hacked"})
      end
    end

    test "delete_feed_folder/2 deletes the folder", %{scope1: scope1} do
      {:ok, folder} = ExternalFeeds.create_feed_folder(scope1, @valid_folder_attrs)
      assert {:ok, %FeedFolder{}} = ExternalFeeds.delete_feed_folder(scope1, folder)

      assert_raise Ecto.NoResultsError, fn ->
        ExternalFeeds.get_feed_folder!(scope1, folder.id)
      end
    end

    test "delete_feed_folder/2 prevents deleting other user's folder", %{
      scope1: scope1,
      scope2: scope2
    } do
      {:ok, folder} = ExternalFeeds.create_feed_folder(scope1, @valid_folder_attrs)

      assert_raise MatchError, fn ->
        ExternalFeeds.delete_feed_folder(scope2, folder)
      end
    end

    test "assign_feed_to_folder/3 assigns feed source to folder", %{scope1: scope1} do
      {:ok, folder} = ExternalFeeds.create_feed_folder(scope1, @valid_folder_attrs)

      {:ok, feed_source} =
        ExternalFeeds.create_feed_source(scope1, %{
          feed_type: "rss",
          name: "Test Feed",
          url: "https://example.com/feed.xml"
        })

      {:ok, updated_feed} = ExternalFeeds.assign_feed_to_folder(scope1, feed_source.id, folder.id)
      assert updated_feed.folder_id == folder.id
    end

    test "assign_feed_to_folder/3 can unassign by passing nil", %{scope1: scope1} do
      {:ok, folder} = ExternalFeeds.create_feed_folder(scope1, @valid_folder_attrs)

      {:ok, feed_source} =
        ExternalFeeds.create_feed_source(scope1, %{
          feed_type: "rss",
          name: "Test Feed",
          url: "https://example.com/feed.xml",
          folder_id: folder.id
        })

      {:ok, updated_feed} = ExternalFeeds.assign_feed_to_folder(scope1, feed_source.id, nil)
      assert is_nil(updated_feed.folder_id)
    end

    test "list_feed_items_by_folder/3 returns items for folder's sources", %{scope1: scope1} do
      {:ok, folder} = ExternalFeeds.create_feed_folder(scope1, @valid_folder_attrs)

      {:ok, feed_source} =
        ExternalFeeds.create_feed_source(scope1, %{
          feed_type: "rss",
          name: "Test Feed",
          url: "https://example.com/feed.xml",
          folder_id: folder.id,
          enabled: true
        })

      {:ok, _item} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          external_id: "test-1",
          title: "Test Item",
          content: "Test content",
          url: "https://example.com/item1",
          published_at: DateTime.utc_now()
        })

      items = ExternalFeeds.list_feed_items_by_folder(scope1, folder.id)
      assert length(items) == 1
      assert hd(items).feed_item.feed_source_id == feed_source.id
    end

    test "list_feed_items_unified respects folder_id filter", %{scope1: scope1} do
      {:ok, folder} = ExternalFeeds.create_feed_folder(scope1, @valid_folder_attrs)

      {:ok, feed_source1} =
        ExternalFeeds.create_feed_source(scope1, %{
          feed_type: "rss",
          name: "In Folder",
          url: "https://example.com/feed1.xml",
          folder_id: folder.id,
          enabled: true
        })

      {:ok, feed_source2} =
        ExternalFeeds.create_feed_source(scope1, %{
          feed_type: "rss",
          name: "Not In Folder",
          url: "https://example.com/feed2.xml",
          enabled: true
        })

      {:ok, _item1} =
        ExternalFeeds.upsert_feed_item(feed_source1.id, %{
          external_id: "test-1",
          title: "In Folder",
          content: "Test",
          url: "https://example.com/item1",
          published_at: DateTime.utc_now()
        })

      {:ok, _item2} =
        ExternalFeeds.upsert_feed_item(feed_source2.id, %{
          external_id: "test-2",
          title: "Not In Folder",
          content: "Test",
          url: "https://example.com/item2",
          published_at: DateTime.utc_now()
        })

      # Filter by folder should only return items from folder's sources
      items = ExternalFeeds.list_feed_items_unified(scope1, folder_id: folder.id)
      assert length(items) == 1
      assert hd(items).feed_item.title == "In Folder"
    end
  end

  describe "search_feed_items/3" do
    import Homesite.AccountsFixtures

    setup do
      # Create two users for scope isolation testing
      user1 = user_fixture()
      user2 = user_fixture()
      scope1 = Accounts.Scope.for_user(user1)
      scope2 = Accounts.Scope.for_user(user2)

      # Create feed sources for user1
      {:ok, feed_source1} =
        ExternalFeeds.create_feed_source(scope1, %{
          feed_type: "rss",
          name: "Tech Blog",
          url: "https://techblog.com/feed.xml"
        })

      {:ok, feed_source2} =
        ExternalFeeds.create_feed_source(scope1, %{
          feed_type: "rss",
          name: "Elixir News",
          url: "https://elixirnews.com/feed.xml"
        })

      # Create feed source for user2
      {:ok, _feed_source3} =
        ExternalFeeds.create_feed_source(scope2, %{
          feed_type: "rss",
          name: "Other User Feed",
          url: "https://other.com/feed.xml"
        })

      %{
        scope1: scope1,
        scope2: scope2,
        feed_source1: feed_source1,
        feed_source2: feed_source2
      }
    end

    test "finds items matching search query in title", %{
      scope1: scope1,
      feed_source1: feed_source
    } do
      {:ok, _item1} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          external_id: "elixir-1",
          title: "Getting Started with Elixir",
          content: "Learn Phoenix framework",
          url: "https://example.com/elixir",
          published_at: DateTime.utc_now()
        })

      {:ok, _item2} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          external_id: "python-1",
          title: "Python Basics",
          content: "Some content",
          url: "https://example.com/python",
          published_at: DateTime.utc_now()
        })

      # Search for "elixir" should find the first item
      results = ExternalFeeds.search_feed_items(scope1, "elixir")
      assert length(results) == 1
      assert hd(results).feed_item.title == "Getting Started with Elixir"
    end

    test "finds items matching search query in content", %{
      scope1: scope1,
      feed_source1: feed_source
    } do
      {:ok, _item} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          external_id: "phoenix-1",
          title: "Web Development",
          content: "Phoenix is a web framework for Elixir",
          url: "https://example.com/phoenix",
          published_at: DateTime.utc_now()
        })

      # Search for "phoenix" should find item via content
      results = ExternalFeeds.search_feed_items(scope1, "phoenix")
      assert length(results) == 1
      assert hd(results).feed_item.title == "Web Development"
    end

    test "finds items matching search query in author_name", %{
      scope1: scope1,
      feed_source1: feed_source
    } do
      {:ok, _item} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          external_id: "author-1",
          title: "Blog Post",
          content: "Some content",
          author_name: "José Valim",
          url: "https://example.com/jose",
          published_at: DateTime.utc_now()
        })

      # Search for author name
      results = ExternalFeeds.search_feed_items(scope1, "Valim")
      assert length(results) == 1
      assert hd(results).feed_item.author_name == "José Valim"
    end

    test "ranks results by relevance", %{scope1: scope1, feed_source1: feed_source} do
      # Item with "elixir" in title (weight A) should rank higher
      {:ok, _item1} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          external_id: "title-match",
          title: "Elixir Programming Language",
          content: "Some other content",
          url: "https://example.com/1",
          published_at: ~U[2025-01-01 10:00:00Z]
        })

      # Item with "elixir" only in content (weight B) should rank lower
      {:ok, _item2} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          external_id: "content-match",
          title: "Web Development",
          content: "Using Elixir for backend",
          url: "https://example.com/2",
          published_at: ~U[2025-01-01 11:00:00Z]
        })

      results = ExternalFeeds.search_feed_items(scope1, "elixir")
      assert length(results) == 2

      # Higher ranked result should come first despite being older
      assert hd(results).feed_item.title == "Elixir Programming Language"
    end

    test "supports AND queries with multiple words", %{scope1: scope1, feed_source1: feed_source} do
      {:ok, _item1} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          external_id: "both",
          title: "Elixir Phoenix Tutorial",
          content: "Learn web development",
          url: "https://example.com/1",
          published_at: DateTime.utc_now()
        })

      {:ok, _item2} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          external_id: "elixir-only",
          title: "Elixir Basics",
          content: "Language fundamentals",
          url: "https://example.com/2",
          published_at: DateTime.utc_now()
        })

      # Search for "elixir phoenix" should only find item1
      results = ExternalFeeds.search_feed_items(scope1, "elixir phoenix")
      assert length(results) == 1
      assert hd(results).feed_item.title == "Elixir Phoenix Tutorial"
    end

    test "respects scope isolation", %{
      scope1: scope1,
      scope2: scope2,
      feed_source1: feed_source1
    } do
      {:ok, _item} =
        ExternalFeeds.upsert_feed_item(feed_source1.id, %{
          external_id: "user1-item",
          title: "User 1 Elixir Post",
          content: "Some content",
          url: "https://example.com/user1",
          published_at: DateTime.utc_now()
        })

      # User 1 can find their item
      results1 = ExternalFeeds.search_feed_items(scope1, "elixir")
      assert length(results1) == 1

      # User 2 cannot find user 1's item
      results2 = ExternalFeeds.search_feed_items(scope2, "elixir")
      assert results2 == []
    end

    test "supports limit and offset options", %{scope1: scope1, feed_source1: feed_source} do
      # Create 5 items
      for i <- 1..5 do
        {:ok, _} =
          ExternalFeeds.upsert_feed_item(feed_source.id, %{
            external_id: "item-#{i}",
            title: "Elixir Post #{i}",
            content: "Content",
            url: "https://example.com/#{i}",
            published_at: DateTime.add(DateTime.utc_now(), -i, :hour)
          })
      end

      # Limit to 2 results
      results = ExternalFeeds.search_feed_items(scope1, "elixir", limit: 2)
      assert length(results) == 2

      # Offset by 2
      results_offset = ExternalFeeds.search_feed_items(scope1, "elixir", limit: 2, offset: 2)
      assert length(results_offset) == 2
      assert hd(results_offset).feed_item.id != hd(results).feed_item.id
    end

    test "filters by unread_only option", %{scope1: scope1, feed_source1: feed_source} do
      {:ok, item1} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          external_id: "unread",
          title: "Unread Elixir Post",
          content: "Content",
          url: "https://example.com/unread",
          published_at: DateTime.utc_now()
        })

      {:ok, item2} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          external_id: "read",
          title: "Read Elixir Post",
          content: "Content",
          url: "https://example.com/read",
          published_at: DateTime.utc_now()
        })

      # Mark item2 as read
      {:ok, _} = ExternalFeeds.mark_item_as_read(scope1, item2.id)

      # Search with unread_only should only find item1
      results = ExternalFeeds.search_feed_items(scope1, "elixir", unread_only: true)
      assert length(results) == 1
      assert hd(results).feed_item.id == item1.id
    end

    test "filters by bookmarked_only option", %{scope1: scope1, feed_source1: feed_source} do
      {:ok, item1} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          external_id: "bookmarked",
          title: "Bookmarked Elixir Post",
          content: "Content",
          url: "https://example.com/bookmarked",
          published_at: DateTime.utc_now()
        })

      {:ok, _item2} =
        ExternalFeeds.upsert_feed_item(feed_source.id, %{
          external_id: "not-bookmarked",
          title: "Regular Elixir Post",
          content: "Content",
          url: "https://example.com/regular",
          published_at: DateTime.utc_now()
        })

      # Bookmark item1
      {:ok, _} = ExternalFeeds.bookmark_item(scope1, item1.id)

      # Search with bookmarked_only should only find item1
      results = ExternalFeeds.search_feed_items(scope1, "elixir", bookmarked_only: true)
      assert length(results) == 1
      assert hd(results).feed_item.id == item1.id
    end

    test "filters by feed_source_id option", %{
      scope1: scope1,
      feed_source1: feed_source1,
      feed_source2: feed_source2
    } do
      {:ok, _} =
        ExternalFeeds.upsert_feed_item(feed_source1.id, %{
          external_id: "source1",
          title: "Elixir from Source 1",
          content: "Content",
          url: "https://example.com/source1",
          published_at: DateTime.utc_now()
        })

      {:ok, _} =
        ExternalFeeds.upsert_feed_item(feed_source2.id, %{
          external_id: "source2",
          title: "Elixir from Source 2",
          content: "Content",
          url: "https://example.com/source2",
          published_at: DateTime.utc_now()
        })

      # Search filtered by feed_source1
      results =
        ExternalFeeds.search_feed_items(scope1, "elixir", feed_source_id: feed_source1.id)

      assert length(results) == 1
      assert hd(results).feed_item.title == "Elixir from Source 1"
    end

    test "returns empty list when no matches found", %{scope1: scope1} do
      results = ExternalFeeds.search_feed_items(scope1, "nonexistent query xyz123")
      assert results == []
    end
  end
end
