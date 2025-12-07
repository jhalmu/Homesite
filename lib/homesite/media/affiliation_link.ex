defmodule Homesite.Media.AffiliationLink do
  @moduledoc """
  Affiliation link schema for tracking related links for projects.

  Affiliation links can include:
  - Client websites
  - Press coverage
  - Related projects
  - Awards or recognitions
  - Any other relevant external links
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "affiliation_links" do
    field :title, :string
    field :url, :string
    field :display_order, :integer, default: 0

    belongs_to :project, Homesite.Media.Project
    belongs_to :user, Homesite.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(affiliation_link, attrs, user_scope) do
    affiliation_link
    |> cast(attrs, [:title, :url, :display_order, :project_id])
    |> validate_required([:title, :url, :project_id])
    |> validate_length(:title, min: 1, max: 200)
    |> validate_length(:url, max: 500)
    |> validate_url(:url)
    |> validate_number(:display_order, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:user_id)
    |> put_change(:user_id, user_scope.user.id)
  end

  defp validate_url(changeset, field) do
    url = get_field(changeset, field)

    if url do
      uri = URI.parse(url)

      if uri.scheme in ["http", "https"] && uri.host do
        changeset
      else
        add_error(changeset, field, "must be a valid URL with http:// or https://")
      end
    else
      changeset
    end
  end
end
