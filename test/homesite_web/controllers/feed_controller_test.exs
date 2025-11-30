defmodule HomesiteWeb.FeedControllerTest do
  use HomesiteWeb.ConnCase

  import Homesite.AccountsFixtures
  import Homesite.ContentFixtures

  alias Homesite.Accounts

  describe "User feed with ID routing" do
    setup do
      user = user_fixture()
      scope = Homesite.Accounts.Scope.for_user(user)
      post = post_fixture(scope, %{published_at: DateTime.utc_now()})

      %{user: user, scope: scope, post: post}
    end

    test "GET /users/:id/rss.xml returns RSS feed", %{conn: conn, user: user, post: post} do
      conn = get(conn, ~p"/users/#{user.id}/rss.xml")

      assert response(conn, 200)
      assert get_resp_header(conn, "content-type") == ["application/rss+xml; charset=utf-8"]
      response_body = response(conn, 200)
      assert response_body =~ post.title
      assert response_body =~ "<rss version=\"2.0\""
    end

    test "GET /users/:id/feed.xml returns Atom feed", %{conn: conn, user: user, post: post} do
      conn = get(conn, ~p"/users/#{user.id}/feed.xml")

      assert response(conn, 200)
      assert get_resp_header(conn, "content-type") == ["application/atom+xml; charset=utf-8"]
      response_body = response(conn, 200)
      assert response_body =~ post.title
      assert response_body =~ "<feed xmlns=\"http://www.w3.org/2005/Atom\">"
    end

    test "GET /users/:id/feed.json returns JSON feed", %{conn: conn, user: user, post: post} do
      conn = get(conn, ~p"/users/#{user.id}/feed.json")

      assert response(conn, 200)
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
      response_json = json_response(conn, 200)
      assert response_json["version"] == "https://jsonfeed.org/version/1.1"
      assert Enum.any?(response_json["items"], fn item -> item["title"] == post.title end)
    end
  end

  describe "User feed with username routing" do
    setup do
      user = user_fixture()
      {:ok, user} = Accounts.update_user_username(user, %{username: "testauthor"})
      scope = Homesite.Accounts.Scope.for_user(user)
      post = post_fixture(scope, %{published_at: DateTime.utc_now()})

      %{user: user, scope: scope, post: post}
    end

    test "GET /users/@username/rss.xml returns RSS feed", %{conn: conn, user: user, post: post} do
      conn = get(conn, ~p"/users/@#{user.username}/rss.xml")

      assert response(conn, 200)
      assert get_resp_header(conn, "content-type") == ["application/rss+xml; charset=utf-8"]
      response_body = response(conn, 200)
      assert response_body =~ post.title
      assert response_body =~ "<rss version=\"2.0\""
    end

    test "GET /users/@username/feed.xml returns Atom feed", %{conn: conn, user: user, post: post} do
      conn = get(conn, ~p"/users/@#{user.username}/feed.xml")

      assert response(conn, 200)
      assert get_resp_header(conn, "content-type") == ["application/atom+xml; charset=utf-8"]
      response_body = response(conn, 200)
      assert response_body =~ post.title
    end

    test "GET /users/@username/feed.json returns JSON feed", %{conn: conn, user: user, post: post} do
      conn = get(conn, ~p"/users/@#{user.username}/feed.json")

      assert response(conn, 200)
      response_json = json_response(conn, 200)
      assert response_json["version"] == "https://jsonfeed.org/version/1.1"
      assert Enum.any?(response_json["items"], fn item -> item["title"] == post.title end)
    end

    test "JSON feed includes username in author URLs", %{conn: conn, user: user} do
      conn = get(conn, ~p"/users/@#{user.username}/feed.json")

      response_json = json_response(conn, 200)
      [item | _] = response_json["items"]

      # URL-encoded @ becomes %40, both formats are valid
      assert item["author"]["url"] =~ user.username
    end
  end

  describe "Feed error handling" do
    test "returns 404 for non-existent user ID", %{conn: conn} do
      conn = get(conn, ~p"/users/999999/feed.xml")

      assert response(conn, 404)
      assert response(conn, 404) == "User not found"
    end

    test "returns 404 for non-existent username", %{conn: conn} do
      conn = get(conn, ~p"/users/@nonexistent/feed.xml")

      assert response(conn, 404)
      assert response(conn, 404) == "User not found"
    end
  end

  describe "Feed content with username" do
    test "both ID and username routes return same content", %{conn: conn} do
      user = user_fixture()
      {:ok, user} = Accounts.update_user_username(user, %{username: "author123"})
      scope = Homesite.Accounts.Scope.for_user(user)
      _post = post_fixture(scope, %{published_at: DateTime.utc_now()})

      conn_id = get(conn, ~p"/users/#{user.id}/feed.json")
      conn_username = get(build_conn(), ~p"/users/@#{user.username}/feed.json")

      json_id = json_response(conn_id, 200)
      json_username = json_response(conn_username, 200)

      # Both should have the same items
      assert length(json_id["items"]) == length(json_username["items"])

      assert Enum.map(json_id["items"], & &1["title"]) ==
               Enum.map(json_username["items"], & &1["title"])
    end
  end

  describe "Feed caching with username" do
    test "ID and username routes share same cache", %{conn: conn} do
      user = user_fixture()
      {:ok, user} = Accounts.update_user_username(user, %{username: "cached"})
      scope = Homesite.Accounts.Scope.for_user(user)
      _post = post_fixture(scope, %{published_at: DateTime.utc_now()})

      # Access via username first
      conn1 = get(conn, ~p"/users/@#{user.username}/feed.json")
      json1 = json_response(conn1, 200)

      # Access via ID
      conn2 = get(build_conn(), ~p"/users/#{user.id}/feed.json")
      json2 = json_response(conn2, 200)

      # Should return same data (cache hit)
      assert json1 == json2
    end
  end
end
