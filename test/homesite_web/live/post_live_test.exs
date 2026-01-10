defmodule HomesiteWeb.PostLiveTest do
  use HomesiteWeb.ConnCase

  import Phoenix.LiveViewTest
  import Homesite.ContentFixtures

  @create_attrs %{
    title: "some title",
    body: "some body content that is long enough",
    publish_date: "2025-11-20",
    publish_time: "11:44"
  }
  @update_attrs %{
    title: "some updated title",
    body: "some updated body content that is long enough",
    publish_date: "2025-11-21",
    publish_time: "11:44"
  }
  @invalid_attrs %{title: nil, body: nil, publish_date: nil, publish_time: nil}

  setup :register_and_log_in_user

  defp create_post(%{scope: scope}) do
    post = post_fixture(scope)

    %{post: post}
  end

  describe "Index" do
    setup [:create_post]

    test "lists all posts", %{conn: conn, post: post} do
      {:ok, _index_live, html} = live(conn, ~p"/posts")

      assert html =~ "Listing Posts"
      assert html =~ post.title
    end

    test "saves new post", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/posts")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Post")
               |> render_click()
               |> follow_redirect(conn, ~p"/posts/new")

      assert render(form_live) =~ "New Post"

      assert form_live
             |> form("#post-form", post: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#post-form", post: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/posts")

      html = render(index_live)
      assert html =~ "Post created successfully"
      assert html =~ "some title"
    end

    test "updates post in listing", %{conn: conn, post: post} do
      {:ok, index_live, _html} = live(conn, ~p"/posts")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#posts-#{post.id} a[href='/posts/#{post.slug}/edit']")
               |> render_click()
               |> follow_redirect(conn, ~p"/posts/#{post.slug}/edit")

      assert render(form_live) =~ "Edit Post"

      assert form_live
             |> form("#post-form", post: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#post-form", post: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/posts")

      html = render(index_live)
      assert html =~ "Post updated successfully"
      assert html =~ "some updated title"
    end

    test "deletes post in listing", %{conn: conn, post: post} do
      {:ok, index_live, _html} = live(conn, ~p"/posts")

      assert index_live |> element("#posts-#{post.id} a[phx-click*='delete']") |> render_click()
      refute has_element?(index_live, "#posts-#{post.id}")
    end
  end

  describe "Show" do
    setup [:create_post]

    test "displays post", %{conn: conn, post: post} do
      {:ok, _show_live, html} = live(conn, ~p"/posts/#{post.slug}")

      assert html =~ post.title
      assert html =~ post.body
    end

    test "shows edit button for post owner", %{conn: conn, post: post} do
      {:ok, show_live, _html} = live(conn, ~p"/posts/#{post.slug}")

      assert has_element?(show_live, "a", "Edit post")
    end

    test "hides edit button for non-owner", %{scope: scope} do
      other_scope = Homesite.AccountsFixtures.user_scope_fixture()
      other_post = Homesite.ContentFixtures.post_fixture(other_scope, %{is_public: true})

      conn = build_conn() |> log_in_user(scope.user)
      {:ok, show_live, _html} = live(conn, ~p"/posts/#{other_post.slug}")

      refute has_element?(show_live, "a", "Edit post")
    end

    test "updates post and returns to show", %{conn: conn, post: post} do
      {:ok, show_live, _html} = live(conn, ~p"/posts/#{post.slug}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/posts/#{post.slug}/edit?return_to=show")

      assert render(form_live) =~ "Edit Post"

      assert form_live
             |> form("#post-form", post: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#post-form", post: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/posts/#{post.slug}")

      html = render(show_live)
      assert html =~ "Post updated successfully"
      assert html =~ "some updated title"
    end
  end

  describe "Show (non-authenticated)" do
    test "non-authenticated user can view public post" do
      scope = Homesite.AccountsFixtures.user_scope_fixture()
      public_post = Homesite.ContentFixtures.post_fixture(scope, %{is_public: true})

      conn = build_conn()
      {:ok, _show_live, html} = live(conn, ~p"/posts/#{public_post.slug}")

      assert html =~ public_post.title
      assert html =~ public_post.body
    end

    test "non-authenticated user cannot view private post" do
      scope = Homesite.AccountsFixtures.user_scope_fixture()
      private_post = Homesite.ContentFixtures.post_fixture(scope, %{is_public: false})

      conn = build_conn()

      # The LiveView will raise Ecto.NoResultsError during mount
      # Phoenix catches this and renders a 404 error page
      assert_error_sent 404, fn ->
        live(conn, ~p"/posts/#{private_post.slug}")
      end
    end

    test "non-authenticated user does not see edit button on public post" do
      scope = Homesite.AccountsFixtures.user_scope_fixture()
      public_post = Homesite.ContentFixtures.post_fixture(scope, %{is_public: true})

      conn = build_conn()
      {:ok, show_live, _html} = live(conn, ~p"/posts/#{public_post.slug}")

      refute has_element?(show_live, "a", "Edit post")
    end
  end
end
