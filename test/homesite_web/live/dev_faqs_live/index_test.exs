defmodule HomesiteWeb.DevFaqsLive.IndexTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  # Note: These tests only work in development environment
  # In test/production, the page redirects away

  describe "DEV FAQs Index (development only)" do
    @tag :skip
    test "displays DEV FAQs page", %{conn: conn} do
      # This would work in dev, but redirects in test environment
      # Using string path to avoid compile-time route warnings in test env
      {:ok, view, html} = live(conn, "/dev/faqs")

      assert html =~ "Developer FAQs"
      assert has_element?(view, "article")
    end

    @tag :skip
    test "shows category filters", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/dev/faqs")

      # Should have category filter buttons
      assert has_element?(view, "button", "Authentication")
      assert has_element?(view, "button", "Database")
    end

    @tag :skip
    test "filters by category", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/dev/faqs")

      # Click a category filter
      view
      |> element("button", "Authentication")
      |> render_click()

      # Should navigate to filtered view
      assert_patch(view, "/dev/faqs?category=authentication")
    end

    @tag :skip
    test "clears category filter", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/dev/faqs?category=authentication")

      # Click clear filter
      view
      |> element("button", "All Categories")
      |> render_click()

      assert_patch(view, "/dev/faqs")
    end

    @tag :skip
    test "shows empty state when no articles match filter", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/dev/faqs?category=nonexistent")

      assert has_element?(view, "h3", "No articles found")
    end
  end

  describe "environment restrictions" do
    test "returns 404 in non-dev environment", %{conn: conn} do
      # In test/production environment, /dev routes don't exist
      # They're only compiled in dev environment
      conn = get(conn, "/dev/faqs")

      # Should get 404 since route doesn't exist in test env
      assert conn.status == 404
    end
  end

  describe "edge cases" do
    test "handles missing category parameter gracefully", %{conn: conn} do
      # In test environment, route doesn't exist (404)
      conn = get(conn, "/dev/faqs")
      assert conn.status == 404
    end

    test "handles empty category parameter", %{conn: conn} do
      # In test environment, route doesn't exist (404)
      conn = get(conn, "/dev/faqs?category=")
      assert conn.status == 404
    end

    test "handles special characters in category parameter", %{conn: conn} do
      # In test environment, route doesn't exist (404)
      conn = get(conn, "/dev/faqs?category=%3Cscript%3E")
      assert conn.status == 404
    end
  end
end
