defmodule Homesite.Workers.FeedCleanupWorkerTest do
  use Homesite.DataCase, async: true
  use Oban.Testing, repo: Homesite.Repo

  import Homesite.AccountsFixtures

  alias Homesite.Accounts.Scope
  alias Homesite.ExternalFeeds
  alias Homesite.Repo
  alias Homesite.Workers.FeedCleanupWorker

  describe "perform/1" do
    setup do
      user = user_fixture()
      scope = Scope.for_user(user)

      {:ok, feed_source} =
        ExternalFeeds.create_feed_source(scope, %{
          feed_type: "rss",
          name: "Test Feed",
          url: "https://example.com/feed.xml",
          enabled: true
        })

      %{scope: scope, feed_source: feed_source}
    end

    # Helper function to create a feed item
    defp create_feed_item(feed_source, attrs) do
      unique_id = System.unique_integer()

      default_attrs = %{
        title: "Test Item #{unique_id}",
        url: "https://example.com/item/#{unique_id}",
        content: "Test content",
        author_name: "Test Author",
        published_at: DateTime.utc_now(:second),
        guid: "test-guid-#{unique_id}",
        external_id: "ext-id-#{unique_id}"
      }

      ExternalFeeds.upsert_feed_item(feed_source.id, Map.merge(default_attrs, attrs))
    end

    test "deletes read items older than 30 days", %{scope: scope, feed_source: feed_source} do
      # Create old read item (35 days ago)
      {:ok, old_item} =
        create_feed_item(feed_source, %{
          published_at: DateTime.add(DateTime.utc_now(:second), -35, :day)
        })

      # Mark it as read 35 days ago
      ExternalFeeds.mark_item_as_read(scope, old_item.id)

      # Backdate the read_at timestamp
      Repo.get_by!(ExternalFeeds.FeedItemInteraction,
        user_id: scope.user.id,
        feed_item_id: old_item.id
      )
      |> Ecto.Changeset.change(read_at: DateTime.add(DateTime.utc_now(:second), -35, :day))
      |> Repo.update!()

      # Create recent read item (10 days ago) - should NOT be deleted
      {:ok, recent_item} =
        create_feed_item(feed_source, %{
          published_at: DateTime.add(DateTime.utc_now(:second), -10, :day)
        })

      ExternalFeeds.mark_item_as_read(scope, recent_item.id)

      assert {:ok, _result} = perform_job(FeedCleanupWorker, %{})

      # Old read item should be deleted
      refute Repo.get(ExternalFeeds.FeedItem, old_item.id)

      # Recent read item should still exist
      assert Repo.get(ExternalFeeds.FeedItem, recent_item.id)
    end

    test "deletes unread items older than 90 days", %{feed_source: feed_source} do
      # Create old unread item (95 days ago)
      {:ok, old_item} =
        create_feed_item(feed_source, %{
          published_at: DateTime.add(DateTime.utc_now(:second), -95, :day)
        })

      # Create recent unread item (30 days ago) - should NOT be deleted
      {:ok, recent_item} =
        create_feed_item(feed_source, %{
          published_at: DateTime.add(DateTime.utc_now(:second), -30, :day)
        })

      assert {:ok, _result} = perform_job(FeedCleanupWorker, %{})

      # Old unread item should be deleted
      refute Repo.get(ExternalFeeds.FeedItem, old_item.id)

      # Recent unread item should still exist
      assert Repo.get(ExternalFeeds.FeedItem, recent_item.id)
    end

    test "never deletes bookmarked items regardless of age", %{
      scope: scope,
      feed_source: feed_source
    } do
      # Create very old bookmarked item (120 days ago, read)
      {:ok, old_bookmarked} =
        create_feed_item(feed_source, %{
          published_at: DateTime.add(DateTime.utc_now(:second), -120, :day)
        })

      ExternalFeeds.mark_item_as_read(scope, old_bookmarked.id)
      ExternalFeeds.bookmark_item(scope, old_bookmarked.id)

      # Backdate the read_at
      Repo.get_by!(ExternalFeeds.FeedItemInteraction,
        user_id: scope.user.id,
        feed_item_id: old_bookmarked.id
      )
      |> Ecto.Changeset.change(read_at: DateTime.add(DateTime.utc_now(:second), -120, :day))
      |> Repo.update!()

      # Create old bookmarked unread item (100 days ago, never read)
      {:ok, old_unread_bookmarked} =
        create_feed_item(feed_source, %{
          published_at: DateTime.add(DateTime.utc_now(:second), -100, :day)
        })

      ExternalFeeds.bookmark_item(scope, old_unread_bookmarked.id)

      assert {:ok, _result} = perform_job(FeedCleanupWorker, %{})

      # Both bookmarked items should still exist
      assert Repo.get(ExternalFeeds.FeedItem, old_bookmarked.id)
      assert Repo.get(ExternalFeeds.FeedItem, old_unread_bookmarked.id)
    end

    test "handles items with no interactions", %{feed_source: feed_source} do
      # Create old item with no interaction record (100 days ago)
      {:ok, old_no_interaction} =
        create_feed_item(feed_source, %{
          published_at: DateTime.add(DateTime.utc_now(:second), -100, :day)
        })

      # Create recent item with no interaction (20 days ago)
      {:ok, recent_no_interaction} =
        create_feed_item(feed_source, %{
          published_at: DateTime.add(DateTime.utc_now(:second), -20, :day)
        })

      assert {:ok, _result} = perform_job(FeedCleanupWorker, %{})

      # Old item with no interaction should be deleted (counts as unread > 90 days)
      refute Repo.get(ExternalFeeds.FeedItem, old_no_interaction.id)

      # Recent item should still exist
      assert Repo.get(ExternalFeeds.FeedItem, recent_no_interaction.id)
    end

    test "returns count of deleted items", %{scope: scope, feed_source: feed_source} do
      # Create 3 old read items
      for _ <- 1..3 do
        {:ok, item} =
          create_feed_item(feed_source, %{
            published_at: DateTime.add(DateTime.utc_now(:second), -35, :day)
          })

        ExternalFeeds.mark_item_as_read(scope, item.id)

        Repo.get_by!(ExternalFeeds.FeedItemInteraction,
          user_id: scope.user.id,
          feed_item_id: item.id
        )
        |> Ecto.Changeset.change(read_at: DateTime.add(DateTime.utc_now(:second), -35, :day))
        |> Repo.update!()
      end

      # Create 2 old unread items
      for _ <- 1..2 do
        {:ok, _item} =
          create_feed_item(feed_source, %{
            published_at: DateTime.add(DateTime.utc_now(:second), -95, :day)
          })
      end

      {:ok, result} = perform_job(FeedCleanupWorker, %{})

      assert result.deleted_read == 3
      assert result.deleted_unread == 2
      assert result.total == 5
    end

    test "handles empty database gracefully" do
      # No items in database
      {:ok, result} = perform_job(FeedCleanupWorker, %{})

      assert result.deleted_read == 0
      assert result.deleted_unread == 0
      assert result.total == 0
    end
  end
end
