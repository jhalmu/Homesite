defmodule Homesite.Repo.Migrations.CreateFaqs do
  use Ecto.Migration

  def change do
    create table(:faqs) do
      add :category, :string, null: false
      add :question_en, :text, null: false
      add :question_fi, :text, null: false
      add :answer_en, :text, null: false
      add :answer_fi, :text, null: false
      add :display_order, :integer, null: false, default: 0
      add :is_active, :boolean, null: false, default: true
      add :slug, :string, null: false
      add :metadata, :map, default: %{}

      add :created_by_id, references(:users, on_delete: :nilify_all)
      add :updated_by_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:faqs, [:slug])
    create index(:faqs, [:category])
    create index(:faqs, [:category, :display_order])
    create index(:faqs, [:category, :is_active])
  end
end
