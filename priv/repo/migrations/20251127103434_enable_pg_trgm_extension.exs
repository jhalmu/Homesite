defmodule Homesite.Repo.Migrations.EnablePgTrgmExtension do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm"
    execute "CREATE INDEX tags_name_trgm_idx ON tags USING gin (name gin_trgm_ops)"
  end

  def down do
    execute "DROP INDEX IF EXISTS tags_name_trgm_idx"
    execute "DROP EXTENSION IF EXISTS pg_trgm"
  end
end
