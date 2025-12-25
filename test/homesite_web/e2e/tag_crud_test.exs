defmodule HomesiteWeb.E2E.TagCrudTest do
  @moduledoc """
  End-to-end tests for tag CRUD workflows using Playwright.

  Tests cover:
  - Creating new tags
  - Editing existing tags
  - Viewing tag details and associated posts
  - Deleting tags
  - Similar tag warnings
  - Tag visibility settings
  """
  use PhoenixTest.Playwright.Case, async: false
  use HomesiteWeb, :verified_routes

  import Homesite.AccountsFixtures
  import Homesite.ContentFixtures
  import HomesiteWeb.PlaywrightAuthHelper

  setup do
    Homesite.DataCase.ensure_test_invitation()
    user = user_fixture()
    scope = %Homesite.Accounts.Scope{user: user}
    %{user: user, scope: scope}
  end

  describe "Tags List Page" do
    @tag :playwright
    test "shows tags list for authenticated user", %{conn: conn, user: user, scope: scope} do
      _tag = tag_fixture(scope, %{name: "Elixir", is_public: true})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/tags")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Listing Tags")
      |> assert_has("a", text: "Elixir")
    end

    @tag :playwright
    test "shows new tag button", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/tags")
      |> assert_has("body .phx-connected")
      |> assert_has("a", text: "New Tag")
    end

    @tag :playwright
    test "shows empty state when no tags", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/tags")
      |> assert_has("body .phx-connected")
      |> assert_has("span", text: "No tags yet. Create your first tag to get started!")
    end
  end

  describe "Create Tag" do
    @tag :playwright
    test "renders new tag form", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/tags/new")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "New Tag")
      |> assert_has("input[name='tag[name]']")
      |> assert_has("textarea[name='tag[description]']")
    end

    @tag :playwright
    test "creates tag with valid data", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/tags/new")
      |> assert_has("body .phx-connected")
      |> fill_in("Name", with: "E2E Test Tag")
      |> fill_in("Description", with: "A tag created by E2E tests")
      |> click_button("Save Tag")
      |> assert_has("body .phx-connected")
      # After save, redirects to index page
      |> assert_has("h1", text: "Listing Tags")
      |> assert_has("a", text: "E2E Test Tag")
    end

    @tag :playwright
    test "shows validation error for missing name", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/tags/new")
      |> assert_has("body .phx-connected")
      |> fill_in("Description", with: "Description without name")
      |> click_button("Save Tag")
      |> assert_has("p", text: "can't be blank")
    end

    @tag :playwright
    test "shows validation error for duplicate tag name", %{conn: conn, user: user, scope: scope} do
      _existing = tag_fixture(scope, %{name: "Duplicate Tag"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/tags/new")
      |> assert_has("body .phx-connected")
      |> fill_in("Name", with: "Duplicate Tag")
      |> click_button("Save Tag")
      |> assert_has("p", text: "already exists")
    end

    @tag :playwright
    test "public toggle is checked by default", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/tags/new")
      |> assert_has("body .phx-connected")
      |> assert_has("input[name='tag[is_public]'][checked]")
    end

    @tag :playwright
    test "toggle stays checked when typing", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/tags/new")
      |> assert_has("body .phx-connected")
      |> assert_has("input[name='tag[is_public]'][checked]")
      |> fill_in("Name", with: "Test Tag Name")
      # Verify toggle is still checked after typing
      |> assert_has("input[name='tag[is_public]'][checked]")
    end
  end

  describe "Edit Tag" do
    @tag :playwright
    test "renders edit form with existing data", %{conn: conn, user: user, scope: scope} do
      tag = tag_fixture(scope, %{name: "Original Tag", description: "Original description"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/tags/#{tag}/edit")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Edit Tag")
      |> assert_has("input[value='Original Tag']")
    end

    @tag :playwright
    test "updates tag with new data", %{conn: conn, user: user, scope: scope} do
      tag = tag_fixture(scope, %{name: "Original Tag"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/tags/#{tag}/edit")
      |> assert_has("body .phx-connected")
      |> fill_in("Name", with: "Updated Tag Name")
      |> click_button("Save Tag")
      |> assert_has("body .phx-connected")
      # After save, redirects to index page by default
      |> assert_has("h1", text: "Listing Tags")
      |> assert_has("a", text: "Updated Tag Name")
    end
  end

  describe "View Tag" do
    @tag :playwright
    test "displays tag page with description", %{conn: conn, user: user, scope: scope} do
      tag = tag_fixture(scope, %{name: "Elixir", description: "Elixir programming language"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/tags/#{tag}")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Elixir")
      |> assert_has("p", text: "Elixir programming language")
    end

    @tag :playwright
    test "displays posts with this tag", %{conn: conn, user: user, scope: scope} do
      tag = tag_fixture(scope, %{name: "Programming", is_public: true})

      _post =
        post_fixture(scope, %{
          title: "Programming Post",
          is_public: true,
          published_at: DateTime.utc_now(:second),
          tag_ids: [tag.id]
        })

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/tags/#{tag}")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Programming")
      # Post title appears somewhere on the page (link text)
      |> assert_has("a", text: "Programming Post")
    end

    @tag :playwright
    test "owner sees edit button", %{conn: conn, user: user, scope: scope} do
      tag = tag_fixture(scope, %{name: "My Tag"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/tags/#{tag}")
      |> assert_has("body .phx-connected")
      |> assert_has("a", text: "Edit Tag")
    end

    @tag :playwright
    test "shows empty posts state", %{conn: conn, user: user, scope: scope} do
      tag = tag_fixture(scope, %{name: "Empty Tag"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/tags/#{tag}")
      |> assert_has("body .phx-connected")
      |> assert_has("span", text: "You don't have any posts with this tag yet.")
    end
  end

  describe "Similar Tag Warning" do
    @tag :playwright
    test "shows warning for similar tag names", %{conn: conn, user: user, scope: scope} do
      _existing = tag_fixture(scope, %{name: "Elixir"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/tags/new")
      |> assert_has("body .phx-connected")
      |> fill_in("Name", with: "Elixer")
      |> assert_has(".alert-warning", text: "Similar tags already exist:")
    end
  end

  describe "Delete Tag" do
    @tag :playwright
    test "delete button available on index page", %{conn: conn, user: user, scope: scope} do
      _tag = tag_fixture(scope, %{name: "Tag to Delete"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/tags")
      |> assert_has("body .phx-connected")
      # Delete button has aria-label but no text
      |> assert_has("a[aria-label='Delete tag']")
    end
  end
end
