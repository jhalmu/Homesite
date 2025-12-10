defmodule Homesite.Moderation.ModerationActionLog do
  @moduledoc """
  Schema for moderation action audit log.

  Tracks all moderation actions for accountability and compliance.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @actions ~w(mute_user unmute_user report_user suspend unsuspend ban unban
              banner_create banner_dismiss report_resolve report_dismiss auto_unsuspend)

  schema "moderation_action_logs" do
    field :action, :string
    field :reason, :string
    field :expires_at, :utc_datetime
    field :metadata, :map, default: %{}

    belongs_to :moderator, Homesite.Accounts.User
    belongs_to :target_user, Homesite.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(log, attrs) do
    log
    |> cast(attrs, [:moderator_id, :target_user_id, :action, :reason, :expires_at, :metadata])
    |> validate_required([:target_user_id, :action])
    |> validate_inclusion(:action, @actions)
    |> validate_length(:reason, max: 5000)
    |> foreign_key_constraint(:moderator_id)
    |> foreign_key_constraint(:target_user_id)
  end

  def actions, do: @actions
end
