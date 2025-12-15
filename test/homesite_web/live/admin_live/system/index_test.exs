defmodule HomesiteWeb.AdminLive.System.IndexTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures

  describe "admin system page" do
    test "redirects non-admin users to home page", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: to, flash: flash}}} = live(conn, ~p"/admin/system")
      assert to == "/"
      assert flash["error"] =~ "administrator"
    end

    test "renders system info for admin users", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/system")

      assert html =~ "System Information"
      assert html =~ "Version"
      assert html =~ "Uptime"
    end

    test "displays version information", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/system")

      assert html =~ "Version"
      assert html =~ "Built"
      assert html =~ "Git SHA"
    end

    test "displays runtime environment", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/system")

      assert html =~ "Runtime Environment"
      assert html =~ "Elixir"
      assert html =~ "Erlang/OTP"
      assert html =~ "Phoenix"
      assert html =~ "Ecto"
    end

    test "displays changelog section", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/system")

      assert html =~ "Recent Changes"
    end

    test "displays database info", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/system")

      assert html =~ "Database"
      assert html =~ "PostgreSQL"
    end

    test "requires authentication", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin/system")
      assert {:redirect, %{to: path}} = redirect
      assert path =~ "/users/log-in"
    end
  end
end
