defmodule Homesite.Content do
  @moduledoc """
  The Content context.
  """

  import Ecto.Query, warn: false
  alias Homesite.Repo

  alias Homesite.Content.BlogPost
  alias Homesite.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any blog_post changes.

  The broadcasted messages match the pattern:

    * {:created, %BlogPost{}}
    * {:updated, %BlogPost{}}
    * {:deleted, %BlogPost{}}

  """
  def subscribe_blog_posts(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Homesite.PubSub, "user:#{key}:blog_posts")
  end

  defp broadcast_blog_post(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Homesite.PubSub, "user:#{key}:blog_posts", message)
  end

  @doc """
  Returns the list of blog_posts.

  ## Examples

      iex> list_blog_posts(scope)
      [%BlogPost{}, ...]

  """
  def list_blog_posts(%Scope{} = scope) do
    Repo.all_by(BlogPost, user_id: scope.user.id)
  end

  @doc """
  Gets a single blog_post.

  Raises `Ecto.NoResultsError` if the Blog post does not exist.

  ## Examples

      iex> get_blog_post!(scope, 123)
      %BlogPost{}

      iex> get_blog_post!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_blog_post!(%Scope{} = scope, id) do
    Repo.get_by!(BlogPost, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a blog_post.

  ## Examples

      iex> create_blog_post(scope, %{field: value})
      {:ok, %BlogPost{}}

      iex> create_blog_post(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_blog_post(%Scope{} = scope, attrs) do
    with {:ok, blog_post = %BlogPost{}} <-
           %BlogPost{}
           |> BlogPost.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_blog_post(scope, {:created, blog_post})
      {:ok, blog_post}
    end
  end

  @doc """
  Updates a blog_post.

  ## Examples

      iex> update_blog_post(scope, blog_post, %{field: new_value})
      {:ok, %BlogPost{}}

      iex> update_blog_post(scope, blog_post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_blog_post(%Scope{} = scope, %BlogPost{} = blog_post, attrs) do
    true = blog_post.user_id == scope.user.id

    with {:ok, blog_post = %BlogPost{}} <-
           blog_post
           |> BlogPost.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_blog_post(scope, {:updated, blog_post})
      {:ok, blog_post}
    end
  end

  @doc """
  Deletes a blog_post.

  ## Examples

      iex> delete_blog_post(scope, blog_post)
      {:ok, %BlogPost{}}

      iex> delete_blog_post(scope, blog_post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_blog_post(%Scope{} = scope, %BlogPost{} = blog_post) do
    true = blog_post.user_id == scope.user.id

    with {:ok, blog_post = %BlogPost{}} <-
           Repo.delete(blog_post) do
      broadcast_blog_post(scope, {:deleted, blog_post})
      {:ok, blog_post}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking blog_post changes.

  ## Examples

      iex> change_blog_post(scope, blog_post)
      %Ecto.Changeset{data: %BlogPost{}}

  """
  def change_blog_post(%Scope{} = scope, %BlogPost{} = blog_post, attrs \\ %{}) do
    true = blog_post.user_id == scope.user.id

    BlogPost.changeset(blog_post, attrs, scope)
  end
end
