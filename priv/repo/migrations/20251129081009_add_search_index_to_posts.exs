defmodule Homesite.Repo.Migrations.AddSearchIndexToPosts do
  use Ecto.Migration

  def up do
    # Create GIN indexes for full-text search on posts
    execute "CREATE INDEX posts_title_trgm_idx ON posts USING gin (title gin_trgm_ops)"
    execute "CREATE INDEX posts_body_trgm_idx ON posts USING gin (body gin_trgm_ops)"
  end

  def down do
    execute "DROP INDEX IF EXISTS posts_title_trgm_idx"
    execute "DROP INDEX IF EXISTS posts_body_trgm_idx"
  end
end
