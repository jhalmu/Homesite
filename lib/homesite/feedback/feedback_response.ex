defmodule Homesite.Feedback.FeedbackResponse do
  @moduledoc """
  Schema for user feedback responses.

  Tracks both active (prompted) and passive (user-initiated) feedback,
  including satisfaction ratings, performance ratings, feature usefulness,
  and optional open feedback text.

  Supports social sharing for 4-5 star ratings via unique share tokens.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Homesite.Accounts.User

  @allowed_features ["posts", "feeds", "bookmarks", "tags", "search", "timeline", "analytics"]
  @prompt_types ["active", "passive"]

  schema "feedback_responses" do
    field :overall_satisfaction, :integer
    field :performance_rating, :integer
    field :feature_usefulness, :map
    field :open_feedback, :string

    field :prompt_type, :string
    field :user_rank_at_time, :integer
    field :days_since_signup, :integer
    field :ip_address, :string
    field :user_agent, :string

    field :shared_publicly, :boolean, default: false
    field :share_token, :string
    field :testimonial_approved, :boolean, default: false
    field :approved_at, :utc_datetime

    belongs_to :user, User
    belongs_to :approved_by, User, foreign_key: :approved_by_user_id

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for a new feedback response.

  Automatically generates a share token for 4-5 star ratings.
  """
  def changeset(feedback_response, attrs) do
    feedback_response
    |> cast(attrs, [
      :user_id,
      :overall_satisfaction,
      :performance_rating,
      :feature_usefulness,
      :open_feedback,
      :prompt_type,
      :user_rank_at_time,
      :days_since_signup,
      :ip_address,
      :user_agent
    ])
    |> validate_required([:user_id, :overall_satisfaction, :prompt_type])
    |> validate_inclusion(:overall_satisfaction, 1..5, message: "must be between 1 and 5")
    |> validate_inclusion(:performance_rating, 1..5, message: "must be between 1 and 5")
    |> validate_inclusion(:prompt_type, @prompt_types)
    |> validate_feature_usefulness()
    |> maybe_generate_share_token()
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Creates a changeset for sharing feedback publicly.
  """
  def share_changeset(feedback_response, attrs) do
    feedback_response
    |> cast(attrs, [:shared_publicly, :share_token])
    |> validate_required([:share_token])
    |> unique_constraint(:share_token)
  end

  @doc """
  Creates a changeset for approving a testimonial (admin only).
  """
  def approval_changeset(feedback_response, attrs) do
    feedback_response
    |> cast(attrs, [:testimonial_approved, :approved_by_user_id, :approved_at])
    |> validate_required([:testimonial_approved])
  end

  # Private functions

  defp validate_feature_usefulness(changeset) do
    case get_field(changeset, :feature_usefulness) do
      nil ->
        changeset

      features when is_map(features) ->
        invalid_keys =
          Map.keys(features)
          |> Enum.reject(&(&1 in @allowed_features))

        if Enum.empty?(invalid_keys) do
          changeset
        else
          add_error(
            changeset,
            :feature_usefulness,
            "contains invalid features: #{Enum.join(invalid_keys, ", ")}"
          )
        end

      _ ->
        add_error(changeset, :feature_usefulness, "must be a map")
    end
  end

  defp maybe_generate_share_token(changeset) do
    satisfaction = get_field(changeset, :overall_satisfaction)

    if satisfaction in [4, 5] and is_nil(get_field(changeset, :share_token)) do
      put_change(changeset, :share_token, generate_share_token())
    else
      changeset
    end
  end

  defp generate_share_token do
    :crypto.strong_rand_bytes(16)
    |> Base.url_encode64(padding: false)
  end
end
