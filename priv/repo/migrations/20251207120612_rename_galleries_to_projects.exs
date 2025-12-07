defmodule Homesite.Repo.Migrations.RenameGalleriesToProjects do
  use Ecto.Migration

  def change do
    # Rename table
    rename table(:galleries), to: table(:projects)

    # Rename indexes
    execute "ALTER INDEX galleries_pkey RENAME TO projects_pkey",
            "ALTER INDEX projects_pkey RENAME TO galleries_pkey"

    execute "ALTER INDEX galleries_user_id_slug_index RENAME TO projects_user_id_slug_index",
            "ALTER INDEX projects_user_id_slug_index RENAME TO galleries_user_id_slug_index"

    # Rename join table
    rename table(:gallery_media_items), to: table(:project_media_items)

    execute "ALTER TABLE project_media_items RENAME COLUMN gallery_id TO project_id",
            "ALTER TABLE project_media_items RENAME COLUMN project_id TO gallery_id"
  end
end
