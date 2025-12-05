defmodule Homesite.Feedback.RankHistory do
  @moduledoc """
  Audit trail for user rank changes.

  Stores snapshots of rank calculations including the breakdown of how
  the rank was calculated. Useful for debugging and transparency.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Homesite.Accounts.User

  schema "rank_history" do
    field :old_rank, :integer
    field :new_rank, :integer
    field :calculation_details, :map

    belongs_to :user, User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Creates a changeset for a new rank history entry.

  ## Calculation Details Format

  The `calculation_details` map should contain the breakdown:

      %{
        posts_count: 10,
        posts_score: 3.0,
        feed_reads: 450,
        feed_reads_score: 2.0,
        bookmarks: 8,
        bookmarks_score: 0.8,
        account_age_days: 180,
        age_score: 1.0,
        recent_activity: 35,
        engagement_score: 1.4,
        total_score: 8.2,
        final_rank: 8
      }
  """
  def changeset(rank_history, attrs) do
    rank_history
    |> cast(attrs, [:user_id, :old_rank, :new_rank, :calculation_details])
    |> validate_required([:user_id, :old_rank, :new_rank])
    |> validate_number(:old_rank, greater_than_or_equal_to: 1, less_than_or_equal_to: 10)
    |> validate_number(:new_rank, greater_than_or_equal_to: 1, less_than_or_equal_to: 10)
    |> foreign_key_constraint(:user_id)
  end
end
