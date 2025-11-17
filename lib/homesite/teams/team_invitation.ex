defmodule Homesite.Teams.TeamInvitation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "team_invitations" do
    field :email, :string
    field :role, :string, default: "member"
    field :token, :string
    field :expires_at, :utc_datetime

    belongs_to :team, Homesite.Teams.Team
    belongs_to :invited_by, Homesite.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(team_invitation, attrs) do
    team_invitation
    |> cast(attrs, [:email, :role, :token, :expires_at, :team_id, :invited_by_id])
    |> validate_required([:email, :role, :token, :expires_at, :team_id, :invited_by_id])
    |> validate_email()
    |> validate_inclusion(:role, ["member", "curator", "admin"])
    |> unique_constraint(:token)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> validate_length(:email, max: 160)
  end
end
