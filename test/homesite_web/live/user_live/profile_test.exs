defmodule HomesiteWeb.UserLive.ProfileTest do
  use HomesiteWeb.ConnCase

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures
  import Homesite.ContentFixtures

  alias Homesite.Accounts

  describe "Profile page" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "displays user profile with ID routing", %{conn: conn, user: user} do
      {:ok, user} = Accounts.update_user_profile(user, %{display_name: "Test User"})

      {:ok, _view, html} = live(conn, ~p"/users/#{user.id}")

      assert html =~ "Test User"
    end

    test "displays user profile with username routing", %{conn: conn, user: user} do
      # Set username and display name for the user
      {:ok, user} = Accounts.update_user_username(user, %{username: "testuser"})
      {:ok, user} = Accounts.update_user_profile(user, %{display_name: "Test User"})

      {:ok, _view, html} = live(conn, ~p"/users/@testuser")

      assert html =~ "Test User"
    end

    test "displays user's published posts", %{conn: conn, user: user} do
      scope = Homesite.Accounts.Scope.for_user(user)
      post = post_fixture(scope, %{published_at: DateTime.utc_now()})

      {:ok, _view, html} = live(conn, ~p"/users/#{user.id}")

      assert html =~ post.title
      assert html =~ "Published Posts"
    end

    test "does not display unpublished posts", %{conn: conn, user: user} do
      scope = Homesite.Accounts.Scope.for_user(user)
      # Create published and unpublished posts
      _published =
        post_fixture(scope, %{title: "Published Post", published_at: DateTime.utc_now()})

      # Create unpublished post directly via repo (bypassing post_fixture validation)
      unpublished =
        Homesite.Repo.insert!(%Homesite.Content.Post{
          title: "Unpublished Post",
          body: "unpublished content that should not appear",
          slug: "unpublished-#{System.unique_integer([:positive])}",
          user_id: user.id,
          published_at: nil
        })

      {:ok, _view, html} = live(conn, ~p"/users/#{user.id}")

      refute html =~ unpublished.title
      refute html =~ "unpublished content"
    end

    test "shows 'No published posts yet' when user has no posts", %{conn: conn, user: user} do
      {:ok, _view, html} = live(conn, ~p"/users/#{user.id}")

      assert html =~ "No published posts yet"
    end

    test "displays social links when present", %{conn: conn, user: user} do
      {:ok, user} =
        Accounts.update_user_profile(user, %{
          website_url: "https://example.com",
          bluesky_handle: "@user.bsky.social",
          mastodon_handle: "@user@mastodon.social"
        })

      {:ok, _view, html} = live(conn, ~p"/users/#{user.id}")

      assert html =~ "Website"
      assert html =~ "Bluesky"
      assert html =~ "Mastodon"
    end

    test "redirects to home with error for non-existent user ID", %{conn: conn} do
      result = live(conn, ~p"/users/999999")

      assert {:error, {:redirect, %{to: "/", flash: %{"error" => "User not found"}}}} = result
    end

    test "redirects to home with error for non-existent username", %{conn: conn} do
      result = live(conn, ~p"/users/@nonexistent")

      assert {:error, {:redirect, %{to: "/", flash: %{"error" => "User not found"}}}} = result
    end

    test "displays bio when present", %{conn: conn, user: user} do
      {:ok, user} = Accounts.update_user_profile(user, %{bio: "This is my bio"})

      {:ok, _view, html} = live(conn, ~p"/users/#{user.id}")

      assert html =~ "This is my bio"
    end
  end

  describe "Username routing" do
    test "both ID and username routes work for same user", %{conn: conn} do
      user = user_fixture()
      {:ok, user} = Accounts.update_user_username(user, %{username: "johndoe"})

      {:ok, _view_id, html_id} = live(conn, ~p"/users/#{user.id}")
      {:ok, _view_username, html_username} = live(conn, ~p"/users/@johndoe")

      # Both should show the same content
      display_name = user.display_name || String.split(user.email, "@") |> List.first()
      assert html_id =~ display_name
      assert html_username =~ display_name
    end

    test "changing username updates accessible route", %{conn: conn} do
      user = user_fixture()
      {:ok, user} = Accounts.update_user_username(user, %{username: "oldname"})

      # Old username works
      {:ok, _view, _html} = live(conn, ~p"/users/@oldname")

      # Update username
      {:ok, user} = Accounts.update_user_username(user, %{username: "newname"})

      # New username works
      {:ok, _view, _html} = live(conn, ~p"/users/@newname")

      # Old username no longer works
      result = live(conn, ~p"/users/@oldname")
      assert {:error, {:redirect, %{to: "/", flash: %{"error" => "User not found"}}}} = result

      # ID still works
      {:ok, _view, _html} = live(conn, ~p"/users/#{user.id}")
    end
  end
end
