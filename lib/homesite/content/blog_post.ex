defmodule Homesite.Content.BlogPost do
  use Ecto.Schema
  import Ecto.Changeset

  schema "blog_posts" do
    field :title_fi, :string
    field :title_en, :string
    field :content_fi, :string
    field :content_en, :string
    field :slug, :string
    field :author_type, :string
    field :author_id, :integer
    field :curator_added, :boolean, default: false
    field :status, :string, default: "draft"
    field :published_at, :utc_datetime
    field :metadata, :map

    belongs_to :created_by, Homesite.Accounts.User

    # Polymorphic tagging
    has_many :taggings, {"blog_post", Homesite.Tags.Tagging},
      foreign_key: :taggable_id,
      where: [taggable_type: "blog_post"]

    has_many :tags, through: [:taggings, :tag]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(blog_post, attrs) do
    blog_post
    |> cast(attrs, [
      :title_fi,
      :title_en,
      :content_fi,
      :content_en,
      :slug,
      :author_type,
      :author_id,
      :created_by_id,
      :curator_added,
      :status,
      :published_at,
      :metadata
    ])
    |> validate_required([:title_fi, :content_fi, :author_type, :author_id, :created_by_id])
    |> validate_length(:title_fi, min: 3, max: 200)
    |> validate_length(:title_en, max: 200)
    |> validate_length(:content_fi, min: 10)
    |> validate_inclusion(:author_type, ["user", "team"])
    |> validate_inclusion(:status, ["draft", "published"])
    |> generate_slug()
    |> unique_constraint(:slug)
  end

  @doc """
  Changeset for publishing a blog post
  """
  def publish_changeset(blog_post) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    blog_post
    |> change(status: "published", published_at: now)
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :slug) do
      nil ->
        # Auto-generate from Finnish title if no slug provided
        case get_change(changeset, :title_fi) do
          nil -> changeset
          title -> put_change(changeset, :slug, slugify(title))
        end

      _slug ->
        changeset
    end
  end

  defp slugify(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[åä]/u, "a")
    |> String.replace(~r/ö/u, "o")
    |> String.replace(~r/[^a-z0-9\s-]/u, "")
    |> String.replace(~r/\s+/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
  end
end
