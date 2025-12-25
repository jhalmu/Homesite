defmodule Homesite.Chat.PresenceTest do
  use Homesite.DataCase, async: false

  alias Homesite.Accounts.Scope
  alias Homesite.Chat.Presence

  import Homesite.AccountsFixtures

  describe "online_count/0" do
    test "returns count of tracked users" do
      # Initially should be 0 or whatever is currently tracked
      count = Presence.online_count()
      assert is_integer(count)
      assert count >= 0
    end
  end

  describe "online_user_ids/0" do
    test "returns list of user IDs" do
      ids = Presence.online_user_ids()
      assert is_list(ids)
    end
  end

  describe "online?/1" do
    test "returns false for user not tracked" do
      # Use a random ID that won't be tracked
      refute Presence.online?(999_999_999)
    end
  end

  describe "subscribe/0" do
    test "subscribes to presence topic" do
      assert :ok = Presence.subscribe()
    end
  end

  describe "track_user/1 and untrack_user/1" do
    test "track_user returns ok tuple" do
      user = user_fixture()
      scope = Scope.for_user(user)

      result = Presence.track_user(scope)
      assert {:ok, _ref} = result
    end

    test "untrack_user returns ok" do
      user = user_fixture()
      scope = Scope.for_user(user)

      # Track first
      Presence.track_user(scope)

      # Then untrack
      assert :ok = Presence.untrack_user(scope)
    end
  end
end
