defmodule Homesite.Accounts.UserNotifierTest do
  use Homesite.DataCase, async: true

  alias Homesite.Accounts.UserNotifier

  import Homesite.AccountsFixtures
  import Swoosh.TestAssertions

  describe "deliver_update_email_instructions/2" do
    test "sends email with update instructions" do
      user = user_fixture()
      url = "https://example.com/update-email?token=abc123"

      assert {:ok, email} = UserNotifier.deliver_update_email_instructions(user, url)

      assert email.to == [{"", user.email}]
      assert {"Orangedinos", _from_email} = email.from
      assert email.subject == "Update email instructions"
      assert email.text_body =~ "Hi #{user.email}"
      assert email.text_body =~ url
      assert email.text_body =~ "change your email"
    end

    test "includes warning about ignoring if not requested" do
      user = user_fixture()
      url = "https://example.com/update-email?token=abc123"

      {:ok, email} = UserNotifier.deliver_update_email_instructions(user, url)

      assert email.text_body =~ "If you didn't request this change"
    end
  end

  describe "deliver_login_instructions/2" do
    test "sends confirmation instructions for unconfirmed user" do
      user = unconfirmed_user_fixture()
      url = "https://example.com/confirm?token=abc123"

      assert {:ok, email} = UserNotifier.deliver_login_instructions(user, url)

      assert email.to == [{"", user.email}]
      # Bilingual subject for registration confirmation
      assert email.subject == "Confirm your account / Vahvista tilisi"
      assert email.text_body =~ "confirm your account"
      assert email.text_body =~ url
    end

    test "sends magic link for confirmed user" do
      user = user_fixture()
      url = "https://example.com/login?token=abc123"

      assert {:ok, email} = UserNotifier.deliver_login_instructions(user, url)

      assert email.to == [{"", user.email}]
      assert email.subject == "Log in instructions"
      assert email.text_body =~ "log into your account"
      assert email.text_body =~ url
    end

    test "includes ignore notice for unconfirmed user" do
      user = unconfirmed_user_fixture()
      url = "https://example.com/confirm?token=abc123"

      {:ok, email} = UserNotifier.deliver_login_instructions(user, url)

      assert email.text_body =~ "If you didn't create an account"
    end

    test "includes ignore notice for confirmed user" do
      user = user_fixture()
      url = "https://example.com/login?token=abc123"

      {:ok, email} = UserNotifier.deliver_login_instructions(user, url)

      assert email.text_body =~ "If you didn't request this email"
    end
  end

  describe "email format" do
    test "uses text body format" do
      user = user_fixture()
      url = "https://example.com/test"

      {:ok, email} = UserNotifier.deliver_login_instructions(user, url)

      assert email.text_body != nil
      # No HTML body
      assert email.html_body == nil
    end

    test "email contains proper dividers" do
      user = user_fixture()
      url = "https://example.com/test"

      {:ok, email} = UserNotifier.deliver_login_instructions(user, url)

      # Check for visual dividers in plain text
      assert email.text_body =~ "=============================="
    end
  end

  describe "edge cases" do
    test "handles email with special characters" do
      # Create user with special email
      user = user_fixture(%{email: "test+special@example.com"})
      url = "https://example.com/test"

      assert {:ok, email} = UserNotifier.deliver_login_instructions(user, url)
      assert email.to == [{"", "test+special@example.com"}]
    end

    test "handles URL with query parameters" do
      user = user_fixture()
      url = "https://example.com/login?token=abc123&redirect=/dashboard"

      {:ok, email} = UserNotifier.deliver_login_instructions(user, url)

      assert email.text_body =~ url
    end

    test "handles unicode in URL" do
      user = user_fixture()
      url = "https://example.com/login?name=%E6%97%A5%E6%9C%AC%E8%AA%9E"

      {:ok, email} = UserNotifier.deliver_login_instructions(user, url)

      assert email.text_body =~ url
    end
  end
end
