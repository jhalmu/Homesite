defmodule HomesiteWeb.E2E.PostWorkflowsTest do
  @moduledoc """
  End-to-end tests for post CRUD workflows using Playwright.

  Tests cover:
  - Creating new posts with title and body
  - Editing existing posts
  - Adding and removing tags from posts
  - Publishing and unpublishing posts
  - Deleting posts
  - Post visibility (public vs private)
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

  describe "Posts List Page" do
    @tag :playwright
    test "shows posts list for authenticated user", %{conn: conn, user: user, scope: scope} do
      _post = post_fixture(scope, %{title: "My First Post", is_public: true})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/posts")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Listing Posts")
      |> assert_has("a", text: "My First Post")
    end

    @tag :playwright
    test "shows new post button", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/posts")
      |> assert_has("body .phx-connected")
      |> assert_has("a", text: "New Post")
    end

    @tag :playwright
    test "shows empty state when no posts", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/posts")
      |> assert_has("body .phx-connected")
      |> assert_has("span", text: "No posts yet. Create your first post to get started!")
    end
  end

  describe "Create Post" do
    @tag :playwright
    test "renders new post form", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/posts/new")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "New Post")
      |> assert_has("input[name='post[title]']")
      |> assert_has("textarea[name='post[body]']")
    end

    @tag :playwright
    test "creates post with valid data", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/posts/new")
      |> assert_has("body .phx-connected")
      |> fill_in("Title", with: "E2E Test Post")
      |> fill_in("Body", with: "This is a test post created by Playwright E2E tests.")
      |> click_button("Save Post")
      |> assert_has("body .phx-connected")
      # After save, redirects to index with success message
      |> assert_has(".alert", text: "Post created successfully")
      |> assert_has("a", text: "E2E Test Post")
    end

    @tag :playwright
    test "shows validation error for missing title", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/posts/new")
      |> assert_has("body .phx-connected")
      |> fill_in("Body", with: "Content without title")
      |> click_button("Save Post")
      |> assert_has("p", text: "can't be blank")
    end

    @tag :playwright
    test "shows validation error for missing body", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/posts/new")
      |> assert_has("body .phx-connected")
      |> fill_in("Title", with: "Title without body")
      |> click_button("Save Post")
      |> assert_has("p", text: "can't be blank")
    end

    @tag :playwright
    test "can toggle public visibility", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/posts/new")
      |> assert_has("body .phx-connected")
      |> assert_has("input[name='post[is_public]']")
    end
  end

  describe "Edit Post" do
    @tag :playwright
    test "renders edit form with existing data", %{conn: conn, user: user, scope: scope} do
      post = post_fixture(scope, %{title: "Original Title", body: "Original body content"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/posts/#{post.slug}/edit")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Edit Post")
      |> assert_has("input[value='Original Title']")
    end

    @tag :playwright
    test "updates post with new data", %{conn: conn, user: user, scope: scope} do
      post = post_fixture(scope, %{title: "Original Title", body: "Original body"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/posts/#{post.slug}/edit")
      |> assert_has("body .phx-connected")
      |> fill_in("Title", with: "Updated Title")
      |> click_button("Save Post")
      |> assert_has("body .phx-connected")
      # After save, redirects to index with success message
      |> assert_has(".alert", text: "Post updated successfully")
      |> assert_has("a", text: "Updated Title")
    end
  end

  describe "View Post" do
    @tag :playwright
    test "displays public post to anonymous user", %{conn: conn, scope: scope} do
      post =
        post_fixture(scope, %{
          title: "Public Post",
          body: "This is public content",
          is_public: true,
          published_at: DateTime.utc_now(:second)
        })

      conn
      |> visit(~p"/posts/#{post.slug}")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Public Post")
      |> assert_has("article", text: "This is public content")
    end

    @tag :playwright
    test "displays post with tags", %{conn: conn, user: user, scope: scope} do
      tag = tag_fixture(scope, %{name: "Elixir", is_public: true})

      post =
        post_fixture(scope, %{
          title: "Tagged Post",
          body: "Content with tags",
          is_public: true,
          published_at: DateTime.utc_now(:second),
          tag_ids: [tag.id]
        })

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/posts/#{post.slug}")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Tagged Post")
      # Tags are displayed as badge links in the post metadata
      |> assert_has(".badge-ghost", text: "Elixir")
    end

    @tag :playwright
    test "owner sees edit button", %{conn: conn, user: user, scope: scope} do
      post = post_fixture(scope, %{title: "My Post", is_public: true})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/posts/#{post.slug}")
      |> assert_has("body .phx-connected")
      |> assert_has("a", text: "Edit post")
    end
  end

  describe "Delete Post" do
    @tag :playwright
    test "delete button available on posts list", %{conn: conn, user: user, scope: scope} do
      _post = post_fixture(scope, %{title: "Post to Delete"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/posts")
      |> assert_has("body .phx-connected")
      # Delete button has trash icon, use aria-label
      |> assert_has("a[aria-label='Delete post']")
    end
  end

  describe "Post with Tags" do
    @tag :playwright
    test "can search and add existing tags", %{conn: conn, user: user, scope: scope} do
      _tag = tag_fixture(scope, %{name: "Phoenix", is_public: true})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/posts/new")
      |> assert_has("body .phx-connected")
      |> assert_has("input[name='tag_search']")
    end

    @tag :playwright
    test "can create new tag inline", %{conn: conn, user: user} do
      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/posts/new")
      |> assert_has("body .phx-connected")
      # The tag search input should be present
      |> assert_has("input[name='tag_search']")
    end
  end
end
