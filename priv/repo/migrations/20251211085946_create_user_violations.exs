defmodule Homesite.Repo.Migrations.CreateUserViolations do
  use Ecto.Migration

  def change do
    create table(:user_violations) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :reporter_id, references(:users, on_delete: :nilify_all)
      add :action_type, :string, null: false
      add :reason_category, :string
      add :reason_text, :text
      add :weight, :integer, default: 1, null: false
      add :source, :string
      add :content_type, :string
      add :content_id, :integer
      add :metadata, :map, default: %{}
      add :resolved_at, :utc_datetime
      add :resolved_by_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:user_violations, [:user_id])
    create index(:user_violations, [:reporter_id])
    create index(:user_violations, [:action_type])
    create index(:user_violations, [:user_id, :resolved_at])
  end
end
