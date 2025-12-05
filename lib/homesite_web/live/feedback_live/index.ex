defmodule HomesiteWeb.FeedbackLive.Index do
  @moduledoc """
  Passive feedback form - always available at /feedback route.

  Users can voluntarily submit feedback at any time.
  """
  use HomesiteWeb, :live_view

  alias Homesite.Feedback
  import HomesiteWeb.CoreComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-[calc(100vh-200px)] px-[var(--spacing-card)] py-[var(--spacing-xl)]">
        <div class="max-w-2xl mx-auto">
          <div class="mb-8">
            <h1 class="text-3xl font-bold mb-2">{gettext("Share Your Feedback")}</h1>
            <p class="text-base-content/70">
              {gettext("We'd love to hear your thoughts on how we're doing. Your feedback helps us improve!")}
            </p>
          </div>

          <.form for={@form} id="feedback-form" phx-submit="save" phx-change="validate" class="space-y-6">
            <%!-- Overall Satisfaction (Required) --%>
            <div class="form-control">
              <label class="label">
                <span class="label-text font-semibold">
                  {gettext("Overall Satisfaction")} <span class="text-error">*</span>
                </span>
              </label>
              <div class="rating rating-lg">
                <%= for rating <- 1..5 do %>
                  <input
                    type="radio"
                    name="feedback[overall_satisfaction]"
                    value={rating}
                    class="mask mask-star-2 bg-orange-400"
                    checked={@form[:overall_satisfaction].value == rating}
                  />
                <% end %>
              </div>
            </div>

            <%!-- Performance Rating (Optional) --%>
            <div class="form-control">
              <label class="label">
                <span class="label-text font-semibold">{gettext("Performance")}</span>
                <span class="label-text-alt">{gettext("Optional")}</span>
              </label>
              <div class="rating rating-lg">
                <%= for rating <- 1..5 do %>
                  <input
                    type="radio"
                    name="feedback[performance_rating]"
                    value={rating}
                    class="mask mask-star-2 bg-blue-400"
                    checked={@form[:performance_rating].value == rating}
                  />
                <% end %>
              </div>
              <label class="label">
                <span class="label-text-alt">{gettext("How fast and responsive is the site?")}</span>
              </label>
            </div>

            <%!-- Feature Usefulness (Optional) --%>
            <div class="form-control">
              <label class="label">
                <span class="label-text font-semibold">{gettext("Which features do you find useful?")}</span>
                <span class="label-text-alt">{gettext("Optional")}</span>
              </label>
              <div class="grid grid-cols-2 gap-2">
                <%= for feature <- ["posts", "feeds", "bookmarks", "tags", "search", "timeline"] do %>
                  <label class="label cursor-pointer justify-start gap-2">
                    <input
                      type="checkbox"
                      name={"feedback[feature_usefulness][#{feature}]"}
                      value="true"
                      class="checkbox checkbox-sm"
                    />
                    <span class="label-text">{format_feature_name(feature)}</span>
                  </label>
                <% end %>
              </div>
            </div>

            <%!-- Open Feedback (Optional) --%>
            <div class="form-control">
              <label class="label">
                <span class="label-text font-semibold">{gettext("Additional Feedback")}</span>
                <span class="label-text-alt">{gettext("Optional")}</span>
              </label>
              <textarea
                name="feedback[open_feedback]"
                class="textarea textarea-bordered h-24"
                placeholder={gettext("Tell us what you think...")}
              >{@form[:open_feedback].value}</textarea>
            </div>

            <%!-- Submit Button --%>
            <div class="flex gap-4">
              <button type="submit" class="btn btn-primary" phx-disable-with={gettext("Submitting...")}>
                <.icon name="hero-paper-airplane" /> {gettext("Submit Feedback")}
              </button>
            </div>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    changeset = Feedback.FeedbackResponse.changeset(%Feedback.FeedbackResponse{}, %{})

    {:ok,
     socket
     |> assign(:page_title, gettext("Feedback"))
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"feedback" => feedback_params}, socket) do
    changeset =
      %Feedback.FeedbackResponse{}
      |> Feedback.FeedbackResponse.changeset(feedback_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"feedback" => feedback_params}, socket) do
    # Add prompt_type
    feedback_params = Map.put(feedback_params, "prompt_type", "passive")

    # Convert feature_usefulness checkboxes to map
    feedback_params = normalize_feature_usefulness(feedback_params)

    case Feedback.create_feedback_response(socket.assigns.current_scope, feedback_params) do
      {:ok, feedback} ->
        # Check if user wants to share (4-5 stars)
        socket =
          if feedback.overall_satisfaction >= 4 do
            put_flash(socket, :info, gettext("Thank you for your feedback! Would you like to share your testimonial publicly?"))
          else
            put_flash(socket, :info, gettext("Thank you for your feedback! We appreciate your input."))
          end

        {:noreply,
         socket
         |> push_navigate(to: ~p"/")}

      {:error, :rate_limited} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("You can only submit feedback once per week. Please try again later."))
         |> assign_form(Feedback.FeedbackResponse.changeset(%Feedback.FeedbackResponse{}, feedback_params))}

      {:error, :negative_feedback_limit} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("You've reached the limit for critical feedback. Please share some positive feedback too!"))
         |> assign_form(Feedback.FeedbackResponse.changeset(%Feedback.FeedbackResponse{}, feedback_params))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset, as: "feedback"))
  end

  defp normalize_feature_usefulness(params) do
    features = Map.get(params, "feature_usefulness", %{})

    # Convert checkbox map to simple true values
    normalized =
      features
      |> Enum.filter(fn {_k, v} -> v == "true" end)
      |> Enum.map(fn {k, _v} -> {k, true} end)
      |> Map.new()

    Map.put(params, "feature_usefulness", normalized)
  end

  defp format_feature_name("posts"), do: gettext("Posts")
  defp format_feature_name("feeds"), do: gettext("Feeds")
  defp format_feature_name("bookmarks"), do: gettext("Bookmarks")
  defp format_feature_name("tags"), do: gettext("Tags")
  defp format_feature_name("search"), do: gettext("Search")
  defp format_feature_name("timeline"), do: gettext("Timeline")
  defp format_feature_name(feature), do: String.capitalize(feature)
end
