defmodule HomesiteWeb.ModerationLive.MutesTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures

  alias Homesite.Accounts.Scope
  alias Homesite.Moderation

  describe "mutes page" do
    test "redirects unauthenticated users", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/moderation/mutes")
    end

    test "renders empty state when no muted users", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/moderation/mutes")

      assert html =~ "Muted Users"
      assert html =~ "No muted users"
      assert html =~ "haven&#39;t muted anyone"
    end

    test "displays muted users list", %{conn: conn} do
      user = user_fixture()
      other_user = user_fixture(%{email: "muted@example.com"})
      scope = Scope.for_user(user)

      {:ok, _mute} = Moderation.mute_user(scope, other_user.id, reason: "Spamming")

      conn = log_in_user(conn, user)
      {:ok, _lv, html} = live(conn, ~p"/moderation/mutes")

      assert html =~ "Muted Users"
      assert html =~ "muted@example.com"
      assert html =~ "Spamming"
      assert html =~ "Unmute"
    end

    test "can unmute a user", %{conn: conn} do
      user = user_fixture()
      other_user = user_fixture(%{email: "tomute@example.com"})
      scope = Scope.for_user(user)

      {:ok, _mute} = Moderation.mute_user(scope, other_user.id, reason: "Temporary")

      conn = log_in_user(conn, user)
      {:ok, lv, html} = live(conn, ~p"/moderation/mutes")

      assert html =~ "tomute@example.com"

      # Unmute the user
      html = lv |> element("button[phx-click=unmute]") |> render_click()

      assert html =~ "No muted users"
      refute html =~ "tomute@example.com"
    end
  end
end
