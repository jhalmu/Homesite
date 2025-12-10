defmodule HomesiteWeb.AdminLive.Moderation.BansTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures

  alias Homesite.Accounts.Scope
  alias Homesite.Moderation

  describe "bans page" do
    test "redirects non-admin users", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/", flash: flash}}} =
               live(conn, ~p"/admin/moderation/bans")

      assert flash["error"] =~ "administrator"
    end

    test "renders empty state when no bans", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/moderation/bans")

      assert html =~ "User Bans"
      assert html =~ "No active bans"
    end

    test "displays active bans", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      admin_scope = Scope.for_user(admin)
      user = user_fixture(%{email: "banned@example.com"})

      {:ok, _ban} = Moderation.ban_user(admin_scope, user.id, "Severe violation of terms")

      conn = log_in_user(conn, admin)
      {:ok, _lv, html} = live(conn, ~p"/admin/moderation/bans")

      assert html =~ "banned@example.com"
      assert html =~ "Severe violation"
      assert html =~ "Unban"
    end

    test "can toggle ban form", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      conn = log_in_user(conn, admin)

      {:ok, lv, html} = live(conn, ~p"/admin/moderation/bans")

      # Initially no form visible
      refute html =~ ~r/<input[^>]*name="user_id"/

      # Show form using header button - should have warning about permanence
      html = lv |> element("button.btn-error[phx-click=toggle_form]") |> render_click()
      assert html =~ ~r/<input[^>]*name="user_id"/
      assert html =~ "Reason"
      assert html =~ "permanent"

      # Hide form using cancel button
      html = lv |> element("button.btn-ghost[phx-click=toggle_form]") |> render_click()
      refute html =~ ~r/<input[^>]*name="user_id"/
    end

    test "can ban a user", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      user = user_fixture()
      conn = log_in_user(conn, admin)

      {:ok, lv, _html} = live(conn, ~p"/admin/moderation/bans")

      # Show form using header button
      lv |> element("button.btn-error[phx-click=toggle_form]") |> render_click()

      # Submit ban
      html =
        lv
        |> form("#ban-form", %{
          user_id: to_string(user.id),
          reason: "Permanent ban for severe violations"
        })
        |> render_submit()

      assert html =~ "User banned successfully"
      assert Moderation.banned?(user.id)
    end

    test "can unban a user", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      admin_scope = Scope.for_user(admin)
      user = user_fixture(%{email: "tounban@example.com"})

      {:ok, _ban} = Moderation.ban_user(admin_scope, user.id, "Will be unbanned")

      conn = log_in_user(conn, admin)
      {:ok, lv, html} = live(conn, ~p"/admin/moderation/bans")

      assert html =~ "tounban@example.com"

      # Unban
      html = lv |> element("button[phx-click=unban]") |> render_click()

      assert html =~ "User unbanned successfully"
      refute Moderation.banned?(user.id)
    end
  end
end
