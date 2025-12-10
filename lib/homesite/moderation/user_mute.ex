defmodule Homesite.Moderation.UserMute do
  @moduledoc """
  Schema for user-initiated mutes.

  Users can mute other users to hide their content globally (posts, chat, etc.).
  This is a personal preference and does not affect the muted user.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_mutes" do
    field :reason, :string

    belongs_to :user, Homesite.Accounts.User
    belongs_to :muted_user, Homesite.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(mute, attrs) do
    mute
    |> cast(attrs, [:user_id, :muted_user_id, :reason])
    |> validate_required([:user_id, :muted_user_id])
    |> validate_length(:reason, max: 500)
    |> validate_not_self_mute()
    |> unique_constraint([:user_id, :muted_user_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:muted_user_id)
  end

  defp validate_not_self_mute(changeset) do
    user_id = get_field(changeset, :user_id)
    muted_user_id = get_field(changeset, :muted_user_id)

    if user_id && muted_user_id && user_id == muted_user_id do
      add_error(changeset, :muted_user_id, "cannot mute yourself")
    else
      changeset
    end
  end
end
