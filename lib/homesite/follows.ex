defmodule Homesite.Follows do
  @moduledoc """
  The Follows context manages user follow relationships.

  All functions require a Scope for authorization.
  """

  import Ecto.Query
  alias Homesite.Repo
  alias Homesite.Accounts.Scope
  alias Homesite.Follows.Follower
  alias Homesite.Accounts.User

  # PubSub topic helpers
  defp followers_topic(user_id), do: "user:#{user_id}:followers"

  @doc """
  Subscribes to follow updates for a user.
  Broadcasts: {:new_follower, %Follower{}}, {:unfollowed, %Follower{}}
  """
  def subscribe_followers(%Scope{} = scope) do
    Phoenix.PubSub.subscribe(Homesite.PubSub, followers_topic(scope.user.id))
  end

  @doc """
  Unsubscribes from follow updates for a user.
  """
  def unsubscribe_followers(%Scope{} = scope) do
    Phoenix.PubSub.unsubscribe(Homesite.PubSub, followers_topic(scope.user.id))
  end

  @doc """
  Follows a user. Returns {:ok, follower} or {:error, changeset}.
  Broadcasts :new_follower to the followed user's topic.
  """
  def follow_user(%Scope{} = scope, followed_user_id) when is_integer(followed_user_id) do
    attrs = %{follower_id: scope.user.id, followed_id: followed_user_id}

    %Follower{}
    |> Follower.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, follower} ->
        follower = Repo.preload(follower, [:follower, :followed])
        broadcast_follow(follower, :new_follower)
        {:ok, follower}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Unfollows a user. Returns {:ok, follower} or {:error, :not_found}.
  """
  def unfollow_user(%Scope{} = scope, followed_user_id) when is_integer(followed_user_id) do
    query =
      from f in Follower,
        where: f.follower_id == ^scope.user.id and f.followed_id == ^followed_user_id

    case Repo.one(query) do
      nil ->
        {:error, :not_found}

      follower ->
        follower = Repo.preload(follower, [:follower, :followed])
        Repo.delete(follower)
        broadcast_follow(follower, :unfollowed)
        {:ok, follower}
    end
  end

  @doc """
  Checks if the current user follows another user.
  """
  def following?(%Scope{} = scope, followed_user_id) when is_integer(followed_user_id) do
    query =
      from f in Follower,
        where: f.follower_id == ^scope.user.id and f.followed_id == ^followed_user_id

    Repo.exists?(query)
  end

  @doc """
  Lists users who follow the current user (followers).
  Returns a list of maps with :user and :followed_at keys.
  """
  def list_followers(%Scope{} = scope) do
    list_followers_for_user(scope.user.id)
  end

  @doc """
  Lists users who follow a specific user (for public profile views).
  Returns a list of maps with :user and :followed_at keys.
  """
  def list_followers_for_user(user_id) when is_integer(user_id) do
    query =
      from f in Follower,
        where: f.followed_id == ^user_id,
        join: u in User,
        on: u.id == f.follower_id,
        order_by: [desc: f.inserted_at],
        select: %{user: u, followed_at: f.inserted_at, id: f.id}

    Repo.all(query)
  end

  @doc """
  Lists users the current user follows (following).
  Returns a list of maps with :user and :followed_at keys.
  """
  def list_following(%Scope{} = scope) do
    list_following_for_user(scope.user.id)
  end

  @doc """
  Lists users a specific user follows (for public profile views).
  Returns a list of maps with :user and :followed_at keys.
  """
  def list_following_for_user(user_id) when is_integer(user_id) do
    query =
      from f in Follower,
        where: f.follower_id == ^user_id,
        join: u in User,
        on: u.id == f.followed_id,
        order_by: [desc: f.inserted_at],
        select: %{user: u, followed_at: f.inserted_at, id: f.id}

    Repo.all(query)
  end

  @doc """
  Gets follower and following counts for a user.
  """
  def get_follow_counts(user_id) when is_integer(user_id) do
    followers_count =
      from(f in Follower, where: f.followed_id == ^user_id, select: count())
      |> Repo.one()

    following_count =
      from(f in Follower, where: f.follower_id == ^user_id, select: count())
      |> Repo.one()

    %{followers: followers_count, following: following_count}
  end

  @doc """
  Check if two users follow each other (mutual follow).
  """
  def mutual_follow?(%Scope{} = scope, other_user_id) when is_integer(other_user_id) do
    following?(scope, other_user_id) and
      Repo.exists?(
        from f in Follower,
          where: f.follower_id == ^other_user_id and f.followed_id == ^scope.user.id
      )
  end

  @doc """
  Check if a user is following another user (for display purposes).
  """
  def is_following?(follower_id, followed_id)
      when is_integer(follower_id) and is_integer(followed_id) do
    Repo.exists?(
      from f in Follower,
        where: f.follower_id == ^follower_id and f.followed_id == ^followed_id
    )
  end

  # Broadcasts follow event to the followed user's topic
  defp broadcast_follow(%Follower{} = follower, event) do
    Phoenix.PubSub.broadcast(
      Homesite.PubSub,
      followers_topic(follower.followed_id),
      {event, follower}
    )
  end
end
