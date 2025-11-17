defmodule Homesite.Tags do
  @moduledoc """
  The Tags context.
  """

  import Ecto.Query, warn: false
  alias Homesite.Repo

  alias Homesite.Tags.Tag
  alias Homesite.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any tag changes.

  The broadcasted messages match the pattern:

    * {:created, %Tag{}}
    * {:updated, %Tag{}}
    * {:deleted, %Tag{}}

  """
  def subscribe_tags(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Homesite.PubSub, "user:#{key}:tags")
  end

  defp broadcast_tag(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Homesite.PubSub, "user:#{key}:tags", message)
  end

  @doc """
  Returns the list of tags.

  ## Examples

      iex> list_tags(scope)
      [%Tag{}, ...]

  """
  def list_tags(%Scope{} = scope) do
    Repo.all_by(Tag, user_id: scope.user.id)
  end

  @doc """
  Gets a single tag.

  Raises `Ecto.NoResultsError` if the Tag does not exist.

  ## Examples

      iex> get_tag!(scope, 123)
      %Tag{}

      iex> get_tag!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_tag!(%Scope{} = scope, id) do
    Repo.get_by!(Tag, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a tag.

  ## Examples

      iex> create_tag(scope, %{field: value})
      {:ok, %Tag{}}

      iex> create_tag(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tag(%Scope{} = scope, attrs) do
    with {:ok, tag = %Tag{}} <-
           %Tag{}
           |> Tag.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_tag(scope, {:created, tag})
      {:ok, tag}
    end
  end

  @doc """
  Updates a tag.

  ## Examples

      iex> update_tag(scope, tag, %{field: new_value})
      {:ok, %Tag{}}

      iex> update_tag(scope, tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tag(%Scope{} = scope, %Tag{} = tag, attrs) do
    true = tag.user_id == scope.user.id

    with {:ok, tag = %Tag{}} <-
           tag
           |> Tag.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_tag(scope, {:updated, tag})
      {:ok, tag}
    end
  end

  @doc """
  Deletes a tag.

  ## Examples

      iex> delete_tag(scope, tag)
      {:ok, %Tag{}}

      iex> delete_tag(scope, tag)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tag(%Scope{} = scope, %Tag{} = tag) do
    true = tag.user_id == scope.user.id

    with {:ok, tag = %Tag{}} <-
           Repo.delete(tag) do
      broadcast_tag(scope, {:deleted, tag})
      {:ok, tag}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tag changes.

  ## Examples

      iex> change_tag(scope, tag)
      %Ecto.Changeset{data: %Tag{}}

  """
  def change_tag(%Scope{} = scope, %Tag{} = tag, attrs \\ %{}) do
    true = tag.user_id == scope.user.id

    Tag.changeset(tag, attrs, scope)
  end

  alias Homesite.Tags.Tagging
  alias Homesite.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any tagging changes.

  The broadcasted messages match the pattern:

    * {:created, %Tagging{}}
    * {:updated, %Tagging{}}
    * {:deleted, %Tagging{}}

  """
  def subscribe_taggings(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Homesite.PubSub, "user:#{key}:taggings")
  end

  defp broadcast_tagging(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Homesite.PubSub, "user:#{key}:taggings", message)
  end

  @doc """
  Returns the list of taggings.

  ## Examples

      iex> list_taggings(scope)
      [%Tagging{}, ...]

  """
  def list_taggings(%Scope{} = scope) do
    Repo.all_by(Tagging, user_id: scope.user.id)
  end

  @doc """
  Gets a single tagging.

  Raises `Ecto.NoResultsError` if the Tagging does not exist.

  ## Examples

      iex> get_tagging!(scope, 123)
      %Tagging{}

      iex> get_tagging!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_tagging!(%Scope{} = scope, id) do
    Repo.get_by!(Tagging, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a tagging.

  ## Examples

      iex> create_tagging(scope, %{field: value})
      {:ok, %Tagging{}}

      iex> create_tagging(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tagging(%Scope{} = scope, attrs) do
    with {:ok, tagging = %Tagging{}} <-
           %Tagging{}
           |> Tagging.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_tagging(scope, {:created, tagging})
      {:ok, tagging}
    end
  end

  @doc """
  Updates a tagging.

  ## Examples

      iex> update_tagging(scope, tagging, %{field: new_value})
      {:ok, %Tagging{}}

      iex> update_tagging(scope, tagging, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tagging(%Scope{} = scope, %Tagging{} = tagging, attrs) do
    true = tagging.user_id == scope.user.id

    with {:ok, tagging = %Tagging{}} <-
           tagging
           |> Tagging.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_tagging(scope, {:updated, tagging})
      {:ok, tagging}
    end
  end

  @doc """
  Deletes a tagging.

  ## Examples

      iex> delete_tagging(scope, tagging)
      {:ok, %Tagging{}}

      iex> delete_tagging(scope, tagging)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tagging(%Scope{} = scope, %Tagging{} = tagging) do
    true = tagging.user_id == scope.user.id

    with {:ok, tagging = %Tagging{}} <-
           Repo.delete(tagging) do
      broadcast_tagging(scope, {:deleted, tagging})
      {:ok, tagging}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tagging changes.

  ## Examples

      iex> change_tagging(scope, tagging)
      %Ecto.Changeset{data: %Tagging{}}

  """
  def change_tagging(%Scope{} = scope, %Tagging{} = tagging, attrs \\ %{}) do
    true = tagging.user_id == scope.user.id

    Tagging.changeset(tagging, attrs, scope)
  end
end
