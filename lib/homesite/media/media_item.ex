defmodule Homesite.Media.MediaItem do
  @moduledoc """
  Media item schema for storing images with multiple sizes in PostgreSQL bytea.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "media_items" do
    field :original_filename, :string
    field :title, :string
    field :caption, :string
    field :alt_text, :string

    # Binary image data (3 sizes)
    field :thumb_data, :binary
    field :medium_data, :binary
    field :large_data, :binary

    # Image metadata
    field :content_type, :string
    field :file_size_bytes, :integer
    field :width, :integer
    field :height, :integer
    field :aspect_ratio, :decimal
    field :aspect_category, :string

    # Dimensions for each size (for srcset)
    field :thumb_width, :integer
    field :thumb_height, :integer
    field :medium_width, :integer
    field :medium_height, :integer
    field :large_width, :integer
    field :large_height, :integer

    belongs_to :user, Homesite.Accounts.User

    many_to_many :projects, Homesite.Media.Project,
      join_through: "project_media_items",
      on_replace: :delete

    many_to_many :posts, Homesite.Content.Post,
      join_through: "post_media_items",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(media_item, attrs, user_scope) do
    media_item
    |> cast(attrs, [
      :original_filename,
      :title,
      :caption,
      :alt_text,
      :thumb_data,
      :medium_data,
      :large_data,
      :content_type,
      :file_size_bytes,
      :width,
      :height,
      :aspect_ratio,
      :aspect_category,
      :thumb_width,
      :thumb_height,
      :medium_width,
      :medium_height,
      :large_width,
      :large_height
    ])
    |> validate_required([
      :original_filename,
      :alt_text,
      :thumb_data,
      :medium_data,
      :large_data,
      :content_type,
      :file_size_bytes,
      :width,
      :height,
      :aspect_ratio,
      :aspect_category,
      :thumb_width,
      :thumb_height,
      :medium_width,
      :medium_height,
      :large_width,
      :large_height
    ])
    |> validate_length(:alt_text, min: 3, max: 200)
    |> validate_length(:title, max: 200)
    |> validate_length(:caption, max: 2000)
    |> validate_inclusion(:content_type, ["image/jpeg", "image/png", "image/webp"])
    |> validate_inclusion(:aspect_category, ["landscape", "portrait", "square"])
    |> validate_number(:file_size_bytes, greater_than: 0, less_than_or_equal_to: 10 * 1024 * 1024)
    |> validate_number(:width, greater_than: 0)
    |> validate_number(:height, greater_than: 0)
    |> foreign_key_constraint(:user_id)
    |> put_change(:user_id, user_scope.user.id)
  end
end
