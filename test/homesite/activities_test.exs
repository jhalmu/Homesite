defmodule Homesite.ActivitiesTest do
  use Homesite.DataCase, async: true

  alias Homesite.Activities
  alias Homesite.Activities.Activity
  alias Homesite.Content.Post

  import Homesite.AccountsFixtures

  describe "create_activity/4" do
    test "creates activity with valid data" do
      user = user_fixture()

      assert {:ok, %Activity{} = activity} =
               Activities.create_activity(user, "blog_published", nil, "Published a blog post")

      assert activity.user_id == user.id
      assert activity.activity_type == "blog_published"
      assert activity.content == "Published a blog post"
      assert is_nil(activity.subject_type)
      assert is_nil(activity.subject_id)
    end

    test "creates activity with subject" do
      user = user_fixture()
      # Create a mock post-like struct for testing
      post = %Post{id: 123, title: "Test Post"}

      assert {:ok, %Activity{} = activity} =
               Activities.create_activity(user, "blog_published", post, "Published: Test Post")

      assert activity.user_id == user.id
      assert activity.activity_type == "blog_published"
      assert activity.subject_type == "Post"
      assert activity.subject_id == 123
      assert activity.content == "Published: Test Post"
    end

    test "validates activity_type inclusion" do
      user = user_fixture()

      assert {:error, changeset} =
               Activities.create_activity(user, "invalid_type", nil, "Invalid activity")

      assert "is invalid" in errors_on(changeset).activity_type
    end

    test "validates required fields" do
      user = user_fixture()

      # Empty content
      assert {:error, changeset} = Activities.create_activity(user, "blog_published", nil, nil)
      assert "can't be blank" in errors_on(changeset).content
    end

    test "supports all valid activity types" do
      user = user_fixture()
      valid_types = ["blog_published", "blog_draft", "tag_created", "user_registered"]

      for type <- valid_types do
        assert {:ok, %Activity{activity_type: ^type}} =
                 Activities.create_activity(user, type, nil, "Activity: #{type}")
      end
    end
  end

  describe "list_recent_activities/1" do
    test "returns activities ordered by inserted_at desc" do
      user = user_fixture()

      {:ok, activity1} = Activities.create_activity(user, "blog_published", nil, "First")
      {:ok, activity2} = Activities.create_activity(user, "blog_draft", nil, "Second")
      {:ok, activity3} = Activities.create_activity(user, "tag_created", nil, "Third")

      # Manually set timestamps to ensure ordering
      now = DateTime.utc_now()

      Homesite.Repo.update_all(
        from(a in Activity, where: a.id == ^activity1.id),
        set: [inserted_at: DateTime.add(now, -2, :minute)]
      )

      Homesite.Repo.update_all(
        from(a in Activity, where: a.id == ^activity2.id),
        set: [inserted_at: DateTime.add(now, -1, :minute)]
      )

      Homesite.Repo.update_all(
        from(a in Activity, where: a.id == ^activity3.id),
        set: [inserted_at: now]
      )

      activities = Activities.list_recent_activities(user_id: user.id)
      activity_ids = Enum.map(activities, & &1.id)

      # Most recent first: activity3, activity2, activity1
      assert activity_ids == [activity3.id, activity2.id, activity1.id]
    end

    test "respects limit option" do
      user = user_fixture()

      for i <- 1..5 do
        Activities.create_activity(user, "blog_published", nil, "Activity #{i}")
      end

      activities = Activities.list_recent_activities(limit: 3)
      assert length(activities) == 3
    end

    test "filters by user_id" do
      user1 = user_fixture()
      user2 = user_fixture()

      {:ok, activity1} = Activities.create_activity(user1, "blog_published", nil, "User 1 activity")
      {:ok, _activity2} = Activities.create_activity(user2, "blog_published", nil, "User 2 activity")

      activities = Activities.list_recent_activities(user_id: user1.id)

      assert length(activities) == 1
      assert hd(activities).id == activity1.id
    end

    test "preloads user association" do
      user = user_fixture()
      Activities.create_activity(user, "blog_published", nil, "Test activity")

      [activity] = Activities.list_recent_activities(user_id: user.id)
      assert activity.user.id == user.id
      assert activity.user.email == user.email
    end

    test "returns empty list when no activities exist for user" do
      user = user_fixture()
      activities = Activities.list_recent_activities(user_id: user.id)
      assert activities == []
    end

    test "default limit is 20" do
      user = user_fixture()

      for i <- 1..25 do
        Activities.create_activity(user, "blog_published", nil, "Activity #{i}")
      end

      activities = Activities.list_recent_activities()
      assert length(activities) == 20
    end
  end

  describe "delete_old_activities/1" do
    test "deletes activities older than specified days" do
      user = user_fixture()

      # Create an activity
      {:ok, activity} = Activities.create_activity(user, "blog_published", nil, "Old activity")

      # Manually backdate the activity to 31 days ago
      cutoff = DateTime.utc_now() |> DateTime.add(-31, :day)

      Homesite.Repo.update_all(
        from(a in Activity, where: a.id == ^activity.id),
        set: [inserted_at: cutoff]
      )

      # Delete activities older than 30 days
      {deleted_count, _} = Activities.delete_old_activities(30)

      assert deleted_count == 1
      assert Homesite.Repo.get(Activity, activity.id) == nil
    end

    test "keeps activities newer than specified days" do
      user = user_fixture()

      {:ok, activity} = Activities.create_activity(user, "blog_published", nil, "Recent activity")

      # Delete activities older than 30 days (this activity is new)
      {deleted_count, _} = Activities.delete_old_activities(30)

      assert deleted_count == 0
      assert Homesite.Repo.get(Activity, activity.id) != nil
    end

    test "handles zero days correctly" do
      user = user_fixture()

      {:ok, activity} = Activities.create_activity(user, "blog_published", nil, "Activity")

      # Backdate to 1 hour ago
      one_hour_ago = DateTime.utc_now() |> DateTime.add(-1, :hour)

      Homesite.Repo.update_all(
        from(a in Activity, where: a.id == ^activity.id),
        set: [inserted_at: one_hour_ago]
      )

      # Delete activities older than 0 days (should delete anything not from today)
      {deleted_count, _} = Activities.delete_old_activities(0)

      assert deleted_count == 1
    end
  end

  describe "edge cases" do
    test "handles very long content strings" do
      user = user_fixture()
      long_content = String.duplicate("a", 10_000)

      # This should either succeed or fail with a validation error, not crash
      result = Activities.create_activity(user, "blog_published", nil, long_content)

      case result do
        {:ok, activity} ->
          assert String.length(activity.content) == 10_000

        {:error, changeset} ->
          assert changeset.valid? == false
      end
    end

    test "handles unicode content" do
      user = user_fixture()
      unicode_content = "Published: 日本語テスト 🎉 émojis et français"

      assert {:ok, activity} =
               Activities.create_activity(user, "blog_published", nil, unicode_content)

      assert activity.content == unicode_content
    end

    test "handles special characters in content" do
      user = user_fixture()
      special_content = "Published: <script>alert('xss')</script> & \"quotes\" 'single'"

      assert {:ok, activity} =
               Activities.create_activity(user, "blog_published", nil, special_content)

      # Content is stored as-is (XSS protection happens at render time)
      assert activity.content == special_content
    end

    test "subject_type extracts last module name" do
      user = user_fixture()
      post = %Post{id: 1, title: "Test"}

      {:ok, activity} = Activities.create_activity(user, "blog_published", post, "Test")

      # Should be "Post" not "Elixir.Homesite.Content.Post"
      assert activity.subject_type == "Post"
    end
  end
end
