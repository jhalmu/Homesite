defmodule Homesite.Chat.Presence do
  @moduledoc """
  Phoenix Presence for tracking online users in chat.

  Tracks which users are currently viewing chat channels.
  Provides counts for display in navigation indicators.
  """

  use Phoenix.Presence,
    otp_app: :homesite,
    pubsub_server: Homesite.PubSub

  alias Homesite.Accounts.Scope

  @topic "chat:presence"

  @doc """
  Track a user as present in chat.

  Call this when a user mounts a chat LiveView.
  """
  def track_user(%Scope{} = scope) do
    track(self(), @topic, scope.user.id, %{
      user_id: scope.user.id,
      username: scope.user.display_name || scope.user.email,
      online_at: System.system_time(:second)
    })
  end

  @doc """
  Untrack a user from chat presence.

  Usually called automatically when the process terminates.
  """
  def untrack_user(%Scope{} = scope) do
    untrack(self(), @topic, scope.user.id)
  end

  @doc """
  Subscribe to presence updates.

  Subscribers receive Phoenix.Presence diff messages.
  """
  def subscribe do
    Phoenix.PubSub.subscribe(Homesite.PubSub, @topic)
  end

  @doc """
  Returns the count of currently online users in chat.
  """
  def online_count do
    @topic
    |> list()
    |> map_size()
  end

  @doc """
  Returns list of online user IDs.
  """
  def online_user_ids do
    @topic
    |> list()
    |> Map.keys()
  end

  @doc """
  Check if a specific user is online in chat.
  """
  def online?(user_id) do
    user_id in online_user_ids()
  end
end
