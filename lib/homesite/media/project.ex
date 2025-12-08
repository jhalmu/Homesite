defmodule Homesite.Media.Project do
  @moduledoc """
  Project schema for organizing media items into portfolio projects.

  Projects are collections of media items with rich metadata including:
  - Basic info: name, description, cover image
  - Project metadata: category, tags, project date
  - Team: collaborators with contact info
  - Related links: affiliation links (clients, press, etc.)
  - Visibility control: user decides which metadata fields show publicly
  - Completion tracking: percentage based on filled fields
  """
  use Ecto.Schema
  import Ecto.Changeset

  @valid_template_types ~w(photography coding writing books gears movies custom)

  schema "projects" do
    field :name, :string
    field :description, :string
    field :slug, :string
    field :is_public, :boolean, default: false
    field :is_portfolio, :boolean, default: false
    field :is_archived, :boolean, default: false
    field :archived_at, :utc_datetime
    field :display_order, :integer, default: 0
    field :template_type, :string, default: "photography"

    # Project-specific metadata
    field :project_date, :date
    field :category, :string
    field :tags, {:array, :string}, default: []

    field :field_visibility, :map,
      default: %{
        "description" => true,
        "category" => true,
        "tags" => true,
        "project_date" => true,
        "collaborators" => true,
        "affiliation_links" => true
      }

    field :completion_percentage, :integer, default: 0

    belongs_to :user, Homesite.Accounts.User
    belongs_to :cover_media_item, Homesite.Media.MediaItem

    has_many :collaborators, Homesite.Media.Collaborator, on_delete: :delete_all
    has_many :affiliation_links, Homesite.Media.AffiliationLink, on_delete: :delete_all
    has_many :collections, Homesite.Media.Collection, on_delete: :delete_all

    many_to_many :media_items, Homesite.Media.MediaItem,
      join_through: "project_media_items",
      on_replace: :delete

    many_to_many :posts, Homesite.Content.Post,
      join_through: "project_posts",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc """
  Basic changeset for Step 1 of project creation (name and description only).
  Used in stepped form for minimal project creation.
  """
  def basic_changeset(project, attrs, user_scope) do
    project
    |> cast(attrs, [:name, :slug, :description, :template_type])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 200)
    |> validate_length(:description, max: 1000)
    |> validate_inclusion(:template_type, @valid_template_types)
    |> maybe_generate_slug()
    |> validate_required([:slug])
    |> unique_constraint(:slug, name: :projects_user_id_slug_index)
    |> put_change(:user_id, user_scope.user.id)
    |> calculate_completion()
  end

  @doc """
  Full changeset for complete project updates.
  Includes all metadata fields: category, tags, dates, visibility settings.
  """
  def changeset(project, attrs, user_scope) do
    project
    |> cast(attrs, [
      :name,
      :slug,
      :description,
      :template_type,
      :is_public,
      :is_portfolio,
      :display_order,
      :cover_media_item_id,
      :project_date,
      :category,
      :tags,
      :field_visibility
    ])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 200)
    |> validate_length(:description, max: 1000)
    |> validate_length(:category, max: 100)
    |> validate_inclusion(:template_type, @valid_template_types)
    |> validate_tags()
    |> maybe_generate_slug()
    |> validate_required([:slug])
    |> unique_constraint(:slug, name: :projects_user_id_slug_index)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:cover_media_item_id)
    |> put_change(:user_id, user_scope.user.id)
    |> calculate_completion()
  end

  # Only generate a slug if one wasn't provided and there's a name change
  defp maybe_generate_slug(changeset) do
    # If a slug was already provided, don't overwrite it
    if get_change(changeset, :slug) do
      changeset
    else
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
  end

  defp transliterate(string) do
    string
    |> String.normalize(:nfd)
    |> String.replace(~r/[^A-z\s-]/u, "")
  end

  defp validate_tags(changeset) do
    case get_change(changeset, :tags) do
      nil ->
        changeset

      tags when is_list(tags) and length(tags) <= 20 ->
        if Enum.all?(tags, &is_binary/1) do
          changeset
        else
          add_error(changeset, :tags, "must be a list of strings")
        end

      _ ->
        add_error(changeset, :tags, "maximum 20 tags allowed")
    end
  end

  # Calculate project completion percentage based on filled fields.
  #
  # Scoring:
  # - Name (required): 20% (always present)
  # - Description: +15%
  # - Category: +10%
  # - Tags (at least one): +10%
  # - Project date: +10%
  # - Cover image: +15%
  # - Collaborators: +10% (calculated in context layer)
  # - Affiliation links: +10% (calculated in context layer)
  #
  # Maximum: 100%
  defp calculate_completion(changeset) do
    data = apply_changes(changeset)

    # Base (has name)
    percentage =
      20 +
        if(data.description && data.description != "", do: 15, else: 0) +
        if(data.category && data.category != "", do: 10, else: 0) +
        if(data.tags && length(data.tags) > 0, do: 10, else: 0) +
        if(data.project_date, do: 10, else: 0) +
        if(data.cover_media_item_id, do: 15, else: 0)

    # Note: Collaborators (+10%) and affiliation links (+10%) are counted in context layer
    # when those associations are preloaded, since they're not directly accessible here

    put_change(changeset, :completion_percentage, min(percentage, 100))
  end
end
