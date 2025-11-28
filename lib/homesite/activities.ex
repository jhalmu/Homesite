defmodule Homesite.Activities do
  @moduledoc """
  The Activities context for tracking user actions.
  """

  import Ecto.Query, warn: false
  alias Homesite.Repo

  alias Homesite.Activities.Activity
  alias Homesite.Accounts.User

  @doc """
  Creates an activity.

  ## Examples

      iex> create_activity(%User{}, "blog_published", %Post{}, "Published blog post")
      {:ok, %Activity{}}

  """
  def create_activity(%User{} = user, activity_type, subject \\ nil, content) do
    attrs = %{
      user_id: user.id,
      activity_type: activity_type,
      content: content
    }

    attrs =
      if subject do
        attrs
        |> Map.put(:subject_type, subject.__struct__ |> to_string() |> String.split(".") |> List.last())
        |> Map.put(:subject_id, subject.id)
      else
        attrs
      end

    %Activity{}
    |> Activity.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Lists recent activities, optionally filtered by user.

  ## Examples

      iex> list_recent_activities(limit: 20)
      [%Activity{}, ...]

      iex> list_recent_activities(user_id: 1, limit: 10)
      [%Activity{}, ...]

  """
  def list_recent_activities(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    user_id = Keyword.get(opts, :user_id)

    query =
      from a in Activity,
        order_by: [desc: a.inserted_at],
        limit: ^limit,
        preload: [:user]

    query =
      if user_id do
        from a in query, where: a.user_id == ^user_id
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Deletes old activities older than the specified days.

  ## Examples

      iex> delete_old_activities(30)
      {5, nil}

  """
  def delete_old_activities(days_old) do
    cutoff_date = DateTime.utc_now() |> DateTime.add(-days_old, :day)

    from(a in Activity, where: a.inserted_at < ^cutoff_date)
    |> Repo.delete_all()
  end
end
