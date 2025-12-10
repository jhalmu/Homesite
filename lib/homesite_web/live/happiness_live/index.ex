defmodule HomesiteWeb.HappinessLive.Index do
  @moduledoc """
  Public happiness meter page showing overall site satisfaction.

  Displays:
  - Animated SVG happiness meter (sun for ≥60, thermometer for <60)
  - Public testimonials grid
  - Feedback link for authenticated users
  """
  use HomesiteWeb, :live_view

  alias Homesite.Feedback
  import HomesiteWeb.Helpers.DateHelpers

  @impl true
  def mount(_params, _session, socket) do
    # Calculate happiness score (90-day rolling window)
    happiness = Feedback.calculate_happiness_score(90)

    # Get public testimonials (approved only)
    testimonials = Feedback.list_public_testimonials(limit: 6)

    {:ok,
     socket
     |> assign(:page_title, gettext("Happiness Meter"))
     |> assign(:happiness, happiness)
     |> assign(:testimonials, testimonials)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="px-[var(--spacing-card)] py-[var(--spacing-xl)] min-h-screen">
        <%!-- Header --%>
        <div class="mb-[var(--space-2xl)] text-center">
          <h1 class="mb-[var(--space-sm)] text-4xl font-bold">{gettext("Happiness Meter")}</h1>
          <p class="text-base-content/70 text-[var(--text-lg)] mx-auto max-w-2xl">
            {gettext("See how our community feels about Homesite based on real user feedback")}
          </p>
        </div>

        <%!-- Happiness Meter (Main Visual) --%>
        <div class="mb-[var(--space-2xl)] flex justify-center">
          <div class="card bg-base-200 w-full max-w-md shadow-xl">
            <div class="card-body items-center text-center">
              <%!-- SVG Animation --%>
              <%= if @happiness.score >= 60 do %>
                <%!-- Happy State: Sun --%>
                <.sun_meter score={@happiness.score} />
              <% else %>
                <%!-- Needs Improvement: Thermometer --%>
                <.thermometer_meter score={@happiness.score} />
              <% end %>

              <%!-- Score Display --%>
              <div class="mt-[var(--space-md)]">
                <div class="text-primary text-[var(--text-5xl)] font-bold">
                  {@happiness.score}%
                </div>
                <div class="text-base-content/70 mt-[var(--space-xs)] text-[var(--text-lg)]">
                  {gettext("Overall Satisfaction")}
                </div>
              </div>

              <%!-- Stats --%>
              <div class="stats stats-vertical mt-[var(--space-md)] shadow lg:stats-horizontal">
                <div class="stat">
                  <div class="stat-title">{gettext("Responses")}</div>
                  <div class="stat-value text-[var(--text-2xl)]">{@happiness.total_responses}</div>
                  <div class="stat-desc">{gettext("Last 90 days")}</div>
                </div>

                <div class="stat">
                  <div class="stat-title">{gettext("Confidence")}</div>
                  <div class="stat-value text-[var(--text-2xl)]">
                    {confidence_emoji(@happiness.confidence)}
                  </div>
                  <div class="stat-desc">{confidence_text(@happiness.confidence)}</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <%!-- Public Testimonials --%>
        <%= if length(@testimonials) > 0 do %>
          <div class="mb-[var(--space-2xl)]">
            <h2 class="mb-[var(--space-lg)] text-center text-3xl font-bold">
              {gettext("What Users Are Saying")}
            </h2>

            <div class="gap-[var(--space-md)] grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
              <%= for testimonial <- @testimonials do %>
                <div class="card bg-base-100 shadow-xl">
                  <div class="card-body">
                    <%!-- Star Rating --%>
                    <div class="rating rating-sm mb-[var(--space-xs)]">
                      <%= for star <- 1..5 do %>
                        <%= if star <= testimonial.overall_satisfaction do %>
                          <span class="text-orange-400">⭐</span>
                        <% else %>
                          <span class="text-base-content/20">⭐</span>
                        <% end %>
                      <% end %>
                    </div>

                    <%!-- Feedback Text --%>
                    <%= if testimonial.open_feedback do %>
                      <p class="text-base-content/80">
                        "{testimonial.open_feedback}"
                      </p>
                    <% end %>

                    <%!-- User Info --%>
                    <div class="text-base-content/60 mt-[var(--space-sm)] gap-[var(--space-xs)] text-[var(--text-sm)] flex items-center">
                      <div class="avatar placeholder">
                        <div class="bg-neutral text-neutral-content w-8 rounded-full">
                          <span class="text-[var(--text-xs)]">
                            {get_initial(testimonial)}
                          </span>
                        </div>
                      </div>
                      <div>
                        <div class="font-semibold">{get_user_name(testimonial)}</div>
                        <div class="text-[var(--text-xs)]">
                          {format_date(testimonial.inserted_at)}
                        </div>
                      </div>
                    </div>

                    <%!-- Share Link --%>
                    <%= if testimonial.share_token do %>
                      <div class="card-actions mt-[var(--space-xs)] justify-end">
                        <.link
                          navigate={~p"/testimonials/#{testimonial.share_token}"}
                          class="link link-primary text-[var(--text-xs)]"
                        >
                          {gettext("View full testimonial")} →
                        </.link>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>

        <%!-- Call to Action --%>
        <div class="mb-[var(--space-2xl)] text-center">
          <div class="card from-primary/10 to-secondary/10 mx-auto max-w-2xl bg-gradient-to-r shadow-xl">
            <div class="card-body">
              <h3 class="card-title mb-[var(--space-sm)] text-[var(--text-2xl)] justify-center">
                {gettext("How can we do better?")}
              </h3>
              <p class="text-base-content/70 mb-[var(--space-md)]">
                {gettext(
                  "Your feedback helps us improve. Share your thoughts and help shape the future of Homesite."
                )}
              </p>

              <%= if @current_scope do %>
                <div class="card-actions justify-center">
                  <.link navigate={~p"/feedback"} class="btn btn-primary btn-lg">
                    <.icon name="hero-chat-bubble-left-right" /> {gettext("Share Your Feedback")}
                  </.link>
                </div>
              <% else %>
                <div class="card-actions justify-center">
                  <.link navigate={~p"/users/log-in"} class="btn btn-primary btn-lg">
                    {gettext("Log in to share feedback")}
                  </.link>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # SVG Components

  defp sun_meter(assigns) do
    ~H"""
    <svg viewBox="0 0 200 200" class="h-48 w-48">
      <defs>
        <radialGradient id="sunGradient">
          <stop offset="0%" stop-color="#FFD700" />
          <stop offset="100%" stop-color="#FFA500" />
        </radialGradient>
      </defs>

      <%!-- Animated Rays --%>
      <%= for i <- 0..11 do %>
        <% angle = i * 30
        rad = angle * :math.pi() / 180
        x1 = 100 + 70 * :math.cos(rad)
        y1 = 100 + 70 * :math.sin(rad)
        x2 = 100 + 90 * :math.cos(rad)
        y2 = 100 + 90 * :math.sin(rad) %>
        <line
          x1={x1}
          y1={y1}
          x2={x2}
          y2={y2}
          stroke="#FFA500"
          stroke-width="3"
          stroke-linecap="round"
          class="motion-safe:animate-pulse"
          style={"animation-delay: #{i * 0.1}s"}
        />
      <% end %>

      <%!-- Sun Circle --%>
      <circle cx="100" cy="100" r="50" fill="url(#sunGradient)" />

      <%!-- Smiley Face --%>
      <circle cx="85" cy="90" r="5" fill="#FF8C00" />
      <circle cx="115" cy="90" r="5" fill="#FF8C00" />
      <path
        d="M 75 105 Q 100 120 125 105"
        stroke="#FF8C00"
        stroke-width="4"
        fill="none"
        stroke-linecap="round"
      />
    </svg>
    """
  end

  defp thermometer_meter(assigns) do
    ~H"""
    <svg viewBox="0 0 200 200" class="h-48 w-48">
      <defs>
        <linearGradient id="thermGradient" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stop-color="#60A5FA" />
          <stop offset="100%" stop-color="#3B82F6" />
        </linearGradient>
      </defs>

      <%!-- Thermometer Body --%>
      <rect
        x="85"
        y="40"
        width="30"
        height="120"
        rx="15"
        fill="#E5E7EB"
        stroke="#9CA3AF"
        stroke-width="2"
      />

      <%!-- Mercury Level --%>
      <% mercury_height = 120 * @score / 100
      mercury_y = 40 + (120 - mercury_height) %>
      <rect
        x="85"
        y={mercury_y}
        width="30"
        height={mercury_height}
        rx="15"
        fill="url(#thermGradient)"
      />

      <%!-- Bulb --%>
      <circle cx="100" cy="170" r="20" fill="url(#thermGradient)" stroke="#3B82F6" stroke-width="2" />

      <%!-- Scale Marks --%>
      <%= for i <- 0..4 do %>
        <% y = 50 + i * 25 %>
        <line x1="115" y1={y} x2="125" y2={y} stroke="#9CA3AF" stroke-width="2" />
        <text x="130" y={y + 5} font-size="12" fill="#6B7280">{100 - i * 25}%</text>
      <% end %>
    </svg>
    """
  end

  # Helper Functions

  defp confidence_emoji(:none), do: "?"
  defp confidence_emoji(:very_low), do: "📊"
  defp confidence_emoji(:low), do: "📈"
  defp confidence_emoji(:medium), do: "✓"
  defp confidence_emoji(:high), do: "✓✓"
  defp confidence_emoji(_), do: "?"

  defp confidence_text(:none), do: gettext("No data")
  defp confidence_text(:very_low), do: gettext("Very low")
  defp confidence_text(:low), do: gettext("Low")
  defp confidence_text(:medium), do: gettext("Medium")
  defp confidence_text(:high), do: gettext("High")
  defp confidence_text(_), do: gettext("Unknown")

  defp get_initial(testimonial) do
    cond do
      testimonial.user && testimonial.user.display_name ->
        String.first(testimonial.user.display_name) |> String.upcase()

      testimonial.user && testimonial.user.email ->
        String.first(testimonial.user.email) |> String.upcase()

      true ->
        "U"
    end
  end

  defp get_user_name(testimonial) do
    cond do
      testimonial.user && testimonial.user.display_name ->
        testimonial.user.display_name

      testimonial.user && testimonial.user.email ->
        String.split(testimonial.user.email, "@") |> hd()

      true ->
        gettext("Anonymous User")
    end
  end
end
