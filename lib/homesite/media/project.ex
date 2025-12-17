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
  import Ecto.Query

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

    many_to_many :tags, Homesite.Content.Tag,
      join_through: Homesite.Media.ProjectTag,
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
      :field_visibility
    ])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 200)
    |> validate_length(:description, max: 1000)
    |> validate_length(:category, max: 100)
    |> validate_inclusion(:template_type, @valid_template_types)
    |> maybe_generate_slug()
    |> validate_required([:slug])
    |> unique_constraint(:slug, name: :projects_user_id_slug_index)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:cover_media_item_id)
    |> put_change(:user_id, user_scope.user.id)
    |> put_tags(attrs, user_scope)
    |> calculate_completion(attrs)
  end

  # Generate a slug only for new projects or if explicitly changed.
  # Preserves existing slug when name is updated (allows fixing typos without breaking URLs).
  defp maybe_generate_slug(changeset) do
    cond do
      # If a slug was explicitly provided in attrs, use it
      get_change(changeset, :slug) ->
        changeset

      # If the record already has a slug (update), preserve it
      changeset.data.slug && changeset.data.slug != "" ->
        changeset

      # New project - generate slug from name
      true ->
        case get_change(changeset, :name) || changeset.data.name do
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

  defp put_tags(changeset, %{"tag_ids" => tag_ids}, user_scope) when is_list(tag_ids) do
    tag_ids = Enum.reject(tag_ids, &(&1 == "" || is_nil(&1)))

    if tag_ids == [] do
      put_assoc(changeset, :tags, [])
    else
      tags =
        Homesite.Repo.all(
          from t in Homesite.Content.Tag,
            where: t.id in ^tag_ids and t.user_id == ^user_scope.user.id
        )

      put_assoc(changeset, :tags, tags)
    end
  end

  defp put_tags(changeset, _attrs, _user_scope), do: changeset

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
  defp calculate_completion(changeset, attrs \\ %{}) do
    data = apply_changes(changeset)

    # Check if tags are present (from attrs or existing association)
    has_tags =
      case attrs do
        %{"tag_ids" => tag_ids} when is_list(tag_ids) ->
          tag_ids |> Enum.reject(&(&1 == "" || is_nil(&1))) |> length() > 0

        _ ->
          # Check existing tags from changeset
          case get_change(changeset, :tags) do
            nil -> Ecto.assoc_loaded?(data.tags) && length(data.tags) > 0
            tags -> length(tags) > 0
          end
      end

    # Base (has name)
    percentage =
      20 +
        if(data.description && data.description != "", do: 15, else: 0) +
        if(data.category && data.category != "", do: 10, else: 0) +
        if(has_tags, do: 10, else: 0) +
        if(data.project_date, do: 10, else: 0) +
        if(data.cover_media_item_id, do: 15, else: 0)

    # Note: Collaborators (+10%) and affiliation links (+10%) are counted in context layer
    # when those associations are preloaded, since they're not directly accessible here

    put_change(changeset, :completion_percentage, min(percentage, 100))
  end
end
