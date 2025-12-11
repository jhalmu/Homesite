defmodule Homesite.NotificationsTest do
  use Homesite.DataCase, async: true

  alias Homesite.Notifications
  alias Homesite.Accounts.Scope

  import Homesite.AccountsFixtures

  describe "create_notification/4" do
    test "creates a notification" do
      user = user_fixture()
      actor = user_fixture()

      assert {:ok, notification} =
               Notifications.create_notification(user.id, "new_follower", actor.id)

      assert notification.user_id == user.id
      assert notification.type == "new_follower"
      assert notification.actor_id == actor.id
      assert is_nil(notification.read_at)
    end

    test "creates notification with data" do
      user = user_fixture()

      assert {:ok, notification} =
               Notifications.create_notification(user.id, "post_published", nil, %{
                 "post_title" => "Test Post"
               })

      assert notification.data["post_title"] == "Test Post"
    end

    test "creates notification without actor" do
      user = user_fixture()

      assert {:ok, notification} = Notifications.create_notification(user.id, "new_follower")
      assert is_nil(notification.actor_id)
    end
  end

  describe "notify_new_follower/2" do
    test "creates new_follower notification" do
      followed_user = user_fixture()
      follower_user = user_fixture()

      assert {:ok, notification} =
               Notifications.notify_new_follower(followed_user.id, follower_user)

      assert notification.type == "new_follower"
      assert notification.user_id == followed_user.id
      assert notification.actor_id == follower_user.id
      assert notification.data["follower_email"] == follower_user.email
    end
  end

  describe "list_notifications/2" do
    test "returns notifications for the user" do
      user = user_fixture()
      scope = Scope.for_user(user)
      actor = user_fixture()

      {:ok, n1} = Notifications.create_notification(user.id, "new_follower", actor.id)
      {:ok, n2} = Notifications.create_notification(user.id, "new_follower", actor.id)

      notifications = Notifications.list_notifications(scope)

      assert length(notifications) == 2
      notification_ids = Enum.map(notifications, & &1.id)
      assert n1.id in notification_ids
      assert n2.id in notification_ids
    end

    test "does not return other user's notifications" do
      user1 = user_fixture()
      user2 = user_fixture()
      scope1 = Scope.for_user(user1)

      {:ok, _} = Notifications.create_notification(user2.id, "new_follower")

      notifications = Notifications.list_notifications(scope1)
      assert notifications == []
    end

    test "orders by newest first" do
      user = user_fixture()
      scope = Scope.for_user(user)

      {:ok, _n1} = Notifications.create_notification(user.id, "new_follower")
      {:ok, _n2} = Notifications.create_notification(user.id, "new_follower")

      [first, second] = Notifications.list_notifications(scope)

      # Should be ordered by inserted_at desc, with higher ID as tiebreaker
      # Both notifications were created in the same second, so the one with
      # the higher ID (n2) should come first
      assert first.id > second.id
    end

    test "respects limit option" do
      user = user_fixture()
      scope = Scope.for_user(user)

      for _ <- 1..5 do
        Notifications.create_notification(user.id, "new_follower")
      end

      notifications = Notifications.list_notifications(scope, limit: 3)
      assert length(notifications) == 3
    end

    test "unread_only option filters to unread" do
      user = user_fixture()
      scope = Scope.for_user(user)

      {:ok, n1} = Notifications.create_notification(user.id, "new_follower")
      {:ok, _n2} = Notifications.create_notification(user.id, "new_follower")

      # Mark one as read
      Notifications.mark_as_read(scope, n1.id)

      unread = Notifications.list_notifications(scope, unread_only: true)
      assert length(unread) == 1
    end
  end

  describe "unread_count/1" do
    test "returns count of unread notifications" do
      user = user_fixture()
      scope = Scope.for_user(user)

      {:ok, _} = Notifications.create_notification(user.id, "new_follower")
      {:ok, _} = Notifications.create_notification(user.id, "new_follower")
      {:ok, n3} = Notifications.create_notification(user.id, "new_follower")

      # Mark one as read
      Notifications.mark_as_read(scope, n3.id)

      assert Notifications.unread_count(scope) == 2
    end

    test "returns 0 when no unread notifications" do
      user = user_fixture()
      scope = Scope.for_user(user)

      assert Notifications.unread_count(scope) == 0
    end
  end

  describe "mark_as_read/2" do
    test "marks notification as read" do
      user = user_fixture()
      scope = Scope.for_user(user)

      {:ok, notification} = Notifications.create_notification(user.id, "new_follower")
      assert is_nil(notification.read_at)

      {:ok, updated} = Notifications.mark_as_read(scope, notification.id)
      refute is_nil(updated.read_at)
    end

    test "raises when user doesn't own notification" do
      user1 = user_fixture()
      user2 = user_fixture()
      scope2 = Scope.for_user(user2)

      {:ok, notification} = Notifications.create_notification(user1.id, "new_follower")

      assert_raise MatchError, fn ->
        Notifications.mark_as_read(scope2, notification.id)
      end
    end
  end

  describe "mark_all_as_read/1" do
    test "marks all unread notifications as read" do
      user = user_fixture()
      scope = Scope.for_user(user)

      {:ok, _} = Notifications.create_notification(user.id, "new_follower")
      {:ok, _} = Notifications.create_notification(user.id, "new_follower")
      {:ok, _} = Notifications.create_notification(user.id, "new_follower")

      count = Notifications.mark_all_as_read(scope)
      assert count == 3
      assert Notifications.unread_count(scope) == 0
    end

    test "returns 0 when no unread notifications" do
      user = user_fixture()
      scope = Scope.for_user(user)

      assert Notifications.mark_all_as_read(scope) == 0
    end
  end

  describe "delete_notification/2" do
    test "deletes notification" do
      user = user_fixture()
      scope = Scope.for_user(user)

      {:ok, notification} = Notifications.create_notification(user.id, "new_follower")

      assert {:ok, _} = Notifications.delete_notification(scope, notification.id)
      assert Notifications.list_notifications(scope) == []
    end

    test "raises when user doesn't own notification" do
      user1 = user_fixture()
      user2 = user_fixture()
      scope2 = Scope.for_user(user2)

      {:ok, notification} = Notifications.create_notification(user1.id, "new_follower")

      assert_raise MatchError, fn ->
        Notifications.delete_notification(scope2, notification.id)
      end
    end
  end

  describe "cleanup_old_notifications/1" do
    test "deletes notifications older than specified days" do
      user = user_fixture()
      scope = Scope.for_user(user)

      # Create notification with old timestamp
      {:ok, notification} = Notifications.create_notification(user.id, "new_follower")

      # Manually update to old timestamp
      old_date = DateTime.add(DateTime.utc_now(:second), -31, :day)

      Repo.update_all(
        from(n in Homesite.Notifications.Notification, where: n.id == ^notification.id),
        set: [inserted_at: old_date]
      )

      # Create recent notification
      {:ok, _recent} = Notifications.create_notification(user.id, "new_follower")

      deleted_count = Notifications.cleanup_old_notifications(30)

      assert deleted_count == 1
      assert length(Notifications.list_notifications(scope)) == 1
    end
  end

  describe "preloads actor" do
    test "list_notifications preloads actor" do
      user = user_fixture()
      actor = user_fixture()
      scope = Scope.for_user(user)

      {:ok, _} = Notifications.create_notification(user.id, "new_follower", actor.id)

      [notification] = Notifications.list_notifications(scope)

      assert notification.actor.id == actor.id
      assert notification.actor.email == actor.email
    end
  end
end
