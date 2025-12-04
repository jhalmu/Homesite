defmodule HomesiteWeb.AdminLive.Analytics.IndexTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures

  describe "admin analytics page" do
    test "redirects non-admin users to home page", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Router's :require_admin hook returns an error with redirect
      assert {:error, {:redirect, %{to: to, flash: flash}}} = live(conn, ~p"/admin/analytics")
      assert to == "/"
      assert flash["error"] =~ "administrator"
    end

    test "renders analytics for admin users", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/analytics")

      assert html =~ "Analytics Dashboard"
    end

    test "displays user statistics section", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/analytics")

      assert html =~ "User Metrics"
      assert html =~ "Total Users"
    end

    test "displays content statistics section", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/analytics")

      assert html =~ "Content Metrics"
      assert html =~ "Total Posts"
      assert html =~ "Total Tags"
    end

    test "displays top authors section", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/analytics")

      assert html =~ "Top Authors"
    end

    test "displays popular tags section", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/analytics")

      assert html =~ "Popular Tags"
    end

    test "requires authentication", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin/analytics")
      assert {:redirect, %{to: path}} = redirect
      assert path =~ "/users/log-in"
    end
  end
end
