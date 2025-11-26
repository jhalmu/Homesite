defmodule Homesite.Content do
  @moduledoc """
  The Content context.
  """

  import Ecto.Query, warn: false

  alias Homesite.Accounts.Scope
  alias Homesite.Content.{Post, Tag}
  alias Homesite.Repo

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
    Repo.scoped_all(Tag, user_id: scope.user.id)
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
  Gets a single tag by name.

  Returns nil if the Tag does not exist.

  ## Examples

      iex> get_tag_by_name(scope, "Technology")
      %Tag{}

      iex> get_tag_by_name(scope, "NonExistent")
      nil

  """
  def get_tag_by_name(%Scope{} = scope, name) do
    Repo.get_by(Tag, name: name, user_id: scope.user.id)
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

  @doc """
  Subscribes to scoped notifications about any post changes.

  The broadcasted messages match the pattern:

    * {:created, %Post{}}
    * {:updated, %Post{}}
    * {:deleted, %Post{}}

  """
  def subscribe_posts(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Homesite.PubSub, "user:#{key}:posts")
  end

  defp broadcast_post(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Homesite.PubSub, "user:#{key}:posts", message)
  end

  @doc """
  Returns the list of posts.

  ## Examples

      iex> list_posts(scope)
      [%Post{}, ...]

  """
  def list_posts(%Scope{} = scope) do
    Repo.scoped_all(Post, user_id: scope.user.id)
  end

  @doc """
  Returns all public posts (non-authenticated access).

  Only returns posts with a published_at date, ordered by published_at descending.
  No scope required - this is for public viewing.

  ## Examples

      iex> list_public_posts()
      [%Post{}, ...]

  """
  def list_public_posts do
    from(p in Post,
      where: not is_nil(p.published_at),
      order_by: [desc: p.published_at],
      preload: [:user, :tags]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of published posts for a specific user (public access).

  Only returns posts with a published_at date, ordered by published_at descending.

  ## Examples

      iex> list_published_posts_for_user(123)
      [%Post{}, ...]

  """
  def list_published_posts_for_user(user_id) do
    from(p in Post,
      where: p.user_id == ^user_id and not is_nil(p.published_at),
      order_by: [desc: p.published_at]
    )
    |> Repo.all()
  end

  @doc """
  Returns the user's posts that have the specified tag.

  ## Examples

      iex> list_user_posts_by_tag(scope, tag_id)
      [%Post{}, ...]

  """
  def list_user_posts_by_tag(%Scope{} = scope, tag_id) do
    from(p in Post,
      join: pt in "post_tags",
      on: pt.post_id == p.id,
      where: p.user_id == ^scope.user.id and pt.tag_id == ^tag_id,
      order_by: [desc: p.published_at],
      preload: [:user]
    )
    |> Repo.all()
  end

  @doc """
  Returns public posts from other users that have the specified tag.

  Excludes posts from the specified user_id.

  ## Examples

      iex> list_public_posts_by_tag(tag_id, exclude_user_id)
      [%Post{}, ...]

  """
  def list_public_posts_by_tag(tag_id, exclude_user_id \\ nil) do
    query =
      from(p in Post,
        join: pt in "post_tags",
        on: pt.post_id == p.id,
        where: pt.tag_id == ^tag_id and not is_nil(p.published_at),
        order_by: [desc: p.published_at],
        preload: [:user]
      )

    query =
      if exclude_user_id do
        from(p in query, where: p.user_id != ^exclude_user_id)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Returns all published posts from all users (public homepage).

  ## Examples

      iex> list_all_published_posts()
      [%Post{}, ...]

  """
  def list_all_published_posts do
    from(p in Post,
      where: not is_nil(p.published_at),
      order_by: [desc: p.published_at],
      preload: [:user],
      limit: 20
    )
    |> Repo.all()
  end

  @doc """
  Gets a single post.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!(scope, 123)
      %Post{}

      iex> get_post!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_post!(%Scope{} = scope, id) do
    Post
    |> Repo.get_by!(id: id, user_id: scope.user.id)
    |> Repo.preload(:user)
  end

  @doc """
  Gets a single post by ID for public viewing.

  Only returns posts that are public (is_public = true) or belong to the given scope.
  Raises `Ecto.NoResultsError` if the Post does not exist or is not accessible.

  ## Examples

      iex> get_post_by_id!(scope, 123)
      %Post{}

      iex> get_post_by_id!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_post_by_id!(%Scope{} = scope, id) do
    user_id = scope.user.id

    Post
    |> where([p], p.id == ^id)
    |> where([p], p.is_public == true or p.user_id == ^user_id)
    |> Repo.one!()
    |> Repo.preload(:user)
  end

  @doc """
  Gets a single public post by ID without requiring authentication.

  Returns only posts with is_public = true.
  Raises `Ecto.NoResultsError` if the Post does not exist or is not public.

  ## Examples

      iex> get_public_post!(123)
      %Post{}

      iex> get_public_post!(456)
      ** (Ecto.NoResultsError)

  """
  def get_public_post!(id) do
    Post
    |> where([p], p.id == ^id and p.is_public == true)
    |> Repo.one!()
    |> Repo.preload(:user)
  end

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(scope, %{field: value})
      {:ok, %Post{}}

      iex> create_post(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(%Scope{} = scope, attrs) do
    with {:ok, post = %Post{}} <-
           %Post{}
           |> Post.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_post(scope, {:created, post})
      {:ok, post}
    end
  end

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(scope, post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(scope, post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post(%Scope{} = scope, %Post{} = post, attrs) do
    true = post.user_id == scope.user.id

    with {:ok, post = %Post{}} <-
           post
           |> Post.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_post(scope, {:updated, post})
      {:ok, post}
    end
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(scope, post)
      {:ok, %Post{}}

      iex> delete_post(scope, post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post(%Scope{} = scope, %Post{} = post) do
    true = post.user_id == scope.user.id

    with {:ok, post = %Post{}} <-
           Repo.delete(post) do
      broadcast_post(scope, {:deleted, post})
      {:ok, post}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(scope, post)
      %Ecto.Changeset{data: %Post{}}

  """
  def change_post(%Scope{} = scope, %Post{} = post, attrs \\ %{}) do
    true = post.user_id == scope.user.id

    Post.changeset(post, attrs, scope)
  end

  # RSS Feed Functions

  @doc """
  Returns recent public posts for RSS feed.

  Only returns posts that are published (published_at is not nil).
  Orders by published_at descending (newest first).
  Preloads user and tags associations for feed display.

  ## Examples

      iex> list_public_posts_for_feed(20)
      [%Post{}, ...]

  """
  def list_public_posts_for_feed(limit \\ 20) do
    from(p in Post,
      where: not is_nil(p.published_at),
      order_by: [desc: p.published_at],
      limit: ^limit,
      preload: [:user, :tags]
    )
    |> Repo.all()
  end

  @doc """
  Returns recent public posts by a specific user for RSS feed.

  Only returns posts that are published (published_at is not nil).
  Orders by published_at descending (newest first).
  Preloads user and tags associations for feed display.

  ## Examples

      iex> list_user_posts_for_feed(user_id, 20)
      [%Post{}, ...]

  """
  def list_user_posts_for_feed(user_id, limit \\ 20) do
    from(p in Post,
      where: p.user_id == ^user_id and not is_nil(p.published_at),
      order_by: [desc: p.published_at],
      limit: ^limit,
      preload: [:user, :tags]
    )
    |> Repo.all()
  end

  @doc """
  Returns recent public posts with a specific tag for RSS feed.

  Only returns posts that are published (published_at is not nil).
  Orders by published_at descending (newest first).
  Preloads user and tags associations for feed display.
  Uses tag slug for lookup.

  ## Examples

      iex> list_tag_posts_for_feed("elixir", 20)
      [%Post{}, ...]

  """
  def list_tag_posts_for_feed(tag_slug, limit \\ 20) do
    from(p in Post,
      join: t in assoc(p, :tags),
      where: t.slug == ^tag_slug and not is_nil(p.published_at),
      order_by: [desc: p.published_at],
      limit: ^limit,
      preload: [:user, :tags]
    )
    |> Repo.all()
  end
end
