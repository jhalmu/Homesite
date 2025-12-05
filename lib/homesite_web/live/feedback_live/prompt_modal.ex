defmodule HomesiteWeb.FeedbackLive.PromptModal do
  @moduledoc """
  Active feedback prompt modal - shows proactively based on user activity.

  Multi-step state machine:
  1. :initial - Toast notification in bottom-right
  2. :questions - Full modal with feedback form
  3. :share_option - Ask if user wants to share (4-5 stars only)
  4. :share_platforms - Show social sharing buttons
  5. :complete - Dismiss modal
  """
  use HomesiteWeb, :live_component

  alias Homesite.Feedback
  import HomesiteWeb.CoreComponents

  @impl true
  def update(assigns, socket) do
    require Logger
    should_show = should_show_prompt?(assigns)
    current_step = socket.assigns[:step]

    Logger.info("🔔 Feedback modal update - should_show: #{should_show}, current_step: #{inspect(current_step)}")

    socket =
      socket
      |> assign(assigns)
      |> assign_new(:step, fn -> :initial end)
      |> assign(:should_show, should_show)
      |> assign_new(:feedback_response, fn -> nil end)
      |> assign_new(:form, fn ->
        changeset = Feedback.FeedbackResponse.changeset(%Feedback.FeedbackResponse{}, %{})
        to_form(changeset, as: "feedback")
      end)

    Logger.info("🔔 After update - step: #{inspect(socket.assigns.step)}, should_show: #{socket.assigns.should_show}")
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @should_show do %>
        <%= case @step do %>
          <% :initial -> %>
            <div
              id="feedback-toast"
              class="toast toast-end toast-bottom z-50"
              phx-click="dismiss"
              phx-target={@myself}
            >
              <div class="alert alert-info shadow-lg cursor-pointer">
                <div>
                  <.icon name="hero-chat-bubble-left-right" />
                  <div>
                    <h3 class="font-bold">{gettext("How are we doing?")}</h3>
                    <div class="text-xs">{gettext("Share your feedback and help us improve!")}</div>
                  </div>
                </div>
                <div class="flex gap-2">
                  <button
                    type="button"
                    class="btn btn-sm btn-primary"
                    phx-click="show_form"
                    phx-target={@myself}
                  >
                    {gettext("Sure!")}
                  </button>
                  <button
                    type="button"
                    class="btn btn-sm btn-ghost"
                    phx-click="dismiss"
                    phx-target={@myself}
                  >
                    {gettext("Later")}
                  </button>
                </div>
              </div>
            </div>

          <% :questions -> %>
            <div class="modal modal-open" phx-click="dismiss" phx-target={@myself}>
              <div class="modal-box max-w-2xl" phx-click="stop_propagation">
                <h3 class="font-bold text-lg mb-4">{gettext("Share Your Feedback")}</h3>

                <.form
                  for={@form}
                  id="feedback-prompt-form"
                  phx-submit="save"
                  phx-change="validate"
                  phx-target={@myself}
                  class="space-y-6"
                >
                  <%!-- Overall Satisfaction (Required) --%>
                  <div class="form-control">
                    <h3 class="text-sm font-semibold mb-2">
                      {gettext("Overall Satisfaction")} <span class="text-error">*</span>
                    </h3>
                    <div class="rating rating-lg" phx-click="stop_propagation">
                      <%= for rating <- 1..5 do %>
                        <input
                          type="radio"
                          name="feedback[overall_satisfaction]"
                          value={rating}
                          class="mask mask-heart bg-red-400"
                          checked={@form[:overall_satisfaction].value == rating}
                          phx-click="stop_propagation"
                        />
                      <% end %>
                    </div>
                  </div>

                  <%!-- Performance Rating (Required) --%>
                  <div class="form-control">
                    <h3 class="text-sm font-semibold mb-2">
                      {gettext("How fast and responsive is the site?")} <span class="text-error">*</span>
                    </h3>
                    <div class="rating rating-lg" phx-click="stop_propagation">
                      <%= for rating <- 1..5 do %>
                        <input
                          type="radio"
                          name="feedback[performance_rating]"
                          value={rating}
                          class="mask mask-heart bg-blue-400"
                          checked={@form[:performance_rating].value == rating}
                          phx-click="stop_propagation"
                        />
                      <% end %>
                    </div>
                  </div>

                  <%!-- Open Feedback (Required) --%>
                  <div class="form-control">
                    <h3 class="text-sm font-semibold mb-2">
                      {gettext("Tell us what you think...")} <span class="text-error">*</span>
                    </h3>
                    <textarea
                      name="feedback[open_feedback]"
                      class="textarea textarea-bordered h-24"
                      placeholder={"#{gettext("Tell us what you think...")} ❤️"}
                      required
                    >{@form[:open_feedback].value}</textarea>
                  </div>

                  <%!-- Modal Actions --%>
                  <div class="modal-action">
                    <button
                      type="button"
                      class="btn btn-ghost"
                      phx-click="dismiss"
                      phx-target={@myself}
                    >
                      {gettext("Cancel")}
                    </button>
                    <button type="submit" class="btn btn-primary" phx-disable-with={gettext("Submitting...")}>
                      <.icon name="hero-paper-airplane" /> {gettext("Submit Feedback")}
                    </button>
                  </div>
                </.form>
              </div>
            </div>

          <% :share_option -> %>
            <div class="modal modal-open" phx-click="dismiss" phx-target={@myself}>
              <div class="modal-box" phx-click="stop_propagation">
                <h3 class="font-bold text-lg mb-4">{gettext("Thank you for your feedback!")}</h3>

                <p class="py-4">
                  {gettext("We're thrilled you had a great experience! Would you like to share your testimonial publicly to help others discover Homesite?")}
                </p>

                <div class="modal-action">
                  <button
                    type="button"
                    class="btn btn-ghost"
                    phx-click="decline_share"
                    phx-target={@myself}
                  >
                    {gettext("No, thanks")}
                  </button>
                  <button
                    type="button"
                    class="btn btn-primary"
                    phx-click="show_share_platforms"
                    phx-target={@myself}
                  >
                    <.icon name="hero-share" /> {gettext("Yes, share it!")}
                  </button>
                </div>
              </div>
            </div>

          <% :share_platforms -> %>
            <div class="modal modal-open" phx-click="dismiss" phx-target={@myself}>
              <div class="modal-box" phx-click="stop_propagation">
                <h3 class="font-bold text-lg mb-4">{gettext("Share Your Testimonial")}</h3>

                <p class="mb-4">
                  {gettext("Choose a platform to share your testimonial:")}
                </p>

                <%= if @feedback_response && @feedback_response.share_token do %>
                  <div class="space-y-2">
                    <%!-- Twitter/X --%>
                    <a
                      href={
                        twitter_share_url(
                          url(@socket, ~p"/testimonials/#{@feedback_response.share_token}"),
                          @feedback_response
                        )
                      }
                      target="_blank"
                      class="btn btn-block justify-start gap-2"
                    >
                      <.icon name="hero-at-symbol" /> {gettext("Share on X (Twitter)")}
                    </a>

                    <%!-- LinkedIn --%>
                    <a
                      href={linkedin_share_url(url(@socket, ~p"/testimonials/#{@feedback_response.share_token}"))}
                      target="_blank"
                      class="btn btn-block justify-start gap-2"
                    >
                      <.icon name="hero-briefcase" /> {gettext("Share on LinkedIn")}
                    </a>

                    <%!-- Facebook --%>
                    <a
                      href={facebook_share_url(url(@socket, ~p"/testimonials/#{@feedback_response.share_token}"))}
                      target="_blank"
                      class="btn btn-block justify-start gap-2"
                    >
                      <.icon name="hero-user-group" /> {gettext("Share on Facebook")}
                    </a>

                    <%!-- Copy Link --%>
                    <button
                      type="button"
                      class="btn btn-block justify-start gap-2"
                      phx-hook="CopyButton"
                      id="copy-testimonial-link"
                      data-clipboard-text={url(@socket, ~p"/testimonials/#{@feedback_response.share_token}")}
                    >
                      <.icon name="hero-clipboard" /> {gettext("Copy Link")}
                    </button>
                  </div>
                <% end %>

                <div class="modal-action">
                  <button
                    type="button"
                    class="btn btn-ghost"
                    phx-click="dismiss"
                    phx-target={@myself}
                  >
                    {gettext("Close")}
                  </button>
                </div>
              </div>
            </div>

          <% :complete -> %>
            <%!-- Hidden state - modal dismissed --%>
        <% end %>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("show_form", _params, socket) do
    require Logger
    Logger.info("🔔 Feedback modal: show_form event received!")
    Logger.info("🔔 Current step: #{inspect(socket.assigns[:step])}")

    # Mark prompt as shown
    if socket.assigns.current_scope do
      Feedback.mark_prompt_shown(socket.assigns.current_scope.user)
    end

    new_socket = assign(socket, step: :questions)
    Logger.info("🔔 New step: #{inspect(new_socket.assigns.step)}")
    {:noreply, new_socket}
  end

  @impl true
  def handle_event("dismiss", _params, socket) do
    # Mark prompt as shown even if dismissed
    if socket.assigns.current_scope do
      Feedback.mark_prompt_shown(socket.assigns.current_scope.user)
    end

    {:noreply, assign(socket, should_show: false, step: :complete)}
  end

  @impl true
  def handle_event("stop_propagation", _params, socket) do
    # Prevent modal background click from closing modal
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"feedback" => feedback_params}, socket) do
    changeset =
      %Feedback.FeedbackResponse{}
      |> Feedback.FeedbackResponse.changeset(feedback_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: "feedback"))}
  end

  @impl true
  def handle_event("save", %{"feedback" => feedback_params}, socket) do
    # Add prompt_type
    feedback_params = Map.put(feedback_params, "prompt_type", "active")

    case Feedback.create_feedback_response(socket.assigns.current_scope, feedback_params) do
      {:ok, feedback} ->
        # Check if user wants to share (4-5 stars)
        socket =
          if feedback.overall_satisfaction >= 4 do
            socket
            |> assign(:feedback_response, feedback)
            |> assign(:step, :share_option)
          else
            # Low rating - just thank them
            send(self(), {:put_flash, :info, gettext("Thank you for your feedback! We appreciate your input.")})
            assign(socket, should_show: false, step: :complete)
          end

        {:noreply, socket}

      {:error, :rate_limited} ->
        send(
          self(),
          {:put_flash, :error,
           gettext("You can only submit feedback once per week. Please try again later.")}
        )

        {:noreply, assign(socket, should_show: false, step: :complete)}

      {:error, :negative_feedback_limit} ->
        send(
          self(),
          {:put_flash, :error,
           gettext(
             "You've reached the limit for critical feedback. Please share some positive feedback too!"
           )}
        )

        {:noreply, assign(socket, should_show: false, step: :complete)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "feedback"))}
    end
  end

  @impl true
  def handle_event("decline_share", _params, socket) do
    send(self(), {:put_flash, :info, gettext("Thank you for your feedback!")})
    {:noreply, assign(socket, should_show: false, step: :complete)}
  end

  @impl true
  def handle_event("show_share_platforms", _params, socket) do
    # Mark feedback as publicly shared
    if socket.assigns.feedback_response do
      case Feedback.share_feedback_publicly(
             socket.assigns.current_scope,
             socket.assigns.feedback_response.id
           ) do
        {:ok, updated_feedback} ->
          {:noreply, assign(socket, step: :share_platforms, feedback_response: updated_feedback)}

        {:error, _changeset} ->
          send(self(), {:put_flash, :error, gettext("Failed to share feedback publicly.")})
          {:noreply, assign(socket, should_show: false, step: :complete)}
      end
    else
      {:noreply, assign(socket, should_show: false, step: :complete)}
    end
  end

  # Private functions

  defp should_show_prompt?(assigns) do
    case assigns do
      %{current_scope: %{user: user}} when not is_nil(user) ->
        Feedback.should_show_prompt?(user)

      _ ->
        false
    end
  end

  # Social sharing URL builders
  defp twitter_share_url(url, feedback) do
    hearts = String.duplicate("❤️", feedback.overall_satisfaction)
    text = "I rated Homesite #{hearts}! #{feedback.open_feedback || ""}"
    "https://twitter.com/intent/tweet?text=#{URI.encode(text)}&url=#{URI.encode(url)}"
  end

  defp linkedin_share_url(url) do
    "https://www.linkedin.com/sharing/share-offsite/?url=#{URI.encode(url)}"
  end

  defp facebook_share_url(url) do
    "https://www.facebook.com/sharer/sharer.php?u=#{URI.encode(url)}"
  end
end
