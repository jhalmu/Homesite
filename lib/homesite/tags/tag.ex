defmodule Homesite.Tags.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tags" do
    field :name_fi, :string
    field :name_en, :string
    field :slug, :string

    has_many :taggings, Homesite.Tags.Tagging

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name_fi, :name_en, :slug])
    |> validate_required([:name_fi, :name_en, :slug])
    |> validate_length(:name_fi, min: 2, max: 50)
    |> validate_length(:name_en, min: 2, max: 50)
    |> validate_length(:slug, min: 2, max: 50)
    |> validate_format(:slug, ~r/^[a-z0-9\-]+$/, message: "must contain only lowercase letters, numbers, and hyphens")
    |> unique_constraint(:slug)
  end
end
