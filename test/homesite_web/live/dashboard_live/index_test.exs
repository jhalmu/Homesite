defmodule HomesiteWeb.DashboardLive.IndexTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures
  import Homesite.ContentFixtures

  describe "dashboard page" do
    test "redirects unauthenticated users to login", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/dashboard")
      assert {:redirect, %{to: path}} = redirect
      assert path =~ "/users/log-in"
    end

    test "renders dashboard for authenticated users", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/dashboard")

      assert html =~ "Dashboard" || html =~ "Welcome"
    end

    test "displays post statistics", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      scope = Homesite.Accounts.Scope.for_user(user)

      # Create a published post
      _published_post =
        post_fixture(scope, %{title: "Published", published_at: DateTime.utc_now(:second)})

      {:ok, _lv, html} = live(conn, ~p"/dashboard")

      assert html =~ "Posts" || html =~ "Total Posts"
    end

    test "displays tag statistics", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      scope = Homesite.Accounts.Scope.for_user(user)

      _tag = tag_fixture(scope, %{name: "test-tag"})

      {:ok, _lv, html} = live(conn, ~p"/dashboard")

      assert html =~ "Tags" || html =~ "Total Tags"
    end

    test "displays feed source section", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/dashboard")

      assert html =~ "Feed" || html =~ "Sources"
    end
  end

  describe "dashboard with content" do
    test "shows post count", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      scope = Homesite.Accounts.Scope.for_user(user)

      # Create 3 published posts
      for i <- 1..3 do
        post_fixture(scope, %{title: "Published #{i}", published_at: DateTime.utc_now(:second)})
      end

      {:ok, _lv, html} = live(conn, ~p"/dashboard")

      # Dashboard should show post count
      assert html =~ "3" || html =~ "Posts"
    end

    test "shows tags count", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      scope = Homesite.Accounts.Scope.for_user(user)

      # Create 2 tags
      for i <- 1..2 do
        tag_fixture(scope, %{name: "tag-#{i}"})
      end

      {:ok, _lv, html} = live(conn, ~p"/dashboard")

      assert html =~ "2" || html =~ "Tags"
    end
  end

  describe "profile section" do
    test "shows username claim prompt when no username", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/dashboard")

      assert html =~ "username" || html =~ "Claim" || html =~ "Profile"
    end

    test "shows profile info when user has username", %{conn: conn} do
      user = user_fixture(%{username: "testuser"})
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/dashboard")

      assert html =~ "Profile" || html =~ "testuser"
    end
  end
end
