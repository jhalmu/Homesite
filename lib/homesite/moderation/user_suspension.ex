defmodule Homesite.Moderation.UserSuspension do
  @moduledoc """
  Schema for user suspensions.

  Admins can temporarily suspend user accounts, preventing login.
  Suspensions always have an expiration date.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_suspensions" do
    field :reason, :string
    field :expires_at, :utc_datetime
    field :lifted_at, :utc_datetime

    belongs_to :user, Homesite.Accounts.User
    belongs_to :suspended_by, Homesite.Accounts.User, foreign_key: :suspended_by_user_id
    belongs_to :lifted_by, Homesite.Accounts.User, foreign_key: :lifted_by_user_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(suspension, attrs) do
    suspension
    |> cast(attrs, [:user_id, :suspended_by_user_id, :reason, :expires_at])
    |> validate_required([:user_id, :suspended_by_user_id, :reason, :expires_at])
    |> validate_length(:reason, min: 10, max: 5000)
    |> validate_future_expiry()
    |> validate_not_self_suspend()
    |> unique_constraint(:user_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:suspended_by_user_id)
  end

  @doc """
  Changeset for lifting a suspension early.
  """
  def lift_changeset(suspension, attrs) do
    suspension
    |> cast(attrs, [:lifted_at, :lifted_by_user_id])
    |> validate_required([:lifted_at, :lifted_by_user_id])
  end

  defp validate_future_expiry(changeset) do
    expires_at = get_field(changeset, :expires_at)

    if expires_at && DateTime.compare(DateTime.utc_now(), expires_at) != :lt do
      add_error(changeset, :expires_at, "must be in the future")
    else
      changeset
    end
  end

  defp validate_not_self_suspend(changeset) do
    user_id = get_field(changeset, :user_id)
    suspended_by_user_id = get_field(changeset, :suspended_by_user_id)

    if user_id && suspended_by_user_id && user_id == suspended_by_user_id do
      add_error(changeset, :user_id, "cannot suspend yourself")
    else
      changeset
    end
  end

  @doc """
  Check if a suspension is currently active (not lifted and not expired).
  """
  def active?(%__MODULE__{lifted_at: lifted_at}) when not is_nil(lifted_at), do: false

  def active?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :lt
  end
end
