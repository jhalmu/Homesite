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
      assert tag.slug =~ ~r/^some-name-\d+$/
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
      assert tag.slug =~ ~r/^some-updated-name-\d+$/
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

    test "get_tag_by_name/2 returns tag when it exists" do
      scope = user_scope_fixture()
      tag = tag_fixture(scope, %{name: "Technology"})

      assert tag_found = Content.get_tag_by_name(scope, "Technology")
      assert tag_found.id == tag.id
      assert tag_found.name == "Technology"
    end

    test "get_tag_by_name/2 returns nil when tag does not exist" do
      scope = user_scope_fixture()

      assert Content.get_tag_by_name(scope, "NonExistent") == nil
    end

    test "get_tag_by_name/2 does not return tags from other users" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      _tag = tag_fixture(scope1, %{name: "Technology"})

      assert Content.get_tag_by_name(scope2, "Technology") == nil
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
      fetched_post = Content.get_post!(scope, post.id)
      assert fetched_post.id == post.id
      assert fetched_post.user.id == scope.user.id
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
      fetched_post = Content.get_post!(scope, post.id)
      assert fetched_post.id == post.id
      assert fetched_post.title == post.title
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

    test "get_public_post!/1 returns public post" do
      scope = user_scope_fixture()
      public_post = post_fixture(scope, %{is_public: true})

      fetched_post = Content.get_public_post!(public_post.id)
      assert fetched_post.id == public_post.id
      assert fetched_post.user.id == scope.user.id
    end

    test "get_public_post!/1 raises for private post" do
      scope = user_scope_fixture()
      private_post = post_fixture(scope, %{is_public: false})

      assert_raise Ecto.NoResultsError, fn ->
        Content.get_public_post!(private_post.id)
      end
    end

    test "get_public_post!/1 raises for non-existent post" do
      assert_raise Ecto.NoResultsError, fn ->
        Content.get_public_post!(99999)
      end
    end

    test "get_post_by_id!/2 returns public post for authenticated user" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      public_post = post_fixture(other_scope, %{is_public: true})

      fetched_post = Content.get_post_by_id!(scope, public_post.id)
      assert fetched_post.id == public_post.id
    end

    test "get_post_by_id!/2 returns own private post" do
      scope = user_scope_fixture()
      private_post = post_fixture(scope, %{is_public: false})

      fetched_post = Content.get_post_by_id!(scope, private_post.id)
      assert fetched_post.id == private_post.id
    end

    test "get_post_by_id!/2 raises for other user's private post" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()
      private_post = post_fixture(scope1, %{is_public: false})

      assert_raise Ecto.NoResultsError, fn ->
        Content.get_post_by_id!(scope2, private_post.id)
      end
    end
  end

  describe "list_published_posts_for_user/1" do
    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.ContentFixtures

    test "returns published posts for the user" do
      scope = user_scope_fixture()
      post1 = post_fixture(scope, %{published_at: ~U[2025-11-20 11:44:00Z]})
      post2 = post_fixture(scope, %{published_at: ~U[2025-11-21 11:44:00Z]})

      posts = Content.list_published_posts_for_user(scope.user.id)

      assert length(posts) == 2
      post_ids = Enum.map(posts, & &1.id)
      assert post1.id in post_ids
      assert post2.id in post_ids
    end

    test "returns posts ordered by published_at descending" do
      scope = user_scope_fixture()

      old_post = post_fixture(scope, %{published_at: ~U[2025-11-10 10:00:00Z], title: "Old Post"})

      new_post =
        post_fixture(scope, %{published_at: ~U[2025-11-20 10:00:00Z], title: "New Post"})

      posts = Content.list_published_posts_for_user(scope.user.id)

      assert length(posts) == 2
      assert hd(posts).id == new_post.id
      assert List.last(posts).id == old_post.id
    end

    test "does not return posts from other users" do
      scope1 = user_scope_fixture()
      scope2 = user_scope_fixture()

      _user1_post = post_fixture(scope1, %{published_at: ~U[2025-11-20 11:44:00Z]})
      user2_post = post_fixture(scope2, %{published_at: ~U[2025-11-20 11:44:00Z]})

      posts = Content.list_published_posts_for_user(scope2.user.id)

      assert length(posts) == 1
      assert hd(posts).id == user2_post.id
    end

    test "returns empty list when user has no posts" do
      scope = user_scope_fixture()

      posts = Content.list_published_posts_for_user(scope.user.id)

      assert posts == []
    end
  end
end
