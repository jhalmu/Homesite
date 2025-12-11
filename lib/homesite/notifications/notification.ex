defmodule Homesite.Notifications.Notification do
  @moduledoc """
  Schema for user notifications.

  Notifications are stored events that inform users about activities
  related to them, such as new followers.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Homesite.Accounts.User

  @notification_types ~w(new_follower post_published)

  schema "notifications" do
    field :type, :string
    field :read_at, :utc_datetime
    field :data, :map, default: %{}

    belongs_to :user, User
    belongs_to :actor, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:user_id, :type, :read_at, :data, :actor_id])
    |> validate_required([:user_id, :type])
    |> validate_inclusion(:type, @notification_types)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:actor_id)
  end

  @doc """
  Returns a changeset that marks the notification as read.
  """
  def mark_read_changeset(notification) do
    change(notification, read_at: DateTime.utc_now(:second))
  end

  @doc """
  Returns the list of valid notification types.
  """
  def notification_types, do: @notification_types
end
