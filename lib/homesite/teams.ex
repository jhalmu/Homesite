defmodule Homesite.Teams do
  @moduledoc """
  The Teams context.
  """

  import Ecto.Query, warn: false
  alias Homesite.Repo

  alias Homesite.Teams.Team
  alias Homesite.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any team changes.

  The broadcasted messages match the pattern:

    * {:created, %Team{}}
    * {:updated, %Team{}}
    * {:deleted, %Team{}}

  """
  def subscribe_teams(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Homesite.PubSub, "user:#{key}:teams")
  end

  defp broadcast_team(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Homesite.PubSub, "user:#{key}:teams", message)
  end

  @doc """
  Returns the list of teams.

  ## Examples

      iex> list_teams(scope)
      [%Team{}, ...]

  """
  def list_teams(%Scope{} = scope) do
    Repo.all_by(Team, user_id: scope.user.id)
  end

  @doc """
  Gets a single team.

  Raises `Ecto.NoResultsError` if the Team does not exist.

  ## Examples

      iex> get_team!(scope, 123)
      %Team{}

      iex> get_team!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_team!(%Scope{} = scope, id) do
    Repo.get_by!(Team, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a team.

  ## Examples

      iex> create_team(scope, %{field: value})
      {:ok, %Team{}}

      iex> create_team(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_team(%Scope{} = scope, attrs) do
    with {:ok, team = %Team{}} <-
           %Team{}
           |> Team.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_team(scope, {:created, team})
      {:ok, team}
    end
  end

  @doc """
  Updates a team.

  ## Examples

      iex> update_team(scope, team, %{field: new_value})
      {:ok, %Team{}}

      iex> update_team(scope, team, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_team(%Scope{} = scope, %Team{} = team, attrs) do
    true = team.user_id == scope.user.id

    with {:ok, team = %Team{}} <-
           team
           |> Team.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_team(scope, {:updated, team})
      {:ok, team}
    end
  end

  @doc """
  Deletes a team.

  ## Examples

      iex> delete_team(scope, team)
      {:ok, %Team{}}

      iex> delete_team(scope, team)
      {:error, %Ecto.Changeset{}}

  """
  def delete_team(%Scope{} = scope, %Team{} = team) do
    true = team.user_id == scope.user.id

    with {:ok, team = %Team{}} <-
           Repo.delete(team) do
      broadcast_team(scope, {:deleted, team})
      {:ok, team}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking team changes.

  ## Examples

      iex> change_team(scope, team)
      %Ecto.Changeset{data: %Team{}}

  """
  def change_team(%Scope{} = scope, %Team{} = team, attrs \\ %{}) do
    true = team.user_id == scope.user.id

    Team.changeset(team, attrs, scope)
  end

  alias Homesite.Teams.TeamMembership
  alias Homesite.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any team_membership changes.

  The broadcasted messages match the pattern:

    * {:created, %TeamMembership{}}
    * {:updated, %TeamMembership{}}
    * {:deleted, %TeamMembership{}}

  """
  def subscribe_team_memberships(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Homesite.PubSub, "user:#{key}:team_memberships")
  end

  defp broadcast_team_membership(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Homesite.PubSub, "user:#{key}:team_memberships", message)
  end

  @doc """
  Returns the list of team_memberships.

  ## Examples

      iex> list_team_memberships(scope)
      [%TeamMembership{}, ...]

  """
  def list_team_memberships(%Scope{} = scope) do
    Repo.all_by(TeamMembership, user_id: scope.user.id)
  end

  @doc """
  Gets a single team_membership.

  Raises `Ecto.NoResultsError` if the Team membership does not exist.

  ## Examples

      iex> get_team_membership!(scope, 123)
      %TeamMembership{}

      iex> get_team_membership!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_team_membership!(%Scope{} = scope, id) do
    Repo.get_by!(TeamMembership, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a team_membership.

  ## Examples

      iex> create_team_membership(scope, %{field: value})
      {:ok, %TeamMembership{}}

      iex> create_team_membership(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_team_membership(%Scope{} = scope, attrs) do
    with {:ok, team_membership = %TeamMembership{}} <-
           %TeamMembership{}
           |> TeamMembership.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_team_membership(scope, {:created, team_membership})
      {:ok, team_membership}
    end
  end

  @doc """
  Updates a team_membership.

  ## Examples

      iex> update_team_membership(scope, team_membership, %{field: new_value})
      {:ok, %TeamMembership{}}

      iex> update_team_membership(scope, team_membership, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_team_membership(%Scope{} = scope, %TeamMembership{} = team_membership, attrs) do
    true = team_membership.user_id == scope.user.id

    with {:ok, team_membership = %TeamMembership{}} <-
           team_membership
           |> TeamMembership.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_team_membership(scope, {:updated, team_membership})
      {:ok, team_membership}
    end
  end

  @doc """
  Deletes a team_membership.

  ## Examples

      iex> delete_team_membership(scope, team_membership)
      {:ok, %TeamMembership{}}

      iex> delete_team_membership(scope, team_membership)
      {:error, %Ecto.Changeset{}}

  """
  def delete_team_membership(%Scope{} = scope, %TeamMembership{} = team_membership) do
    true = team_membership.user_id == scope.user.id

    with {:ok, team_membership = %TeamMembership{}} <-
           Repo.delete(team_membership) do
      broadcast_team_membership(scope, {:deleted, team_membership})
      {:ok, team_membership}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking team_membership changes.

  ## Examples

      iex> change_team_membership(scope, team_membership)
      %Ecto.Changeset{data: %TeamMembership{}}

  """
  def change_team_membership(%Scope{} = scope, %TeamMembership{} = team_membership, attrs \\ %{}) do
    true = team_membership.user_id == scope.user.id

    TeamMembership.changeset(team_membership, attrs, scope)
  end

  alias Homesite.Teams.TeamInvitation
  alias Homesite.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any team_invitation changes.

  The broadcasted messages match the pattern:

    * {:created, %TeamInvitation{}}
    * {:updated, %TeamInvitation{}}
    * {:deleted, %TeamInvitation{}}

  """
  def subscribe_team_invitations(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Homesite.PubSub, "user:#{key}:team_invitations")
  end

  defp broadcast_team_invitation(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Homesite.PubSub, "user:#{key}:team_invitations", message)
  end

  @doc """
  Returns the list of team_invitations.

  ## Examples

      iex> list_team_invitations(scope)
      [%TeamInvitation{}, ...]

  """
  def list_team_invitations(%Scope{} = scope) do
    Repo.all_by(TeamInvitation, user_id: scope.user.id)
  end

  @doc """
  Gets a single team_invitation.

  Raises `Ecto.NoResultsError` if the Team invitation does not exist.

  ## Examples

      iex> get_team_invitation!(scope, 123)
      %TeamInvitation{}

      iex> get_team_invitation!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_team_invitation!(%Scope{} = scope, id) do
    Repo.get_by!(TeamInvitation, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a team_invitation.

  ## Examples

      iex> create_team_invitation(scope, %{field: value})
      {:ok, %TeamInvitation{}}

      iex> create_team_invitation(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_team_invitation(%Scope{} = scope, attrs) do
    with {:ok, team_invitation = %TeamInvitation{}} <-
           %TeamInvitation{}
           |> TeamInvitation.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_team_invitation(scope, {:created, team_invitation})
      {:ok, team_invitation}
    end
  end

  @doc """
  Updates a team_invitation.

  ## Examples

      iex> update_team_invitation(scope, team_invitation, %{field: new_value})
      {:ok, %TeamInvitation{}}

      iex> update_team_invitation(scope, team_invitation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_team_invitation(%Scope{} = scope, %TeamInvitation{} = team_invitation, attrs) do
    true = team_invitation.user_id == scope.user.id

    with {:ok, team_invitation = %TeamInvitation{}} <-
           team_invitation
           |> TeamInvitation.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_team_invitation(scope, {:updated, team_invitation})
      {:ok, team_invitation}
    end
  end

  @doc """
  Deletes a team_invitation.

  ## Examples

      iex> delete_team_invitation(scope, team_invitation)
      {:ok, %TeamInvitation{}}

      iex> delete_team_invitation(scope, team_invitation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_team_invitation(%Scope{} = scope, %TeamInvitation{} = team_invitation) do
    true = team_invitation.user_id == scope.user.id

    with {:ok, team_invitation = %TeamInvitation{}} <-
           Repo.delete(team_invitation) do
      broadcast_team_invitation(scope, {:deleted, team_invitation})
      {:ok, team_invitation}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking team_invitation changes.

  ## Examples

      iex> change_team_invitation(scope, team_invitation)
      %Ecto.Changeset{data: %TeamInvitation{}}

  """
  def change_team_invitation(%Scope{} = scope, %TeamInvitation{} = team_invitation, attrs \\ %{}) do
    true = team_invitation.user_id == scope.user.id

    TeamInvitation.changeset(team_invitation, attrs, scope)
  end
end
