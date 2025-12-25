defmodule HomesiteWeb.E2E.ChatTest do
  @moduledoc """
  End-to-end tests for chat system workflows using Playwright.

  Tests cover:
  - Viewing chat channels
  - Joining chat rooms
  - Sending messages
  - Real-time message updates
  - Chat moderation features
  """
  use PhoenixTest.Playwright.Case, async: false
  use HomesiteWeb, :verified_routes

  import Homesite.AccountsFixtures
  import Homesite.ChatFixtures
  import HomesiteWeb.PlaywrightAuthHelper

  setup do
    Homesite.DataCase.ensure_test_invitation()
    user = user_fixture()
    scope = %Homesite.Accounts.Scope{user: user}
    %{user: user, scope: scope}
  end

  describe "Chat Index Page" do
    @tag :playwright
    test "shows chat channels for authenticated user", %{conn: conn, user: user} do
      channel =
        channel_fixture(%{
          name: "test-general-#{System.unique_integer([:positive])}",
          is_default: true
        })

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/chat")
      |> assert_has("body .phx-connected")
      |> assert_has("ul.menu a", text: channel.name)
    end

    @tag :playwright
    test "redirects unauthenticated users", %{conn: conn} do
      conn
      |> visit(~p"/chat")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "Log in")
    end
  end

  describe "Chat Channel" do
    @tag :playwright
    test "shows channel with message input", %{conn: conn, user: user} do
      channel = channel_fixture(%{name: "test-channel"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/chat/#{channel.slug}")
      |> assert_has("body .phx-connected")
      |> assert_has("textarea[name='message[body]']")
    end

    @tag :playwright
    test "shows channel name in header", %{conn: conn, user: user} do
      channel = channel_fixture(%{name: "announcements"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/chat/#{channel.slug}")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "##{channel.name}")
    end

    @tag :playwright
    test "shows send button", %{conn: conn, user: user} do
      channel = channel_fixture(%{name: "test-channel"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/chat/#{channel.slug}")
      |> assert_has("body .phx-connected")
      |> assert_has("button[type='submit']")
    end

    @tag :playwright
    test "shows existing messages", %{conn: conn, user: user, scope: scope} do
      channel = channel_fixture(%{name: "test-channel"})
      _message = message_fixture(scope, channel, %{body: "Hello World!"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/chat/#{channel.slug}")
      |> assert_has("body .phx-connected")
      |> assert_has(".chat-bubble", text: "Hello World!")
    end
  end

  describe "Send Message" do
    @tag :playwright
    test "can send a message", %{conn: conn, user: user} do
      channel = channel_fixture(%{name: "test-channel"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/chat/#{channel.slug}")
      |> assert_has("body .phx-connected")
      |> fill_in("Message", with: "Test message from E2E")
      |> click_button("Send message")
      |> assert_has("body .phx-connected")
      |> assert_has(".chat-bubble", text: "Test message from E2E")
    end

    @tag :playwright
    test "input clears after sending", %{conn: conn, user: user} do
      channel = channel_fixture(%{name: "test-channel"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/chat/#{channel.slug}")
      |> assert_has("body .phx-connected")
      |> fill_in("Message", with: "Test message")
      |> click_button("Send message")
      |> assert_has("body .phx-connected")
      # Textarea should be empty after send
      |> assert_has("textarea[name='message[body]']", text: "")
    end

    @tag :playwright
    test "shows validation for empty message", %{conn: conn, user: user} do
      channel = channel_fixture(%{name: "test-channel"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/chat/#{channel.slug}")
      |> assert_has("body .phx-connected")
      # Button should be disabled when textarea is empty (char_count == 0)
      |> assert_has("button[type='submit'][disabled]")
    end
  end

  describe "Chat Navigation" do
    @tag :playwright
    test "can navigate back to channel list", %{conn: conn, user: user} do
      channel = channel_fixture(%{name: "test-channel"})

      conn
      |> playwright_log_in_user(user)
      |> visit(~p"/chat/#{channel.slug}")
      |> assert_has("body .phx-connected")
      |> assert_has("h1", text: "##{channel.name}")
      # Navigate back to /chat
      |> visit(~p"/chat")
      |> assert_has("body .phx-connected")
      |> assert_has("ul.menu a", text: channel.name)
    end
  end
end
