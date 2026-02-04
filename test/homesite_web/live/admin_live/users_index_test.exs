defmodule HomesiteWeb.AdminLive.Users.IndexTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures

  describe "admin user management" do
    test "redirects non-admin users to home page", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Router's :require_admin hook returns an error with redirect
      assert {:error, {:redirect, %{to: to, flash: flash}}} = live(conn, ~p"/admin/users")
      assert to == "/"
      assert flash["error"] =~ "administrator"
    end

    test "redirects admins with insufficient flower level", %{conn: conn} do
      # Create admin with only 1 flower (needs 3 for user management)
      admin = admin_fixture(%{admin_flowers: 1})
      conn = log_in_user(conn, admin)

      # Module-level check redirects to /admin
      assert {:error, {:redirect, %{to: to, flash: flash}}} = live(conn, ~p"/admin/users")
      assert to == "/admin"
      assert flash["error"] =~ "Level 3"
    end

    test "renders user list for admin with sufficient flowers", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/users")

      assert html =~ "User Management"
      assert html =~ "Total Users"
      assert html =~ "Admin Users"
    end

    test "displays user statistics", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/users")

      assert html =~ "Total Users"
      assert html =~ "Admin Users"
      assert html =~ "Banned"
      assert html =~ "Suspended"
    end

    test "displays users table with columns", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/users")

      # Updated table columns (Email + Display Name merged into User)
      assert html =~ "User"
      assert html =~ "Role"
      assert html =~ "Status"
      assert html =~ "Joined"
      assert html =~ "Posts"
      assert html =~ "Actions"
    end

    test "can search users by email", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      _user = user_fixture(%{email: "searchable@example.com"})
      conn = log_in_user(conn, admin)

      {:ok, lv, _html} = live(conn, ~p"/admin/users")

      html =
        lv
        |> form("form", %{search: "searchable"})
        |> render_change()

      assert html =~ "searchable@example.com"
    end

    test "can clear search", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      conn = log_in_user(conn, admin)

      {:ok, lv, _html} = live(conn, ~p"/admin/users")

      # Search first
      lv
      |> form("form", %{search: "something"})
      |> render_change()

      # Clear search
      html = lv |> element("button", "Clear") |> render_click()

      # Search should be cleared
      assert html =~ "User Management"
    end

    test "requires authentication", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin/users")
      assert {:redirect, %{to: path}} = redirect
      assert path =~ "/users/log-in"
    end

    test "displays status filter dropdown", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/users")

      assert html =~ "Status"
      assert html =~ "All users"
      assert html =~ "Active"
      assert html =~ "Banned"
      assert html =~ "Suspended"
    end

    test "displays user status badges", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      _user = user_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/users")

      # Active users should show Active badge
      assert html =~ "Active"
    end

    test "displays banned and suspended counts in stats", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/users")

      assert html =~ "Banned"
      assert html =~ "Suspended"
    end

    test "displays actions dropdown for users", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      _user = user_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/users")

      # Actions dropdown should be present
      assert html =~ "View Profile"
      assert html =~ "Edit Role"
    end

    test "can search users by username", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      user = user_fixture()

      {:ok, _user} =
        Homesite.Accounts.update_user_profile(user, %{username: "unique_username_test"})

      conn = log_in_user(conn, admin)

      {:ok, lv, _html} = live(conn, ~p"/admin/users")

      html =
        lv
        |> form("form", %{search: "unique_username"})
        |> render_change()

      assert html =~ "unique_username_test"
    end

    test "can search users by display name", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      user = user_fixture()

      {:ok, _user} =
        Homesite.Accounts.update_user_profile(user, %{display_name: "Unique Display Name"})

      conn = log_in_user(conn, admin)

      {:ok, lv, _html} = live(conn, ~p"/admin/users")

      html =
        lv
        |> form("form", %{search: "Unique Display"})
        |> render_change()

      assert html =~ "Unique Display Name"
    end
  end
end
