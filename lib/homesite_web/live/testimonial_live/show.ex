defmodule HomesiteWeb.TestimonialLive.Show do
  @moduledoc """
  Public page for viewing a single shared testimonial.

  Accessed via /testimonials/:token for publicly shared feedback.
  Includes social sharing buttons and link back to happiness meter.
  """
  use HomesiteWeb, :live_view

  alias Homesite.Feedback
  import HomesiteWeb.Gettext

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    case Feedback.get_testimonial_by_token(token) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, gettext("Testimonial not found or not publicly shared."))
         |> push_navigate(to: ~p"/happiness")}

      testimonial ->
        {:ok,
         socket
         |> assign(:page_title, gettext("User Testimonial"))
         |> assign(:testimonial, testimonial)
         |> assign(:share_url, url(socket, ~p"/testimonials/#{token}"))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen px-[var(--spacing-card)] py-[var(--spacing-xl)]">
        <div class="max-w-3xl mx-auto">
          <%!-- Back Link --%>
          <div class="mb-8">
            <.link navigate={~p"/happiness"} class="link link-primary">
              ← {gettext("Back to Happiness Meter")}
            </.link>
          </div>

          <%!-- Testimonial Card --%>
          <div class="card bg-gradient-to-br from-base-100 to-base-200 shadow-2xl">
            <div class="card-body">
              <%!-- Header --%>
              <div class="flex items-start justify-between mb-6">
                <div>
                  <h1 class="text-3xl font-bold mb-2">{gettext("User Testimonial")}</h1>
                  <p class="text-base-content/60">
                    {gettext("Shared on")} {Calendar.strftime(@testimonial.inserted_at, "%B %d, %Y")}
                  </p>
                </div>

                <%!-- Star Rating --%>
                <div class="rating rating-lg">
                  <%= for star <- 1..5 do %>
                    <%= if star <= @testimonial.overall_satisfaction do %>
                      <span class="text-orange-400 text-4xl">⭐</span>
                    <% else %>
                      <span class="text-base-content/20 text-4xl">⭐</span>
                    <% end %>
                  <% end %>
                </div>
              </div>

              <div class="divider"></div>

              <%!-- Feedback Content --%>
              <%= if @testimonial.open_feedback do %>
                <div class="mb-6">
                  <h2 class="text-xl font-semibold mb-3">{gettext("What they said:")}</h2>
                  <blockquote class="text-lg text-base-content/90 italic border-l-4 border-primary pl-4">
                    "{@testimonial.open_feedback}"
                  </blockquote>
                </div>
              <% end %>

              <%!-- Additional Ratings --%>
              <%= if @testimonial.performance_rating do %>
                <div class="mb-6">
                  <h3 class="text-lg font-semibold mb-2">{gettext("Performance Rating")}</h3>
                  <div class="rating rating-md">
                    <%= for star <- 1..5 do %>
                      <%= if star <= @testimonial.performance_rating do %>
                        <span class="text-blue-400">⭐</span>
                      <% else %>
                        <span class="text-base-content/20">⭐</span>
                      <% end %>
                    <% end %>
                  </div>
                </div>
              <% end %>

              <%!-- Useful Features --%>
              <%= if @testimonial.feature_usefulness && map_size(@testimonial.feature_usefulness) > 0 do %>
                <div class="mb-6">
                  <h3 class="text-lg font-semibold mb-2">{gettext("Features they found useful:")}</h3>
                  <div class="flex flex-wrap gap-2">
                    <%= for {feature, true} <- @testimonial.feature_usefulness do %>
                      <span class="badge badge-primary badge-lg">
                        {String.capitalize(feature)}
                      </span>
                    <% end %>
                  </div>
                </div>
              <% end %>

              <div class="divider"></div>

              <%!-- User Info --%>
              <div class="flex items-center gap-3 mb-6">
                <div class="avatar placeholder">
                  <div class="bg-primary text-primary-content rounded-full w-12">
                    <span class="text-lg">
                      {get_initial(@testimonial)}
                    </span>
                  </div>
                </div>
                <div>
                  <div class="font-semibold text-lg">{get_user_name(@testimonial)}</div>
                  <div class="text-sm text-base-content/60">
                    {gettext("Rank")}: {rank_display(@testimonial.user_rank_at_time)}
                  </div>
                </div>
              </div>

              <div class="divider"></div>

              <%!-- Social Sharing --%>
              <div class="mb-6">
                <h3 class="text-lg font-semibold mb-3">{gettext("Share this testimonial:")}</h3>
                <div class="flex flex-wrap gap-3">
                  <%!-- Twitter/X --%>
                  <a
                    href={twitter_share_url(@share_url, @testimonial)}
                    target="_blank"
                    class="btn btn-sm gap-2"
                  >
                    <.icon name="hero-at-symbol" /> X (Twitter)
                  </a>

                  <%!-- LinkedIn --%>
                  <a href={linkedin_share_url(@share_url)} target="_blank" class="btn btn-sm gap-2">
                    <.icon name="hero-briefcase" /> LinkedIn
                  </a>

                  <%!-- Facebook --%>
                  <a href={facebook_share_url(@share_url)} target="_blank" class="btn btn-sm gap-2">
                    <.icon name="hero-user-group" /> Facebook
                  </a>

                  <%!-- Copy Link --%>
                  <button
                    type="button"
                    class="btn btn-sm gap-2"
                    phx-hook="CopyButton"
                    id="copy-testimonial-url"
                    data-clipboard-text={@share_url}
                  >
                    <.icon name="hero-clipboard" /> {gettext("Copy Link")}
                  </button>
                </div>
              </div>

              <%!-- Attribution --%>
              <div class="text-center text-sm text-base-content/60 mt-6">
                <p>
                  {gettext("This testimonial is from a real user of Homesite.")}
                </p>
                <p class="mt-2">
                  {gettext("Built with")} ❤️ {gettext("by")} Juha Halmu -
                  <.link navigate={~p"/"} class="link link-primary">
                    {gettext("Check out Homesite")}
                  </.link>
                </p>
              </div>
            </div>
          </div>

          <%!-- Call to Action --%>
          <div class="text-center mt-12">
            <div class="card bg-base-200 shadow-xl">
              <div class="card-body">
                <h3 class="card-title justify-center text-xl mb-4">
                  {gettext("Want to share your experience?")}
                </h3>

                <%= if @current_scope do %>
                  <div class="card-actions justify-center">
                    <.link navigate={~p"/feedback"} class="btn btn-primary">
                      <.icon name="hero-chat-bubble-left-right" /> {gettext("Share Your Feedback")}
                    </.link>
                  </div>
                <% else %>
                  <div class="card-actions justify-center">
                    <.link navigate={~p"/users/log-in"} class="btn btn-primary">
                      {gettext("Log in to share feedback")}
                    </.link>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # Helper Functions

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

  defp rank_display(nil), do: "1"
  defp rank_display(rank), do: to_string(rank)

  # Social sharing URL builders
  defp twitter_share_url(url, testimonial) do
    stars = String.duplicate("⭐", testimonial.overall_satisfaction)
    text = "Check out this #{stars} testimonial for Homesite!"

    "https://twitter.com/intent/tweet?text=#{URI.encode(text)}&url=#{URI.encode(url)}"
  end

  defp linkedin_share_url(url) do
    "https://www.linkedin.com/sharing/share-offsite/?url=#{URI.encode(url)}"
  end

  defp facebook_share_url(url) do
    "https://www.facebook.com/sharer/sharer.php?u=#{URI.encode(url)}"
  end
end
