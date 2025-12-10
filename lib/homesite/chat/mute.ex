defmodule Homesite.Chat.Mute do
  @moduledoc """
  Schema for chat mutes.

  Admins can mute users in specific channels or globally (channel_id = nil).
  Mutes always have an expiration time.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "chat_mutes" do
    field :reason, :string
    field :expires_at, :utc_datetime

    belongs_to :user, Homesite.Accounts.User
    belongs_to :muted_by, Homesite.Accounts.User, foreign_key: :muted_by_user_id
    belongs_to :channel, Homesite.Chat.Channel

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(mute, attrs) do
    mute
    |> cast(attrs, [:user_id, :muted_by_user_id, :channel_id, :reason, :expires_at])
    |> validate_required([:user_id, :muted_by_user_id, :expires_at])
    |> validate_length(:reason, max: 500)
    |> validate_future_expiry()
    |> validate_not_self_mute()
    |> unique_constraint([:user_id, :channel_id], name: :chat_mutes_user_channel_unique)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:muted_by_user_id)
    |> foreign_key_constraint(:channel_id)
  end

  defp validate_future_expiry(changeset) do
    expires_at = get_field(changeset, :expires_at)

    if expires_at && DateTime.compare(DateTime.utc_now(), expires_at) != :lt do
      add_error(changeset, :expires_at, "must be in the future")
    else
      changeset
    end
  end

  defp validate_not_self_mute(changeset) do
    user_id = get_field(changeset, :user_id)
    muted_by_user_id = get_field(changeset, :muted_by_user_id)

    if user_id && muted_by_user_id && user_id == muted_by_user_id do
      add_error(changeset, :user_id, "cannot mute yourself")
    else
      changeset
    end
  end

  @doc """
  Returns true if the mute is currently active (not expired).
  """
  def active?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :lt
  end
end
