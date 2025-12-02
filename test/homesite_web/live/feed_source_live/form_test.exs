defmodule HomesiteWeb.FeedSourceLive.FormTest do
  use HomesiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Homesite.ExternalFeeds

  setup :register_and_log_in_user

  describe "New feed source" do
    test "renders form", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/feeds/new")

      assert html =~ "New Feed Source"
      assert html =~ "Feed Type"
      assert html =~ "Name"
    end

    test "creates RSS feed source with form submission", %{conn: conn, scope: scope} do
      {:ok, view, _html} = live(conn, ~p"/feeds/new")

      # First select feed type to make URL field appear
      view
      |> form("#feed_source-form", feed_source: %{"feed_type" => "rss"})
      |> render_change()

      # Fill out the complete form
      form_data = %{
        "feed_type" => "rss",
        "name" => "Elixir Status",
        "url" => "https://elixirstatus.com/rss",
        "icon" => "📰",
        "refresh_interval" => "30",
        "display_order" => "0",
        "enabled" => "true"
      }

      # Submit the form
      view
      |> form("#feed_source-form", feed_source: form_data)
      |> render_submit()

      # Should redirect to feeds page
      assert_redirect(view, ~p"/feeds")

      # Verify feed source was created in database
      feed_sources = ExternalFeeds.list_feed_sources(scope)
      assert length(feed_sources) == 1

      feed_source = hd(feed_sources)
      assert feed_source.name == "Elixir Status"
      assert feed_source.url == "https://elixirstatus.com/rss"
      assert feed_source.feed_type == "rss"
      assert feed_source.user_id == scope.user.id
    end

    test "creates Atom feed source", %{conn: conn, scope: scope} do
      {:ok, view, _html} = live(conn, ~p"/feeds/new")

      # First select feed type
      view
      |> form("#feed_source-form", feed_source: %{"feed_type" => "atom"})
      |> render_change()

      form_data = %{
        "feed_type" => "atom",
        "name" => "GitHub Releases",
        "url" => "https://github.com/elixir-lang/elixir/releases.atom",
        "icon" => "🔔",
        "refresh_interval" => "60",
        "display_order" => "1",
        "enabled" => "true"
      }

      view
      |> form("#feed_source-form", feed_source: form_data)
      |> render_submit()

      assert_redirect(view, ~p"/feeds")

      feed_sources = ExternalFeeds.list_feed_sources(scope)
      assert length(feed_sources) == 1

      feed_source = hd(feed_sources)
      assert feed_source.feed_type == "atom"
      assert feed_source.name == "GitHub Releases"
    end

    test "validates required fields", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/feeds/new")

      # Select feed type first
      view
      |> form("#feed_source-form", feed_source: %{"feed_type" => "rss"})
      |> render_change()

      # Submit with missing name (empty string)
      form_data = %{
        "feed_type" => "rss",
        "name" => "",
        "url" => "https://example.com/feed.xml"
      }

      html =
        view
        |> form("#feed_source-form", feed_source: form_data)
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end

    test "validates URL for RSS feed type", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/feeds/new")

      # Select RSS feed type first
      view
      |> form("#feed_source-form", feed_source: %{"feed_type" => "rss"})
      |> render_change()

      # Submit with empty URL
      form_data = %{
        "feed_type" => "rss",
        "name" => "Test Feed",
        "url" => ""
      }

      html =
        view
        |> form("#feed_source-form", feed_source: form_data)
        |> render_change()

      # Should show validation error
      assert html =~ "can&#39;t be blank"
    end
  end

  describe "Edit feed source" do
    setup %{scope: scope} do
      {:ok, feed_source} =
        ExternalFeeds.create_feed_source(scope, %{
          "feed_type" => "rss",
          "name" => "Original Name",
          "url" => "https://example.com/feed.xml",
          "enabled" => true
        })

      %{feed_source: feed_source}
    end

    test "renders edit form", %{conn: conn, feed_source: feed_source} do
      {:ok, _view, html} = live(conn, ~p"/feeds/#{feed_source.id}/edit")

      assert html =~ "Edit Feed Source"
      assert html =~ "Original Name"
    end

    test "updates feed source", %{conn: conn, scope: scope, feed_source: feed_source} do
      {:ok, view, _html} = live(conn, ~p"/feeds/#{feed_source.id}/edit")

      form_data = %{
        "feed_type" => "rss",
        "name" => "Updated Name",
        "url" => "https://example.com/new-feed.xml",
        "enabled" => "true"
      }

      view
      |> form("#feed_source-form", feed_source: form_data)
      |> render_submit()

      assert_redirect(view, ~p"/feeds")

      # Verify update
      updated = ExternalFeeds.get_feed_source!(scope, feed_source.id)
      assert updated.name == "Updated Name"
      assert updated.url == "https://example.com/new-feed.xml"
    end
  end
end
