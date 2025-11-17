defmodule Homesite.Teams.TeamMembership do
  use Ecto.Schema
  import Ecto.Changeset

  schema "team_memberships" do
    field :role, :string, default: "member"
    belongs_to :user, Homesite.Accounts.User
    belongs_to :team, Homesite.Teams.Team

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(team_membership, attrs) do
    team_membership
    |> cast(attrs, [:role, :user_id, :team_id])
    |> validate_required([:role, :user_id, :team_id])
    |> validate_inclusion(:role, ["member", "curator", "admin"])
    |> unique_constraint([:user_id, :team_id])
  end
end
