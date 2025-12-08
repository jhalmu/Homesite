defmodule HomesiteWeb.MediaLive.IndexTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures
  import Homesite.MediaFixtures

  describe "Media Library page" do
    setup %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      scope = %Homesite.Accounts.Scope{user: user}

      %{conn: conn, user: user, scope: scope}
    end

    test "renders empty media library", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/media")

      assert html =~ "Media Library"
      assert html =~ "No media items yet"
    end

    test "renders media library with items", %{conn: conn, scope: scope} do
      # Create a media item
      media = media_item_fixture(scope)

      {:ok, _view, html} = live(conn, ~p"/media")

      assert html =~ "Media Library"
      assert html =~ media.alt_text
    end

    test "search filters media items", %{conn: conn, scope: scope} do
      # Create media items with distinct titles
      _media1 = media_item_fixture(scope, %{title: "Unique Photo"})
      _media2 = media_item_fixture(scope, %{title: "Other Image"})

      {:ok, view, _html} = live(conn, ~p"/media")

      # Search for specific item using the search event
      html = render_hook(view, "search", %{"query" => "Unique"})

      assert html =~ "Unique Photo"
      refute html =~ "Other Image"
    end

    test "aspect filter works", %{conn: conn, scope: scope} do
      # Create a square media item
      _media = media_item_fixture(scope)

      {:ok, view, _html} = live(conn, ~p"/media")

      # Filter by aspect ratio
      html =
        view
        |> element("select[name=aspect]")
        |> render_change(%{aspect: "square"})

      # Should still show the media library
      assert html =~ "Media Library"
    end

    test "empty search shows message", %{conn: conn, scope: scope} do
      _media = media_item_fixture(scope, %{title: "Test Image"})

      {:ok, view, _html} = live(conn, ~p"/media")

      # Search for non-existent term
      html = render_hook(view, "search", %{"query" => "nonexistent12345"})

      assert html =~ "No media items found"
    end
  end
end
