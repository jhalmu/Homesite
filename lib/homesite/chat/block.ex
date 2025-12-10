defmodule Homesite.Chat.Block do
  @moduledoc """
  Schema for personal chat blocks.

  Users can block other users to hide their messages from view.
  This is a personal preference and does not affect the blocked user.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "chat_blocks" do
    belongs_to :user, Homesite.Accounts.User
    belongs_to :blocked_user, Homesite.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(block, attrs) do
    block
    |> cast(attrs, [:user_id, :blocked_user_id])
    |> validate_required([:user_id, :blocked_user_id])
    |> validate_not_self_block()
    |> unique_constraint([:user_id, :blocked_user_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:blocked_user_id)
  end

  defp validate_not_self_block(changeset) do
    user_id = get_field(changeset, :user_id)
    blocked_user_id = get_field(changeset, :blocked_user_id)

    if user_id && blocked_user_id && user_id == blocked_user_id do
      add_error(changeset, :blocked_user_id, "cannot block yourself")
    else
      changeset
    end
  end
end
