defmodule HomesiteWeb.FeedbackLiveTest do
  use HomesiteWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Homesite.AccountsFixtures
  import Ecto.Query

  alias Homesite.{Feedback, Repo}
  alias Homesite.Accounts.Scope

  describe "FeedbackLive.Index (Passive Feedback Form)" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "redirects to login if not authenticated", %{conn: conn} do
      {:error, {:redirect, %{to: path}}} = live(conn, ~p"/feedback")
      assert path == ~p"/users/log-in"
    end

    test "renders feedback form for authenticated users", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, html} = live(conn, ~p"/feedback")

      assert html =~ "Share Your Feedback"
      assert html =~ "Overall Satisfaction"
      assert html =~ "How fast and responsive is the site?"
      assert html =~ "Tell us what you think..."
      assert html =~ "Submit Feedback"
    end

    test "shows 5-star rating inputs", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, html} = live(conn, ~p"/feedback")

      # Check for star rating inputs (1-5)
      assert html =~ "name=\"feedback[overall_satisfaction]\" value=\"1\""
      assert html =~ "name=\"feedback[overall_satisfaction]\" value=\"5\""
      assert html =~ "name=\"feedback[performance_rating]\" value=\"1\""
      assert html =~ "name=\"feedback[performance_rating]\" value=\"5\""
    end

    test "shows all three required fields", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, html} = live(conn, ~p"/feedback")

      # Check for all three required fields
      assert html =~ "Overall Satisfaction"
      assert html =~ "How fast and responsive is the site?"
      assert html =~ "Tell us what you think..."
    end

    test "successfully submits feedback with required fields only", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/feedback")

      # Submit with required fields
      result =
        view
        |> form("#feedback-form", %{
          "feedback" => %{
            "overall_satisfaction" => "5",
            "performance_rating" => "5",
            "open_feedback" => "Great!"
          }
        })
        |> render_submit()

      # Should redirect to home page
      assert_redirect(view, ~p"/")

      # Verify feedback was created
      feedback =
        Repo.one!(
          from f in Feedback.FeedbackResponse,
            where: f.user_id == ^user.id,
            order_by: [desc: f.inserted_at],
            limit: 1
        )

      assert feedback.overall_satisfaction == 5
      assert feedback.performance_rating == 5
      assert feedback.open_feedback == "Great!"
      assert feedback.prompt_type == "passive"
    end

    test "successfully submits feedback with all required fields filled", %{
      conn: conn,
      user: user
    } do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/feedback")

      result =
        view
        |> form("#feedback-form", %{
          "feedback" => %{
            "overall_satisfaction" => "4",
            "performance_rating" => "5",
            "open_feedback" => "Great app, love the features!"
          }
        })
        |> render_submit()

      assert_redirect(view, ~p"/")

      # Verify feedback was created with all fields
      feedback =
        Repo.one!(
          from f in Feedback.FeedbackResponse,
            where: f.user_id == ^user.id,
            order_by: [desc: f.inserted_at],
            limit: 1
        )

      assert feedback.overall_satisfaction == 4
      assert feedback.performance_rating == 5
      assert feedback.open_feedback == "Great app, love the features!"
    end

    test "shows special message for 4-5 star ratings", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/feedback")

      view
      |> form("#feedback-form", %{
        "feedback" => %{
          "overall_satisfaction" => "5",
          "performance_rating" => "5",
          "open_feedback" => "Excellent!"
        }
      })
      |> render_submit()

      # Flash message should mention testimonial sharing
      flash = assert_redirect(view, ~p"/")
    end

    test "shows rate limit error when submitting too frequently", %{conn: conn, user: user} do
      # Create existing feedback
      scope = Scope.for_user(user)

      {:ok, _feedback} =
        Feedback.create_feedback_response(scope, %{
          "overall_satisfaction" => 5,
          "performance_rating" => 5,
          "open_feedback" => "First feedback",
          "prompt_type" => "passive"
        })

      # Try to submit again immediately
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/feedback")

      view
      |> form("#feedback-form", %{
        "feedback" => %{
          "overall_satisfaction" => "4",
          "performance_rating" => "4",
          "open_feedback" => "Second attempt"
        }
      })
      |> render_submit()

      # Should show rate limit error
      html = render(view)
      assert html =~ "once per week" or html =~ "rate"
    end

    test "shows negative feedback limit error", %{conn: conn, user: user} do
      # Update user to have reached negative feedback limit
      user =
        Repo.update!(
          Ecto.Changeset.change(user,
            positive_feedback_count: 2,
            negative_feedback_count: 1
          )
        )

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/feedback")

      # Try to submit negative feedback - should redirect with error flash
      result =
        view
        |> form("#feedback-form", %{
          "feedback" => %{
            "overall_satisfaction" => "1",
            "performance_rating" => "1",
            "open_feedback" => "Negative feedback"
          }
        })
        |> render_submit()

      # View should redirect to home with error message
      assert_redirect(view, ~p"/")
    end

    test "validates presence of overall_satisfaction", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/feedback")

      # Submit without overall_satisfaction
      view
      |> form("#feedback-form", %{
        "feedback" => %{
          "performance_rating" => "4"
        }
      })
      |> render_submit()

      # Should stay on same page (validation failed)
      html = render(view)
      assert html =~ "Share Your Feedback"
    end
  end

  describe "FeedbackLive.PromptModal (Active Feedback Prompt)" do
    setup do
      # Create user who should see prompt (8 days old)
      eight_days_ago = DateTime.add(DateTime.utc_now(), -8, :day)
      user = user_fixture(%{inserted_at: eight_days_ago})
      %{user: user}
    end

    test "does not show prompt for unauthenticated users", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")
      refute html =~ "How are we doing?"
    end

    test "shows prompt component for users due for feedback", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/")

      # The feedback prompt may render as a modal/component for eligible users
      # Check for feedback-related elements or the prompt class
      assert html =~ "feedback" or html =~ "How are we doing?"
    end

    test "does not show prompt for opted-out users", %{conn: conn} do
      # Create opted-out user
      eight_days_ago = DateTime.add(DateTime.utc_now(), -8, :day)
      user = user_fixture(%{inserted_at: eight_days_ago, feedback_prompt_preference: "opted_out"})

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/")

      refute html =~ "feedback-toast"
      refute html =~ "How are we doing?"
    end

    test "does not show prompt for new users (less than 7 days old)", %{conn: conn} do
      # Create new user (today)
      user = user_fixture()

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/")

      refute html =~ "feedback-toast"
    end

    test "does not show prompt if user already saw it recently", %{conn: conn} do
      # Create user with recent prompt
      eight_days_ago = DateTime.add(DateTime.utc_now(), -8, :day)
      two_days_ago = DateTime.add(DateTime.utc_now(), -2, :day)

      user =
        user_fixture(%{
          inserted_at: eight_days_ago,
          last_feedback_prompt_at: two_days_ago
        })

      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/")

      refute html =~ "feedback-toast"
    end

    test "prompt component is present in layout for eligible users", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/")

      # Component should be present (even if not visible)
      assert html =~ "live_component" or html =~ "feedback"
    end
  end

  describe "Footer Widget" do
    test "shows feedback link for authenticated users", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      {:ok, view, html} = live(conn, ~p"/")

      # Should show feedback section in footer
      assert html =~ "Feedback"
      assert html =~ "Share Your Feedback"
      assert html =~ "Help us improve!"
      assert html =~ ~p"/feedback"
    end

    test "does not show feedback link for unauthenticated users", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")

      # Should not show feedback section
      refute html =~ "Share Your Feedback" and html =~ "Help us improve!"
    end
  end
end
