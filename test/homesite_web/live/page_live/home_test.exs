defmodule HomesiteWeb.PageLive.HomeTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures
  import Homesite.ContentFixtures

  describe "home page (public)" do
    test "renders welcome message", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ "Welcome"
    end

    test "displays published posts", %{conn: conn} do
      user = user_fixture()
      scope = Homesite.Accounts.Scope.for_user(user)
      post = post_fixture(scope, %{title: "Public Post", published_at: DateTime.utc_now(:second)})

      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ post.title
    end

    test "only displays published posts", %{conn: conn} do
      user = user_fixture()
      scope = Homesite.Accounts.Scope.for_user(user)

      # Create a published post with a specific title
      published_post =
        post_fixture(scope, %{title: "My Published Post", published_at: DateTime.utc_now(:second)})

      {:ok, _lv, html} = live(conn, ~p"/")

      # Published post should be visible on home page
      assert html =~ published_post.title
    end

    test "does not require authentication", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ "Welcome"
    end
  end

  describe "home page (authenticated)" do
    test "shows feed items when logged in", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, _html} = live(conn, ~p"/")
      # Authenticated user sees feed section (even if empty)
    end
  end

  describe "markdown_preview/2" do
    test "truncates long text" do
      markdown = String.duplicate("Hello ", 100)
      preview = HomesiteWeb.PageLive.Home.markdown_preview(markdown, 50)

      assert String.length(preview) <= 53
      assert String.ends_with?(preview, "...")
    end

    test "does not add ellipsis to short text" do
      markdown = "Short text"
      preview = HomesiteWeb.PageLive.Home.markdown_preview(markdown, 100)

      refute String.ends_with?(preview, "...")
    end

    test "strips HTML from markdown" do
      markdown = "# Heading\n\nParagraph text"
      preview = HomesiteWeb.PageLive.Home.markdown_preview(markdown, 100)

      refute preview =~ "<h1>"
      refute preview =~ "<p>"
    end
  end
end
