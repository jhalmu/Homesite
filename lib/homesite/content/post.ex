defmodule Homesite.Content.Post do
  @moduledoc """
  Blog post schema with user scoping and tag associations.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "posts" do
    field :title, :string
    field :body, :string
    field :slug, :string
    field :published_at, :utc_datetime
    field :is_public, :boolean, default: true
    field :read_time_minutes, :integer, default: 1
    field :featured_image_url, :string
    field :featured_image_alt, :string

    belongs_to :user, Homesite.Accounts.User

    many_to_many :tags, Homesite.Content.Tag,
      join_through: Homesite.Content.PostTag,
      on_replace: :delete

    many_to_many :media_items, Homesite.Media.MediaItem,
      join_through: "post_media_items",
      on_replace: :delete

    many_to_many :projects, Homesite.Media.Project,
      join_through: "project_posts",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs, user_scope) do
    # For existing posts (updates), don't allow slug changes
    cast_fields =
      if is_nil(post.id) do
        [
          :title,
          :body,
          :slug,
          :published_at,
          :is_public,
          :featured_image_url,
          :featured_image_alt
        ]
      else
        [:title, :body, :published_at, :is_public, :featured_image_url, :featured_image_alt]
      end

    post
    |> cast(attrs, cast_fields)
    |> validate_required([:title, :body, :published_at])
    |> validate_length(:title, min: 3, max: 200)
    |> validate_length(:body, min: 10)
    |> generate_slug()
    |> calculate_read_time()
    |> validate_required([:slug])
    |> unique_constraint(:slug)
    |> foreign_key_constraint(:user_id)
    |> put_change(:user_id, user_scope.user.id)
    |> put_tags(attrs, user_scope)
  end

  # Handle string keys (from form params)
  defp put_tags(changeset, %{"tag_ids" => tag_ids}, user_scope) when is_list(tag_ids) do
    do_put_tags(changeset, tag_ids, user_scope)
  end

  # Handle atom keys (from tests/programmatic use)
  defp put_tags(changeset, %{tag_ids: tag_ids}, user_scope) when is_list(tag_ids) do
    do_put_tags(changeset, tag_ids, user_scope)
  end

  defp put_tags(changeset, _attrs, _user_scope), do: changeset

  defp do_put_tags(changeset, tag_ids, user_scope) do
    # Filter out empty strings and get valid tag IDs
    tag_ids = Enum.reject(tag_ids, &(&1 == "" || is_nil(&1)))

    if tag_ids == [] do
      put_assoc(changeset, :tags, [])
    else
      # Fetch tags that belong to the user
      tags =
        Homesite.Repo.all(
          from t in Homesite.Content.Tag,
            where: t.id in ^tag_ids and t.user_id == ^user_scope.user.id
        )

      put_assoc(changeset, :tags, tags)
    end
  end

  defp generate_slug(changeset) do
    # Only generate slug for new posts (id is nil)
    # Existing posts keep their slug even when title changes
    if is_nil(changeset.data.id) do
      case get_change(changeset, :title) do
        nil ->
          changeset

        title ->
          base_slug = slugify(title)
          unique_slug = ensure_unique_slug(base_slug)
          put_change(changeset, :slug, unique_slug)
      end
    else
      changeset
    end
  end

  defp slugify(title) do
    slug =
      title
      |> String.downcase()
      |> transliterate()
      # Keep only alphanumeric and hyphens
      |> String.replace(~r/[^a-z0-9-]+/, "-")
      |> String.trim("-")

    # Fallback for titles with only non-Latin characters (Japanese, Chinese, etc.)
    if slug == "" do
      "post-#{:os.system_time(:millisecond)}"
    else
      slug
    end
  end

  defp ensure_unique_slug(base_slug) do
    if slug_exists?(base_slug) do
      find_available_slug(base_slug, 2)
    else
      base_slug
    end
  end

  defp find_available_slug(base_slug, counter) do
    candidate = "#{base_slug}-#{counter}"

    if slug_exists?(candidate) do
      find_available_slug(base_slug, counter + 1)
    else
      candidate
    end
  end

  defp slug_exists?(slug) do
    Homesite.Repo.exists?(from p in __MODULE__, where: p.slug == ^slug)
  end

  # Transliterate special characters to ASCII for URL-friendly slugs
  # Uses a hybrid approach:
  # 1. First handle special base characters that don't decompose (Nordic, German, etc.)
  # 2. Then normalize Unicode to strip accents from decomposable characters
  # 3. Finally remove any remaining non-ASCII characters
  defp transliterate(string) do
    string
    # Handle base characters that don't decompose with NFD
    # Nordic/Scandinavian
    |> String.replace("ä", "a")
    |> String.replace("ö", "o")
    |> String.replace("å", "a")
    |> String.replace("æ", "ae")
    |> String.replace("ø", "o")
    # German
    |> String.replace("ü", "u")
    |> String.replace("ß", "ss")
    # Polish
    |> String.replace("ł", "l")
    # Icelandic (multi-character)
    |> String.replace("þ", "th")
    |> String.replace("ð", "d")
    # Turkish
    |> String.replace("ı", "i")
    # Normalize to NFD (decompose accented characters like é → e + accent)
    |> String.normalize(:nfd)
    # Strip combining diacritical marks (accents, tildes, etc.)
    |> String.replace(~r/\p{Mn}+/u, "")
    # Remove any remaining non-ASCII characters
    |> String.replace(~r/[^\x00-\x7F]+/, "")
  end

  # Calculate reading time based on body content
  # Uses standard 200 words per minute reading speed
  # Minimum 1 minute to avoid showing "0 min read"
  defp calculate_read_time(changeset) do
    case get_change(changeset, :body) do
      nil ->
        changeset

      body ->
        text = strip_markdown(body)
        word_count = text |> String.split(~r/\s+/) |> Enum.reject(&(&1 == "")) |> length()
        read_time = max(1, ceil(word_count / 200))
        put_change(changeset, :read_time_minutes, read_time)
    end
  end

  # Strip markdown formatting to count actual words
  # Removes: headers, links, images, code blocks, emphasis, lists
  defp strip_markdown(markdown) do
    markdown
    # Remove code blocks
    |> String.replace(~r/```[\s\S]*?```/m, "")
    |> String.replace(~r/`[^`]+`/, "")
    # Remove images
    |> String.replace(~r/!\[([^\]]*)\]\([^\)]+\)/, "\\1")
    # Remove links (keep text)
    |> String.replace(~r/\[([^\]]+)\]\([^\)]+\)/, "\\1")
    # Remove headers
    |> String.replace(~r/^[#]{1,6}\s+/m, "")
    # Remove emphasis
    |> String.replace(~r/\*\*([^\*]+)\*\*/, "\\1")
    |> String.replace(~r/__([^_]+)__/, "\\1")
    |> String.replace(~r/\*([^\*]+)\*/, "\\1")
    |> String.replace(~r/_([^_]+)_/, "\\1")
    # Remove list markers
    |> String.replace(~r/^[\*\-\+]\s+/m, "")
    |> String.replace(~r/^\d+\.\s+/m, "")
    # Remove blockquotes
    |> String.replace(~r/^>\s+/m, "")
    # Remove horizontal rules
    |> String.replace(~r/^[\*\-_]{3,}$/m, "")
  end
end
