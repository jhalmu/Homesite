defmodule Homesite.Follows.Follower do
  @moduledoc """
  Schema for user follow relationships.

  A follower relationship represents one user following another.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Homesite.Accounts.User

  schema "followers" do
    belongs_to :follower, User
    belongs_to :followed, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(follower, attrs) do
    follower
    |> cast(attrs, [:follower_id, :followed_id])
    |> validate_required([:follower_id, :followed_id])
    |> validate_not_self_follow()
    |> unique_constraint([:follower_id, :followed_id],
      message: "already following this user"
    )
    |> foreign_key_constraint(:follower_id)
    |> foreign_key_constraint(:followed_id)
    |> check_constraint(:followed_id, name: :no_self_follow, message: "cannot follow yourself")
  end

  defp validate_not_self_follow(changeset) do
    follower_id = get_field(changeset, :follower_id)
    followed_id = get_field(changeset, :followed_id)

    if follower_id && follower_id == followed_id do
      add_error(changeset, :followed_id, "cannot follow yourself")
    else
      changeset
    end
  end
end
