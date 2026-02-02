defmodule HomesiteWeb.AdminLive.Settings.Index do
  use HomesiteWeb, :live_view

  alias Homesite.Settings

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="px-[var(--spacing-card)] py-[var(--spacing-xl)] container mx-auto">
        <.header>
          {gettext("Application Settings")}
          <:subtitle>
            {gettext("Configure registration mode and security features")}
          </:subtitle>
        </.header>

        <div class="mt-[var(--spacing-lg)] space-y-[var(--spacing-lg)]">
          <%!-- Registration Mode --%>
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">{gettext("Registration Mode")}</h2>
              <p class="text-base-content/70 text-sm">
                {gettext("Control how users can register for accounts")}
              </p>

              <div class="form-control mt-4">
                <label class="label cursor-pointer">
                  <span class="label-text">
                    <strong>{gettext("Closed")}</strong> - {gettext("Registration is disabled")}
                  </span>
                  <input
                    type="radio"
                    name="registration_mode"
                    class="radio radio-primary"
                    value="closed"
                    checked={@registration_mode == :closed}
                    phx-click="update_registration_mode"
                    phx-value-mode="closed"
                  />
                </label>
              </div>

              <div class="form-control">
                <label class="label cursor-pointer">
                  <span class="label-text">
                    <strong>{gettext("Invite Only")}</strong> - {gettext("Requires invitation code")}
                  </span>
                  <input
                    type="radio"
                    name="registration_mode"
                    class="radio radio-primary"
                    value="invite_only"
                    checked={@registration_mode == :invite_only}
                    phx-click="update_registration_mode"
                    phx-value-mode="invite_only"
                  />
                </label>
              </div>

              <div class="form-control">
                <label class="label cursor-pointer">
                  <span class="label-text">
                    <strong>{gettext("Open")}</strong>
                    - {gettext("Anyone can register (invitation optional)")}
                  </span>
                  <input
                    type="radio"
                    name="registration_mode"
                    class="radio radio-primary"
                    value="open"
                    checked={@registration_mode == :open}
                    phx-click="update_registration_mode"
                    phx-value-mode="open"
                  />
                </label>
              </div>
            </div>
          </div>

          <%!-- CAPTCHA Settings --%>
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">{gettext("CAPTCHA Protection")}</h2>
              <p class="text-base-content/70 text-sm">
                {gettext("Enable Cloudflare Turnstile CAPTCHA to prevent bot registrations")}
              </p>

              <div class="form-control mt-4">
                <label class="label cursor-pointer">
                  <span class="label-text">{gettext("Enable Turnstile CAPTCHA")}</span>
                  <input
                    type="checkbox"
                    class="toggle toggle-primary"
                    checked={@turnstile_enabled}
                    phx-click="toggle_turnstile"
                  />
                </label>
              </div>

              <%= if @turnstile_enabled do %>
                <div class="alert alert-info mt-4">
                  <.icon name="hero-information-circle" class="h-5 w-5" />
                  <span>
                    {gettext(
                      "CAPTCHA is enabled. Make sure TURNSTILE_SITE_KEY and TURNSTILE_SECRET_KEY environment variables are configured."
                    )}
                  </span>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    registration_mode = Settings.registration_mode()
    turnstile_enabled = Settings.turnstile_enabled?()

    socket =
      socket
      |> assign(:registration_mode, registration_mode)
      |> assign(:turnstile_enabled, turnstile_enabled)

    {:ok, socket}
  end

  @impl true
  def handle_event("update_registration_mode", %{"mode" => mode}, socket) do
    mode_atom = String.to_existing_atom(mode)

    case Settings.update_setting("registration_mode", %{"mode" => mode}) do
      {:ok, _setting} ->
        {:noreply,
         socket
         |> assign(:registration_mode, mode_atom)
         |> put_flash(:info, gettext("Registration mode updated successfully"))}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to update registration mode"))}
    end
  end

  def handle_event("toggle_turnstile", _params, socket) do
    new_value = !socket.assigns.turnstile_enabled

    case Settings.update_setting("turnstile_enabled", %{"enabled" => new_value}) do
      {:ok, _setting} ->
        {:noreply,
         socket
         |> assign(:turnstile_enabled, new_value)
         |> put_flash(
           :info,
           if(new_value,
             do: gettext("CAPTCHA enabled"),
             else: gettext("CAPTCHA disabled")
           )
         )}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to update CAPTCHA setting"))}
    end
  end
end
