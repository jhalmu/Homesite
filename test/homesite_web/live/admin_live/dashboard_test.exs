defmodule HomesiteWeb.AdminLive.DashboardTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures

  describe "admin dashboard" do
    test "redirects non-admin users to home page", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Router's :require_admin hook returns an error with redirect
      assert {:error, {:redirect, %{to: to, flash: flash}}} = live(conn, ~p"/admin")
      assert to == "/"
      assert flash["error"] =~ "administrator"
    end

    test "renders dashboard for admin users", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert html =~ "Admin Dashboard"
      assert html =~ "System overview"
    end

    test "displays search statistics cards", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert html =~ "Total Searches"
      assert html =~ "Avg Search Time"
      assert html =~ "No Results"
      assert html =~ "Avg Results"
    end

    test "displays popular searches table", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert html =~ "Popular Searches"
      assert html =~ "Query"
      assert html =~ "Count"
    end

    test "displays no-result searches table", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert html =~ "Searches With No Results"
    end

    test "displays recent activity log", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert html =~ "Recent Activity"
      assert html =~ "Time"
      assert html =~ "User"
      assert html =~ "Action"
    end

    test "requires authentication", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin")
      assert {:redirect, %{to: path}} = redirect
      assert path =~ "/users/log-in"
    end
  end
end
