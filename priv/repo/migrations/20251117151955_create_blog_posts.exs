defmodule Homesite.Repo.Migrations.CreateBlogPosts do
  use Ecto.Migration

  def change do
    create table(:blog_posts) do
      add :title_fi, :string, null: false
      add :title_en, :string
      add :content_fi, :text, null: false
      add :content_en, :text
      add :slug, :string, null: false
      add :author_type, :string, null: false
      add :author_id, :integer, null: false
      add :created_by_id, references(:users, on_delete: :nilify_all), null: false
      add :curator_added, :boolean, default: false, null: false
      add :status, :string, default: "draft", null: false
      add :published_at, :utc_datetime
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:blog_posts, [:slug])
    create index(:blog_posts, [:created_by_id])
    create index(:blog_posts, [:author_type, :author_id])
    create index(:blog_posts, [:status])
    create index(:blog_posts, [:published_at])
  end
end
