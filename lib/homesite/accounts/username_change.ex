defmodule Homesite.Accounts.UsernameChange do
  @moduledoc """
  Schema for tracking username changes for audit and security purposes.

  Helps prevent username squatting and provides an audit trail.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Homesite.Accounts.User

  schema "username_changes" do
    belongs_to :user, User
    field :old_username, :string
    field :new_username, :string
    field :changed_at, :utc_datetime
    field :ip_address, :string
    field :user_agent, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(username_change, attrs) do
    username_change
    |> cast(attrs, [:user_id, :old_username, :new_username, :changed_at, :ip_address, :user_agent])
    |> validate_required([:user_id, :new_username, :changed_at])
    |> foreign_key_constraint(:user_id)
  end
end
