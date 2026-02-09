defmodule Homesite.FeedbackTest do
  use Homesite.DataCase, async: false

  alias Homesite.Accounts.Scope
  alias Homesite.{Feedback, Repo}
  alias Homesite.Feedback.{FeedbackResponse, RankHistory}

  import Homesite.AccountsFixtures

  describe "create_feedback_response/2" do
    setup do
      user = user_fixture()
      scope = Scope.for_user(user)
      %{user: user, scope: scope}
    end

    test "creates feedback with valid data", %{scope: scope} do
      attrs = %{
        "overall_satisfaction" => 5,
        "performance_rating" => 4,
        "open_feedback" => "Great app!",
        "prompt_type" => "active"
      }

      assert {:ok, %FeedbackResponse{} = feedback} =
               Feedback.create_feedback_response(scope, attrs)

      assert feedback.overall_satisfaction == 5
      assert feedback.performance_rating == 4
      assert feedback.open_feedback == "Great app!"
      assert feedback.prompt_type == "active"
      assert feedback.user_id == scope.user.id
    end

    test "auto-generates share_token for 4-5 star ratings", %{scope: scope} do
      attrs = %{
        "overall_satisfaction" => 5,
        "performance_rating" => 5,
        "open_feedback" => "Great!",
        "prompt_type" => "passive"
      }

      assert {:ok, %FeedbackResponse{} = feedback} =
               Feedback.create_feedback_response(scope, attrs)

      assert is_binary(feedback.share_token)
      assert String.length(feedback.share_token) > 10
    end

    test "does not generate share_token for 1-3 star ratings", %{scope: scope} do
      attrs = %{
        "overall_satisfaction" => 3,
        "performance_rating" => 3,
        "open_feedback" => "Okay",
        "prompt_type" => "passive"
      }

      assert {:ok, %FeedbackResponse{} = feedback} =
               Feedback.create_feedback_response(scope, attrs)

      assert is_nil(feedback.share_token)
    end

    test "captures user rank at time of feedback", %{user: user} do
      # Update user rank
      user = Repo.update!(Ecto.Changeset.change(user, rank: 7))
      scope = Scope.for_user(user)

      attrs = %{
        "overall_satisfaction" => 5,
        "performance_rating" => 5,
        "open_feedback" => "Test",
        "prompt_type" => "active"
      }

      assert {:ok, %FeedbackResponse{} = feedback} =
               Feedback.create_feedback_response(scope, attrs)

      assert feedback.user_rank_at_time == 7
    end

    test "requires overall_satisfaction", %{scope: scope} do
      attrs = %{"prompt_type" => "active"}

      assert {:error, %Ecto.Changeset{} = changeset} =
               Feedback.create_feedback_response(scope, attrs)

      assert "can't be blank" in errors_on(changeset).overall_satisfaction
    end

    test "requires prompt_type", %{scope: scope} do
      attrs = %{"overall_satisfaction" => 5}

      assert {:error, %Ecto.Changeset{} = changeset} =
               Feedback.create_feedback_response(scope, attrs)

      assert "can't be blank" in errors_on(changeset).prompt_type
    end

    test "validates satisfaction rating is 1-5", %{scope: scope} do
      attrs = %{"overall_satisfaction" => 6, "prompt_type" => "active"}

      assert {:error, %Ecto.Changeset{} = changeset} =
               Feedback.create_feedback_response(scope, attrs)

      assert "must be between 1 and 5" in errors_on(changeset).overall_satisfaction
    end
  end

  describe "can_submit_feedback?/2 - anti-spam rules" do
    setup do
      user = user_fixture()
      scope = Scope.for_user(user)
      %{user: user, scope: scope}
    end

    test "allows first feedback", %{user: user} do
      assert {:ok, :allowed} = Feedback.can_submit_feedback?(user, 5)
    end

    test "enforces 7-day rate limit", %{scope: scope, user: user} do
      # Submit first feedback
      attrs = %{
        "overall_satisfaction" => 5,
        "performance_rating" => 5,
        "open_feedback" => "First",
        "prompt_type" => "active"
      }

      assert {:ok, _feedback} = Feedback.create_feedback_response(scope, attrs)

      # Try to submit again immediately
      assert {:error, :rate_limited} = Feedback.can_submit_feedback?(user, 5)
    end

    test "allows feedback after 7 days", %{scope: scope, user: user} do
      # Submit first feedback
      attrs = %{
        "overall_satisfaction" => 5,
        "performance_rating" => 5,
        "open_feedback" => "First",
        "prompt_type" => "active"
      }

      {:ok, feedback} = Feedback.create_feedback_response(scope, attrs)

      # Manually update timestamp to 8 days ago
      eight_days_ago = DateTime.add(DateTime.utc_now(), -8, :day) |> DateTime.truncate(:second)
      Repo.update!(Ecto.Changeset.change(feedback, inserted_at: eight_days_ago))

      # Should allow new feedback
      assert {:ok, :allowed} = Feedback.can_submit_feedback?(user, 4)
    end

    test "enforces positive/negative bias (2x rule)", %{user: user} do
      # User has given 2 positive feedback
      user =
        Repo.update!(
          Ecto.Changeset.change(user, positive_feedback_count: 2, negative_feedback_count: 0)
        )

      # Can give 1 negative feedback (2 positive / 2 = 1)
      assert {:ok, :allowed} = Feedback.can_submit_feedback?(user, 2)

      # After giving 1 negative, can't give another
      user = Repo.update!(Ecto.Changeset.change(user, negative_feedback_count: 1))
      assert {:error, :negative_feedback_limit} = Feedback.can_submit_feedback?(user, 1)
    end

    test "allows more positive feedback without limit", %{user: user} do
      # User has given 5 positive and 2 negative
      user =
        Repo.update!(
          Ecto.Changeset.change(user, positive_feedback_count: 5, negative_feedback_count: 2)
        )

      # Can still give more positive feedback
      assert {:ok, :allowed} = Feedback.can_submit_feedback?(user, 5)
    end
  end

  describe "calculate_happiness_score/1" do
    setup do
      user = user_fixture()
      scope = Scope.for_user(user)
      %{user: user, scope: scope}
    end

    test "returns zero score with no feedback" do
      result = Feedback.calculate_happiness_score(90)

      assert result.score == 0
      assert result.total_responses == 0
      assert result.confidence == :none
    end

    test "calculates average score from feedback", %{scope: scope} do
      # Create 3 feedback responses from different users to avoid rate limiting
      user2 = user_fixture()
      scope2 = Scope.for_user(user2)
      user3 = user_fixture()
      scope3 = Scope.for_user(user3)

      Feedback.create_feedback_response(scope, %{
        "overall_satisfaction" => 5,
        "performance_rating" => 5,
        "open_feedback" => "Perfect!",
        "prompt_type" => "active"
      })

      Feedback.create_feedback_response(scope2, %{
        "overall_satisfaction" => 4,
        "performance_rating" => 4,
        "open_feedback" => "Good",
        "prompt_type" => "passive"
      })

      Feedback.create_feedback_response(scope3, %{
        "overall_satisfaction" => 5,
        "performance_rating" => 5,
        "open_feedback" => "Excellent",
        "prompt_type" => "active"
      })

      result = Feedback.calculate_happiness_score(90)

      # Average: (5 + 4 + 5) / 3 = 4.67 → (4.67 / 5 * 100) ≈ 93
      assert result.score >= 90
      assert result.score <= 100
      assert result.total_responses == 3
      assert result.confidence == :low
    end

    test "applies exponential decay to older feedback", %{scope: scope} do
      # Create recent feedback (5 stars)
      {:ok, _recent} =
        Feedback.create_feedback_response(scope, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "Recent great feedback",
          "prompt_type" => "active"
        })

      # Create old feedback (1 star) - 60 days ago from different user
      # Give user2 positive feedback first to avoid anti-spam bias rule
      user2 = user_fixture()
      user2 = Repo.update!(Ecto.Changeset.change(user2, positive_feedback_count: 2))
      scope2 = Scope.for_user(user2)

      {:ok, old} =
        Feedback.create_feedback_response(scope2, %{
          "overall_satisfaction" => 1,
          "performance_rating" => 1,
          "open_feedback" => "Old bad feedback",
          "prompt_type" => "passive"
        })

      sixty_days_ago = DateTime.add(DateTime.utc_now(), -60, :day) |> DateTime.truncate(:second)
      Repo.update!(Ecto.Changeset.change(old, inserted_at: sixty_days_ago))

      result = Feedback.calculate_happiness_score(90)

      # Recent feedback should be weighted more heavily
      # Score should be closer to 100 than 50
      assert result.score > 75
      assert result.total_responses == 2
    end

    test "respects time window", %{scope: scope} do
      # Create feedback 100 days ago
      {:ok, old_feedback} =
        Feedback.create_feedback_response(scope, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "Old feedback",
          "prompt_type" => "active"
        })

      hundred_days_ago =
        DateTime.add(DateTime.utc_now(), -100, :day) |> DateTime.truncate(:second)

      Repo.update!(Ecto.Changeset.change(old_feedback, inserted_at: hundred_days_ago))

      # Query last 90 days
      result = Feedback.calculate_happiness_score(90)

      assert result.total_responses == 0
      assert result.score == 0
    end

    test "calculates confidence levels correctly", %{scope: scope} do
      # Use different users to avoid rate limiting
      users = for _ <- 1..15, do: user_fixture()

      # 2 responses = very_low
      Feedback.create_feedback_response(scope, %{
        "overall_satisfaction" => 5,
        "performance_rating" => 5,
        "open_feedback" => "Great",
        "prompt_type" => "active"
      })

      Feedback.create_feedback_response(Scope.for_user(Enum.at(users, 0)), %{
        "overall_satisfaction" => 4,
        "performance_rating" => 4,
        "open_feedback" => "Good",
        "prompt_type" => "active"
      })

      assert Feedback.calculate_happiness_score(90).confidence == :very_low

      # 5 responses total = low
      Feedback.create_feedback_response(Scope.for_user(Enum.at(users, 1)), %{
        "overall_satisfaction" => 5,
        "performance_rating" => 5,
        "open_feedback" => "Excellent",
        "prompt_type" => "passive"
      })

      Feedback.create_feedback_response(Scope.for_user(Enum.at(users, 2)), %{
        "overall_satisfaction" => 4,
        "performance_rating" => 4,
        "open_feedback" => "Nice",
        "prompt_type" => "passive"
      })

      Feedback.create_feedback_response(Scope.for_user(Enum.at(users, 3)), %{
        "overall_satisfaction" => 5,
        "performance_rating" => 5,
        "open_feedback" => "Perfect",
        "prompt_type" => "passive"
      })

      assert Feedback.calculate_happiness_score(90).confidence == :low

      # 15 responses = medium
      for i <- 4..13 do
        Feedback.create_feedback_response(Scope.for_user(Enum.at(users, i)), %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "Test #{i}",
          "prompt_type" => "active"
        })
      end

      assert Feedback.calculate_happiness_score(90).confidence == :medium
    end
  end

  describe "calculate_rank/1" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "calculates rank for new user with no activity", %{user: user} do
      assert {:ok, rank} = Feedback.calculate_rank(user)
      assert rank == 1
    end

    test "admin users use admin_flowers system" do
      admin = admin_fixture(%{admin_flowers: 3})

      assert {:ok, rank} = Feedback.calculate_rank(admin)
      # admin_flowers * 2
      assert rank == 6
    end

    test "stores rank history when rank changes", %{user: user} do
      # Calculate initial rank
      {:ok, _rank} = Feedback.calculate_rank(user)

      # Update user to have activity (simulate)
      user = Repo.update!(Ecto.Changeset.change(user, rank: 5))

      # Recalculate (this should create history)
      {:ok, new_rank} = Feedback.calculate_rank(user)

      # Check if history was created (if rank changed)
      if new_rank != 5 do
        history = Repo.get_by(RankHistory, user_id: user.id)
        assert history != nil
        assert history.old_rank == 5
        assert history.new_rank == new_rank
        assert is_map(history.calculation_details)
      end
    end
  end

  describe "should_show_prompt?/1" do
    test "shows prompt to new users after 7 days" do
      # User created 8 days ago
      user = user_fixture()
      eight_days_ago = DateTime.add(DateTime.utc_now(), -8, :day) |> DateTime.truncate(:second)
      user = Repo.update!(Ecto.Changeset.change(user, inserted_at: eight_days_ago))

      assert Feedback.should_show_prompt?(user) == true
    end

    test "does not show prompt to new users before 7 days" do
      # User created 5 days ago
      user = user_fixture()
      five_days_ago = DateTime.add(DateTime.utc_now(), -5, :day) |> DateTime.truncate(:second)
      user = Repo.update!(Ecto.Changeset.change(user, inserted_at: five_days_ago))

      assert Feedback.should_show_prompt?(user) == false
    end

    test "does not show prompt to opted-out users" do
      user = user_fixture()
      user = Repo.update!(Ecto.Changeset.change(user, feedback_prompt_preference: "opted_out"))
      assert Feedback.should_show_prompt?(user) == false
    end

    test "respects exponential backoff schedule" do
      # User with one previous feedback (7 days interval passed)
      user = user_fixture()
      fifteen_days_ago = DateTime.add(DateTime.utc_now(), -15, :day) |> DateTime.truncate(:second)
      eight_days_ago = DateTime.add(DateTime.utc_now(), -8, :day) |> DateTime.truncate(:second)

      user =
        Repo.update!(
          Ecto.Changeset.change(user,
            inserted_at: fifteen_days_ago,
            last_feedback_prompt_at: eight_days_ago
          )
        )

      assert Feedback.should_show_prompt?(user) == true
    end
  end

  describe "public testimonials" do
    setup do
      user = user_fixture()
      scope = Scope.for_user(user)

      {:ok, feedback} =
        Feedback.create_feedback_response(scope, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "Excellent app!",
          "prompt_type" => "active"
        })

      # Share it publicly
      {:ok, shared_feedback} = Feedback.share_feedback_publicly(scope, feedback.id)

      %{user: user, scope: scope, feedback: shared_feedback}
    end

    test "get_testimonial_by_token/1 returns feedback with valid token", %{feedback: feedback} do
      result = Feedback.get_testimonial_by_token(feedback.share_token)
      assert result.id == feedback.id
    end

    test "get_testimonial_by_token/1 returns nil for invalid token" do
      assert Feedback.get_testimonial_by_token("invalid-token") == nil
    end

    test "get_testimonial_by_token/1 only returns publicly shared feedback" do
      # Create new user to avoid rate limiting
      user = user_fixture()
      scope = Scope.for_user(user)

      # Create feedback that's not shared
      {:ok, private_feedback} =
        Feedback.create_feedback_response(scope, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "Private feedback",
          "prompt_type" => "passive"
        })

      assert Feedback.get_testimonial_by_token(private_feedback.share_token) == nil
    end

    test "share_feedback_publicly/2 makes feedback public", %{scope: scope, feedback: feedback} do
      assert {:ok, updated} = Feedback.share_feedback_publicly(scope, feedback.id)
      assert updated.shared_publicly == true
      assert updated.share_token != nil
    end

    test "list_public_testimonials/1 only returns approved testimonials by default", %{
      scope: scope,
      feedback: feedback
    } do
      # Share and approve the feedback
      {:ok, shared} = Feedback.share_feedback_publicly(scope, feedback.id)

      # Should not appear without approval
      assert Enum.empty?(Feedback.list_public_testimonials())

      # Approve it (need admin scope)
      admin = user_fixture(%{role: "admin"})
      admin_scope = Scope.for_user(admin) |> Map.put(:admin_override?, true)
      {:ok, _approved} = Feedback.approve_testimonial(admin_scope, shared.id)

      # Now should appear
      testimonials = Feedback.list_public_testimonials()
      assert length(testimonials) == 1
      assert hd(testimonials).id == shared.id
    end
  end

  describe "admin functions" do
    setup do
      admin = user_fixture(%{role: "admin"})
      user = user_fixture()
      admin_scope = Scope.for_user(admin) |> Map.put(:admin_override?, true)
      user_scope = Scope.for_user(user)

      %{admin_scope: admin_scope, user_scope: user_scope, user: user}
    end

    test "list_feedback_responses/2 requires admin access", %{user_scope: user_scope} do
      assert_raise RuntimeError, "Unauthorized: Admin access required", fn ->
        Feedback.list_feedback_responses(user_scope)
      end
    end

    test "list_feedback_responses/2 returns all feedback for admins", %{
      admin_scope: admin_scope,
      user_scope: user_scope
    } do
      # Create some feedback from different users to avoid rate limiting
      user2 = user_fixture()
      scope2 = Scope.for_user(user2)

      Feedback.create_feedback_response(user_scope, %{
        "overall_satisfaction" => 5,
        "performance_rating" => 5,
        "open_feedback" => "Great",
        "prompt_type" => "active"
      })

      Feedback.create_feedback_response(scope2, %{
        "overall_satisfaction" => 3,
        "performance_rating" => 3,
        "open_feedback" => "Okay",
        "prompt_type" => "passive"
      })

      responses = Feedback.list_feedback_responses(admin_scope)
      assert length(responses) == 2
    end

    test "approve_testimonial/2 requires admin access", %{user_scope: user_scope} do
      assert_raise RuntimeError, "Unauthorized: Admin access required", fn ->
        Feedback.approve_testimonial(user_scope, 1)
      end
    end

    test "approve_testimonial/2 marks testimonial as approved", %{
      admin_scope: admin_scope,
      user_scope: user_scope
    } do
      {:ok, feedback} =
        Feedback.create_feedback_response(user_scope, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "To be approved",
          "prompt_type" => "active"
        })

      {:ok, shared} = Feedback.share_feedback_publicly(user_scope, feedback.id)

      {:ok, approved} = Feedback.approve_testimonial(admin_scope, shared.id)

      assert approved.testimonial_approved == true
      assert approved.approved_by_user_id == admin_scope.user.id
      assert approved.approved_at != nil
    end

    test "get_feedback_analytics/2 returns comprehensive stats", %{
      admin_scope: admin_scope,
      user_scope: user_scope
    } do
      # Create some feedback from different users to avoid rate limiting
      user2 = user_fixture()
      scope2 = Scope.for_user(user2)
      user3 = user_fixture()
      scope3 = Scope.for_user(user3)

      Feedback.create_feedback_response(user_scope, %{
        "overall_satisfaction" => 5,
        "performance_rating" => 5,
        "open_feedback" => "Excellent",
        "prompt_type" => "active"
      })

      Feedback.create_feedback_response(scope2, %{
        "overall_satisfaction" => 4,
        "performance_rating" => 4,
        "open_feedback" => "Good",
        "prompt_type" => "passive"
      })

      Feedback.create_feedback_response(scope3, %{
        "overall_satisfaction" => 5,
        "performance_rating" => 5,
        "open_feedback" => "Great",
        "prompt_type" => "active"
      })

      analytics = Feedback.get_feedback_analytics(admin_scope, 90)

      assert analytics.total_responses == 3
      assert analytics.avg_rating >= 4.0
      assert analytics.avg_rating <= 5.0
      assert is_map(analytics.happiness)
      assert is_list(analytics.by_rank)
    end
  end
end
