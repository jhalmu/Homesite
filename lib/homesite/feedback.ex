defmodule Homesite.Feedback do
  @moduledoc """
  The Feedback context.

  Manages user feedback, happiness scoring, rank calculation, and testimonials.
  """
  import Ecto.Query, warn: false
  require Logger

  alias Homesite.Repo
  alias Homesite.Accounts.{User, Scope}
  alias Homesite.Feedback.{FeedbackResponse, RankHistory}

  ## Feedback Collection

  @doc """
  Creates a feedback response.

  Automatically snapshots user rank and days since signup.
  Enforces anti-spam rules (rate limiting and positive/negative bias).

  ## Examples

      iex> create_feedback_response(scope, %{overall_satisfaction: 5, prompt_type: "active"})
      {:ok, %FeedbackResponse{}}

      iex> create_feedback_response(scope, %{overall_satisfaction: 7})
      {:error, %Ecto.Changeset{}}
  """
  def create_feedback_response(%Scope{} = scope, attrs) do
    user = scope.user
    rating = Map.get(attrs, "overall_satisfaction") || Map.get(attrs, :overall_satisfaction)

    with {:ok, :allowed} <- can_submit_feedback?(user, rating) do
      attrs =
        attrs
        |> Map.put("user_id", user.id)
        |> Map.put("user_rank_at_time", User.get_rank(user))
        |> Map.put("days_since_signup", days_since_signup(user))

      changeset = FeedbackResponse.changeset(%FeedbackResponse{}, attrs)

      Repo.transaction(fn ->
        case Repo.insert(changeset) do
          {:ok, feedback} ->
            # Update user's feedback counters
            update_feedback_counters(user, rating)
            feedback

          {:error, changeset} ->
            Repo.rollback(changeset)
        end
      end)
    end
  end

  @doc """
  Checks if a user can submit feedback based on anti-spam rules.

  ## Anti-spam rules:
  1. Maximum 1 feedback per 7 days (rate limit)
  2. Can give 2x more positive (4-5 star) than negative (1-2 star) feedback

  Returns `{:ok, :allowed}` or `{:error, reason}`.
  """
  def can_submit_feedback?(%User{} = user, rating) do
    seven_days_ago = DateTime.add(DateTime.utc_now(), -7, :day)

    # Check rate limit
    recent_count =
      from(f in FeedbackResponse,
        where: f.user_id == ^user.id and f.inserted_at > ^seven_days_ago,
        select: count(f.id)
      )
      |> Repo.one()

    cond do
      recent_count > 0 ->
        {:error, :rate_limited}

      rating in [1, 2] and user.negative_feedback_count >= div(user.positive_feedback_count, 2) ->
        {:error, :negative_feedback_limit}

      true ->
        {:ok, :allowed}
    end
  end

  @doc """
  Gets a single feedback response.

  Raises `Ecto.NoResultsError` if the FeedbackResponse does not exist or doesn't belong to the user.
  """
  def get_feedback_response!(%Scope{} = scope, id) do
    feedback =
      FeedbackResponse
      |> Repo.get!(id)
      |> Repo.preload([:user, :approved_by])

    # Enforce scope isolation
    true = feedback.user_id == scope.user.id

    feedback
  end

  @doc """
  Shares a feedback response publicly.

  Generates a share token if not already present.
  """
  def share_feedback_publicly(%Scope{} = scope, feedback_id) do
    feedback = get_feedback_response!(scope, feedback_id)

    attrs = %{
      shared_publicly: true,
      share_token: feedback.share_token || generate_share_token()
    }

    feedback
    |> FeedbackResponse.share_changeset(attrs)
    |> Repo.update()
  end

  ## Public Testimonials

  @doc """
  Gets a testimonial by its public share token.

  Returns nil if not found or not shared publicly.
  """
  def get_testimonial_by_token(token) when is_binary(token) do
    from(f in FeedbackResponse,
      where: f.share_token == ^token and f.shared_publicly == true,
      preload: [:user]
    )
    |> Repo.one()
  end

  def get_testimonial_by_token(_), do: nil

  @doc """
  Lists public testimonials.

  ## Options
    * `:limit` - Maximum number of testimonials to return (default: 50)
    * `:approved_only` - Only show approved testimonials (default: true)
    * `:min_rating` - Minimum overall satisfaction rating (default: 4)
  """
  def list_public_testimonials(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    approved_only = Keyword.get(opts, :approved_only, true)
    min_rating = Keyword.get(opts, :min_rating, 4)

    query =
      from(f in FeedbackResponse,
        where: f.shared_publicly == true and f.overall_satisfaction >= ^min_rating,
        order_by: [desc: f.inserted_at],
        limit: ^limit,
        preload: [:user]
      )

    query =
      if approved_only do
        from(f in query, where: f.testimonial_approved == true)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Gets featured testimonials (high ratings, recently approved).

  Returns up to `count` testimonials.
  """
  def get_featured_testimonials(count \\ 3) do
    from(f in FeedbackResponse,
      where:
        f.shared_publicly == true and
          f.testimonial_approved == true and
          f.overall_satisfaction == 5,
      order_by: [desc: f.approved_at],
      limit: ^count,
      preload: [:user]
    )
    |> Repo.all()
  end

  ## Happiness Scoring

  @doc """
  Calculates the happiness score (1-100 scale) for the given time window.

  Uses exponential decay weighting with 30-day half-life: `weight = 0.5^(age_days / 30)`

  Returns a map with:
  - `:score` - Weighted average score (1-100)
  - `:total_responses` - Number of feedback responses
  - `:confidence` - Confidence level (:low, :medium, :high)
  """
  def calculate_happiness_score(days \\ 90) do
    cutoff_date = DateTime.add(DateTime.utc_now(), -days, :day)

    feedback =
      from(f in FeedbackResponse,
        where: f.inserted_at > ^cutoff_date,
        select: %{
          satisfaction: f.overall_satisfaction,
          inserted_at: f.inserted_at
        }
      )
      |> Repo.all()

    if Enum.empty?(feedback) do
      %{score: 0, total_responses: 0, confidence: :none}
    else
      now = DateTime.utc_now()

      {weighted_sum, weight_sum} =
        Enum.reduce(feedback, {0.0, 0.0}, fn item, {sum, weights} ->
          age_days = DateTime.diff(now, item.inserted_at, :day)
          weight = :math.pow(0.5, age_days / 30)
          score = item.satisfaction / 5 * 100

          {sum + score * weight, weights + weight}
        end)

      score = round(weighted_sum / weight_sum)
      confidence = calculate_confidence(length(feedback))

      %{score: score, total_responses: length(feedback), confidence: confidence}
    end
  end

  @doc """
  Gets happiness trend over time.

  Returns a list of data points with score and response count per bucket.

  ## Examples

      iex> get_happiness_trend(90, 7)
      [
        %{date: ~D[2025-11-15], score: 82, responses: 15},
        %{date: ~D[2025-11-22], score: 85, responses: 18},
        ...
      ]
  """
  def get_happiness_trend(days \\ 90, _bucket_days \\ 7) do
    cutoff_date = DateTime.add(DateTime.utc_now(), -days, :day)

    feedback =
      from(f in FeedbackResponse,
        where: f.inserted_at > ^cutoff_date,
        select: %{
          satisfaction: f.overall_satisfaction,
          inserted_at: f.inserted_at
        },
        order_by: [asc: f.inserted_at]
      )
      |> Repo.all()

    feedback
    |> Enum.group_by(fn item ->
      Date.beginning_of_week(DateTime.to_date(item.inserted_at))
    end)
    |> Enum.map(fn {date, items} ->
      avg_score = Enum.sum(Enum.map(items, & &1.satisfaction)) / length(items) * 20
      %{date: date, score: round(avg_score), responses: length(items)}
    end)
    |> Enum.sort_by(& &1.date, Date)
  end

  ## Prompt Scheduling

  @doc """
  Checks if a user should be shown a feedback prompt.

  Based on exponential backoff schedule: [7, 14, 30, 60, 90, 180, 365] days.
  User preference "less_frequent" doubles intervals after 60 days.
  """
  def should_show_prompt?(%User{} = user) do
    cond do
      User.feedback_opted_out?(user) ->
        false

      is_nil(user.last_feedback_prompt_at) ->
        # First prompt: 7 days after signup
        days_since_signup = days_since_signup(user)
        days_since_signup >= 7

      true ->
        # Calculate next prompt time based on feedback count and preference
        feedback_count = count_user_feedback(user.id)
        days_since_last_prompt = DateTime.diff(DateTime.utc_now(), user.last_feedback_prompt_at, :day)
        next_interval = calculate_prompt_interval(feedback_count, user.feedback_prompt_preference)

        days_since_last_prompt >= next_interval
    end
  end

  @doc """
  Marks that a prompt was shown to the user.

  Updates `last_feedback_prompt_at` to current timestamp.
  """
  def mark_prompt_shown(%User{} = user) do
    user
    |> Ecto.Changeset.change(%{last_feedback_prompt_at: DateTime.utc_now()})
    |> Repo.update()
  end

  @doc """
  Lists users who are due for a feedback prompt.

  Returns up to `limit` users.
  """
  def list_users_due_for_prompt(limit \\ 500) do
    seven_days_ago = DateTime.add(DateTime.utc_now(), -7, :day)

    from(u in User,
      where:
        u.feedback_prompt_preference != "opted_out" and
          (is_nil(u.last_feedback_prompt_at) or u.last_feedback_prompt_at < ^seven_days_ago),
      limit: ^limit
    )
    |> Repo.all()
    |> Enum.filter(&should_show_prompt?/1)
  end

  ## Rank Calculation

  @doc """
  Calculates and updates a user's rank based on activity.

  ## Rank components (1-10 scale):
  - Posts published: 0.3 pts/post (max 3)
  - Feed items read: 0.005 pts/item (max 2)
  - Bookmarks: 0.1 pts/bookmark (max 1)
  - Account age: 0.5 pts per 90 days (max 2)
  - Recent activity (30 days): 0-2 pts based on engagement

  Admins use admin_flowers mapped to rank (flowers * 2).
  """
  def calculate_rank(%User{role: "admin"} = user) do
    # Admins use admin_flowers system
    {:ok, User.get_rank(user)}
  end

  def calculate_rank(%User{} = user) do
    # Calculate activity scores
    posts_count = count_user_posts(user.id)
    feed_reads = count_user_read_items(user.id)
    bookmarks = count_user_bookmarks(user.id)
    account_age_days = days_since_signup(user)
    recent_activity = count_recent_activity(user.id, 30)

    # Calculate weighted scores with caps
    posts_score = min(posts_count * 0.3, 3.0)
    feed_reads_score = min(feed_reads * 0.005, 2.0)
    bookmarks_score = min(bookmarks * 0.1, 1.0)
    age_score = min(account_age_days / 90 * 0.5, 2.0)
    engagement_score = min(recent_activity / 50 * 2, 2.0)

    total_score = posts_score + feed_reads_score + bookmarks_score + age_score + engagement_score
    new_rank = max(1, min(10, round(total_score)))

    calculation_details = %{
      posts_count: posts_count,
      posts_score: posts_score,
      feed_reads: feed_reads,
      feed_reads_score: feed_reads_score,
      bookmarks: bookmarks,
      bookmarks_score: bookmarks_score,
      account_age_days: account_age_days,
      age_score: age_score,
      recent_activity: recent_activity,
      engagement_score: engagement_score,
      total_score: total_score,
      final_rank: new_rank
    }

    # Update user rank and store history
    old_rank = user.rank || 1

    if new_rank != old_rank do
      Repo.transaction(fn ->
        # Update user
        user
        |> Ecto.Changeset.change(%{rank: new_rank, rank_updated_at: DateTime.utc_now()})
        |> Repo.update!()

        # Store history
        %RankHistory{}
        |> RankHistory.changeset(%{
          user_id: user.id,
          old_rank: old_rank,
          new_rank: new_rank,
          calculation_details: calculation_details
        })
        |> Repo.insert!()

        new_rank
      end)
    else
      {:ok, new_rank}
    end
  end

  @doc """
  Recalculates ranks for all non-admin users.

  ## Options
    * `:batch_size` - Process users in batches (default: 100)
  """
  def recalculate_all_ranks(opts \\ []) do
    batch_size = Keyword.get(opts, :batch_size, 100)

    from(u in User, where: u.role != "admin")
    |> Repo.stream()
    |> Stream.chunk_every(batch_size)
    |> Stream.each(fn batch ->
      Enum.each(batch, fn user ->
        case calculate_rank(user) do
          {:ok, _rank} -> :ok
          {:error, reason} -> Logger.warning("Failed to calculate rank for user #{user.id}: #{inspect(reason)}")
        end
      end)
    end)
    |> Stream.run()

    :ok
  end

  ## Admin Functions

  @doc """
  Lists all feedback responses (admin only).

  ## Options
    * `:limit` - Maximum number of responses (default: 50)
    * `:min_rating` - Filter by minimum rating
    * `:prompt_type` - Filter by prompt type ("active" or "passive")
  """
  def list_feedback_responses(scope, opts \\ [])

  def list_feedback_responses(%Scope{admin_override?: true}, opts) do
    limit = Keyword.get(opts, :limit, 50)
    min_rating = Keyword.get(opts, :min_rating)
    prompt_type = Keyword.get(opts, :prompt_type)

    query =
      from(f in FeedbackResponse,
        order_by: [desc: f.inserted_at],
        limit: ^limit,
        preload: [:user, :approved_by]
      )

    query =
      if min_rating do
        from(f in query, where: f.overall_satisfaction >= ^min_rating)
      else
        query
      end

    query =
      if prompt_type do
        from(f in query, where: f.prompt_type == ^prompt_type)
      else
        query
      end

    Repo.all(query)
  end

  def list_feedback_responses(_scope, _opts) do
    raise "Unauthorized: Admin access required"
  end

  @doc """
  Approves a testimonial for public display (admin only).
  """
  def approve_testimonial(%Scope{admin_override?: true} = scope, feedback_id) do
    feedback = Repo.get!(FeedbackResponse, feedback_id)

    feedback
    |> FeedbackResponse.approval_changeset(%{
      testimonial_approved: true,
      approved_by_user_id: scope.user.id,
      approved_at: DateTime.utc_now()
    })
    |> Repo.update()
  end

  def approve_testimonial(_scope, _feedback_id) do
    raise "Unauthorized: Admin access required"
  end

  @doc """
  Unapproves a testimonial (removes public approval).

  Admins can unapprove testimonials to remove them from public display
  while keeping them shared.
  """
  def unapprove_testimonial(%Scope{admin_override?: true} = _scope, feedback_id) do
    feedback = Repo.get!(FeedbackResponse, feedback_id)

    feedback
    |> FeedbackResponse.approval_changeset(%{
      testimonial_approved: false,
      approved_by_user_id: nil,
      approved_at: nil
    })
    |> Repo.update()
  end

  def unapprove_testimonial(_scope, _feedback_id) do
    raise "Unauthorized: Admin access required"
  end

  @doc """
  Lists pending testimonials (shared but not yet approved).

  Returns all testimonials that are shared publicly but haven't been
  approved by an admin yet.
  """
  def list_pending_testimonials(%Scope{admin_override?: true} = _scope) do
    from(f in FeedbackResponse,
      where: f.shared_publicly == true and is_nil(f.testimonial_approved),
      order_by: [desc: f.inserted_at],
      preload: [:user]
    )
    |> Repo.all()
  end

  def list_pending_testimonials(_scope) do
    raise "Unauthorized: Admin access required"
  end

  @doc """
  Gets feedback analytics for admin dashboard.

  Returns:
  - Happiness score
  - Total responses (last `days`)
  - Response rate by rank
  - Average rating
  """
  def get_feedback_analytics(scope, days \\ 90)

  def get_feedback_analytics(%Scope{admin_override?: true}, days) do
    happiness = calculate_happiness_score(days)
    cutoff_date = DateTime.add(DateTime.utc_now(), -days, :day)

    total_responses =
      from(f in FeedbackResponse, where: f.inserted_at > ^cutoff_date, select: count(f.id))
      |> Repo.one()

    avg_rating =
      from(f in FeedbackResponse,
        where: f.inserted_at > ^cutoff_date,
        select: avg(f.overall_satisfaction)
      )
      |> Repo.one()
      |> case do
        nil -> 0.0
        %Decimal{} = val -> Decimal.to_float(val) |> Float.round(2)
        val when is_float(val) -> Float.round(val, 2)
      end

    response_by_rank =
      from(f in FeedbackResponse,
        join: u in User,
        on: f.user_id == u.id,
        where: f.inserted_at > ^cutoff_date,
        group_by: u.rank,
        select: %{rank: u.rank, count: count(f.id)},
        order_by: [asc: u.rank]
      )
      |> Repo.all()

    %{
      happiness: happiness,
      total_responses: total_responses,
      avg_rating: avg_rating,
      response_by_rank: response_by_rank
    }
  end

  def get_feedback_analytics(_scope, _days) do
    raise "Unauthorized: Admin access required"
  end

  ## Private Functions

  defp days_since_signup(%User{inserted_at: inserted_at}) do
    DateTime.diff(DateTime.utc_now(), inserted_at, :day)
  end

  defp update_feedback_counters(user, rating) do
    cond do
      rating in [4, 5] ->
        from(u in User, where: u.id == ^user.id)
        |> Repo.update_all(inc: [positive_feedback_count: 1])

      rating in [1, 2] ->
        from(u in User, where: u.id == ^user.id)
        |> Repo.update_all(inc: [negative_feedback_count: 1])

      true ->
        :ok
    end
  end

  defp count_user_feedback(user_id) do
    from(f in FeedbackResponse, where: f.user_id == ^user_id, select: count(f.id))
    |> Repo.one()
  end

  defp calculate_prompt_interval(feedback_count, preference) do
    # Base intervals: [7, 14, 30, 60, 90, 180, 365]
    base_intervals = [7, 14, 30, 60, 90, 180, 365]
    index = min(feedback_count, length(base_intervals) - 1)
    interval = Enum.at(base_intervals, index)

    # Double intervals after 60 days if user prefers less frequent
    if preference == "less_frequent" and interval >= 60 do
      interval * 2
    else
      interval
    end
  end

  defp calculate_confidence(response_count) do
    cond do
      response_count >= 30 -> :high
      response_count >= 10 -> :medium
      response_count >= 3 -> :low
      true -> :very_low
    end
  end

  defp generate_share_token do
    :crypto.strong_rand_bytes(16)
    |> Base.url_encode64(padding: false)
  end

  # Delegate to other contexts for activity metrics
  defp count_user_posts(user_id) do
    Homesite.Content.count_user_posts(user_id)
  end

  defp count_user_read_items(user_id) do
    Homesite.ExternalFeeds.count_user_read_items(user_id)
  end

  defp count_user_bookmarks(user_id) do
    Homesite.ExternalFeeds.count_user_bookmarks(user_id)
  end

  defp count_recent_activity(user_id, days) do
    # Count posts + feed reads + bookmarks in last N days
    cutoff = DateTime.add(DateTime.utc_now(), -days, :day)

    posts =
      from(p in Homesite.Content.Post,
        where: p.user_id == ^user_id and p.inserted_at > ^cutoff,
        select: count(p.id)
      )
      |> Repo.one()

    interactions =
      from(i in Homesite.ExternalFeeds.FeedItemInteraction,
        where: i.user_id == ^user_id and i.inserted_at > ^cutoff,
        select: count(i.id)
      )
      |> Repo.one()

    posts + interactions
  end
end
