defmodule Homesite.Media.ContentSection do
  @moduledoc """
  ContentSection schema for flexible content blocks within projects.

  Sections can be of different types:
  - `rich_text` - General markdown content
  - `code_block` - Code with syntax highlighting
  - `book_info` - Structured book metadata (ISBN, Publisher, etc.)
  - `chapter` - Book/writing chapter content
  - `gear_spec` - Equipment specifications
  - `movie_info` - Film metadata

  Each section has:
  - Type discriminator
  - Optional title
  - Content (markdown text)
  - Metadata (JSON for type-specific structured data)
  - Display order for controlling presentation
  """
  use Ecto.Schema
  import Ecto.Changeset

  @valid_section_types ~w(rich_text code_block book_info chapter gear_spec movie_info)

  schema "content_sections" do
    field :section_type, :string
    field :title, :string
    field :content, :string
    field :metadata, :map, default: %{}
    field :display_order, :integer, default: 0

    belongs_to :project, Homesite.Media.Project
    belongs_to :user, Homesite.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Returns the list of valid section types.
  """
  def valid_section_types, do: @valid_section_types

  @doc false
  def changeset(section, attrs, user_scope) do
    section
    |> cast(attrs, [:section_type, :title, :content, :metadata, :display_order, :project_id])
    |> validate_required([:section_type, :project_id])
    |> validate_inclusion(:section_type, @valid_section_types)
    |> validate_length(:title, max: 200)
    |> validate_number(:display_order, greater_than_or_equal_to: 0)
    |> validate_metadata()
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:user_id)
    |> put_change(:user_id, user_scope.user.id)
  end

  # Validates and normalizes metadata based on section_type.
  defp validate_metadata(changeset) do
    section_type = get_field(changeset, :section_type)
    metadata = get_field(changeset, :metadata) || %{}

    case section_type do
      "book_info" -> validate_book_metadata(changeset, metadata)
      "code_block" -> validate_code_metadata(changeset, metadata)
      "gear_spec" -> validate_gear_metadata(changeset, metadata)
      "movie_info" -> validate_movie_metadata(changeset, metadata)
      _ -> changeset
    end
  end

  defp validate_book_metadata(changeset, metadata) do
    # Validate book-specific fields
    valid_keys =
      ~w(isbn publisher author pages language format edition publication_year rating reading_status)

    filtered =
      Map.take(metadata, valid_keys)
      |> normalize_book_fields()

    put_change(changeset, :metadata, filtered)
  end

  defp normalize_book_fields(metadata) do
    metadata
    |> normalize_integer("pages")
    |> normalize_integer("publication_year")
    |> normalize_integer("rating", 1, 5)
    |> normalize_enum("format", ~w(paperback hardcover ebook audiobook))
    |> normalize_enum("reading_status", ~w(reading completed want_to_read dnf))
  end

  defp validate_code_metadata(changeset, metadata) do
    valid_keys = ~w(language filename github_url line_start line_end)
    filtered = Map.take(metadata, valid_keys)
    put_change(changeset, :metadata, filtered)
  end

  defp validate_gear_metadata(changeset, metadata) do
    valid_keys = ~w(brand model price purchase_url)
    filtered = Map.take(metadata, valid_keys)
    put_change(changeset, :metadata, filtered)
  end

  defp validate_movie_metadata(changeset, metadata) do
    valid_keys = ~w(director year runtime imdb_url)
    filtered = Map.take(metadata, valid_keys)
    put_change(changeset, :metadata, filtered)
  end

  defp normalize_integer(metadata, key) do
    case metadata[key] do
      nil ->
        metadata

      value when is_integer(value) ->
        metadata

      value when is_binary(value) ->
        case Integer.parse(value) do
          {int, _} -> Map.put(metadata, key, int)
          :error -> Map.delete(metadata, key)
        end

      _ ->
        Map.delete(metadata, key)
    end
  end

  defp normalize_integer(metadata, key, min, max) do
    metadata = normalize_integer(metadata, key)

    case metadata[key] do
      nil -> metadata
      value when value >= min and value <= max -> metadata
      _ -> Map.delete(metadata, key)
    end
  end

  defp normalize_enum(metadata, key, valid_values) do
    case metadata[key] do
      nil ->
        metadata

      value when is_binary(value) ->
        if value in valid_values do
          metadata
        else
          Map.delete(metadata, key)
        end

      _ ->
        Map.delete(metadata, key)
    end
  end
end
