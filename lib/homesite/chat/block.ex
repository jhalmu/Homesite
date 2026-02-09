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
  def changeset(block, attrs, opts \\ []) do
    block
    |> cast(attrs, [:user_id, :blocked_user_id])
    |> validate_required([:user_id, :blocked_user_id])
    |> validate_not_self_block()
    |> validate_not_blocking_admin(opts)
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

  defp validate_not_blocking_admin(changeset, opts) do
    # Allow passing a custom function for testing
    get_user_fn = Keyword.get(opts, :get_user_fn, &default_get_user/1)

    case get_change(changeset, :blocked_user_id) do
      nil ->
        changeset

      blocked_user_id ->
        check_admin_role(changeset, get_user_fn.(blocked_user_id))
    end
  end

  defp check_admin_role(changeset, nil), do: changeset

  defp check_admin_role(changeset, user) do
    if user.role == "admin" do
      add_error(changeset, :blocked_user_id, "cannot block admin accounts")
    else
      changeset
    end
  end

  defp default_get_user(id) do
    Homesite.Accounts.get_user!(id)
  rescue
    Ecto.NoResultsError -> nil
  end
end
