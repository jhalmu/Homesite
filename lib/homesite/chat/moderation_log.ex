defmodule Homesite.Chat.ModerationLog do
  @moduledoc """
  Schema for chat moderation audit log.

  Tracks all moderation actions (ban, unban, mute, unmute) for accountability.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @actions ~w(ban unban mute unmute)

  schema "chat_moderation_logs" do
    field :action, :string
    field :reason, :string
    field :expires_at, :utc_datetime
    field :metadata, :map, default: %{}

    belongs_to :moderator, Homesite.Accounts.User
    belongs_to :target_user, Homesite.Accounts.User
    belongs_to :channel, Homesite.Chat.Channel

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(log, attrs) do
    log
    |> cast(attrs, [
      :moderator_id,
      :target_user_id,
      :action,
      :channel_id,
      :reason,
      :expires_at,
      :metadata
    ])
    |> validate_required([:moderator_id, :target_user_id, :action])
    |> validate_inclusion(:action, @actions)
    |> validate_length(:reason, max: 500)
    |> foreign_key_constraint(:moderator_id)
    |> foreign_key_constraint(:target_user_id)
    |> foreign_key_constraint(:channel_id)
  end

  @doc """
  Returns the list of valid moderation actions.
  """
  def actions, do: @actions
end
