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
            <%!-- Show form-level errors only if form was submitted --%>
            <%= if @form.source.action == :insert && @form.errors != [] do %>
              <div class="alert alert-error">
                <.icon name="hero-exclamation-triangle" />
                <div>
                  <p class="font-bold">{gettext("Please fix the following errors:")}</p>
                  <ul class="list-disc list-inside">
                    <%= for {field, {msg, _}} <- @form.errors do %>
                      <li>{field}: {msg}</li>
                    <% end %>
                  </ul>
                </div>
              </div>
            <% end %>

            <%!-- Overall Satisfaction (Required) --%>
            <div class="form-control">
              <h3 class="text-sm font-semibold mb-2">
                {gettext("Overall Satisfaction")} <span class="text-error">*</span>
              </h3>
              <div class="rating rating-lg">
                <%= for rating <- 1..5 do %>
                  <input
                    type="radio"
                    name="feedback[overall_satisfaction]"
                    value={rating}
                    class="mask mask-heart bg-red-400"
                    checked={@form[:overall_satisfaction].value == rating}
                    required={rating == 1}
                  />
                <% end %>
              </div>
            </div>

            <%!-- Performance Rating (Required) --%>
            <div class="form-control">
              <h3 class="text-sm font-semibold mb-2">
                {gettext("How fast and responsive is the site?")} <span class="text-error">*</span>
              </h3>
              <div class="rating rating-lg">
                <%= for rating <- 1..5 do %>
                  <input
                    type="radio"
                    name="feedback[performance_rating]"
                    value={rating}
                    class="mask mask-heart bg-blue-400"
                    checked={@form[:performance_rating].value == rating}
                    required={rating == 1}
                  />
                <% end %>
              </div>
            </div>

            <%!-- Open Feedback (Required) --%>
            <div class="form-control">
              <textarea
                name="feedback[open_feedback]"
                class="textarea textarea-bordered h-24"
                placeholder={"#{gettext("Tell us what you think...")} ❤️"}
                required
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
  def mount(params, _session, socket) do
    changeset = Feedback.FeedbackResponse.changeset(%Feedback.FeedbackResponse{}, %{})

    # Get referrer from params or default to home
    referrer = params["from"] || "/"

    {:ok,
     socket
     |> assign(:page_title, gettext("Feedback"))
     |> assign(:referrer, referrer)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"feedback" => feedback_params}, socket) do
    # Don't show validation errors until submit - just update form values
    changeset =
      %Feedback.FeedbackResponse{}
      |> Feedback.FeedbackResponse.changeset(feedback_params)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"feedback" => feedback_params}, socket) do
    # Add prompt_type
    feedback_params = Map.put(feedback_params, "prompt_type", "passive")

    case Feedback.create_feedback_response(socket.assigns.current_scope, feedback_params) do
      {:ok, _feedback} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Thank you for your feedback! We appreciate your input."))
         |> push_navigate(to: socket.assigns.referrer)}

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
end
