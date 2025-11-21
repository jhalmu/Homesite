defmodule Homesite.ContentTest do
  use Homesite.DataCase

  alias Homesite.Content

  describe "tags" do
    alias Homesite.Content.Tag

    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.ContentFixtures

    @invalid_attrs %{name: nil, slug: nil, is_public: nil}

    test "list_tags/1 returns all scoped tags" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      tag = tag_fixture(scope)
      other_tag = tag_fixture(other_scope)
      assert Content.list_tags(scope) == [tag]
      assert Content.list_tags(other_scope) == [other_tag]
    end

    test "get_tag!/2 returns the tag with given id" do
      scope = user_scope_fixture()
      tag = tag_fixture(scope)
      other_scope = user_scope_fixture()
      assert Content.get_tag!(scope, tag.id) == tag
      assert_raise Ecto.NoResultsError, fn -> Content.get_tag!(other_scope, tag.id) end
    end

    test "create_tag/2 with valid data creates a tag" do
      valid_attrs = %{name: "some name", slug: "some slug", is_public: true}
      scope = user_scope_fixture()

      assert {:ok, %Tag{} = tag} = Content.create_tag(scope, valid_attrs)
      assert tag.name == "some name"
      assert tag.slug == "some-name"
      assert tag.is_public == true
      assert tag.user_id == scope.user.id
    end

    test "create_tag/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Content.create_tag(scope, @invalid_attrs)
    end

    test "update_tag/3 with valid data updates the tag" do
      scope = user_scope_fixture()
      tag = tag_fixture(scope)
      update_attrs = %{name: "some updated name", slug: "some updated slug", is_public: false}

      assert {:ok, %Tag{} = tag} = Content.update_tag(scope, tag, update_attrs)
      assert tag.name == "some updated name"
      assert tag.slug == "some-updated-name"
      assert tag.is_public == false
    end

    test "update_tag/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      tag = tag_fixture(scope)

      assert_raise MatchError, fn ->
        Content.update_tag(other_scope, tag, %{})
      end
    end

    test "update_tag/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      tag = tag_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Content.update_tag(scope, tag, @invalid_attrs)
      assert tag == Content.get_tag!(scope, tag.id)
    end

    test "delete_tag/2 deletes the tag" do
      scope = user_scope_fixture()
      tag = tag_fixture(scope)
      assert {:ok, %Tag{}} = Content.delete_tag(scope, tag)
      assert_raise Ecto.NoResultsError, fn -> Content.get_tag!(scope, tag.id) end
    end

    test "delete_tag/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      tag = tag_fixture(scope)
      assert_raise MatchError, fn -> Content.delete_tag(other_scope, tag) end
    end

    test "change_tag/2 returns a tag changeset" do
      scope = user_scope_fixture()
      tag = tag_fixture(scope)
      assert %Ecto.Changeset{} = Content.change_tag(scope, tag)
    end
  end

  describe "posts" do
    alias Homesite.Content.Post

    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.ContentFixtures

    @invalid_attrs %{title: nil, body: nil, slug: nil, published_at: nil}

    test "list_posts/1 returns all scoped posts" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      post = post_fixture(scope)
      other_post = post_fixture(other_scope)
      assert Content.list_posts(scope) == [post]
      assert Content.list_posts(other_scope) == [other_post]
    end

    test "get_post!/2 returns the post with given id" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      other_scope = user_scope_fixture()
      assert Content.get_post!(scope, post.id) == post
      assert_raise Ecto.NoResultsError, fn -> Content.get_post!(other_scope, post.id) end
    end

    test "create_post/2 with valid data creates a post" do
      valid_attrs = %{
        title: "some title",
        body: "some body content",
        slug: "some slug",
        published_at: ~U[2025-11-20 11:44:00Z]
      }

      scope = user_scope_fixture()

      assert {:ok, %Post{} = post} = Content.create_post(scope, valid_attrs)
      assert post.title == "some title"
      assert post.body == "some body content"
      assert post.slug =~ "some-title-"
      assert post.published_at == ~U[2025-11-20 11:44:00Z]
      assert post.user_id == scope.user.id
    end

    test "create_post/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Content.create_post(scope, @invalid_attrs)
    end

    test "update_post/3 with valid data updates the post" do
      scope = user_scope_fixture()
      post = post_fixture(scope)

      update_attrs = %{
        title: "some updated title",
        body: "some updated body content",
        slug: "some updated slug",
        published_at: ~U[2025-11-21 11:44:00Z]
      }

      assert {:ok, %Post{} = post} = Content.update_post(scope, post, update_attrs)
      assert post.title == "some updated title"
      assert post.body == "some updated body content"
      assert post.slug =~ "some-updated-title-"
      assert post.published_at == ~U[2025-11-21 11:44:00Z]
    end

    test "update_post/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      post = post_fixture(scope)

      assert_raise MatchError, fn ->
        Content.update_post(other_scope, post, %{})
      end
    end

    test "update_post/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Content.update_post(scope, post, @invalid_attrs)
      assert post == Content.get_post!(scope, post.id)
    end

    test "delete_post/2 deletes the post" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      assert {:ok, %Post{}} = Content.delete_post(scope, post)
      assert_raise Ecto.NoResultsError, fn -> Content.get_post!(scope, post.id) end
    end

    test "delete_post/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      post = post_fixture(scope)
      assert_raise MatchError, fn -> Content.delete_post(other_scope, post) end
    end

    test "change_post/2 returns a post changeset" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      assert %Ecto.Changeset{} = Content.change_post(scope, post)
    end
  end
end
