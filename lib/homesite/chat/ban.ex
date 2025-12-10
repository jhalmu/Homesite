defmodule Homesite.Chat.Ban do
  @moduledoc """
  Schema for chat bans.

  Admins can ban users from chat entirely. Bans can be temporary (with expires_at)
  or permanent (expires_at = nil).
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "chat_bans" do
    field :reason, :string
    field :expires_at, :utc_datetime

    belongs_to :user, Homesite.Accounts.User
    belongs_to :banned_by, Homesite.Accounts.User, foreign_key: :banned_by_user_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(ban, attrs) do
    ban
    |> cast(attrs, [:user_id, :banned_by_user_id, :reason, :expires_at])
    |> validate_required([:user_id, :banned_by_user_id])
    |> validate_length(:reason, max: 500)
    |> validate_not_self_ban()
    |> unique_constraint(:user_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:banned_by_user_id)
  end

  defp validate_not_self_ban(changeset) do
    user_id = get_field(changeset, :user_id)
    banned_by_user_id = get_field(changeset, :banned_by_user_id)

    if user_id && banned_by_user_id && user_id == banned_by_user_id do
      add_error(changeset, :user_id, "cannot ban yourself")
    else
      changeset
    end
  end

  @doc """
  Returns true if the ban is currently active (not expired).
  """
  def active?(%__MODULE__{expires_at: nil}), do: true

  def active?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :lt
  end
end
