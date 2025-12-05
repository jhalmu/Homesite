defmodule Homesite.Repo.Migrations.CreateFeedbackResponses do
  use Ecto.Migration

  def change do
    create table(:feedback_responses) do
      add :user_id, references(:users, on_delete: :delete_all), null: false

      # Response data
      add :overall_satisfaction, :integer, null: false # 1-5 stars (REQUIRED)
      add :performance_rating, :integer # 1-5 stars (optional)
      add :feature_usefulness, :map, default: %{} # {posts: true, feeds: true, ...}
      add :open_feedback, :text # Optional comment

      # Metadata
      add :prompt_type, :string, null: false # "active" | "passive"
      add :user_rank_at_time, :integer # Snapshot of rank
      add :days_since_signup, :integer
      add :ip_address, :string
      add :user_agent, :string

      # Sharing & testimonial
      add :shared_publicly, :boolean, default: false
      add :share_token, :string # For /testimonials/:token URL
      add :testimonial_approved, :boolean, default: false
      add :approved_by_user_id, references(:users, on_delete: :nilify_all)
      add :approved_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:feedback_responses, [:user_id])
    create index(:feedback_responses, [:overall_satisfaction])
    create index(:feedback_responses, [:prompt_type])
    create index(:feedback_responses, [:shared_publicly])
    create unique_index(:feedback_responses, [:share_token])
    create index(:feedback_responses, [:inserted_at])
  end
end
