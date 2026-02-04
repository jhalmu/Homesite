defmodule HomesiteWeb.AdminLive.Moderation.SuspensionsTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures

  alias Homesite.Accounts.Scope
  alias Homesite.Moderation

  describe "suspensions page" do
    test "redirects non-admin users", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/", flash: flash}}} =
               live(conn, ~p"/admin/moderation/suspensions")

      assert flash["error"] =~ "administrator"
    end

    test "renders empty state when no suspensions", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      conn = log_in_user(conn, admin)

      {:ok, _lv, html} = live(conn, ~p"/admin/moderation/suspensions")

      assert html =~ "User Suspensions"
      assert html =~ "No active suspensions"
    end

    test "displays active suspensions", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      admin_scope = Scope.for_user(admin)
      user = user_fixture(%{email: "suspended@example.com"})

      expires_at = DateTime.utc_now() |> DateTime.add(86_400, :second)

      {:ok, _suspension} =
        Moderation.suspend_user(admin_scope, user.id, "Violation of terms", expires_at)

      conn = log_in_user(conn, admin)
      {:ok, _lv, html} = live(conn, ~p"/admin/moderation/suspensions")

      assert html =~ "suspended@example.com"
      assert html =~ "Violation of terms"
      assert html =~ "Unsuspend"
    end

    test "can toggle suspension form", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      conn = log_in_user(conn, admin)

      {:ok, lv, html} = live(conn, ~p"/admin/moderation/suspensions")

      # Initially no form visible
      refute html =~ ~r/<input[^>]*name="user_search"/

      # Show form using header button
      html = lv |> element("button.btn-warning[phx-click=toggle_form]") |> render_click()
      assert html =~ ~r/<input[^>]*name="user_search"/
      assert html =~ "Expires At"
      assert html =~ "Reason"

      # Hide form using cancel button
      html = lv |> element("button.btn-ghost[phx-click=toggle_form]") |> render_click()
      refute html =~ ~r/<input[^>]*name="user_search"/
    end

    test "can suspend a user via user search", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      user = user_fixture()
      conn = log_in_user(conn, admin)

      {:ok, lv, _html} = live(conn, ~p"/admin/moderation/suspensions")

      # Show form
      lv |> element("button.btn-warning[phx-click=toggle_form]") |> render_click()

      # Search for user
      lv |> render_hook("search_users", %{query: user.email})

      # Select the user
      lv |> render_click("select_user", %{id: to_string(user.id)})

      # Submit suspension
      expires_at =
        DateTime.utc_now()
        |> DateTime.add(86_400, :second)
        |> DateTime.to_iso8601()

      html =
        lv
        |> form("#suspend-form", %{
          reason: "Testing suspension functionality",
          expires_at: expires_at
        })
        |> render_submit()

      assert html =~ "User suspended successfully"
      assert Moderation.suspended?(user.id)
    end

    test "can unsuspend a user", %{conn: conn} do
      admin = admin_fixture(%{admin_flowers: 5})
      admin_scope = Scope.for_user(admin)
      user = user_fixture(%{email: "tounsuspend@example.com"})

      expires_at = DateTime.utc_now() |> DateTime.add(86_400, :second)

      {:ok, _suspension} =
        Moderation.suspend_user(admin_scope, user.id, "Will be lifted", expires_at)

      conn = log_in_user(conn, admin)
      {:ok, lv, html} = live(conn, ~p"/admin/moderation/suspensions")

      assert html =~ "tounsuspend@example.com"

      # Unsuspend
      html = lv |> element("button[phx-click=unsuspend]") |> render_click()

      assert html =~ "User unsuspended successfully"
      refute Moderation.suspended?(user.id)
    end
  end
end
