defmodule Homesite.Repo.Migrations.AddSearchToFeedItems do
  use Ecto.Migration

  def up do
    # Add tsvector column for full-text search
    alter table(:feed_items) do
      add :search_vector, :tsvector
    end

    # Create function to update search_vector
    # Combines title (weight A), content (weight B), and author_name/author_handle (weight C)
    execute """
    CREATE FUNCTION feed_items_search_vector_update() RETURNS trigger AS $$
    BEGIN
      NEW.search_vector :=
        setweight(to_tsvector('english', coalesce(NEW.title, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(NEW.content, '')), 'B') ||
        setweight(to_tsvector('english', coalesce(NEW.author_name, '') || ' ' || coalesce(NEW.author_handle, '')), 'C');
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """

    # Create trigger to auto-update search_vector on insert/update
    execute """
    CREATE TRIGGER feed_items_search_vector_trigger
    BEFORE INSERT OR UPDATE ON feed_items
    FOR EACH ROW EXECUTE FUNCTION feed_items_search_vector_update();
    """

    # Create GIN index for fast full-text search
    create index(:feed_items, [:search_vector], using: "GIN")

    # Backfill existing data
    execute """
    UPDATE feed_items SET search_vector =
      setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
      setweight(to_tsvector('english', coalesce(content, '')), 'B') ||
      setweight(to_tsvector('english', coalesce(author_name, '') || ' ' || coalesce(author_handle, '')), 'C');
    """
  end

  def down do
    # Drop trigger
    execute "DROP TRIGGER IF EXISTS feed_items_search_vector_trigger ON feed_items;"

    # Drop function
    execute "DROP FUNCTION IF EXISTS feed_items_search_vector_update();"

    # Drop column (index will be dropped automatically)
    alter table(:feed_items) do
      remove :search_vector
    end
  end
end
