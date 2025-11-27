defmodule Homesite.Repo.Migrations.MigrateTagsToGlobalNamespace do
  use Ecto.Migration
  import Ecto.Query

  def up do
    # Step 1: Consolidate duplicate public tags
    # For each duplicate name, keep the oldest public tag and remap post_tags

    execute """
    WITH duplicate_tags AS (
      SELECT
        name,
        MIN(id) as keep_id,
        ARRAY_AGG(id ORDER BY id) as all_ids
      FROM tags
      WHERE is_public = true
      GROUP BY name
      HAVING COUNT(*) > 1
    ),
    expanded_duplicates AS (
      SELECT
        dt.name,
        dt.keep_id,
        tag_id as delete_id
      FROM duplicate_tags dt
      CROSS JOIN LATERAL unnest(dt.all_ids) AS tag_id
      WHERE tag_id != dt.keep_id
    )
    UPDATE post_tags pt
    SET tag_id = ed.keep_id
    FROM expanded_duplicates ed
    WHERE pt.tag_id = ed.delete_id;
    """

    execute """
    WITH duplicate_tags AS (
      SELECT name, MIN(id) as keep_id
      FROM tags
      WHERE is_public = true
      GROUP BY name
      HAVING COUNT(*) > 1
    )
    DELETE FROM tags t
    WHERE t.is_public = true
    AND t.id NOT IN (SELECT keep_id FROM duplicate_tags)
    AND EXISTS (
      SELECT 1 FROM tags t2
      WHERE t2.name = t.name
      AND t2.id < t.id
      AND t2.is_public = true
    );
    """

    # Step 2: Drop old unique constraint (user_id, name)
    drop_if_exists index(:tags, [:user_id, :name], name: :tags_user_id_name_index)

    # Step 3: Add global unique constraint for public tags
    create unique_index(:tags, [:name],
             name: :tags_global_public_name_index,
             where: "is_public = true"
           )

    # Step 4: Keep user-scoped constraint for private tags
    create unique_index(:tags, [:user_id, :name],
             name: :tags_private_user_name_index,
             where: "is_public = false"
           )

    # Step 5: Remove duplicate post_tags that may have been created
    execute """
    DELETE FROM post_tags
    WHERE id NOT IN (
      SELECT MIN(id)
      FROM post_tags
      GROUP BY post_id, tag_id
    );
    """
  end

  def down do
    # Rollback: revert to user-scoped tags
    # Note: Cannot fully restore as duplicate data has been consolidated
    drop_if_exists index(:tags, [:name], name: :tags_global_public_name_index)
    drop_if_exists index(:tags, [:user_id, :name], name: :tags_private_user_name_index)

    create unique_index(:tags, [:user_id, :name], name: :tags_user_id_name_index)
  end
end
