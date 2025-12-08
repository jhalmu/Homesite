defmodule Homesite.Chat do
  @moduledoc """
  The Chat context.

  Provides IRC-style channel-based chat for registered users.
  All channels are public - any authenticated user can participate.
  """

  import Ecto.Query, warn: false

  alias Homesite.Accounts.Scope
  alias Homesite.Chat.{Channel, Message}
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
end
