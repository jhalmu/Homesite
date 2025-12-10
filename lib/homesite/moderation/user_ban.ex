defmodule Homesite.Moderation.UserBan do
  @moduledoc """
  Schema for user bans.

  Admins can permanently ban user accounts, preventing login.
  Bans are permanent but can be lifted in rare cases.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_bans" do
    field :reason, :string
    field :permanent, :boolean, default: true
    field :lifted_at, :utc_datetime

    belongs_to :user, Homesite.Accounts.User
    belongs_to :banned_by, Homesite.Accounts.User, foreign_key: :banned_by_user_id
    belongs_to :lifted_by, Homesite.Accounts.User, foreign_key: :lifted_by_user_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(ban, attrs) do
    ban
    |> cast(attrs, [:user_id, :banned_by_user_id, :reason])
    |> validate_required([:user_id, :banned_by_user_id, :reason])
    |> validate_length(:reason, min: 10, max: 5000)
    |> validate_not_self_ban()
    |> unique_constraint(:user_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:banned_by_user_id)
  end

  @doc """
  Changeset for lifting a ban (rare).
  """
  def lift_changeset(ban, attrs) do
    ban
    |> cast(attrs, [:lifted_at, :lifted_by_user_id, :permanent])
    |> validate_required([:lifted_at, :lifted_by_user_id])
    |> put_change(:permanent, false)
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
  Check if a ban is currently active (not lifted).
  """
  def active?(%__MODULE__{lifted_at: lifted_at}) when not is_nil(lifted_at), do: false
  def active?(%__MODULE__{}), do: true
end
