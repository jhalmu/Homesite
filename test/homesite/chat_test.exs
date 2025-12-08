defmodule Homesite.ChatTest do
  use Homesite.DataCase

  alias Homesite.Chat
  alias Homesite.Chat.{Channel, Message}

  import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
  import Homesite.ChatFixtures

  describe "channels" do
    test "list_channels/0 returns all channels" do
      channel = channel_fixture()
      channels = Chat.list_channels()
      assert Enum.any?(channels, fn c -> c.id == channel.id end)
    end

    test "list_channels/0 orders by is_default desc, name asc" do
      # Create channels in reverse order
      channel_c = channel_fixture(%{name: "channel-c", is_default: false})
      channel_a = channel_fixture(%{name: "channel-a", is_default: false})
      channel_default = channel_fixture(%{name: "default-channel", is_default: true})

      channels = Chat.list_channels()
      channel_ids = Enum.map(channels, & &1.id)

      # Default channel should be first, then alphabetical
      assert hd(channel_ids) == channel_default.id

      non_default_ids = Enum.filter(channel_ids, fn id -> id != channel_default.id end)

      assert Enum.find_index(non_default_ids, fn id -> id == channel_a.id end) <
               Enum.find_index(non_default_ids, fn id -> id == channel_c.id end)
    end

    test "get_channel!/1 returns the channel with given id" do
      channel = channel_fixture()
      assert Chat.get_channel!(channel.id).id == channel.id
    end

    test "get_channel!/1 raises when channel not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Chat.get_channel!(0)
      end
    end

    test "get_channel_by_slug!/1 returns the channel with given slug" do
      channel = channel_fixture(%{name: "test-slug"})
      found = Chat.get_channel_by_slug!("test-slug")
      assert found.id == channel.id
    end

    test "get_channel_by_slug!/1 raises when channel not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Chat.get_channel_by_slug!("nonexistent")
      end
    end

    test "get_default_channel/0 returns a default channel" do
      # The migration seeds a default #general channel
      # This test verifies the function returns it
      found = Chat.get_default_channel()

      # Should return a channel with is_default: true
      assert found.is_default == true
    end

    test "create_channel/2 creates a channel" do
      scope = user_scope_fixture()

      attrs = %{name: "new-channel", description: "A new channel"}
      assert {:ok, %Channel{} = channel} = Chat.create_channel(scope, attrs)
      assert channel.name == "new-channel"
      assert channel.slug == "new-channel"
      assert channel.description == "A new channel"
      assert channel.created_by_user_id == scope.user.id
    end

    test "create_channel/2 returns error with invalid data" do
      scope = user_scope_fixture()

      assert {:error, %Ecto.Changeset{}} = Chat.create_channel(scope, %{name: ""})
    end

    test "create_channel/2 validates name format" do
      scope = user_scope_fixture()

      # Name must be lowercase with only letters, numbers, and hyphens
      assert {:error, changeset} = Chat.create_channel(scope, %{name: "Invalid Name"})
      assert "only lowercase letters, numbers, and hyphens allowed" in errors_on(changeset).name
    end

    test "create_channel/2 enforces unique name" do
      scope = user_scope_fixture()
      channel_fixture(%{name: "unique-test"})

      assert {:error, changeset} = Chat.create_channel(scope, %{name: "unique-test"})
      assert "has already been taken" in errors_on(changeset).name
    end

    test "update_channel/2 updates the channel" do
      channel = channel_fixture()

      assert {:ok, updated} = Chat.update_channel(channel, %{description: "Updated description"})
      assert updated.description == "Updated description"
    end

    test "delete_channel/1 deletes the channel" do
      channel = channel_fixture(%{is_default: false})

      assert {:ok, %Channel{}} = Chat.delete_channel(channel)
      assert_raise Ecto.NoResultsError, fn -> Chat.get_channel!(channel.id) end
    end

    test "delete_channel/1 prevents deleting default channel" do
      channel = channel_fixture(%{is_default: true, name: "no-delete-default"})

      assert {:error, :cannot_delete_default} = Chat.delete_channel(channel)
      assert Chat.get_channel!(channel.id)
    end

    test "change_channel/2 returns a changeset" do
      channel = channel_fixture()
      assert %Ecto.Changeset{} = Chat.change_channel(channel)
    end
  end

  describe "messages" do
    setup do
      scope = user_scope_fixture()
      channel = channel_fixture()
      %{scope: scope, channel: channel}
    end

    test "list_messages/2 returns messages for a channel", %{scope: scope, channel: channel} do
      message = message_fixture(scope, channel)
      messages = Chat.list_messages(channel.id)

      assert length(messages) >= 1
      assert Enum.any?(messages, fn m -> m.id == message.id end)
    end

    test "list_messages/2 orders messages chronologically", %{scope: scope, channel: channel} do
      # Create messages with slight delay to ensure different timestamps
      msg1 = message_fixture(scope, channel, %{body: "First message"})
      msg2 = message_fixture(scope, channel, %{body: "Second message"})
      msg3 = message_fixture(scope, channel, %{body: "Third message"})

      messages = Chat.list_messages(channel.id)
      message_ids = Enum.map(messages, & &1.id)

      # Messages should be in chronological order (oldest first)
      assert Enum.find_index(message_ids, fn id -> id == msg1.id end) <
               Enum.find_index(message_ids, fn id -> id == msg2.id end)

      assert Enum.find_index(message_ids, fn id -> id == msg2.id end) <
               Enum.find_index(message_ids, fn id -> id == msg3.id end)
    end

    test "list_messages/2 respects limit option", %{scope: scope, channel: channel} do
      for i <- 1..10 do
        message_fixture(scope, channel, %{body: "Message #{i}"})
      end

      messages = Chat.list_messages(channel.id, limit: 5)
      assert length(messages) == 5
    end

    test "list_messages/2 returns messages with preloaded user", %{scope: scope, channel: channel} do
      message_fixture(scope, channel)
      [message | _] = Chat.list_messages(channel.id)

      assert %Homesite.Accounts.User{} = message.user
      assert message.user.id == scope.user.id
    end

    test "get_message!/1 returns the message with preloaded user", %{
      scope: scope,
      channel: channel
    } do
      message = message_fixture(scope, channel)
      found = Chat.get_message!(message.id)

      assert found.id == message.id
      assert found.user.id == scope.user.id
    end

    test "create_message/3 creates a message", %{scope: scope, channel: channel} do
      attrs = %{"body" => "Hello, world!"}
      assert {:ok, %Message{} = message} = Chat.create_message(scope, channel.id, attrs)

      assert message.body == "Hello, world!"
      assert message.channel_id == channel.id
      assert message.user_id == scope.user.id
    end

    test "create_message/3 returns error with empty body", %{scope: scope, channel: channel} do
      assert {:error, changeset} = Chat.create_message(scope, channel.id, %{"body" => ""})
      assert "can't be blank" in errors_on(changeset).body
    end

    test "create_message/3 validates message length", %{scope: scope, channel: channel} do
      long_body = String.duplicate("a", 281)
      assert {:error, changeset} = Chat.create_message(scope, channel.id, %{"body" => long_body})
      assert "must be between 1 and 280 characters" in errors_on(changeset).body
    end

    test "create_message/3 accepts 280 character message", %{scope: scope, channel: channel} do
      body = String.duplicate("a", 280)
      assert {:ok, %Message{}} = Chat.create_message(scope, channel.id, %{"body" => body})
    end

    test "delete_message/2 deletes user's own message", %{scope: scope, channel: channel} do
      message = message_fixture(scope, channel)

      assert {:ok, %Message{}} = Chat.delete_message(scope, message)
      assert_raise Ecto.NoResultsError, fn -> Chat.get_message!(message.id) end
    end

    test "delete_message/2 prevents deleting other user's message", %{channel: channel} do
      # Create message as one user
      owner_scope = user_scope_fixture()
      message = message_fixture(owner_scope, channel)

      # Try to delete as another user
      other_scope = user_scope_fixture()

      assert_raise MatchError, fn ->
        Chat.delete_message(other_scope, message)
      end

      # Message should still exist
      assert Chat.get_message!(message.id)
    end

    test "change_message/2 returns a changeset" do
      assert %Ecto.Changeset{} = Chat.change_message(%Message{})
    end
  end

  describe "pubsub" do
    setup do
      scope = user_scope_fixture()
      channel = channel_fixture()
      %{scope: scope, channel: channel}
    end

    test "subscribe_channel/1 and create_message/3 broadcasts new_message", %{
      scope: scope,
      channel: channel
    } do
      Chat.subscribe_channel(channel.id)

      {:ok, message} = Chat.create_message(scope, channel.id, %{"body" => "Test broadcast"})

      assert_receive {:new_message, received_message}
      assert received_message.id == message.id
      assert received_message.body == "Test broadcast"
    end

    test "subscribe_channel/1 and delete_message/2 broadcasts deleted_message", %{
      scope: scope,
      channel: channel
    } do
      message = message_fixture(scope, channel)

      Chat.subscribe_channel(channel.id)

      {:ok, _deleted} = Chat.delete_message(scope, message)

      assert_receive {:deleted_message, deleted_id}
      assert deleted_id == message.id
    end

    test "unsubscribe_channel/1 stops receiving messages", %{scope: scope, channel: channel} do
      Chat.subscribe_channel(channel.id)
      Chat.unsubscribe_channel(channel.id)

      {:ok, _message} = Chat.create_message(scope, channel.id, %{"body" => "No broadcast"})

      refute_receive {:new_message, _}, 100
    end
  end
end
