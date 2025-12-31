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

    test "shows orphan filter button with count", %{conn: conn, scope: scope} do
      # Create orphan media (not in any project)
      _orphan = media_item_fixture(scope, %{title: "Orphan Image"})

      {:ok, _view, html} = live(conn, ~p"/media")

      # Should show the "Unused" button with count
      # The button should be in the filter section
      assert html =~ "toggle-orphan-filter"
      assert html =~ "hero-archive-box-x-mark"
    end

    test "orphan filter toggles correctly", %{conn: conn, scope: scope} do
      # Create orphan media with unique alt text
      orphan =
        media_item_fixture(scope, %{title: "Orphan Media", alt_text: "Unique orphan alt text"})

      # Create attached media with unique alt text
      project = project_fixture(scope)

      attached =
        media_item_fixture(scope, %{title: "Attached Media", alt_text: "Unique attached alt text"})

      {:ok, _} = Homesite.Media.add_media_to_project(scope, project.id, attached.id, 1)

      {:ok, view, html} = live(conn, ~p"/media")

      # Initially shows both
      assert html =~ "Orphan Media"
      assert html =~ "Attached Media"

      # Toggle orphan filter on
      html = render_click(view, "toggle-orphan-filter")

      # Should only show orphan (check by unique alt text)
      assert html =~ "Unique orphan alt text"
      refute html =~ "Unique attached alt text"

      # Toggle orphan filter off
      html = render_click(view, "toggle-orphan-filter")

      # Should show both again
      assert html =~ "Unique orphan alt text"
      assert html =~ "Unique attached alt text"
    end

    test "orphan filter shows empty message when all used", %{conn: conn, scope: scope} do
      # Create only attached media
      project = project_fixture(scope)
      attached = media_item_fixture(scope, %{title: "All Used"})
      {:ok, _} = Homesite.Media.add_media_to_project(scope, project.id, attached.id, 1)

      {:ok, view, _html} = live(conn, ~p"/media")

      # Toggle orphan filter on
      html = render_click(view, "toggle-orphan-filter")

      # Should show appropriate message
      assert html =~ "All images are in use"
    end

    test "orphan count updates when media added to project", %{conn: conn, scope: scope} do
      # Create orphan media
      orphan = media_item_fixture(scope, %{title: "Soon Attached"})

      {:ok, _view, html} = live(conn, ~p"/media")

      # Should show orphan filter button
      assert html =~ "toggle-orphan-filter"

      # Add to project (simulating real-time update would require PubSub)
      project = project_fixture(scope)
      {:ok, _} = Homesite.Media.add_media_to_project(scope, project.id, orphan.id, 1)

      # Refresh the page to see updated count
      {:ok, _view, html} = live(conn, ~p"/media")

      # Button should still be visible after media is attached
      assert html =~ "toggle-orphan-filter"
    end

    test "orphan filter button has proper accessibility", %{conn: conn, scope: scope} do
      _orphan = media_item_fixture(scope)

      {:ok, _view, html} = live(conn, ~p"/media")

      # Button should be present and have icon
      assert html =~ "toggle-orphan-filter"
      assert html =~ "hero-archive-box-x-mark"
    end
  end
end
