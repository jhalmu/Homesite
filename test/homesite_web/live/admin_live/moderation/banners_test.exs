defmodule HomesiteWeb.AdminLive.Moderation.BannersTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures

  alias Homesite.Accounts.Scope
  alias Homesite.Moderation

  describe "banners page" do
    test "redirects non-admin users", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/", flash: flash}}} =
               live(conn, ~p"/admin/moderation/banners")

      assert flash["error"] =~ "administrator"
    end

    test "renders empty state when no banners", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/moderation/banners")

      assert html =~ "Warning Banners"
      assert html =~ "No warning banners"
    end

    test "displays banners", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      admin_scope = Scope.for_user(admin)
      user = user_fixture(%{email: "warned@example.com"})

      {:ok, _banner} =
        Moderation.create_banner(admin_scope, user.id, "Please review community guidelines",
          severity: "warning"
        )

      conn = log_in_user(conn, admin)
      {:ok, _lv, html} = live(conn, ~p"/admin/moderation/banners")

      assert html =~ "warned@example.com"
      assert html =~ "community guidelines"
      assert html =~ "warning"
      assert html =~ "Active"
    end

    test "can toggle banner form", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      conn = log_in_user(conn, admin)

      {:ok, lv, html} = live(conn, ~p"/admin/moderation/banners")

      # Initially no form visible
      refute html =~ ~r/<input[^>]*name="user_id"/

      # Show form using the header button
      html = lv |> element("button.btn-warning[phx-click=toggle_form]") |> render_click()
      assert html =~ ~r/<input[^>]*name="user_id"/
      assert html =~ "Severity"
      assert html =~ "Message"

      # Hide form using cancel button
      html = lv |> element("button.btn-ghost[phx-click=toggle_form]") |> render_click()
      refute html =~ ~r/<input[^>]*name="user_id"/
    end

    test "can create a warning banner", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      user = user_fixture(%{email: "towarn@example.com"})
      conn = log_in_user(conn, admin)

      {:ok, lv, _html} = live(conn, ~p"/admin/moderation/banners")

      # Show form
      lv |> element("button.btn-warning[phx-click=toggle_form]") |> render_click()

      # Create banner
      html =
        lv
        |> form("#banner-form", %{
          user_id: to_string(user.id),
          message: "This is a test warning message for the user",
          severity: "warning"
        })
        |> render_submit()

      assert html =~ "Warning banner sent successfully"
      assert html =~ "towarn@example.com"

      # Verify banner exists
      banners = Moderation.list_active_banners(user.id)
      assert length(banners) == 1
      assert hd(banners).message =~ "test warning"
    end

    test "can delete a banner", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      admin_scope = Scope.for_user(admin)
      user = user_fixture(%{email: "delwarn@example.com"})

      {:ok, _banner} =
        Moderation.create_banner(admin_scope, user.id, "Banner to be deleted")

      conn = log_in_user(conn, admin)
      {:ok, lv, html} = live(conn, ~p"/admin/moderation/banners")

      assert html =~ "delwarn@example.com"

      # Delete banner
      html = lv |> element("button[phx-click=delete_banner]") |> render_click()

      assert html =~ "Banner deleted"
      assert html =~ "No warning banners"
    end

    test "shows correct severity badges", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      admin_scope = Scope.for_user(admin)
      user1 = user_fixture()
      user2 = user_fixture()
      user3 = user_fixture()

      {:ok, _} = Moderation.create_banner(admin_scope, user1.id, "Info message", severity: "info")

      {:ok, _} =
        Moderation.create_banner(admin_scope, user2.id, "Warning message", severity: "warning")

      {:ok, _} =
        Moderation.create_banner(admin_scope, user3.id, "Error message", severity: "error")

      conn = log_in_user(conn, admin)
      {:ok, _lv, html} = live(conn, ~p"/admin/moderation/banners")

      assert html =~ "info"
      assert html =~ "warning"
      assert html =~ "error"
    end
  end
end
