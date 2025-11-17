defmodule Homesite.Teams.Team do
  use Ecto.Schema
  import Ecto.Changeset

  schema "teams" do
    field :name, :string
    field :slug, :string
    field :avatar, :binary
    field :description_fi, :string
    field :description_en, :string
    field :public_profile, :boolean, default: true
    field :settings, :map

    has_many :team_memberships, Homesite.Teams.TeamMembership
    has_many :users, through: [:team_memberships, :user]
    has_many :team_invitations, Homesite.Teams.TeamInvitation

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :slug, :avatar, :description_fi, :description_en, :public_profile, :settings])
    |> validate_required([:name, :slug])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:slug, min: 2, max: 100)
    |> validate_format(:slug, ~r/^[a-z0-9\-]+$/, message: "must contain only lowercase letters, numbers, and hyphens")
    |> unique_constraint(:slug)
  end
end
