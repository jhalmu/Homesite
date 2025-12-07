defmodule HomesiteWeb.AdminLive.Feedback.Index do
  @moduledoc """
  Admin dashboard for feedback analytics and testimonial moderation.

  Displays:
  - Happiness score and trends
  - Total responses and response rate
  - Pending testimonials for moderation
  - Recent feedback submissions
  - Response rate by user rank
  """
  use HomesiteWeb, :live_view

  alias Homesite.Feedback
  import HomesiteWeb.Gettext

  @impl true
  def mount(_params, _session, socket) do
    # Verify admin access
    unless socket.assigns.current_scope && socket.assigns.current_scope.admin_override? do
      {:ok,
       socket
       |> put_flash(:error, gettext("You must be an admin to access this page."))
       |> push_navigate(to: ~p"/")}
    else
      {:ok,
       socket
       |> assign(:hide_feedback_modal, true)
       |> load_analytics()}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    days = String.to_integer(params["days"] || "90")
    {:noreply, socket |> assign(:days, days) |> load_analytics()}
  end

  @impl true
  def handle_event("approve_testimonial", %{"id" => id}, socket) do
    feedback_id = String.to_integer(id)

    case Feedback.approve_testimonial(socket.assigns.current_scope, feedback_id) do
      {:ok, _feedback} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Testimonial approved and now visible publicly."))
         |> load_analytics()}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to approve testimonial."))}
    end
  end

  def handle_event("unapprove_testimonial", %{"id" => id}, socket) do
    feedback_id = String.to_integer(id)

    case Feedback.unapprove_testimonial(socket.assigns.current_scope, feedback_id) do
      {:ok, _feedback} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Testimonial unapproved."))
         |> load_analytics()}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to unapprove testimonial."))}
    end
  end

  def handle_event("filter_days", %{"days" => days}, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/feedback?days=#{days}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="px-[var(--spacing-card)] py-[var(--spacing-xl)] min-h-screen">
        <%!-- Header --%>
        <div class="mb-[var(--space-sm)]">
          <h1 class="mb-[var(--space-xs)] text-4xl font-bold">{gettext("Feedback Analytics")}</h1>
          <p class="text-base-content/70">
            {gettext("Monitor user feedback, happiness trends, and moderate testimonials")}
          </p>
        </div>

        <%!-- Time Range Selector --%>
        <div class="mb-[var(--space-sm)]">
          <div class="join">
            <button
              phx-click="filter_days"
              phx-value-days="30"
              class={"#{if @days == 30, do: "btn-active", else: ""} btn join-item"}
            >
              {gettext("30 Days")}
            </button>
            <button
              phx-click="filter_days"
              phx-value-days="90"
              class={"#{if @days == 90, do: "btn-active", else: ""} btn join-item"}
            >
              {gettext("90 Days")}
            </button>
            <button
              phx-click="filter_days"
              phx-value-days="365"
              class={"#{if @days == 365, do: "btn-active", else: ""} btn join-item"}
            >
              {gettext("1 Year")}
            </button>
          </div>
        </div>

        <%!-- Summary Stats --%>
        <div class="mb-[var(--space-sm)] grid grid-cols-1 gap-[var(--space-sm)] md:grid-cols-3">
          <%!-- Happiness Score Card --%>
          <div class="card bg-base-200 shadow-xl">
            <div class="card-body">
              <h2 class="card-title text-[var(--text-sm)]">{gettext("Happiness Score")}</h2>
              <div class="text-primary text-4xl font-bold">
                {@analytics.happiness.score}%
              </div>
              <p class="text-base-content/60 text-[var(--text-sm)]">
                {confidence_text(@analytics.happiness.confidence)}
              </p>
            </div>
          </div>

          <%!-- Total Responses Card --%>
          <div class="card bg-base-200 shadow-xl">
            <div class="card-body">
              <h2 class="card-title text-[var(--text-sm)]">{gettext("Total Responses")}</h2>
              <div class="text-secondary text-4xl font-bold">
                {@analytics.happiness.total_responses}
              </div>
              <p class="text-base-content/60 text-[var(--text-sm)]">
                {gettext("Last")} {@days} {gettext("days")}
              </p>
            </div>
          </div>

          <%!-- Pending Testimonials Card --%>
          <div class="card bg-base-200 shadow-xl">
            <div class="card-body">
              <h2 class="card-title text-[var(--text-sm)]">{gettext("Pending Approval")}</h2>
              <div class="text-warning text-4xl font-bold">
                {length(@pending_testimonials)}
              </div>
              <p class="text-base-content/60 text-[var(--text-sm)]">
                {gettext("Testimonials awaiting review")}
              </p>
            </div>
          </div>
        </div>

        <%!-- Happiness Trend Chart (Simplified) --%>
        <div class="card bg-base-200 mb-[var(--space-sm)] shadow-xl">
          <div class="card-body">
            <h2 class="card-title">{gettext("Happiness Trend")}</h2>

            <%= if length(@analytics.trend) > 0 do %>
              <div class="overflow-x-auto">
                <table class="table-sm table">
                  <thead>
                    <tr>
                      <th>{gettext("Date")}</th>
                      <th>{gettext("Score")}</th>
                      <th>{gettext("Responses")}</th>
                      <th>{gettext("Visual")}</th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= for point <- @analytics.trend do %>
                      <tr>
                        <td>{point.date}</td>
                        <td>{point.score}%</td>
                        <td>{point.count}</td>
                        <td>
                          <progress
                            class="progress progress-primary w-32"
                            value={point.score}
                            max="100"
                          >
                          </progress>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            <% else %>
              <p class="text-base-content/60">{gettext("No trend data available")}</p>
            <% end %>
          </div>
        </div>

        <%!-- Response Rate by Rank --%>
        <div class="card bg-base-200 mb-[var(--space-sm)] shadow-xl">
          <div class="card-body">
            <h2 class="card-title">{gettext("Response Rate by User Rank")}</h2>

            <%= if length(@analytics.by_rank) > 0 do %>
              <div class="overflow-x-auto">
                <table class="table-sm table">
                  <thead>
                    <tr>
                      <th>{gettext("Rank")}</th>
                      <th>{gettext("Responses")}</th>
                      <th>{gettext("Avg Rating")}</th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= for rank_stat <- @analytics.by_rank do %>
                      <tr>
                        <td>{rank_stat.rank}</td>
                        <td>{rank_stat.count}</td>
                        <td>
                          <div class="flex items-center gap-1">
                            {Float.round(rank_stat.avg_rating, 1)}
                            <span class="text-orange-400">⭐</span>
                          </div>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            <% else %>
              <p class="text-base-content/60">{gettext("No rank data available")}</p>
            <% end %>
          </div>
        </div>

        <%!-- Pending Testimonials (Moderation) --%>
        <%= if length(@pending_testimonials) > 0 do %>
          <div class="card bg-base-200 mb-[var(--space-sm)] shadow-xl">
            <div class="card-body">
              <h2 class="card-title">{gettext("Pending Testimonials")}</h2>
              <p class="text-base-content/60 mb-[var(--space-sm)] text-[var(--text-sm)]">
                {gettext("Review and approve testimonials for public display")}
              </p>

              <div class="space-y-[var(--space-sm)]">
                <%= for testimonial <- @pending_testimonials do %>
                  <div class="card bg-base-100 shadow">
                    <div class="card-body">
                      <%!-- Rating --%>
                      <div class="mb-[var(--space-xs)] flex items-center gap-[var(--space-xs)]">
                        <%= for _star <- 1..testimonial.overall_satisfaction do %>
                          <span class="text-orange-400">⭐</span>
                        <% end %>
                        <span class="text-base-content/60 text-[var(--text-sm)]">
                          {Calendar.strftime(testimonial.inserted_at, "%B %d, %Y")}
                        </span>
                      </div>

                      <%!-- Feedback Text --%>
                      <%= if testimonial.open_feedback do %>
                        <blockquote class="border-primary mb-[var(--space-sm)] border-l-4 pl-4">
                          "{testimonial.open_feedback}"
                        </blockquote>
                      <% end %>

                      <%!-- User Info --%>
                      <div class="mb-[var(--space-sm)] flex items-center gap-[var(--space-xs)] text-[var(--text-sm)]">
                        <%= if testimonial.user do %>
                          <span class="font-semibold">
                            {testimonial.user.display_name || testimonial.user.email}
                          </span>
                          <span class="badge badge-sm">
                            {gettext("Rank")} {testimonial.user_rank_at_time || 1}
                          </span>
                        <% end %>
                      </div>

                      <%!-- Actions --%>
                      <div class="card-actions justify-end">
                        <button
                          phx-click="approve_testimonial"
                          phx-value-id={testimonial.id}
                          data-section="pending"
                          class="btn btn-sm btn-success"
                        >
                          <.icon name="hero-check" /> {gettext("Approve")}
                        </button>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>

        <%!-- Recent Feedback --%>
        <div class="card bg-base-200 shadow-xl">
          <div class="card-body">
            <h2 class="card-title">{gettext("Recent Feedback")}</h2>

            <%= if length(@recent_feedback) > 0 do %>
              <div class="overflow-x-auto">
                <table class="table-sm table">
                  <thead>
                    <tr>
                      <th>{gettext("Date")}</th>
                      <th>{gettext("User")}</th>
                      <th>{gettext("Rating")}</th>
                      <th>{gettext("Type")}</th>
                      <th>{gettext("Shared")}</th>
                      <th>{gettext("Actions")}</th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= for feedback <- @recent_feedback do %>
                      <tr>
                        <td>{Calendar.strftime(feedback.inserted_at, "%m/%d")}</td>
                        <td>
                          <%= if feedback.user do %>
                            <span class="text-sm">
                              {feedback.user.display_name ||
                                String.split(feedback.user.email, "@") |> hd()}
                            </span>
                          <% end %>
                        </td>
                        <td>
                          <div class="flex items-center gap-[var(--space-inline)]">
                            {feedback.overall_satisfaction}
                            <span class="text-orange-400">⭐</span>
                          </div>
                        </td>
                        <td>
                          <span class="badge badge-sm">
                            {feedback.prompt_type}
                          </span>
                        </td>
                        <td>
                          <%= if feedback.shared_publicly do %>
                            <span class="badge badge-success badge-sm">{gettext("Yes")}</span>
                          <% else %>
                            <span class="badge badge-ghost badge-sm">{gettext("No")}</span>
                          <% end %>
                        </td>
                        <td>
                          <%= if feedback.shared_publicly && !feedback.testimonial_approved do %>
                            <button
                              phx-click="approve_testimonial"
                              phx-value-id={feedback.id}
                              data-section="recent"
                              class="btn btn-xs btn-primary"
                            >
                              {gettext("Approve")}
                            </button>
                          <% else %>
                            <%= if feedback.testimonial_approved do %>
                              <button
                                phx-click="unapprove_testimonial"
                                phx-value-id={feedback.id}
                                class="btn btn-xs btn-warning"
                              >
                                {gettext("Unapprove")}
                              </button>
                            <% end %>
                          <% end %>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            <% else %>
              <p class="text-base-content/60">{gettext("No recent feedback")}</p>
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # Private Functions

  defp load_analytics(socket) do
    days = socket.assigns[:days] || 90
    scope = socket.assigns.current_scope

    # Get analytics data
    analytics = Feedback.get_feedback_analytics(scope, days)

    # Get pending testimonials for moderation
    pending = Feedback.list_pending_testimonials(scope)

    # Get recent feedback
    recent = Feedback.list_feedback_responses(scope, limit: 50, order: :desc)

    socket
    |> assign(:analytics, analytics)
    |> assign(:pending_testimonials, pending)
    |> assign(:recent_feedback, recent)
    |> assign(:page_title, gettext("Feedback Analytics"))
  end

  defp confidence_text(:none), do: gettext("No data")
  defp confidence_text(:very_low), do: gettext("Very low confidence")
  defp confidence_text(:low), do: gettext("Low confidence")
  defp confidence_text(:medium), do: gettext("Medium confidence")
  defp confidence_text(:high), do: gettext("High confidence")
  defp confidence_text(_), do: gettext("Unknown")
end
