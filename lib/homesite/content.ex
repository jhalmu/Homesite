defmodule Homesite.Content do
  @moduledoc """
  The Content context.
  """

  import Ecto.Query, warn: false

  alias Homesite.Accounts.Scope
  alias Homesite.Activities
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
  Returns all tags across all users (for sitemap).
  """
  def list_all_tags do
    from(t in Tag, order_by: [desc: t.updated_at], preload: [:user])
    |> Repo.all()
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
  Search public tags with fuzzy matching using PostgreSQL pg_trgm extension.
  Returns tags sorted by similarity score.

  ## Examples

      iex> search_public_tags("elixr")  # typo
      [%Tag{name: "Elixir"}, ...]

      iex> search_public_tags("phoenix", 5)
      [%Tag{name: "Phoenix"}, ...]

  """
  def search_public_tags(query, limit \\ 10) when is_binary(query) do
    from(t in Tag,
      where: t.is_public == true,
      where: fragment("similarity(?, ?) > 0.3", t.name, ^query),
      order_by: [desc: fragment("similarity(?, ?)", t.name, ^query)],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Find similar tags to suggest avoiding duplicates.
  Uses PostgreSQL trigram similarity for typo tolerance.

  ## Examples

      iex> find_similar_tags("Elixir")
      [%Tag{name: "Elixir-Lang"}, %Tag{name: "Elixir Programming"}, ...]

      iex> find_similar_tags("NewTag", tag_id, 3)
      []

  """
  def find_similar_tags(name, exclude_tag_id \\ nil, limit \\ 5)
      when is_binary(name) do
    query =
      from(t in Tag,
        where: t.is_public == true,
        where: fragment("? % ?", t.name, ^name),
        order_by: [desc: fragment("similarity(?, ?)", t.name, ^name)],
        limit: ^limit
      )

    query =
      if exclude_tag_id,
        do: where(query, [t], t.id != ^exclude_tag_id),
        else: query

    Repo.all(query)
  end

  @doc """
  Get or create a tag atomically.
  Handles concurrent creation of same tag name with retry logic.

  ## Examples

      iex> get_or_create_tag(scope, %{"name" => "Elixir"})
      {:ok, %Tag{name: "Elixir"}}

  """
  def get_or_create_tag(%Scope{} = scope, %{"name" => name} = attrs)
      when is_binary(name) do
    # First try to find existing public tag
    case Repo.get_by(Tag, name: name, is_public: true) do
      %Tag{} = tag -> {:ok, tag}
      nil -> create_tag_with_retry(scope, attrs)
    end
  end

  defp create_tag_with_retry(scope, attrs, retries \\ 3) do
    case create_tag(scope, attrs) do
      {:ok, tag} ->
        {:ok, tag}

      {:error, %Ecto.Changeset{errors: errors} = changeset} ->
        # Check if error is due to unique constraint (race condition)
        case Keyword.get(errors, :name) do
          {msg, _} when msg in ["This public tag name already exists"] and retries > 0 ->
            # Another user created it concurrently, fetch and return
            case Repo.get_by(Tag, name: attrs["name"], is_public: true) do
              %Tag{} = tag -> {:ok, tag}
              nil -> create_tag_with_retry(scope, attrs, retries - 1)
            end

          _ ->
            {:error, changeset}
        end
    end
  end

  @doc """
  List all public tags with optional search filter and post counts.

  ## Examples

      iex> list_all_public_tags()
      [{%Tag{name: "Elixir"}, 10}, {%Tag{name: "Phoenix"}, 5}, ...]

      iex> list_all_public_tags("phoenix")
      [{%Tag{name: "Phoenix"}, 5}, ...]

  """
  def list_all_public_tags(search \\ nil) do
    query =
      from(t in Tag,
        where: t.is_public == true,
        left_join: pt in "post_tags",
        on: pt.tag_id == t.id,
        group_by: t.id,
        select: {t, count(pt.id)},
        order_by: [desc: count(pt.id), asc: t.name]
      )

    query =
      if search && String.length(search) >= 2 do
        from([t, pt] in query,
          where:
            ilike(t.name, ^"%#{search}%") or
              fragment("? % ?", t.name, ^search)
        )
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Get tag by slug (public access, no scope required).

  Raises `Ecto.NoResultsError` if the Tag does not exist.

  ## Examples

      iex> get_tag_by_slug!("elixir")
      %Tag{slug: "elixir", name: "Elixir"}

      iex> get_tag_by_slug!("nonexistent")
      ** (Ecto.NoResultsError)

  """
  def get_tag_by_slug!(slug) when is_binary(slug) do
    Repo.get_by!(Tag, slug: slug)
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
    from(p in Post,
      where: p.user_id == ^scope.user.id,
      preload: [:user, :tags],
      order_by: [desc: p.inserted_at]
    )
    |> Repo.all()
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
      preload: [:user, :tags],
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
    |> Repo.preload([:user, :tags])
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
    |> Repo.preload([:user, :tags])
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
    |> Repo.preload([:user, :tags])
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

      # Invalidate feed caches if post is published
      if post.published_at do
        invalidate_feed_caches(post)
      end

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
    was_published = not is_nil(post.published_at)

    with {:ok, updated_post = %Post{}} <-
           post
           |> Post.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_post(scope, {:updated, updated_post})

      # Track activity if post is being published for the first time
      if not was_published and updated_post.published_at do
        Activities.create_activity(
          scope.user,
          "blog_published",
          updated_post,
          "Published blog post: #{updated_post.title}"
        )
      end

      # Invalidate feed caches if post was or is published
      if was_published or updated_post.published_at do
        invalidate_feed_caches(updated_post)
      end

      {:ok, updated_post}
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

    # Load tags before deletion for cache invalidation
    post_with_tags = Repo.preload(post, :tags)

    with {:ok, deleted_post = %Post{}} <-
           Repo.delete(post) do
      broadcast_post(scope, {:deleted, deleted_post})

      # Invalidate feed caches if post was published
      if deleted_post.published_at do
        # Use the preloaded tags from before deletion
        invalidate_feed_caches(%{deleted_post | tags: post_with_tags.tags})
      end

      {:ok, deleted_post}
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
  def list_public_posts_for_feed(limit \\ 20, offset \\ 0) do
    from(p in Post,
      where: not is_nil(p.published_at),
      order_by: [desc: p.published_at],
      limit: ^limit,
      offset: ^offset,
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
  def list_user_posts_for_feed(user_id, limit \\ 20, offset \\ 0) do
    from(p in Post,
      where: p.user_id == ^user_id and not is_nil(p.published_at),
      order_by: [desc: p.published_at],
      limit: ^limit,
      offset: ^offset,
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
  def list_tag_posts_for_feed(tag_slug, limit \\ 20, offset \\ 0) do
    from(p in Post,
      join: t in assoc(p, :tags),
      where: t.slug == ^tag_slug and not is_nil(p.published_at),
      order_by: [desc: p.published_at],
      limit: ^limit,
      offset: ^offset,
      preload: [:user, :tags]
    )
    |> Repo.all()
  end

  # Search functions

  @doc """
  Search public posts by title and body content using PostgreSQL full-text search.

  Uses trigram similarity for fuzzy matching. Returns posts that match the query
  with a similarity threshold of 0.3 or higher.

  ## Options

    * `:limit` - Maximum number of results (default: 20)
    * `:tag_id` - Filter by tag ID (optional)
    * `:user_id` - Filter by user ID (optional)

  ## Examples

      iex> search_posts("elixir")
      [%Post{}, ...]

      iex> search_posts("phoenix", limit: 10, tag_id: 5)
      [%Post{}, ...]

  """
  def search_posts(query, opts \\ []) when is_binary(query) do
    # Return empty list for empty or whitespace-only queries
    case String.trim(query) do
      "" ->
        []

      trimmed_query ->
        limit = Keyword.get(opts, :limit, 20)
        # Ensure limit is non-negative
        limit = max(limit, 0)
        tag_id = Keyword.get(opts, :tag_id)
        user_id = Keyword.get(opts, :user_id)

        base_query =
          from(p in Post,
            where: not is_nil(p.published_at) and p.is_public == true,
            where:
              fragment("similarity(?, ?) > 0.1", p.title, ^trimmed_query) or
                fragment("similarity(?, ?) > 0.1", p.body, ^trimmed_query) or
                fragment("? ILIKE ?", p.title, ^"%#{trimmed_query}%") or
                fragment("? ILIKE ?", p.body, ^"%#{trimmed_query}%"),
            order_by: [
              desc:
                fragment(
                  "greatest(similarity(?, ?), similarity(?, ?))",
                  p.title,
                  ^trimmed_query,
                  p.body,
                  ^trimmed_query
                )
            ],
            limit: ^limit,
            preload: [:user, :tags]
          )

        base_query
        |> maybe_filter_by_tag(tag_id)
        |> maybe_filter_by_user(user_id)
        |> Repo.all()
    end
  end

  @doc """
  Search posts within a user's own posts (authenticated search).

  Searches both published and unpublished posts for the scoped user.

  ## Examples

      iex> search_user_posts(scope, "elixir")
      [%Post{}, ...]

  """
  def search_user_posts(%Scope{} = scope, query, opts \\ []) when is_binary(query) do
    # Return empty list for empty or whitespace-only queries
    case String.trim(query) do
      "" ->
        []

      trimmed_query ->
        limit = Keyword.get(opts, :limit, 20)
        # Ensure limit is non-negative
        limit = max(limit, 0)

        from(p in Post,
          where: p.user_id == ^scope.user.id,
          where:
            fragment("similarity(?, ?) > 0.1", p.title, ^trimmed_query) or
              fragment("similarity(?, ?) > 0.1", p.body, ^trimmed_query) or
              fragment("? ILIKE ?", p.title, ^"%#{trimmed_query}%") or
              fragment("? ILIKE ?", p.body, ^"%#{trimmed_query}%"),
          order_by: [
            desc:
              fragment(
                "greatest(similarity(?, ?), similarity(?, ?))",
                p.title,
                ^trimmed_query,
                p.body,
                ^trimmed_query
              )
          ],
          limit: ^limit,
          preload: [:user, :tags]
        )
        |> Repo.all()
    end
  end

  @doc """
  Search tags by name and slug using PostgreSQL full-text search.

  Returns all tags (not user-scoped) that match the query with trigram
  similarity or ILIKE matching.

  ## Options

    * `:limit` - Maximum number of results (default: 20)

  ## Examples

      iex> search_tags("elixir")
      [%Tag{name: "Elixir", slug: "elixir"}, ...]

      iex> search_tags("phoenix", limit: 10)
      [%Tag{}, ...]

  """
  def search_tags(query, opts \\ []) when is_binary(query) do
    case String.trim(query) do
      "" ->
        []

      trimmed_query ->
        limit = Keyword.get(opts, :limit, 20)
        limit = max(limit, 0)

        from(t in Tag,
          where:
            fragment("similarity(?, ?) > 0.1", t.name, ^trimmed_query) or
              fragment("similarity(?, ?) > 0.1", t.slug, ^trimmed_query) or
              fragment("? ILIKE ?", t.name, ^"%#{trimmed_query}%") or
              fragment("? ILIKE ?", t.slug, ^"%#{trimmed_query}%"),
          order_by: [
            desc:
              fragment(
                "greatest(similarity(?, ?), similarity(?, ?))",
                t.name,
                ^trimmed_query,
                t.slug,
                ^trimmed_query
              )
          ],
          limit: ^limit,
          preload: [:user]
        )
        |> Repo.all()
    end
  end

  defp maybe_filter_by_tag(query, nil), do: query

  defp maybe_filter_by_tag(query, tag_id) do
    from(p in query,
      join: pt in "post_tags",
      on: pt.post_id == p.id,
      where: pt.tag_id == ^tag_id
    )
  end

  defp maybe_filter_by_user(query, nil), do: query

  defp maybe_filter_by_user(query, user_id) do
    from(p in query, where: p.user_id == ^user_id)
  end

  ## Analytics

  @doc """
  Returns comprehensive content statistics for the analytics dashboard.

  Returns a map with:
  - `total_posts`: Total published posts
  - `total_drafts`: Total unpublished posts
  - `posts_7d`: Posts published in last 7 days
  - `posts_30d`: Posts published in last 30 days
  - `total_tags`: Total tags created
  - `avg_post_length`: Average post body length in characters
  - `post_growth`: List of daily post counts for last 30 days
  - `top_authors`: List of most active authors with post counts
  - `popular_tags`: List of most used tags with usage counts

  ## Examples

      iex> get_content_stats()
      %{
        total_posts: 250,
        total_drafts: 15,
        posts_7d: 8,
        posts_30d: 35,
        ...
      }

  """
  def get_content_stats do
    now = DateTime.utc_now(:second)
    seven_days_ago = DateTime.add(now, -7, :day)
    thirty_days_ago = DateTime.add(now, -30, :day)

    total_posts =
      from(p in Post, where: not is_nil(p.published_at))
      |> Repo.aggregate(:count, :id)

    total_drafts =
      from(p in Post, where: is_nil(p.published_at))
      |> Repo.aggregate(:count, :id)

    posts_7d =
      from(p in Post,
        where: not is_nil(p.published_at) and p.published_at >= ^seven_days_ago
      )
      |> Repo.aggregate(:count, :id)

    posts_30d =
      from(p in Post,
        where: not is_nil(p.published_at) and p.published_at >= ^thirty_days_ago
      )
      |> Repo.aggregate(:count, :id)

    total_tags = Repo.aggregate(Tag, :count, :id)

    # Average post length
    avg_post_length =
      from(p in Post,
        where: not is_nil(p.published_at),
        select: avg(fragment("LENGTH(?)", p.body))
      )
      |> Repo.one()
      |> case do
        nil -> 0
        avg -> round(avg)
      end

    # Post growth - daily post counts for last 30 days
    post_growth =
      from(p in Post,
        where: not is_nil(p.published_at) and p.published_at >= ^thirty_days_ago,
        group_by: fragment("DATE(?)", p.published_at),
        select: %{
          date: fragment("DATE(?)", p.published_at),
          count: count(p.id)
        },
        order_by: fragment("DATE(?) ASC", p.published_at)
      )
      |> Repo.all()

    # Top authors by post count
    top_authors =
      from(p in Post,
        join: u in assoc(p, :user),
        where: not is_nil(p.published_at),
        group_by: [p.user_id, u.email],
        select: %{
          user_id: p.user_id,
          email: u.email,
          post_count: count(p.id)
        },
        order_by: [desc: count(p.id)],
        limit: 10
      )
      |> Repo.all()

    # Popular tags by usage count
    popular_tags =
      from(t in Tag,
        left_join: pt in "post_tags",
        on: pt.tag_id == t.id,
        group_by: [t.id, t.name],
        select: %{
          tag_id: t.id,
          name: t.name,
          usage_count: count(pt.post_id)
        },
        order_by: [desc: count(pt.post_id)],
        limit: 15
      )
      |> Repo.all()

    %{
      total_posts: total_posts,
      total_drafts: total_drafts,
      posts_7d: posts_7d,
      posts_30d: posts_30d,
      total_tags: total_tags,
      avg_post_length: avg_post_length,
      post_growth: post_growth,
      top_authors: top_authors,
      popular_tags: popular_tags
    }
  end

  # Private Functions

  defp invalidate_feed_caches(%Post{} = post) do
    # Clear site-wide feeds (always affected by any post change)
    Homesite.FeedCache.clear_site_wide_feeds()

    # Clear user-specific feeds
    Homesite.FeedCache.clear_user_feeds(post.user_id)

    # Clear tag-specific feeds if tags are loaded
    case post do
      %{tags: tags} when is_list(tags) ->
        Enum.each(tags, fn tag ->
          Homesite.FeedCache.clear_tag_feeds(tag.slug)
        end)

      _ ->
        :ok
    end
  end
end
