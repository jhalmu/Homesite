defmodule Homesite.Repo.Migrations.FixTagSlugConstraints do
  use Ecto.Migration

  def up do
    # Drop the global unique slug index
    drop_if_exists index(:tags, [:slug], name: :tags_slug_index)

    # Add scoped unique slug indexes matching the name constraints
    # Public tags: globally unique slug
    create unique_index(:tags, [:slug],
             name: :tags_global_public_slug_index,
             where: "is_public = true"
           )

    # Private tags: user-scoped unique slug
    create unique_index(:tags, [:user_id, :slug],
             name: :tags_private_user_slug_index,
             where: "is_public = false"
           )
  end

  def down do
    # Rollback: restore global unique slug index
    drop_if_exists index(:tags, [:slug], name: :tags_global_public_slug_index)
    drop_if_exists index(:tags, [:user_id, :slug], name: :tags_private_user_slug_index)

    create unique_index(:tags, [:slug], name: :tags_slug_index)
  end
end
