defmodule HomesiteWeb.AdminLive.Invitations.IndexTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures

  describe "admin invitations management" do
    test "redirects non-admin users to home page", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      # Router's :require_admin hook returns an error with redirect
      assert {:error, {:redirect, %{to: to, flash: flash}}} = live(conn, ~p"/admin/invitations")
      assert to == "/"
      assert flash["error"] =~ "administrator"
    end

    test "renders invitation list for admin users", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/invitations")

      assert html =~ "Manage Invitations"
      assert html =~ "Active Invitations"
    end

    test "can open new invitation form", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, lv, _html} = live(conn, ~p"/admin/invitations")

      html = lv |> element("a", "Create Invitation") |> render_click()

      assert html =~ "New Invitation"
      assert html =~ "invitation-form"
    end

    test "can cancel invitation form", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, lv, _html} = live(conn, ~p"/admin/invitations")

      # Click new button
      lv |> element("a", "Create Invitation") |> render_click()

      # Click cancel
      _html = lv |> element("button", "Cancel") |> render_click()

      # Form should be gone
      refute has_element?(lv, "#invitation-form")
    end

    test "displays invitation columns", %{conn: conn} do
      admin = admin_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/invitations")

      assert html =~ "Code"
      assert html =~ "Created By"
      assert html =~ "Uses"
      assert html =~ "Expires"
      assert html =~ "Role"
      assert html =~ "Status"
    end

    test "requires authentication", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin/invitations")
      assert {:redirect, %{to: path}} = redirect
      assert path =~ "/users/log-in"
    end
  end
end
