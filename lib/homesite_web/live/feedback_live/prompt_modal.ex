defmodule HomesiteWeb.FeedbackLive.PromptModal do
  @moduledoc """
  Active feedback prompt toast - shows proactively based on user activity.

  Displays a toast notification in bottom-right corner with:
  - "Sure!" button → redirects to /feedback page
  - "Later" button → dismisses toast and marks prompt as shown
  """
  use HomesiteWeb, :live_component

  alias Homesite.Feedback
  import HomesiteWeb.CoreComponents

  @impl true
  def update(assigns, socket) do
    should_show = should_show_prompt?(assigns)

    socket =
      socket
      |> assign(assigns)
      |> assign(:should_show, should_show)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @should_show do %>
        <%!-- Toast notification prompting for feedback --%>
        <div
          id="feedback-toast"
          class="toast toast-end toast-bottom z-50"
        >
          <div class="alert alert-info shadow-lg">
            <div>
              <.icon name="hero-chat-bubble-left-right" />
              <div>
                <h3 class="font-bold">{gettext("How are we doing?")}</h3>
                <div class="text-[var(--text-xs)]">
                  {gettext("Share your feedback and help us improve!")}
                </div>
              </div>
            </div>
            <div class="gap-[var(--space-xs)] flex">
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
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("show_form", _params, socket) do
    # Mark prompt as shown
    if socket.assigns.current_scope do
      Feedback.mark_prompt_shown(socket.assigns.current_scope.user)
    end

    # Redirect to feedback page instead of showing modal
    {:noreply, push_navigate(socket, to: ~p"/feedback")}
  end

  @impl true
  def handle_event("dismiss", _params, socket) do
    # Mark prompt as shown even if dismissed
    if socket.assigns.current_scope do
      Feedback.mark_prompt_shown(socket.assigns.current_scope.user)
    end

    {:noreply, assign(socket, should_show: false)}
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
end
