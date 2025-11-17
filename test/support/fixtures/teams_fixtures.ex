defmodule Homesite.TeamsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Homesite.Teams` context.
  """

  @doc """
  Generate a unique team slug.
  """
  def unique_team_slug, do: "some slug#{System.unique_integer([:positive])}"

  @doc """
  Generate a team.
  """
  def team_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        avatar: "some avatar",
        description_en: "some description_en",
        description_fi: "some description_fi",
        name: "some name",
        public_profile: true,
        settings: %{},
        slug: unique_team_slug()
      })

    {:ok, team} = Homesite.Teams.create_team(scope, attrs)
    team
  end

  @doc """
  Generate a team_membership.
  """
  def team_membership_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        role: "some role"
      })

    {:ok, team_membership} = Homesite.Teams.create_team_membership(scope, attrs)
    team_membership
  end

  @doc """
  Generate a team_invitation.
  """
  def team_invitation_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        email: "some email",
        expires_at: ~U[2025-11-16 15:03:00Z],
        role: "some role",
        token: "some token"
      })

    {:ok, team_invitation} = Homesite.Teams.create_team_invitation(scope, attrs)
    team_invitation
  end
end
