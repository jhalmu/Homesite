defmodule HomesiteWeb.E2E.UserProfileTest do
  @moduledoc """
  End-to-end tests for user profile and social features using Playwright.

  Tests cover:
  - Viewing user profiles
  - Following/unfollowing users
  - Viewing followers/following lists
  - Profile editing
  - Username routing
  """
  use PhoenixTest.Playwright.Case, async: false
  use HomesiteWeb, :verified_routes

  import Homesite.AccountsFixtures
  import Homesite.ContentFixtures
  import HomesiteWeb.PlaywrightAuthHelper

  setup do
    Homesite.DataCase.ensure_test_invitation()
    user = user_fixture()
    scope = %Homesite.Accounts.Scope{user: user}

    # Update user with username for profile routing
    {:ok, user} =
      Homesite.Accounts.update_user_profile(user, %{
        username: "testuser#{System.unique_integer([:positive])}",
        display_name: "Test User"
      })

    %{user: user, scope: scope}
  end

  describe "User Profile Page" do
    @tag :playwright
    test "displays user profile by username", %{conn: conn, user: user} do
      conn
      |> visit(~p"/users/@#{user.username}")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: user.display_name)
    end

    @tag :playwright
    test "displays user's public posts", %{conn: conn, user: user, scope: scope} do
      _post =
        post_fixture(scope, %{
          title: "User's Public Post",
          is_public: true,
          published_at: DateTime.utc_now(:second)
        })

      conn
      |> visit(~p"/users/@#{user.username}")
      |> assert_has("body .phx-connected")
      |> assert_has("a", text: "User's Public Post")
    end

    @tag :playwright
    test "shows follow button for other users", %{conn: conn, user: user} do
      other_user = user_fixture()

      {:ok, other_user} =
        Homesite.Accounts.update_user_profile(other_user, %{
          username: "otheruser#{System.unique_integer([:positive])}",
          display_name: "Other User"
        })

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/users/@#{other_user.username}")
      |> assert_has("body .phx-connected")
      |> assert_has("button", text: "Follow")
    end

    @tag :playwright
    test "does not show follow button on own profile", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/users/@#{user.username}")
      |> assert_has("body .phx-connected")
      |> refute_has("button", text: "Follow")
      |> refute_has("button", text: "Unfollow")
    end
  end

  describe "Followers/Following" do
    @tag :playwright
    test "can view followers page", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/users/@#{user.username}/followers")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: user.display_name)
      |> assert_has(".tab.tab-active", text: "Followers")
    end

    @tag :playwright
    test "can view following page", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/users/@#{user.username}/following")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: user.display_name)
      |> assert_has(".tab.tab-active", text: "Following")
    end

    @tag :playwright
    test "shows empty state when no followers", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/users/@#{user.username}/followers")
      |> assert_has("body .phx-connected")
      |> assert_has("p", text: "No followers")
    end

    @tag :playwright
    test "shows empty state when not following anyone", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/users/@#{user.username}/following")
      |> assert_has("body .phx-connected")
      |> assert_has("p", text: "Not following anyone")
    end
  end

  describe "User Projects" do
    @tag :playwright
    test "can view user's projects page", %{conn: conn, user: user} do
      conn
      |> visit(~p"/users/@#{user.username}/projects")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Projects by")
    end

    @tag :playwright
    test "shows empty state when no projects", %{conn: conn, user: user} do
      conn
      |> visit(~p"/users/@#{user.username}/projects")
      |> assert_has("body .phx-connected")
      |> assert_has("p", text: "No public projects")
    end
  end

  describe "Follow/Unfollow Actions" do
    @tag :playwright
    test "can follow another user", %{conn: conn, user: user} do
      other_user = user_fixture()

      {:ok, other_user} =
        Homesite.Accounts.update_user_profile(other_user, %{
          username: "followme#{System.unique_integer([:positive])}",
          display_name: "Follow Me"
        })

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/users/@#{other_user.username}")
      |> assert_has("body .phx-connected")
      |> click_button("Follow")
      |> assert_has("body .phx-connected")
      |> assert_has("button", text: "Unfollow")
    end
  end
end
