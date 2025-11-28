defmodule Homesite.Repo.Migrations.CreateActivities do
  use Ecto.Migration

  def change do
    create table(:activities) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :activity_type, :string, null: false
      add :subject_type, :string
      add :subject_id, :integer
      add :content, :text, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:activities, [:user_id])
    create index(:activities, [:activity_type])
    create index(:activities, [:inserted_at])
  end
end
