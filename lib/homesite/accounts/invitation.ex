defmodule Homesite.Accounts.Invitation do
  @moduledoc """
  Invitation schema for controlling user registration.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "invitations" do
    field :code, :string
    field :max_uses, :integer
    field :current_uses, :integer, default: 0
    field :expires_at, :utc_datetime
    field :default_role, :string, default: "user"

    belongs_to :created_by, Homesite.Accounts.User, foreign_key: :created_by_user_id

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a new invitation.
  """
  def changeset(invitation, attrs) do
    invitation
    |> cast(attrs, [:code, :max_uses, :expires_at, :default_role, :created_by_user_id])
    |> validate_required([:code, :created_by_user_id])
    |> validate_inclusion(:default_role, ["user", "admin"])
    |> validate_number(:max_uses, greater_than: 0)
    |> validate_number(:current_uses, greater_than_or_equal_to: 0)
    |> unique_constraint(:code)
  end

  @doc """
  Returns true if the invitation is valid (not expired, not exhausted).
  """
  def valid?(%__MODULE__{} = invitation) do
    not_expired?(invitation) and not_exhausted?(invitation)
  end

  @doc """
  Returns true if the invitation has not expired.
  """
  def not_expired?(%__MODULE__{expires_at: nil}), do: true

  def not_expired?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :lt
  end

  @doc """
  Returns true if the invitation has not been exhausted.
  """
  def not_exhausted?(%__MODULE__{max_uses: nil}), do: true

  def not_exhausted?(%__MODULE__{max_uses: max_uses, current_uses: current_uses}) do
    current_uses < max_uses
  end

  @doc """
  Generates a random invitation code (8 characters, alphanumeric uppercase).
  """
  def generate_code do
    # Use only alphanumeric characters (A-Z, 0-9)
    chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    char_list = String.graphemes(chars)

    Enum.map_join(1..8, "", fn _ -> Enum.random(char_list) end)
  end
end
