defmodule Homesite.Content.Post do
  @moduledoc """
  Blog post schema with user scoping and tag associations.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :title, :string
    field :body, :string
    field :slug, :string
    field :published_at, :utc_datetime
    field :is_public, :boolean, default: false
    # field :user_id, :id

    belongs_to :user, Homesite.Accounts.User

    many_to_many :tags, Homesite.Content.Tag,
      join_through: Homesite.Content.PostTag,
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs, user_scope) do
    post
    |> cast(attrs, [:title, :body, :slug, :published_at, :is_public])
    |> validate_required([:title, :body, :published_at])
    |> validate_length(:title, min: 3, max: 200)
    |> validate_length(:body, min: 10)
    |> generate_slug()
    |> validate_required([:slug])
    |> unique_constraint(:slug)
    |> foreign_key_constraint(:user_id)
    |> put_change(:user_id, user_scope.user.id)
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :title) do
      nil ->
        changeset

      title ->
        base_slug =
          title
          |> String.downcase()
          |> transliterate()
          # Keep only alphanumeric and hyphens
          |> String.replace(~r/[^a-z0-9-]+/, "-")
          |> String.trim("-")

        slug = "#{base_slug}-#{:os.system_time(:millisecond)}"
        put_change(changeset, :slug, slug)
    end
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
end
