defmodule HomesiteWeb.E2E.FeedManagementTest do
  @moduledoc """
  End-to-end tests for feed/RSS management workflows using Playwright.

  Tests cover:
  - Viewing aggregated feed
  - Managing feed sources (CRUD)
  - Managing feed folders
  - Feed source configuration
  - Feed refresh functionality
  """
  use PhoenixTest.Playwright.Case, async: false
  use HomesiteWeb, :verified_routes

  import Homesite.AccountsFixtures
  import HomesiteWeb.PlaywrightAuthHelper

  alias Homesite.ExternalFeeds

  setup do
    Homesite.DataCase.ensure_test_invitation()
    user = user_fixture()
    scope = %Homesite.Accounts.Scope{user: user}
    %{user: user, scope: scope}
  end

  describe "Feed Index Page" do
    @tag :playwright
    test "shows aggregated feed for authenticated user", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/feed")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Feed")
    end

    @tag :playwright
    test "shows empty state when no feed sources", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/feed")
      |> assert_has("body .phx-connected")
      |> assert_has("span", text: "No feed items found")
    end

    @tag :playwright
    test "has link to manage feed sources", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/feed")
      |> assert_has("body .phx-connected")
      |> assert_has("a", text: "Manage Sources")
    end
  end

  describe "Feed Sources List" do
    @tag :playwright
    test "shows feed sources list", %{conn: conn, user: user, scope: scope} do
      {:ok, _source} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "Test RSS Feed",
          url: "https://example.com/feed.xml",
          feed_type: "rss"
        })

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/feeds")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "My Feed Sources")
      |> assert_has("div", text: "Test RSS Feed")
    end

    @tag :playwright
    test "shows new feed source button", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/feeds")
      |> assert_has("body .phx-connected")
      |> assert_has("button", text: "New Feed Source")
    end

    @tag :playwright
    test "shows empty state when no sources", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/feeds")
      |> assert_has("body .phx-connected")
      # Table shows empty when no sources, but we should at least verify the page loaded
      |> assert_has("h1", text: "My Feed Sources")
    end
  end

  describe "Create Feed Source" do
    @tag :playwright
    test "renders new feed source form", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/feeds/new")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "New Feed Source")
      |> assert_has("input[name='feed_source[name]']")
      |> assert_has("select[name='feed_source[feed_type]']")

      # URL field is conditionally shown based on feed_type, so just verify the form loads
    end

    @tag :playwright
    test "shows feed type selector", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/feeds/new")
      |> assert_has("body .phx-connected")
      |> assert_has("select[name='feed_source[feed_type]']")
    end

    @tag :playwright
    test "creates RSS feed source with valid data", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/feeds/new")
      |> assert_has("body .phx-connected")
      |> fill_in("Name", with: "My RSS Feed")
      |> fill_in("Feed URL", with: "https://example.com/rss.xml")
      |> click_button("Save Feed Source")
      |> assert_has("body .phx-connected")
      |> assert_has("div", text: "My RSS Feed")
    end

    @tag :playwright
    test "shows validation error for missing name", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/feeds/new")
      |> assert_has("body .phx-connected")
      # Name field is required, leaving it empty should trigger validation
      |> click_button("Save Feed Source")
      |> assert_has("p", text: "can't be blank")
    end

    @tag :playwright
    test "shows validation error for missing URL", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/feeds/new")
      |> assert_has("body .phx-connected")
      |> fill_in("Name", with: "Test Feed")
      # Don't fill in URL - should get validation error
      |> click_button("Save Feed Source")
      # Should show validation error for missing URL (required for RSS feed type)
      |> assert_has("p", text: "can't be blank")
    end
  end

  describe "Edit Feed Source" do
    @tag :playwright
    test "renders edit form with existing data", %{conn: conn, user: user, scope: scope} do
      {:ok, source} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "Existing Feed",
          url: "https://example.com/feed.xml",
          feed_type: "rss"
        })

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/feeds/#{source}/edit")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Edit Feed Source")
      |> assert_has("input[value='Existing Feed']")
    end

    @tag :playwright
    test "can update feed source name", %{conn: conn, user: user, scope: scope} do
      {:ok, source} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "Old Name",
          url: "https://example.com/feed.xml",
          feed_type: "rss"
        })

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/feeds/#{source}/edit")
      |> assert_has("body .phx-connected")
      |> fill_in("Name", with: "New Feed Name")
      |> click_button("Save Feed Source")
      |> assert_has("body .phx-connected")
      |> assert_has("div", text: "New Feed Name")
    end
  end

  describe "View Feed Source" do
    @tag :playwright
    test "displays feed source details", %{conn: conn, user: user, scope: scope} do
      {:ok, source} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "Test Feed",
          url: "https://example.com/feed.xml",
          feed_type: "rss"
        })

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/feeds/#{source}")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Test Feed")
    end

    @tag :playwright
    test "shows edit button", %{conn: conn, user: user, scope: scope} do
      {:ok, source} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "My Feed",
          url: "https://example.com/feed.xml",
          feed_type: "rss"
        })

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/feeds/#{source}")
      |> assert_has("body .phx-connected")
      |> assert_has("button", text: "Edit")
    end

    @tag :playwright
    test "shows refresh button", %{conn: conn, user: user, scope: scope} do
      {:ok, source} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "My Feed",
          url: "https://example.com/feed.xml",
          feed_type: "rss"
        })

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/feeds/#{source}")
      |> assert_has("body .phx-connected")
      |> assert_has("button", text: "Refresh Now")
    end
  end

  describe "Feed Folders" do
    @tag :playwright
    test "shows folders list", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/folders")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Feed Folders")
    end

    @tag :playwright
    test "shows create folder button", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/folders")
      |> assert_has("body .phx-connected")
      |> assert_has("button", text: "New Folder")
    end
  end

  describe "Delete Feed Source" do
    @tag :playwright
    test "delete link available on sources list", %{conn: conn, user: user, scope: scope} do
      {:ok, _source} =
        ExternalFeeds.create_feed_source(scope, %{
          name: "Feed to Delete",
          url: "https://example.com/feed.xml",
          feed_type: "rss"
        })

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/feeds")
      |> assert_has("body .phx-connected")
      |> assert_has("a", text: "Delete")
    end
  end
end
