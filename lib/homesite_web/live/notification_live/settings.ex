defmodule HomesiteWeb.NotificationLive.Settings do
  @moduledoc """
  Notification Settings LiveView.
  Allows users to configure their notification preferences.
  """
  use HomesiteWeb, :authenticated_live_view

  alias Homesite.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="w-[min(95vw,500px)] my-[var(--space-lg)] mx-auto">
        <%!-- Back to notifications --%>
        <div class="mb-[var(--space-md)]">
          <.link
            navigate={~p"/notifications"}
            class="link link-hover gap-[var(--space-inline)] text-[var(--text-sm)] flex items-center"
          >
            <.icon name="hero-arrow-left" class="h-4 w-4" />
            {gettext("Back to notifications")}
          </.link>
        </div>

        <h1 class="text-[var(--font-size-fluid-xl)] mb-[var(--space-lg)] font-bold">
          {gettext("Notification Settings")}
        </h1>

        <.form for={@form} phx-change="update_preferences" class="space-y-[var(--space-md)]">
          <%!-- Section: Notification Types --%>
          <div class="card bg-base-200">
            <div class="card-body">
              <h2 class="card-title text-[var(--text-base)]">
                <.icon name="hero-bell" class="h-5 w-5" />
                {gettext("Notification Types")}
              </h2>

              <p class="text-base-content/60 mb-[var(--space-sm)] text-[var(--text-sm)]">
                {gettext("Choose which notifications you want to receive.")}
              </p>

              <div class="form-control">
                <label class="label gap-[var(--space-sm)] cursor-pointer justify-start">
                  <input
                    type="checkbox"
                    name="new_follower"
                    class="toggle toggle-primary"
                    checked={@preferences["new_follower"]}
                    value="true"
                  />
                  <div>
                    <span class="label-text font-medium">{gettext("New followers")}</span>
                    <p class="text-base-content/60 text-[var(--text-xs)]">
                      {gettext("Get notified when someone follows you")}
                    </p>
                  </div>
                </label>
              </div>
            </div>
          </div>

          <%!-- Section: Display Settings --%>
          <div class="card bg-base-200">
            <div class="card-body">
              <h2 class="card-title text-[var(--text-base)]">
                <.icon name="hero-eye" class="h-5 w-5" />
                {gettext("Display Settings")}
              </h2>

              <p class="text-base-content/60 mb-[var(--space-sm)] text-[var(--text-sm)]">
                {gettext("Configure how notifications are displayed.")}
              </p>

              <div class="form-control">
                <label class="label gap-[var(--space-sm)] cursor-pointer justify-start">
                  <input
                    type="checkbox"
                    name="show_toast"
                    class="toggle toggle-primary"
                    checked={@preferences["show_toast"]}
                    value="true"
                  />
                  <div>
                    <span class="label-text font-medium">{gettext("Toast notifications")}</span>
                    <p class="text-base-content/60 text-[var(--text-xs)]">
                      {gettext("Show pop-up notifications when you receive new notifications")}
                    </p>
                  </div>
                </label>
              </div>
            </div>
          </div>
        </.form>

        <p class="text-base-content/50 mt-[var(--space-md)] text-[var(--text-xs)] text-center">
          {gettext("Changes are saved automatically.")}
        </p>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    current_scope = socket.assigns.current_scope
    preferences = Accounts.get_notification_preferences(current_scope)

    {:ok,
     socket
     |> assign(:page_title, gettext("Notification Settings"))
     |> assign(:preferences, preferences)
     |> assign(:form, to_form(%{}, as: :preferences))}
  end

  @impl true
  def handle_event("update_preferences", params, socket) do
    current_scope = socket.assigns.current_scope

    # Build new preferences from form params
    # Unchecked checkboxes don't send values, so we check for presence
    new_preferences = %{
      "new_follower" => Map.has_key?(params, "new_follower"),
      "show_toast" => Map.has_key?(params, "show_toast")
    }

    case Accounts.update_notification_preferences(current_scope, new_preferences) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> assign(:preferences, new_preferences)
         |> put_flash(:info, gettext("Preferences updated"))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Could not update preferences"))}
    end
  end
end
