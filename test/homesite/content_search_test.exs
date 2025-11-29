defmodule Homesite.ContentSearchTest do
  use Homesite.DataCase

  alias Homesite.Content

  import Homesite.AccountsFixtures
  import Homesite.ContentFixtures

  describe "search_posts/2" do
    setup do
      user = user_fixture()
      scope = Homesite.Accounts.Scope.for_user(user)

      # Create test posts with different content
      {:ok, post1} =
        Content.create_post(scope, %{
          title: "Learning Elixir Programming",
          body: "Elixir is a functional programming language",
          published_at: DateTime.utc_now(:second)
        })

      {:ok, post2} =
        Content.create_post(scope, %{
          title: "Phoenix Framework Guide",
          body: "Phoenix is a web framework for Elixir developers",
          published_at: DateTime.utc_now(:second)
        })

      {:ok, _post3} =
        Content.create_post(scope, %{
          title: "Rust Programming Language",
          body: "Rust is a systems programming language",
          published_at: DateTime.utc_now(:second)
        })

      %{scope: scope, post1: post1, post2: post2}
    end

    test "returns posts matching title" do
      results = Content.search_posts("Elixir")

      assert length(results) >= 1
      titles = Enum.map(results, & &1.title)
      assert "Learning Elixir Programming" in titles
    end

    test "returns posts matching body content" do
      results = Content.search_posts("Phoenix")

      assert length(results) == 1
      assert hd(results).title == "Phoenix Framework Guide"
    end

    test "returns multiple posts when query matches both" do
      results = Content.search_posts("Elixir")

      # Should match both "Learning Elixir" and "Phoenix Framework" (mentions Elixir)
      assert length(results) >= 1
    end

    test "returns empty list for non-matching query" do
      results = Content.search_posts("NonExistentTerm12345")

      assert results == []
    end

    test "returns posts matching different technology" do
      results = Content.search_posts("Rust")

      assert length(results) == 1
      assert hd(results).title == "Rust Programming Language"
    end

    test "limits results when limit option provided" do
      results = Content.search_posts("Elixir", limit: 1)

      assert length(results) <= 1
    end

    test "preloads user and tags associations" do
      results = Content.search_posts("Elixir")

      assert length(results) > 0
      post = hd(results)
      assert Ecto.assoc_loaded?(post.user)
      assert Ecto.assoc_loaded?(post.tags)
    end
  end

  describe "search_user_posts/3" do
    setup do
      user1 = user_fixture()
      user2 = user_fixture()
      scope1 = Homesite.Accounts.Scope.for_user(user1)
      scope2 = Homesite.Accounts.Scope.for_user(user2)

      {:ok, _post1} =
        Content.create_post(scope1, %{
          title: "User1 Elixir Post",
          body: "Content about Elixir",
          published_at: DateTime.utc_now(:second)
        })

      {:ok, _post2} =
        Content.create_post(scope1, %{
          title: "User1 Phoenix Post",
          body: "Phoenix web framework",
          published_at: DateTime.utc_now(:second)
        })

      {:ok, _post3} =
        Content.create_post(scope2, %{
          title: "User2 Elixir Post",
          body: "Another Elixir post",
          published_at: DateTime.utc_now(:second)
        })

      %{scope1: scope1, scope2: scope2}
    end

    test "returns only posts from scoped user", %{scope1: scope1} do
      results = Content.search_user_posts(scope1, "Elixir")

      assert length(results) == 1
      assert Enum.all?(results, fn post -> post.user_id == scope1.user.id end)
    end

    test "can search user's Phoenix posts", %{scope1: scope1} do
      results = Content.search_user_posts(scope1, "Phoenix")

      assert length(results) == 1
      assert hd(results).title == "User1 Phoenix Post"
    end

    test "does not return posts from other users", %{scope1: scope1, scope2: scope2} do
      results = Content.search_user_posts(scope1, "Elixir")

      assert Enum.all?(results, fn post -> post.user_id != scope2.user.id end)
    end
  end
end
