defmodule Homesite.FollowsTest do
  use Homesite.DataCase, async: true

  alias Homesite.Follows
  alias Homesite.Accounts.Scope

  import Homesite.AccountsFixtures

  describe "follow_user/2" do
    test "creates a follow relationship" do
      user1 = user_fixture()
      user2 = user_fixture()
      scope = Scope.for_user(user1)

      assert {:ok, follower} = Follows.follow_user(scope, user2.id)
      assert follower.follower_id == user1.id
      assert follower.followed_id == user2.id
    end

    test "prevents self-follow" do
      user = user_fixture()
      scope = Scope.for_user(user)

      assert {:error, changeset} = Follows.follow_user(scope, user.id)
      assert "cannot follow yourself" in errors_on(changeset).followed_id
    end

    test "prevents duplicate follows" do
      user1 = user_fixture()
      user2 = user_fixture()
      scope = Scope.for_user(user1)

      assert {:ok, _} = Follows.follow_user(scope, user2.id)
      assert {:error, changeset} = Follows.follow_user(scope, user2.id)
      assert "already following this user" in errors_on(changeset).follower_id
    end
  end

  describe "unfollow_user/2" do
    test "removes a follow relationship" do
      user1 = user_fixture()
      user2 = user_fixture()
      scope = Scope.for_user(user1)

      {:ok, _} = Follows.follow_user(scope, user2.id)
      assert {:ok, _} = Follows.unfollow_user(scope, user2.id)
      refute Follows.following?(scope, user2.id)
    end

    test "returns error when not following" do
      user1 = user_fixture()
      user2 = user_fixture()
      scope = Scope.for_user(user1)

      assert {:error, :not_found} = Follows.unfollow_user(scope, user2.id)
    end
  end

  describe "following?/2" do
    test "returns true when following" do
      user1 = user_fixture()
      user2 = user_fixture()
      scope = Scope.for_user(user1)

      {:ok, _} = Follows.follow_user(scope, user2.id)
      assert Follows.following?(scope, user2.id)
    end

    test "returns false when not following" do
      user1 = user_fixture()
      user2 = user_fixture()
      scope = Scope.for_user(user1)

      refute Follows.following?(scope, user2.id)
    end
  end

  describe "list_followers/1" do
    test "returns list of users who follow the current user" do
      user1 = user_fixture()
      user2 = user_fixture()
      user3 = user_fixture()
      scope1 = Scope.for_user(user1)
      scope2 = Scope.for_user(user2)
      scope3 = Scope.for_user(user3)

      # user2 and user3 follow user1
      {:ok, _} = Follows.follow_user(scope2, user1.id)
      {:ok, _} = Follows.follow_user(scope3, user1.id)

      followers = Follows.list_followers(scope1)
      follower_ids = Enum.map(followers, & &1.user.id)

      assert length(followers) == 2
      assert user2.id in follower_ids
      assert user3.id in follower_ids
    end

    test "returns empty list when no followers" do
      user = user_fixture()
      scope = Scope.for_user(user)

      assert Follows.list_followers(scope) == []
    end
  end

  describe "list_following/1" do
    test "returns list of users the current user follows" do
      user1 = user_fixture()
      user2 = user_fixture()
      user3 = user_fixture()
      scope1 = Scope.for_user(user1)

      # user1 follows user2 and user3
      {:ok, _} = Follows.follow_user(scope1, user2.id)
      {:ok, _} = Follows.follow_user(scope1, user3.id)

      following = Follows.list_following(scope1)
      following_ids = Enum.map(following, & &1.user.id)

      assert length(following) == 2
      assert user2.id in following_ids
      assert user3.id in following_ids
    end

    test "returns empty list when not following anyone" do
      user = user_fixture()
      scope = Scope.for_user(user)

      assert Follows.list_following(scope) == []
    end
  end

  describe "get_follow_counts/1" do
    test "returns correct follower and following counts" do
      user1 = user_fixture()
      user2 = user_fixture()
      user3 = user_fixture()
      scope1 = Scope.for_user(user1)
      scope2 = Scope.for_user(user2)

      # user2 follows user1
      {:ok, _} = Follows.follow_user(scope2, user1.id)
      # user1 follows user3
      {:ok, _} = Follows.follow_user(scope1, user3.id)

      counts = Follows.get_follow_counts(user1.id)

      assert counts.followers == 1
      assert counts.following == 1
    end

    test "returns zero counts for new user" do
      user = user_fixture()
      counts = Follows.get_follow_counts(user.id)

      assert counts.followers == 0
      assert counts.following == 0
    end
  end

  describe "mutual_follow?/2" do
    test "returns true when both users follow each other" do
      user1 = user_fixture()
      user2 = user_fixture()
      scope1 = Scope.for_user(user1)
      scope2 = Scope.for_user(user2)

      {:ok, _} = Follows.follow_user(scope1, user2.id)
      {:ok, _} = Follows.follow_user(scope2, user1.id)

      assert Follows.mutual_follow?(scope1, user2.id)
      assert Follows.mutual_follow?(scope2, user1.id)
    end

    test "returns false when only one follows the other" do
      user1 = user_fixture()
      user2 = user_fixture()
      scope1 = Scope.for_user(user1)

      {:ok, _} = Follows.follow_user(scope1, user2.id)

      refute Follows.mutual_follow?(scope1, user2.id)
    end
  end

  describe "is_following?/2" do
    test "returns true when user A follows user B" do
      user1 = user_fixture()
      user2 = user_fixture()
      scope1 = Scope.for_user(user1)

      {:ok, _} = Follows.follow_user(scope1, user2.id)

      assert Follows.is_following?(user1.id, user2.id)
    end

    test "returns false when user A does not follow user B" do
      user1 = user_fixture()
      user2 = user_fixture()

      refute Follows.is_following?(user1.id, user2.id)
    end
  end
end
