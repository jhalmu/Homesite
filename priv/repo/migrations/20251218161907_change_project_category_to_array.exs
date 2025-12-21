defmodule Homesite.Repo.Migrations.ChangeProjectCategoryToArray do
  use Ecto.Migration

  def up do
    # Add new array column
    alter table(:projects) do
      add :categories, {:array, :string}, default: []
    end

    # Migrate existing data: convert single category string to array
    execute """
    UPDATE projects
    SET categories = CASE
      WHEN category IS NOT NULL AND category != '' THEN ARRAY[category]
      ELSE '{}'::varchar[]
    END
    """

    # Remove old column
    alter table(:projects) do
      remove :category
    end
  end

  def down do
    # Add back old column
    alter table(:projects) do
      add :category, :string
    end

    # Migrate data back: take first element of array
    execute """
    UPDATE projects
    SET category = CASE
      WHEN array_length(categories, 1) > 0 THEN categories[1]
      ELSE NULL
    END
    """

    # Remove array column
    alter table(:projects) do
      remove :categories
    end
  end
end
