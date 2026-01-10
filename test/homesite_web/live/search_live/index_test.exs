defmodule HomesiteWeb.SearchLive.IndexTest do
  use HomesiteWeb.ConnCase

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures
  import Homesite.ContentFixtures

  alias Homesite.Content

  setup do
    user = user_fixture()
    scope = Homesite.Accounts.Scope.for_user(user)

    # Create searchable posts
    {:ok, post1} =
      Content.create_post(scope, %{
        title: "Elixir Programming Guide",
        body: "Learn functional programming with Elixir",
        published_at: DateTime.utc_now(:second)
      })

    {:ok, post2} =
      Content.create_post(scope, %{
        title: "Phoenix Framework Tutorial",
        body: "Build web applications with Phoenix and Elixir",
        published_at: DateTime.utc_now(:second)
      })

    %{scope: scope, post1: post1, post2: post2}
  end

  describe "Search page" do
    test "displays search form", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/search")

      assert html =~ "Search"
      assert has_element?(view, "form#search-form")
      assert has_element?(view, "input[name='query']")
    end

    test "shows empty state when no query", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/search")

      assert html =~ "Start searching"
      assert html =~ "Enter keywords to search"
    end

    test "performs search via URL params", %{conn: conn, post1: post1} do
      {:ok, _view, html} = live(conn, ~p"/search?#{[q: "Elixir"]}")

      assert html =~ post1.title
      assert html =~ "result"
    end

    test "displays search results", %{conn: conn, post1: post1} do
      {:ok, view, _html} = live(conn, ~p"/search")

      html = render_submit(view, "search", %{"query" => "Elixir"})

      assert html =~ post1.title
      assert html =~ "result"
    end

    test "shows 'no results' message for non-matching query", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/search")

      html = render_submit(view, "search", %{"query" => "NonExistentTerm12345"})

      assert html =~ "No results found"
    end

    test "displays multiple results when available", %{conn: conn, post1: post1, post2: post2} do
      {:ok, view, _html} = live(conn, ~p"/search")

      html = render_submit(view, "search", %{"query" => "Elixir"})

      assert html =~ post1.title
      assert html =~ post2.title
    end

    test "includes link to post", %{conn: conn, post1: post1} do
      {:ok, view, _html} = live(conn, ~p"/search")

      html = render_submit(view, "search", %{"query" => "Elixir"})

      assert html =~ "/posts/#{post1.slug}"
    end

    test "shows post metadata (author, date)", %{conn: conn, post1: post1, scope: scope} do
      {:ok, view, _html} = live(conn, ~p"/search")

      html = render_submit(view, "search", %{"query" => "Elixir"})

      assert html =~ scope.user.email
      assert html =~ Calendar.strftime(post1.published_at, "%B %d, %Y")
    end

    test "allows clearing search", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/search?#{[q: "Elixir"]}")

      assert has_element?(view, "button[phx-click='clear']")

      # Clear uses push_patch, not redirect
      html = view |> element("button[phx-click='clear']") |> render_click()

      assert html =~ "Start searching"
      refute html =~ "result"
    end

    test "displays posts without errors when no tags", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/search")

      html = render_submit(view, "search", %{"query" => "Elixir"})

      # Just verify search works without tags
      assert html =~ "result"
    end
  end
end
