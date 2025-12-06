defmodule Homesite.Media.Gallery do
  @moduledoc """
  Gallery schema for organizing media items into portfolios and collections.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "galleries" do
    field :name, :string
    field :description, :string
    field :slug, :string
    field :is_public, :boolean, default: false
    field :is_portfolio, :boolean, default: false
    field :display_order, :integer, default: 0

    belongs_to :user, Homesite.Accounts.User
    belongs_to :cover_media_item, Homesite.Media.MediaItem

    many_to_many :media_items, Homesite.Media.MediaItem,
      join_through: "gallery_media_items",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(gallery, attrs, user_scope) do
    gallery
    |> cast(attrs, [:name, :description, :is_public, :is_portfolio, :display_order, :cover_media_item_id])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 200)
    |> validate_length(:description, max: 1000)
    |> generate_slug()
    |> validate_required([:slug])
    |> unique_constraint(:slug, name: :galleries_user_id_slug_index)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:cover_media_item_id)
    |> put_change(:user_id, user_scope.user.id)
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :name) do
      nil ->
        changeset

      name ->
        base_slug =
          name
          |> String.downcase()
          |> transliterate()
          # Keep only alphanumeric and hyphens
          |> String.replace(~r/[^a-z0-9-]+/, "-")
          |> String.trim("-")

        slug = "#{base_slug}-#{:os.system_time(:millisecond)}"
        put_change(changeset, :slug, slug)
    end
  end

  defp transliterate(string) do
    string
    |> String.normalize(:nfd)
    |> String.replace(~r/[^A-z\s-]/u, "")
  end
end
