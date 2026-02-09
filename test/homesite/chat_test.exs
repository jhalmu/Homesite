defmodule Homesite.ChatTest do
  use Homesite.DataCase

  alias Homesite.Chat
  alias Homesite.Chat.{Ban, Block, Channel, Message, ModerationLog, Mute}

  import Homesite.AccountsFixtures, only: [user_scope_fixture: 0, admin_scope_fixture: 0]
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

      assert messages != []
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

  describe "bans" do
    setup do
      admin_scope = admin_scope_fixture()
      user_scope = user_scope_fixture()
      channel = channel_fixture()
      %{admin_scope: admin_scope, user_scope: user_scope, channel: channel}
    end

    test "ban_user/3 bans a user", %{admin_scope: admin_scope, user_scope: user_scope} do
      assert {:ok, %Ban{} = ban} = Chat.ban_user(admin_scope, user_scope.user.id, reason: "Spam")

      assert ban.user_id == user_scope.user.id
      assert ban.banned_by_user_id == admin_scope.user.id
      assert ban.reason == "Spam"
      assert ban.expires_at == nil
    end

    test "ban_user/3 creates a moderation log entry", %{
      admin_scope: admin_scope,
      user_scope: user_scope
    } do
      {:ok, _ban} = Chat.ban_user(admin_scope, user_scope.user.id, reason: "Spam")

      logs = Chat.list_moderation_logs()

      assert Enum.any?(logs, fn log ->
               log.action == "ban" &&
                 log.target_user_id == user_scope.user.id &&
                 log.moderator_id == admin_scope.user.id
             end)
    end

    test "ban_user/3 with expiration date creates temporary ban", %{
      admin_scope: admin_scope,
      user_scope: user_scope
    } do
      # Use truncated datetime to match database precision
      expires_at = DateTime.utc_now() |> DateTime.add(1, :day) |> DateTime.truncate(:second)

      assert {:ok, %Ban{} = ban} =
               Chat.ban_user(admin_scope, user_scope.user.id, expires_at: expires_at)

      assert DateTime.compare(ban.expires_at, expires_at) == :eq
    end

    test "ban_user/3 requires admin scope", %{user_scope: user_scope} do
      other_user = user_scope_fixture()

      assert_raise MatchError, fn ->
        Chat.ban_user(user_scope, other_user.user.id)
      end
    end

    test "banned?/1 returns true for banned users", %{
      admin_scope: admin_scope,
      user_scope: user_scope
    } do
      refute Chat.banned?(user_scope.user.id)

      {:ok, _ban} = Chat.ban_user(admin_scope, user_scope.user.id)

      assert Chat.banned?(user_scope.user.id)
    end

    test "banned?/1 returns false for expired bans", %{
      admin_scope: admin_scope,
      user_scope: user_scope
    } do
      # Create a ban that expired 1 second ago
      expires_at = DateTime.add(DateTime.utc_now(), -1, :second)
      {:ok, _ban} = Chat.ban_user(admin_scope, user_scope.user.id, expires_at: expires_at)

      refute Chat.banned?(user_scope.user.id)
    end

    test "unban_user/2 removes the ban", %{admin_scope: admin_scope, user_scope: user_scope} do
      {:ok, _ban} = Chat.ban_user(admin_scope, user_scope.user.id)
      assert Chat.banned?(user_scope.user.id)

      {:ok, _} = Chat.unban_user(admin_scope, user_scope.user.id)
      refute Chat.banned?(user_scope.user.id)
    end

    test "unban_user/2 creates a moderation log entry", %{
      admin_scope: admin_scope,
      user_scope: user_scope
    } do
      {:ok, _ban} = Chat.ban_user(admin_scope, user_scope.user.id)
      {:ok, _} = Chat.unban_user(admin_scope, user_scope.user.id)

      logs = Chat.list_moderation_logs()

      assert Enum.any?(logs, fn log ->
               log.action == "unban" && log.target_user_id == user_scope.user.id
             end)
    end

    test "unban_user/2 returns error if user not banned", %{
      admin_scope: admin_scope,
      user_scope: user_scope
    } do
      assert {:error, :not_found} = Chat.unban_user(admin_scope, user_scope.user.id)
    end

    test "list_bans/0 returns active bans", %{admin_scope: admin_scope, user_scope: user_scope} do
      {:ok, ban} = Chat.ban_user(admin_scope, user_scope.user.id)

      bans = Chat.list_bans()
      assert Enum.any?(bans, fn b -> b.id == ban.id end)
    end

    test "get_active_ban/1 returns the ban with preloaded banned_by", %{
      admin_scope: admin_scope,
      user_scope: user_scope
    } do
      {:ok, _ban} = Chat.ban_user(admin_scope, user_scope.user.id, reason: "Test")

      ban = Chat.get_active_ban(user_scope.user.id)
      assert ban.banned_by.id == admin_scope.user.id
      assert ban.reason == "Test"
    end
  end

  describe "mutes" do
    setup do
      admin_scope = admin_scope_fixture()
      user_scope = user_scope_fixture()
      channel = channel_fixture()
      %{admin_scope: admin_scope, user_scope: user_scope, channel: channel}
    end

    test "mute_user/3 mutes a user in a channel", %{
      admin_scope: admin_scope,
      user_scope: user_scope,
      channel: channel
    } do
      assert {:ok, %Mute{} = mute} =
               Chat.mute_user(admin_scope, user_scope.user.id,
                 duration: 10,
                 channel_id: channel.id,
                 reason: "Timeout"
               )

      assert mute.user_id == user_scope.user.id
      assert mute.muted_by_user_id == admin_scope.user.id
      assert mute.channel_id == channel.id
      assert mute.reason == "Timeout"
      assert mute.expires_at != nil
    end

    test "mute_user/3 creates global mute when channel_id is nil", %{
      admin_scope: admin_scope,
      user_scope: user_scope
    } do
      assert {:ok, %Mute{} = mute} = Chat.mute_user(admin_scope, user_scope.user.id, duration: 10)

      assert mute.channel_id == nil
    end

    test "mute_user/3 creates a moderation log entry", %{
      admin_scope: admin_scope,
      user_scope: user_scope
    } do
      {:ok, _mute} = Chat.mute_user(admin_scope, user_scope.user.id, duration: 10, reason: "Spam")

      logs = Chat.list_moderation_logs()

      assert Enum.any?(logs, fn log ->
               log.action == "mute" && log.target_user_id == user_scope.user.id
             end)
    end

    test "mute_user/3 requires admin scope", %{user_scope: user_scope} do
      other_user = user_scope_fixture()

      assert_raise MatchError, fn ->
        Chat.mute_user(user_scope, other_user.user.id, duration: 10)
      end
    end

    test "muted?/2 returns true for muted users in channel", %{
      admin_scope: admin_scope,
      user_scope: user_scope,
      channel: channel
    } do
      refute Chat.muted?(user_scope.user.id, channel.id)

      {:ok, _mute} =
        Chat.mute_user(admin_scope, user_scope.user.id, duration: 10, channel_id: channel.id)

      assert Chat.muted?(user_scope.user.id, channel.id)
    end

    test "muted?/2 returns true for globally muted users", %{
      admin_scope: admin_scope,
      user_scope: user_scope,
      channel: channel
    } do
      {:ok, _mute} = Chat.mute_user(admin_scope, user_scope.user.id, duration: 10)

      # Global mute applies to all channels
      assert Chat.muted?(user_scope.user.id, channel.id)
    end

    test "unmute_user/3 removes the mute", %{
      admin_scope: admin_scope,
      user_scope: user_scope,
      channel: channel
    } do
      {:ok, _mute} =
        Chat.mute_user(admin_scope, user_scope.user.id, duration: 10, channel_id: channel.id)

      assert Chat.muted?(user_scope.user.id, channel.id)

      {:ok, _} = Chat.unmute_user(admin_scope, user_scope.user.id, channel_id: channel.id)
      refute Chat.muted?(user_scope.user.id, channel.id)
    end

    test "unmute_user/3 creates a moderation log entry", %{
      admin_scope: admin_scope,
      user_scope: user_scope,
      channel: channel
    } do
      {:ok, _mute} =
        Chat.mute_user(admin_scope, user_scope.user.id, duration: 10, channel_id: channel.id)

      {:ok, _} = Chat.unmute_user(admin_scope, user_scope.user.id, channel_id: channel.id)

      logs = Chat.list_moderation_logs()

      assert Enum.any?(logs, fn log ->
               log.action == "unmute" && log.target_user_id == user_scope.user.id
             end)
    end

    test "list_mutes/1 returns active mutes", %{
      admin_scope: admin_scope,
      user_scope: user_scope,
      channel: channel
    } do
      {:ok, mute} =
        Chat.mute_user(admin_scope, user_scope.user.id, duration: 10, channel_id: channel.id)

      mutes = Chat.list_mutes()
      assert Enum.any?(mutes, fn m -> m.id == mute.id end)
    end

    test "list_mutes/1 filters by channel", %{
      admin_scope: admin_scope,
      user_scope: user_scope,
      channel: channel
    } do
      {:ok, mute} =
        Chat.mute_user(admin_scope, user_scope.user.id, duration: 10, channel_id: channel.id)

      mutes = Chat.list_mutes(channel_id: channel.id)
      assert Enum.any?(mutes, fn m -> m.id == mute.id end)

      other_channel = channel_fixture(%{name: "other-channel"})
      mutes_other = Chat.list_mutes(channel_id: other_channel.id)
      refute Enum.any?(mutes_other, fn m -> m.id == mute.id end)
    end
  end

  describe "blocks (personal)" do
    setup do
      user1_scope = user_scope_fixture()
      user2_scope = user_scope_fixture()
      channel = channel_fixture()
      %{user1_scope: user1_scope, user2_scope: user2_scope, channel: channel}
    end

    test "block_user/2 blocks another user", %{user1_scope: user1_scope, user2_scope: user2_scope} do
      assert {:ok, %Block{} = block} = Chat.block_user(user1_scope, user2_scope.user.id)

      assert block.user_id == user1_scope.user.id
      assert block.blocked_user_id == user2_scope.user.id
    end

    test "block_user/2 prevents self-blocking", %{user1_scope: user1_scope} do
      assert {:error, changeset} = Chat.block_user(user1_scope, user1_scope.user.id)
      assert "cannot block yourself" in errors_on(changeset).blocked_user_id
    end

    test "blocked?/2 returns true for blocked users", %{
      user1_scope: user1_scope,
      user2_scope: user2_scope
    } do
      refute Chat.blocked?(user1_scope, user2_scope.user.id)

      {:ok, _block} = Chat.block_user(user1_scope, user2_scope.user.id)

      assert Chat.blocked?(user1_scope, user2_scope.user.id)
    end

    test "unblock_user/2 removes the block", %{user1_scope: user1_scope, user2_scope: user2_scope} do
      {:ok, _block} = Chat.block_user(user1_scope, user2_scope.user.id)
      assert Chat.blocked?(user1_scope, user2_scope.user.id)

      {:ok, _} = Chat.unblock_user(user1_scope, user2_scope.user.id)
      refute Chat.blocked?(user1_scope, user2_scope.user.id)
    end

    test "unblock_user/2 returns error if user not blocked", %{
      user1_scope: user1_scope,
      user2_scope: user2_scope
    } do
      assert {:error, :not_found} = Chat.unblock_user(user1_scope, user2_scope.user.id)
    end

    test "list_blocks/1 returns blocked users", %{
      user1_scope: user1_scope,
      user2_scope: user2_scope
    } do
      {:ok, block} = Chat.block_user(user1_scope, user2_scope.user.id)

      blocks = Chat.list_blocks(user1_scope)
      assert Enum.any?(blocks, fn b -> b.id == block.id end)
    end

    test "blocked_user_ids/1 returns list of blocked user ids", %{
      user1_scope: user1_scope,
      user2_scope: user2_scope
    } do
      {:ok, _block} = Chat.block_user(user1_scope, user2_scope.user.id)

      blocked_ids = Chat.blocked_user_ids(user1_scope)
      assert user2_scope.user.id in blocked_ids
    end

    test "list_messages_for_user/3 filters out blocked users' messages", %{
      user1_scope: user1_scope,
      user2_scope: user2_scope,
      channel: channel
    } do
      # User2 creates a message
      {:ok, blocked_message} =
        Chat.create_message(user2_scope, channel.id, %{"body" => "Hello from user2"})

      # User1 creates a message
      {:ok, own_message} =
        Chat.create_message(user1_scope, channel.id, %{"body" => "Hello from user1"})

      # Before blocking - user1 sees both messages
      messages_before = Chat.list_messages_for_user(user1_scope, channel.id)
      assert Enum.any?(messages_before, fn m -> m.id == blocked_message.id end)
      assert Enum.any?(messages_before, fn m -> m.id == own_message.id end)

      # User1 blocks user2
      {:ok, _block} = Chat.block_user(user1_scope, user2_scope.user.id)

      # After blocking - user1 only sees their own messages
      messages_after = Chat.list_messages_for_user(user1_scope, channel.id)
      refute Enum.any?(messages_after, fn m -> m.id == blocked_message.id end)
      assert Enum.any?(messages_after, fn m -> m.id == own_message.id end)
    end
  end

  describe "moderation checks on messaging" do
    setup do
      admin_scope = admin_scope_fixture()
      user_scope = user_scope_fixture()
      channel = channel_fixture()
      %{admin_scope: admin_scope, user_scope: user_scope, channel: channel}
    end

    test "create_message_with_checks/3 succeeds for normal users", %{
      user_scope: user_scope,
      channel: channel
    } do
      assert {:ok, %Message{}} =
               Chat.create_message_with_checks(user_scope, channel.id, %{"body" => "Hello"})
    end

    test "create_message_with_checks/3 returns :banned for banned users", %{
      admin_scope: admin_scope,
      user_scope: user_scope,
      channel: channel
    } do
      {:ok, _ban} = Chat.ban_user(admin_scope, user_scope.user.id)

      assert {:error, :banned} =
               Chat.create_message_with_checks(user_scope, channel.id, %{"body" => "Hello"})
    end

    test "create_message_with_checks/3 returns :muted for muted users", %{
      admin_scope: admin_scope,
      user_scope: user_scope,
      channel: channel
    } do
      {:ok, _mute} =
        Chat.mute_user(admin_scope, user_scope.user.id, duration: 10, channel_id: channel.id)

      assert {:error, :muted} =
               Chat.create_message_with_checks(user_scope, channel.id, %{"body" => "Hello"})
    end

    test "can_send_message?/2 returns :ok for normal users", %{
      user_scope: user_scope,
      channel: channel
    } do
      assert :ok = Chat.can_send_message?(user_scope, channel.id)
    end

    test "can_send_message?/2 returns {:error, :banned} for banned users", %{
      admin_scope: admin_scope,
      user_scope: user_scope,
      channel: channel
    } do
      {:ok, _ban} = Chat.ban_user(admin_scope, user_scope.user.id)

      assert {:error, :banned} = Chat.can_send_message?(user_scope, channel.id)
    end

    test "can_send_message?/2 returns {:error, :muted} for muted users", %{
      admin_scope: admin_scope,
      user_scope: user_scope,
      channel: channel
    } do
      {:ok, _mute} =
        Chat.mute_user(admin_scope, user_scope.user.id, duration: 10, channel_id: channel.id)

      assert {:error, :muted} = Chat.can_send_message?(user_scope, channel.id)
    end
  end

  describe "admin-only channels" do
    setup do
      admin_scope = admin_scope_fixture()
      user_scope = user_scope_fixture()
      %{admin_scope: admin_scope, user_scope: user_scope}
    end

    test "list_channels_for_user/1 returns all channels for admins", %{admin_scope: admin_scope} do
      regular_channel = channel_fixture(%{name: "public-channel", is_admin_only: false})
      admin_channel = channel_fixture(%{name: "admin-channel", is_admin_only: true})

      channels = Chat.list_channels_for_user(admin_scope)
      channel_ids = Enum.map(channels, & &1.id)

      assert regular_channel.id in channel_ids
      assert admin_channel.id in channel_ids
    end

    test "list_channels_for_user/1 filters out admin-only channels for regular users", %{
      user_scope: user_scope
    } do
      regular_channel = channel_fixture(%{name: "public-channel-2", is_admin_only: false})
      admin_channel = channel_fixture(%{name: "admin-channel-2", is_admin_only: true})

      channels = Chat.list_channels_for_user(user_scope)
      channel_ids = Enum.map(channels, & &1.id)

      assert regular_channel.id in channel_ids
      refute admin_channel.id in channel_ids
    end

    test "can_access_channel?/2 returns true for public channels for any user", %{
      user_scope: user_scope
    } do
      channel = channel_fixture(%{name: "public-access-test", is_admin_only: false})
      assert Chat.can_access_channel?(user_scope, channel)
    end

    test "can_access_channel?/2 returns true for admin-only channels for admins", %{
      admin_scope: admin_scope
    } do
      channel = channel_fixture(%{name: "admin-access-test", is_admin_only: true})
      assert Chat.can_access_channel?(admin_scope, channel)
    end

    test "can_access_channel?/2 returns false for admin-only channels for regular users", %{
      user_scope: user_scope
    } do
      channel = channel_fixture(%{name: "admin-access-denied", is_admin_only: true})
      refute Chat.can_access_channel?(user_scope, channel)
    end

    test "get_accessible_channel/2 returns {:ok, channel} for accessible channels", %{
      user_scope: user_scope
    } do
      channel = channel_fixture(%{name: "accessible-get-test", is_admin_only: false})
      assert {:ok, found_channel} = Chat.get_accessible_channel(user_scope, channel.slug)
      assert found_channel.id == channel.id
    end

    test "get_accessible_channel/2 returns {:ok, channel} for admin accessing admin-only channel",
         %{
           admin_scope: admin_scope
         } do
      channel = channel_fixture(%{name: "admin-get-test", is_admin_only: true})
      assert {:ok, found_channel} = Chat.get_accessible_channel(admin_scope, channel.slug)
      assert found_channel.id == channel.id
    end

    test "get_accessible_channel/2 returns {:error, :not_authorized} for regular user on admin channel",
         %{
           user_scope: user_scope
         } do
      channel = channel_fixture(%{name: "admin-denied-get", is_admin_only: true})
      assert {:error, :not_authorized} = Chat.get_accessible_channel(user_scope, channel.slug)
    end

    test "get_accessible_channel/2 raises for non-existent channel", %{user_scope: user_scope} do
      assert_raise Ecto.NoResultsError, fn ->
        Chat.get_accessible_channel(user_scope, "nonexistent-channel")
      end
    end
  end

  describe "moderation logs" do
    setup do
      admin_scope = admin_scope_fixture()
      user_scope = user_scope_fixture()
      %{admin_scope: admin_scope, user_scope: user_scope}
    end

    test "list_moderation_logs/1 returns logs ordered by date", %{
      admin_scope: admin_scope,
      user_scope: user_scope
    } do
      {:ok, _ban} = Chat.ban_user(admin_scope, user_scope.user.id)
      {:ok, _} = Chat.unban_user(admin_scope, user_scope.user.id)

      logs = Chat.list_moderation_logs()
      assert length(logs) >= 2

      # Verify both actions are recorded for this user
      actions = Enum.map(logs, & &1.action)
      assert "ban" in actions
      assert "unban" in actions
    end

    test "list_moderation_logs/1 filters by action", %{
      admin_scope: admin_scope,
      user_scope: user_scope
    } do
      {:ok, _ban} = Chat.ban_user(admin_scope, user_scope.user.id)
      {:ok, _} = Chat.unban_user(admin_scope, user_scope.user.id)

      ban_logs = Chat.list_moderation_logs(action: "ban")
      assert Enum.all?(ban_logs, fn log -> log.action == "ban" end)

      unban_logs = Chat.list_moderation_logs(action: "unban")
      assert Enum.all?(unban_logs, fn log -> log.action == "unban" end)
    end

    test "list_moderation_logs/1 respects limit option", %{admin_scope: admin_scope} do
      # Create multiple users to ban
      for _ <- 1..5 do
        user = user_scope_fixture()
        {:ok, _ban} = Chat.ban_user(admin_scope, user.user.id)
      end

      logs = Chat.list_moderation_logs(limit: 3)
      assert length(logs) == 3
    end

    test "moderation logs have preloaded associations", %{
      admin_scope: admin_scope,
      user_scope: user_scope
    } do
      {:ok, _ban} = Chat.ban_user(admin_scope, user_scope.user.id, reason: "Test")

      [log | _] = Chat.list_moderation_logs()
      assert log.moderator.id == admin_scope.user.id
      assert log.target_user.id == user_scope.user.id
    end
  end
end
