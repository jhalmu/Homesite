defmodule Homesite.TeamsTest do
  use Homesite.DataCase

  alias Homesite.Teams

  describe "teams" do
    alias Homesite.Teams.Team

    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.TeamsFixtures

    @invalid_attrs %{name: nil, slug: nil, avatar: nil, description_fi: nil, description_en: nil, public_profile: nil, settings: nil}

    test "list_teams/1 returns all scoped teams" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      team = team_fixture(scope)
      other_team = team_fixture(other_scope)
      assert Teams.list_teams(scope) == [team]
      assert Teams.list_teams(other_scope) == [other_team]
    end

    test "get_team!/2 returns the team with given id" do
      scope = user_scope_fixture()
      team = team_fixture(scope)
      other_scope = user_scope_fixture()
      assert Teams.get_team!(scope, team.id) == team
      assert_raise Ecto.NoResultsError, fn -> Teams.get_team!(other_scope, team.id) end
    end

    test "create_team/2 with valid data creates a team" do
      valid_attrs = %{name: "some name", slug: "some slug", avatar: "some avatar", description_fi: "some description_fi", description_en: "some description_en", public_profile: true, settings: %{}}
      scope = user_scope_fixture()

      assert {:ok, %Team{} = team} = Teams.create_team(scope, valid_attrs)
      assert team.name == "some name"
      assert team.slug == "some slug"
      assert team.avatar == "some avatar"
      assert team.description_fi == "some description_fi"
      assert team.description_en == "some description_en"
      assert team.public_profile == true
      assert team.settings == %{}
      assert team.user_id == scope.user.id
    end

    test "create_team/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Teams.create_team(scope, @invalid_attrs)
    end

    test "update_team/3 with valid data updates the team" do
      scope = user_scope_fixture()
      team = team_fixture(scope)
      update_attrs = %{name: "some updated name", slug: "some updated slug", avatar: "some updated avatar", description_fi: "some updated description_fi", description_en: "some updated description_en", public_profile: false, settings: %{}}

      assert {:ok, %Team{} = team} = Teams.update_team(scope, team, update_attrs)
      assert team.name == "some updated name"
      assert team.slug == "some updated slug"
      assert team.avatar == "some updated avatar"
      assert team.description_fi == "some updated description_fi"
      assert team.description_en == "some updated description_en"
      assert team.public_profile == false
      assert team.settings == %{}
    end

    test "update_team/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      team = team_fixture(scope)

      assert_raise MatchError, fn ->
        Teams.update_team(other_scope, team, %{})
      end
    end

    test "update_team/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      team = team_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Teams.update_team(scope, team, @invalid_attrs)
      assert team == Teams.get_team!(scope, team.id)
    end

    test "delete_team/2 deletes the team" do
      scope = user_scope_fixture()
      team = team_fixture(scope)
      assert {:ok, %Team{}} = Teams.delete_team(scope, team)
      assert_raise Ecto.NoResultsError, fn -> Teams.get_team!(scope, team.id) end
    end

    test "delete_team/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      team = team_fixture(scope)
      assert_raise MatchError, fn -> Teams.delete_team(other_scope, team) end
    end

    test "change_team/2 returns a team changeset" do
      scope = user_scope_fixture()
      team = team_fixture(scope)
      assert %Ecto.Changeset{} = Teams.change_team(scope, team)
    end
  end

  describe "team_memberships" do
    alias Homesite.Teams.TeamMembership

    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.TeamsFixtures

    @invalid_attrs %{role: nil}

    test "list_team_memberships/1 returns all scoped team_memberships" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      team_membership = team_membership_fixture(scope)
      other_team_membership = team_membership_fixture(other_scope)
      assert Teams.list_team_memberships(scope) == [team_membership]
      assert Teams.list_team_memberships(other_scope) == [other_team_membership]
    end

    test "get_team_membership!/2 returns the team_membership with given id" do
      scope = user_scope_fixture()
      team_membership = team_membership_fixture(scope)
      other_scope = user_scope_fixture()
      assert Teams.get_team_membership!(scope, team_membership.id) == team_membership
      assert_raise Ecto.NoResultsError, fn -> Teams.get_team_membership!(other_scope, team_membership.id) end
    end

    test "create_team_membership/2 with valid data creates a team_membership" do
      valid_attrs = %{role: "some role"}
      scope = user_scope_fixture()

      assert {:ok, %TeamMembership{} = team_membership} = Teams.create_team_membership(scope, valid_attrs)
      assert team_membership.role == "some role"
      assert team_membership.user_id == scope.user.id
    end

    test "create_team_membership/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Teams.create_team_membership(scope, @invalid_attrs)
    end

    test "update_team_membership/3 with valid data updates the team_membership" do
      scope = user_scope_fixture()
      team_membership = team_membership_fixture(scope)
      update_attrs = %{role: "some updated role"}

      assert {:ok, %TeamMembership{} = team_membership} = Teams.update_team_membership(scope, team_membership, update_attrs)
      assert team_membership.role == "some updated role"
    end

    test "update_team_membership/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      team_membership = team_membership_fixture(scope)

      assert_raise MatchError, fn ->
        Teams.update_team_membership(other_scope, team_membership, %{})
      end
    end

    test "update_team_membership/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      team_membership = team_membership_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Teams.update_team_membership(scope, team_membership, @invalid_attrs)
      assert team_membership == Teams.get_team_membership!(scope, team_membership.id)
    end

    test "delete_team_membership/2 deletes the team_membership" do
      scope = user_scope_fixture()
      team_membership = team_membership_fixture(scope)
      assert {:ok, %TeamMembership{}} = Teams.delete_team_membership(scope, team_membership)
      assert_raise Ecto.NoResultsError, fn -> Teams.get_team_membership!(scope, team_membership.id) end
    end

    test "delete_team_membership/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      team_membership = team_membership_fixture(scope)
      assert_raise MatchError, fn -> Teams.delete_team_membership(other_scope, team_membership) end
    end

    test "change_team_membership/2 returns a team_membership changeset" do
      scope = user_scope_fixture()
      team_membership = team_membership_fixture(scope)
      assert %Ecto.Changeset{} = Teams.change_team_membership(scope, team_membership)
    end
  end

  describe "team_invitations" do
    alias Homesite.Teams.TeamInvitation

    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.TeamsFixtures

    @invalid_attrs %{token: nil, role: nil, email: nil, expires_at: nil}

    test "list_team_invitations/1 returns all scoped team_invitations" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      team_invitation = team_invitation_fixture(scope)
      other_team_invitation = team_invitation_fixture(other_scope)
      assert Teams.list_team_invitations(scope) == [team_invitation]
      assert Teams.list_team_invitations(other_scope) == [other_team_invitation]
    end

    test "get_team_invitation!/2 returns the team_invitation with given id" do
      scope = user_scope_fixture()
      team_invitation = team_invitation_fixture(scope)
      other_scope = user_scope_fixture()
      assert Teams.get_team_invitation!(scope, team_invitation.id) == team_invitation
      assert_raise Ecto.NoResultsError, fn -> Teams.get_team_invitation!(other_scope, team_invitation.id) end
    end

    test "create_team_invitation/2 with valid data creates a team_invitation" do
      valid_attrs = %{token: "some token", role: "some role", email: "some email", expires_at: ~U[2025-11-16 15:03:00Z]}
      scope = user_scope_fixture()

      assert {:ok, %TeamInvitation{} = team_invitation} = Teams.create_team_invitation(scope, valid_attrs)
      assert team_invitation.token == "some token"
      assert team_invitation.role == "some role"
      assert team_invitation.email == "some email"
      assert team_invitation.expires_at == ~U[2025-11-16 15:03:00Z]
      assert team_invitation.user_id == scope.user.id
    end

    test "create_team_invitation/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Teams.create_team_invitation(scope, @invalid_attrs)
    end

    test "update_team_invitation/3 with valid data updates the team_invitation" do
      scope = user_scope_fixture()
      team_invitation = team_invitation_fixture(scope)
      update_attrs = %{token: "some updated token", role: "some updated role", email: "some updated email", expires_at: ~U[2025-11-17 15:03:00Z]}

      assert {:ok, %TeamInvitation{} = team_invitation} = Teams.update_team_invitation(scope, team_invitation, update_attrs)
      assert team_invitation.token == "some updated token"
      assert team_invitation.role == "some updated role"
      assert team_invitation.email == "some updated email"
      assert team_invitation.expires_at == ~U[2025-11-17 15:03:00Z]
    end

    test "update_team_invitation/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      team_invitation = team_invitation_fixture(scope)

      assert_raise MatchError, fn ->
        Teams.update_team_invitation(other_scope, team_invitation, %{})
      end
    end

    test "update_team_invitation/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      team_invitation = team_invitation_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Teams.update_team_invitation(scope, team_invitation, @invalid_attrs)
      assert team_invitation == Teams.get_team_invitation!(scope, team_invitation.id)
    end

    test "delete_team_invitation/2 deletes the team_invitation" do
      scope = user_scope_fixture()
      team_invitation = team_invitation_fixture(scope)
      assert {:ok, %TeamInvitation{}} = Teams.delete_team_invitation(scope, team_invitation)
      assert_raise Ecto.NoResultsError, fn -> Teams.get_team_invitation!(scope, team_invitation.id) end
    end

    test "delete_team_invitation/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      team_invitation = team_invitation_fixture(scope)
      assert_raise MatchError, fn -> Teams.delete_team_invitation(other_scope, team_invitation) end
    end

    test "change_team_invitation/2 returns a team_invitation changeset" do
      scope = user_scope_fixture()
      team_invitation = team_invitation_fixture(scope)
      assert %Ecto.Changeset{} = Teams.change_team_invitation(scope, team_invitation)
    end
  end
end
