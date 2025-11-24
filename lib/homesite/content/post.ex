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
  defp transliterate(string) do
    string
    # Nordic/Scandinavian
    |> String.replace("ä", "a")
    |> String.replace("ö", "o")
    |> String.replace("å", "a")
    |> String.replace("æ", "ae")
    |> String.replace("ø", "o")
    # German
    |> String.replace("ü", "u")
    |> String.replace("ß", "ss")
    # French
    |> String.replace(~r/[éèêë]/, "e")
    |> String.replace(~r/[àâ]/, "a")
    |> String.replace(~r/[ùû]/, "u")
    |> String.replace(~r/[îï]/, "i")
    |> String.replace("ô", "o")
    |> String.replace("ç", "c")
    # Spanish
    |> String.replace("ñ", "n")
    |> String.replace(~r/[áà]/, "a")
    |> String.replace("í", "i")
    |> String.replace("ó", "o")
    |> String.replace("ú", "u")
    # Portuguese
    |> String.replace(~r/[ãâ]/, "a")
    |> String.replace(~r/[õ]/, "o")
    # Polish
    |> String.replace("ł", "l")
    |> String.replace("ą", "a")
    |> String.replace("ę", "e")
    |> String.replace("ć", "c")
    |> String.replace("ń", "n")
    |> String.replace("ś", "s")
    |> String.replace(~r/[źż]/, "z")
    # Czech/Slovak
    |> String.replace("č", "c")
    |> String.replace("š", "s")
    |> String.replace("ž", "z")
    |> String.replace("ř", "r")
    |> String.replace(~r/[ůú]/, "u")
    # Turkish
    |> String.replace("ı", "i")
    |> String.replace("ş", "s")
    |> String.replace("ğ", "g")
    # Icelandic
    |> String.replace("þ", "th")
    |> String.replace("ð", "d")
  end
end
