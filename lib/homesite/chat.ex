defmodule Homesite.Chat do
  @moduledoc """
  The Chat context.

  Provides IRC-style channel-based chat for registered users.
  All channels are public - any authenticated user can participate.

  ## Moderation Features

  Admins can:
  - Ban users from chat entirely (temporary or permanent)
  - Mute users in specific channels or globally

  Users can:
  - Block other users (hides their messages from view)
  """

  import Ecto.Query, warn: false

  alias Homesite.Accounts
  alias Homesite.Accounts.Scope
  alias Homesite.Chat.{Ban, Block, Channel, Message, ModerationLog, Mute}
  alias Homesite.Repo

  ## PubSub

  @doc """
  Subscribes to notifications for a specific channel.

  The broadcasted messages match the pattern:

    * {:new_message, %Message{}}
    * {:deleted_message, message_id}

  """
  def subscribe_channel(channel_id) do
    Phoenix.PubSub.subscribe(Homesite.PubSub, "chat:channel:#{channel_id}")
  end

  @doc """
  Unsubscribes from a channel's notifications.
  """
  def unsubscribe_channel(channel_id) do
    Phoenix.PubSub.unsubscribe(Homesite.PubSub, "chat:channel:#{channel_id}")
  end

  defp broadcast_channel(channel_id, message) do
    Phoenix.PubSub.broadcast(Homesite.PubSub, "chat:channel:#{channel_id}", message)
  end

  ## Channels

  @doc """
  Returns all chat channels.

  ## Examples

      iex> list_channels()
      [%Channel{}, ...]

  """
  def list_channels do
    from(c in Channel, order_by: [desc: c.is_default, asc: c.name])
    |> Repo.all()
  end

  @doc """
  Gets a single channel by ID.

  Raises `Ecto.NoResultsError` if the Channel does not exist.

  ## Examples

      iex> get_channel!(123)
      %Channel{}

      iex> get_channel!(456)
      ** (Ecto.NoResultsError)

  """
  def get_channel!(id) do
    Repo.get!(Channel, id)
  end

  @doc """
  Gets a single channel by slug.

  Raises `Ecto.NoResultsError` if the Channel does not exist.

  ## Examples

      iex> get_channel_by_slug!("general")
      %Channel{slug: "general"}

      iex> get_channel_by_slug!("nonexistent")
      ** (Ecto.NoResultsError)

  """
  def get_channel_by_slug!(slug) when is_binary(slug) do
    Repo.get_by!(Channel, slug: slug)
  end

  @doc """
  Gets the default channel (usually #general).

  Returns nil if no default channel exists.

  ## Examples

      iex> get_default_channel()
      %Channel{is_default: true}

  """
  def get_default_channel do
    Repo.get_by(Channel, is_default: true)
  end

  @doc """
  Creates a channel.

  Only authenticated users can create channels. The creator is recorded.

  ## Examples

      iex> create_channel(scope, %{name: "random"})
      {:ok, %Channel{}}

      iex> create_channel(scope, %{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  def create_channel(%Scope{} = scope, attrs) do
    %Channel{created_by_user_id: scope.user.id}
    |> Channel.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a channel.

  ## Examples

      iex> update_channel(channel, %{description: "New description"})
      {:ok, %Channel{}}

      iex> update_channel(channel, %{name: ""})
      {:error, %Ecto.Changeset{}}

  """
  def update_channel(%Channel{} = channel, attrs) do
    channel
    |> Channel.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a channel.

  Cannot delete the default channel.

  ## Examples

      iex> delete_channel(channel)
      {:ok, %Channel{}}

      iex> delete_channel(default_channel)
      {:error, :cannot_delete_default}

  """
  def delete_channel(%Channel{is_default: true}), do: {:error, :cannot_delete_default}

  def delete_channel(%Channel{} = channel) do
    Repo.delete(channel)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking channel changes.

  ## Examples

      iex> change_channel(channel)
      %Ecto.Changeset{data: %Channel{}}

  """
  def change_channel(%Channel{} = channel, attrs \\ %{}) do
    Channel.changeset(channel, attrs)
  end

  ## Messages

  @doc """
  Returns messages for a channel, ordered by insertion time.

  ## Options

    * `:limit` - Maximum number of messages to return (default: 50)
    * `:before` - Return messages before this message ID (for pagination)

  ## Examples

      iex> list_messages(channel_id)
      [%Message{}, ...]

      iex> list_messages(channel_id, limit: 100, before: 500)
      [%Message{}, ...]

  """
  def list_messages(channel_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    before_id = Keyword.get(opts, :before)

    query =
      from(m in Message,
        where: m.channel_id == ^channel_id,
        order_by: [desc: m.inserted_at, desc: m.id],
        limit: ^limit,
        preload: [:user]
      )

    query =
      if before_id do
        from(m in query, where: m.id < ^before_id)
      else
        query
      end

    # Return in chronological order (oldest first)
    query
    |> Repo.all()
    |> Enum.reverse()
  end

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_message!(id) do
    Message
    |> Repo.get!(id)
    |> Repo.preload(:user)
  end

  @doc """
  Creates a message in a channel.

  Broadcasts `{:new_message, message}` to channel subscribers.

  ## Examples

      iex> create_message(scope, channel_id, %{body: "Hello!"})
      {:ok, %Message{}}

      iex> create_message(scope, channel_id, %{body: ""})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(%Scope{} = scope, channel_id, attrs) do
    # Normalize attrs to string keys to avoid mixed key maps
    attrs =
      attrs
      |> Enum.into(%{}, fn
        {k, v} when is_atom(k) -> {Atom.to_string(k), v}
        {k, v} -> {k, v}
      end)
      |> Map.put("channel_id", channel_id)
      |> Map.put("user_id", scope.user.id)

    with {:ok, message} <-
           %Message{}
           |> Message.changeset(attrs)
           |> Repo.insert() do
      message = Repo.preload(message, :user)
      broadcast_channel(channel_id, {:new_message, message})
      {:ok, message}
    end
  end

  @doc """
  Deletes a message.

  Users can only delete their own messages.
  Broadcasts `{:deleted_message, message_id}` to channel subscribers.

  ## Examples

      iex> delete_message(scope, message)
      {:ok, %Message{}}

      iex> delete_message(other_scope, message)
      ** (MatchError)

  """
  def delete_message(%Scope{} = scope, %Message{} = message) do
    # Security: users can only delete their own messages
    true = message.user_id == scope.user.id

    with {:ok, deleted_message} <- Repo.delete(message) do
      broadcast_channel(message.channel_id, {:deleted_message, deleted_message.id})
      {:ok, deleted_message}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{data: %Message{}}

  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  ## Bans

  @doc """
  Returns all active bans.

  ## Examples

      iex> list_bans()
      [%Ban{}, ...]

  """
  def list_bans do
    now = DateTime.utc_now()

    from(b in Ban,
      where: is_nil(b.expires_at) or b.expires_at > ^now,
      order_by: [desc: b.inserted_at],
      preload: [:user, :banned_by]
    )
    |> Repo.all()
  end

  @doc """
  Gets a ban for a specific user.

  Returns nil if the user is not banned or the ban has expired.
  """
  def get_active_ban(user_id) do
    now = DateTime.utc_now()

    from(b in Ban,
      where: b.user_id == ^user_id,
      where: is_nil(b.expires_at) or b.expires_at > ^now,
      preload: [:banned_by]
    )
    |> Repo.one()
  end

  @doc """
  Checks if a user is currently banned from chat.

  ## Examples

      iex> banned?(user_id)
      true

  """
  def banned?(user_id) do
    get_active_ban(user_id) != nil
  end

  @doc """
  Bans a user from chat.

  Requires admin scope. Creates a moderation log entry.

  ## Options

    * `:reason` - Reason for the ban (optional)
    * `:expires_at` - When the ban expires (optional, nil = permanent)

  ## Examples

      iex> ban_user(admin_scope, user_id, reason: "Spam", expires_at: ~U[2025-01-01 00:00:00Z])
      {:ok, %Ban{}}

  """
  def ban_user(%Scope{} = scope, user_id, opts \\ []) do
    # Require admin
    true = Accounts.Scope.admin?(scope)

    reason = Keyword.get(opts, :reason)
    expires_at = Keyword.get(opts, :expires_at)

    attrs = %{
      "user_id" => user_id,
      "banned_by_user_id" => scope.user.id,
      "reason" => reason,
      "expires_at" => expires_at
    }

    Repo.transaction(fn ->
      # Remove any existing ban first
      from(b in Ban, where: b.user_id == ^user_id)
      |> Repo.delete_all()

      case %Ban{} |> Ban.changeset(attrs) |> Repo.insert() do
        {:ok, ban} ->
          log_moderation_action(scope, user_id, "ban", nil, reason, expires_at)
          Repo.preload(ban, [:user, :banned_by])

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Unbans a user from chat.

  Requires admin scope. Creates a moderation log entry.

  ## Examples

      iex> unban_user(admin_scope, user_id)
      {:ok, %Ban{}}

  """
  def unban_user(%Scope{} = scope, user_id) do
    # Require admin
    true = Accounts.Scope.admin?(scope)

    case Repo.get_by(Ban, user_id: user_id) do
      nil ->
        {:error, :not_found}

      ban ->
        case Repo.delete(ban) do
          {:ok, deleted_ban} ->
            log_moderation_action(scope, user_id, "unban", nil, nil, nil)
            {:ok, deleted_ban}

          error ->
            error
        end
    end
  end

  ## Mutes

  @doc """
  Returns all active mutes.

  ## Options

    * `:channel_id` - Filter by channel (optional)

  """
  def list_mutes(opts \\ []) do
    now = DateTime.utc_now()
    channel_id = Keyword.get(opts, :channel_id)

    query =
      from(m in Mute,
        where: m.expires_at > ^now,
        order_by: [desc: m.inserted_at],
        preload: [:user, :muted_by, :channel]
      )

    query =
      if channel_id do
        from(m in query, where: m.channel_id == ^channel_id or is_nil(m.channel_id))
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Gets active mutes for a user in a specific channel.

  Returns mutes that apply to the channel (channel-specific or global).
  """
  def get_active_mutes(user_id, channel_id) do
    now = DateTime.utc_now()

    from(m in Mute,
      where: m.user_id == ^user_id,
      where: m.expires_at > ^now,
      where: is_nil(m.channel_id) or m.channel_id == ^channel_id,
      preload: [:muted_by, :channel]
    )
    |> Repo.all()
  end

  @doc """
  Checks if a user is currently muted in a channel.

  ## Examples

      iex> muted?(user_id, channel_id)
      true

  """
  def muted?(user_id, channel_id) do
    get_active_mutes(user_id, channel_id) != []
  end

  @doc """
  Mutes a user in a channel or globally.

  Requires admin scope. Creates a moderation log entry.

  ## Options

    * `:channel_id` - Channel to mute in (nil = global mute)
    * `:reason` - Reason for the mute (optional)
    * `:duration` - Duration in minutes (required)

  ## Examples

      iex> mute_user(admin_scope, user_id, duration: 60, reason: "Timeout")
      {:ok, %Mute{}}

  """
  def mute_user(%Scope{} = scope, user_id, opts) do
    # Require admin
    true = Accounts.Scope.admin?(scope)

    channel_id = Keyword.get(opts, :channel_id)
    reason = Keyword.get(opts, :reason)
    duration = Keyword.fetch!(opts, :duration)

    expires_at = DateTime.add(DateTime.utc_now(), duration, :minute)

    attrs = %{
      "user_id" => user_id,
      "muted_by_user_id" => scope.user.id,
      "channel_id" => channel_id,
      "reason" => reason,
      "expires_at" => expires_at
    }

    Repo.transaction(fn ->
      # Remove any existing mute for this user/channel combination first
      query =
        if channel_id do
          from(m in Mute,
            where: m.user_id == ^user_id,
            where: m.channel_id == ^channel_id
          )
        else
          from(m in Mute,
            where: m.user_id == ^user_id,
            where: is_nil(m.channel_id)
          )
        end

      Repo.delete_all(query)

      case %Mute{} |> Mute.changeset(attrs) |> Repo.insert() do
        {:ok, mute} ->
          log_moderation_action(scope, user_id, "mute", channel_id, reason, expires_at)
          Repo.preload(mute, [:user, :muted_by, :channel])

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Unmutes a user in a channel or globally.

  Requires admin scope. Creates a moderation log entry.

  ## Options

    * `:channel_id` - Channel to unmute in (nil = global unmute)

  """
  def unmute_user(%Scope{} = scope, user_id, opts \\ []) do
    # Require admin
    true = Accounts.Scope.admin?(scope)

    channel_id = Keyword.get(opts, :channel_id)

    query =
      if channel_id do
        from(m in Mute,
          where: m.user_id == ^user_id,
          where: m.channel_id == ^channel_id
        )
      else
        from(m in Mute,
          where: m.user_id == ^user_id,
          where: is_nil(m.channel_id)
        )
      end

    case Repo.one(query) do
      nil ->
        {:error, :not_found}

      mute ->
        case Repo.delete(mute) do
          {:ok, deleted_mute} ->
            log_moderation_action(scope, user_id, "unmute", channel_id, nil, nil)
            {:ok, deleted_mute}

          error ->
            error
        end
    end
  end

  ## Blocks (Personal)

  @doc """
  Returns all users blocked by the current user.

  ## Examples

      iex> list_blocks(scope)
      [%Block{}, ...]

  """
  def list_blocks(%Scope{} = scope) do
    from(b in Block,
      where: b.user_id == ^scope.user.id,
      order_by: [desc: b.inserted_at],
      preload: [:blocked_user]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of user IDs that the current user has blocked.
  """
  def blocked_user_ids(%Scope{} = scope) do
    from(b in Block,
      where: b.user_id == ^scope.user.id,
      select: b.blocked_user_id
    )
    |> Repo.all()
  end

  @doc """
  Checks if the current user has blocked another user.

  ## Examples

      iex> blocked?(scope, other_user_id)
      true

  """
  def blocked?(%Scope{} = scope, other_user_id) do
    from(b in Block,
      where: b.user_id == ^scope.user.id and b.blocked_user_id == ^other_user_id
    )
    |> Repo.exists?()
  end

  @doc """
  Blocks another user.

  Users can block others to hide their messages from view.

  ## Examples

      iex> block_user(scope, other_user_id)
      {:ok, %Block{}}

  """
  def block_user(%Scope{} = scope, blocked_user_id) do
    attrs = %{
      "user_id" => scope.user.id,
      "blocked_user_id" => blocked_user_id
    }

    %Block{}
    |> Block.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Unblocks another user.

  ## Examples

      iex> unblock_user(scope, other_user_id)
      {:ok, %Block{}}

  """
  def unblock_user(%Scope{} = scope, blocked_user_id) do
    case Repo.get_by(Block, user_id: scope.user.id, blocked_user_id: blocked_user_id) do
      nil -> {:error, :not_found}
      block -> Repo.delete(block)
    end
  end

  ## Moderation Log

  @doc """
  Returns the moderation log entries.

  ## Options

    * `:limit` - Maximum number of entries (default: 50)
    * `:action` - Filter by action type

  """
  def list_moderation_logs(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    action = Keyword.get(opts, :action)

    query =
      from(l in ModerationLog,
        order_by: [desc: l.inserted_at],
        limit: ^limit,
        preload: [:moderator, :target_user, :channel]
      )

    query =
      if action do
        from(l in query, where: l.action == ^action)
      else
        query
      end

    Repo.all(query)
  end

  defp log_moderation_action(scope, target_user_id, action, channel_id, reason, expires_at) do
    %ModerationLog{}
    |> ModerationLog.changeset(%{
      "moderator_id" => scope.user.id,
      "target_user_id" => target_user_id,
      "action" => action,
      "channel_id" => channel_id,
      "reason" => reason,
      "expires_at" => expires_at
    })
    |> Repo.insert!()
  end

  ## Message helpers with moderation

  @doc """
  Returns messages for a channel, filtered by blocks and excluding muted messages.

  This is the preferred method for displaying messages to users as it respects
  personal blocks.

  ## Options

    * `:limit` - Maximum number of messages to return (default: 50)
    * `:before` - Return messages before this message ID (for pagination)

  """
  def list_messages_for_user(%Scope{} = scope, channel_id, opts \\ []) do
    blocked_ids = blocked_user_ids(scope)

    limit = Keyword.get(opts, :limit, 50)
    before_id = Keyword.get(opts, :before)

    query =
      from(m in Message,
        where: m.channel_id == ^channel_id,
        where: m.user_id not in ^blocked_ids,
        order_by: [desc: m.inserted_at, desc: m.id],
        limit: ^limit,
        preload: [:user]
      )

    query =
      if before_id do
        from(m in query, where: m.id < ^before_id)
      else
        query
      end

    query
    |> Repo.all()
    |> Enum.reverse()
  end

  @doc """
  Creates a message with moderation checks.

  Returns error if user is banned or muted.

  ## Examples

      iex> create_message_with_checks(scope, channel_id, attrs)
      {:ok, %Message{}}

      iex> create_message_with_checks(banned_scope, channel_id, attrs)
      {:error, :banned}

  """
  def create_message_with_checks(%Scope{} = scope, channel_id, attrs) do
    cond do
      banned?(scope.user.id) ->
        {:error, :banned}

      muted?(scope.user.id, channel_id) ->
        {:error, :muted}

      true ->
        create_message(scope, channel_id, attrs)
    end
  end

  @doc """
  Checks if a user can send messages in a channel.

  Returns :ok or {:error, reason}.
  """
  def can_send_message?(%Scope{} = scope, channel_id) do
    cond do
      banned?(scope.user.id) -> {:error, :banned}
      muted?(scope.user.id, channel_id) -> {:error, :muted}
      true -> :ok
    end
  end
end
