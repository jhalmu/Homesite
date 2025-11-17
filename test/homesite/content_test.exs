defmodule Homesite.ContentTest do
  use Homesite.DataCase

  alias Homesite.Content

  describe "blog_posts" do
    alias Homesite.Content.BlogPost

    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.ContentFixtures

    @invalid_attrs %{status: nil, metadata: nil, title_fi: nil, title_en: nil, content_fi: nil, content_en: nil, slug: nil, author_type: nil, author_id: nil, curator_added: nil, published_at: nil}

    test "list_blog_posts/1 returns all scoped blog_posts" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      blog_post = blog_post_fixture(scope)
      other_blog_post = blog_post_fixture(other_scope)
      assert Content.list_blog_posts(scope) == [blog_post]
      assert Content.list_blog_posts(other_scope) == [other_blog_post]
    end

    test "get_blog_post!/2 returns the blog_post with given id" do
      scope = user_scope_fixture()
      blog_post = blog_post_fixture(scope)
      other_scope = user_scope_fixture()
      assert Content.get_blog_post!(scope, blog_post.id) == blog_post
      assert_raise Ecto.NoResultsError, fn -> Content.get_blog_post!(other_scope, blog_post.id) end
    end

    test "create_blog_post/2 with valid data creates a blog_post" do
      valid_attrs = %{status: "some status", metadata: %{}, title_fi: "some title_fi", title_en: "some title_en", content_fi: "some content_fi", content_en: "some content_en", slug: "some slug", author_type: "some author_type", author_id: 42, curator_added: true, published_at: ~U[2025-11-16 15:19:00Z]}
      scope = user_scope_fixture()

      assert {:ok, %BlogPost{} = blog_post} = Content.create_blog_post(scope, valid_attrs)
      assert blog_post.status == "some status"
      assert blog_post.metadata == %{}
      assert blog_post.title_fi == "some title_fi"
      assert blog_post.title_en == "some title_en"
      assert blog_post.content_fi == "some content_fi"
      assert blog_post.content_en == "some content_en"
      assert blog_post.slug == "some slug"
      assert blog_post.author_type == "some author_type"
      assert blog_post.author_id == 42
      assert blog_post.curator_added == true
      assert blog_post.published_at == ~U[2025-11-16 15:19:00Z]
      assert blog_post.user_id == scope.user.id
    end

    test "create_blog_post/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Content.create_blog_post(scope, @invalid_attrs)
    end

    test "update_blog_post/3 with valid data updates the blog_post" do
      scope = user_scope_fixture()
      blog_post = blog_post_fixture(scope)
      update_attrs = %{status: "some updated status", metadata: %{}, title_fi: "some updated title_fi", title_en: "some updated title_en", content_fi: "some updated content_fi", content_en: "some updated content_en", slug: "some updated slug", author_type: "some updated author_type", author_id: 43, curator_added: false, published_at: ~U[2025-11-17 15:19:00Z]}

      assert {:ok, %BlogPost{} = blog_post} = Content.update_blog_post(scope, blog_post, update_attrs)
      assert blog_post.status == "some updated status"
      assert blog_post.metadata == %{}
      assert blog_post.title_fi == "some updated title_fi"
      assert blog_post.title_en == "some updated title_en"
      assert blog_post.content_fi == "some updated content_fi"
      assert blog_post.content_en == "some updated content_en"
      assert blog_post.slug == "some updated slug"
      assert blog_post.author_type == "some updated author_type"
      assert blog_post.author_id == 43
      assert blog_post.curator_added == false
      assert blog_post.published_at == ~U[2025-11-17 15:19:00Z]
    end

    test "update_blog_post/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      blog_post = blog_post_fixture(scope)

      assert_raise MatchError, fn ->
        Content.update_blog_post(other_scope, blog_post, %{})
      end
    end

    test "update_blog_post/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      blog_post = blog_post_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Content.update_blog_post(scope, blog_post, @invalid_attrs)
      assert blog_post == Content.get_blog_post!(scope, blog_post.id)
    end

    test "delete_blog_post/2 deletes the blog_post" do
      scope = user_scope_fixture()
      blog_post = blog_post_fixture(scope)
      assert {:ok, %BlogPost{}} = Content.delete_blog_post(scope, blog_post)
      assert_raise Ecto.NoResultsError, fn -> Content.get_blog_post!(scope, blog_post.id) end
    end

    test "delete_blog_post/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      blog_post = blog_post_fixture(scope)
      assert_raise MatchError, fn -> Content.delete_blog_post(other_scope, blog_post) end
    end

    test "change_blog_post/2 returns a blog_post changeset" do
      scope = user_scope_fixture()
      blog_post = blog_post_fixture(scope)
      assert %Ecto.Changeset{} = Content.change_blog_post(scope, blog_post)
    end
  end
end
