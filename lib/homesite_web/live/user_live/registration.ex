defmodule HomesiteWeb.UserLive.Registration do
  use HomesiteWeb, :live_view

  alias Homesite.Accounts
  alias Homesite.Accounts.User
  alias Homesite.Settings

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-[calc(100vh-200px)] px-[var(--spacing-card)] py-[var(--spacing-xl)] flex items-center justify-center">
        <div class="max-w-[var(--card-max-width)] w-full">
          <%= if @is_preview do %>
            <div class="alert alert-info mb-[var(--spacing-md)]">
              <.icon name="hero-information-circle" class="h-5 w-5" />
              <span>
                {gettext("Admin Preview Mode")} - {gettext(
                  "You are viewing this page as an admin. The registration form is disabled while you're logged in."
                )}
              </span>
            </div>
          <% end %>

          <%= if @registration_mode == :closed do %>
            <div class="text-center">
              <.header>
                {gettext("Registration Closed")}
                <:subtitle>
                  {gettext("Registration is currently closed. Please check back later.")}
                </:subtitle>
              </.header>
            </div>
          <% else %>
            <div class="mb-[var(--spacing-lg)] text-center">
              <.header>
                {gettext("Register for an account")}
                <:subtitle>
                  {gettext("Already registered?")}
                  <.link navigate={~p"/users/log-in"} class="text-brand font-semibold hover:underline">
                    {gettext("Log in")}
                  </.link>
                  {gettext("to your account now.")}
                </:subtitle>
              </.header>
            </div>

            <.form
              for={@form}
              id="registration_form"
              phx-submit={if @is_preview, do: nil, else: "save"}
              phx-change={if @is_preview, do: nil, else: "validate"}
            >
              <%= if @registration_mode == :invite_only do %>
                <.input
                  field={@form[:invitation_code]}
                  type="text"
                  label={gettext("Invitation Code")}
                  required
                  phx-mounted={if @invitation_code, do: nil, else: JS.focus()}
                  value={@invitation_code}
                >
                  <:help>
                    {gettext("Enter the invitation code you received.")}
                  </:help>
                </.input>
              <% else %>
                <%!-- Open mode: invitation code is optional --%>
                <details class="mb-[var(--spacing-md)]">
                  <summary class="text-base-content/70 cursor-pointer text-sm hover:text-base-content">
                    {gettext("Have an invitation code? (Optional)")}
                  </summary>
                  <div class="mt-2">
                    <.input
                      field={@form[:invitation_code]}
                      type="text"
                      label={gettext("Invitation Code")}
                      value={@invitation_code}
                    >
                      <:help>
                        {gettext("If you have an invitation code, enter it here.")}
                      </:help>
                    </.input>
                  </div>
                </details>
              <% end %>

              <.input
                field={@form[:email]}
                type="email"
                label={gettext("Email")}
                autocomplete="username"
                required
                phx-mounted={
                  if @invitation_code && @registration_mode == :invite_only,
                    do: JS.focus(),
                    else: nil
                }
              />

              <.input
                field={@form[:preferred_language]}
                type="select"
                label={gettext("Preferred Language")}
                options={[{gettext("English"), "en"}, {gettext("Finnish"), "fi"}]}
                value={@form[:preferred_language].value || "en"}
              >
                <:help>
                  {gettext(
                    "Choose your preferred language for the user interface. This can be changed later in Settings."
                  )}
                </:help>
              </.input>

              <%= if @turnstile_enabled do %>
                <div class="mb-[var(--spacing-md)]">
                  <Turnstile.widget theme="auto" />
                </div>
              <% end %>

              <.button
                phx-disable-with={gettext("Creating account...")}
                class="btn btn-primary w-full"
                disabled={@is_preview}
              >
                <%= if @is_preview do %>
                  {gettext("Preview Mode - Cannot Register")}
                <% else %>
                  {gettext("Create an account")}
                <% end %>
              </.button>
            </.form>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, %{assigns: %{current_scope: current_scope}} = socket) do
    # Allow admins to view the registration page, but redirect regular users
    if current_scope && current_scope.user && !Homesite.Accounts.Scope.admin?(current_scope) do
      {:ok, redirect(socket, to: HomesiteWeb.UserAuth.signed_in_path(socket))}
    else
      # Get invitation code from URL params (e.g., /users/register?invite=ABC123XY)
      invitation_code = Map.get(params, "invite", "")

      # Check registration mode and CAPTCHA settings
      registration_mode = Settings.registration_mode()
      turnstile_enabled = Settings.turnstile_enabled?()

      changeset = Accounts.change_user_email(%User{}, %{}, validate_unique: false)

      socket =
        socket
        |> assign(:invitation_code, invitation_code)
        |> assign(:registration_mode, registration_mode)
        |> assign(:turnstile_enabled, turnstile_enabled)
        |> assign(:is_preview, current_scope && current_scope.user != nil)
        |> assign_form(changeset)

      {:ok, socket, temporary_assigns: [form: nil]}
    end
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    # Verify CAPTCHA if enabled
    with :ok <- verify_turnstile(socket.assigns.turnstile_enabled, user_params),
         {:ok, user} <- Accounts.register_user(user_params) do
      {:ok, _} =
        Accounts.deliver_login_instructions(
          user,
          &url(~p"/users/log-in/#{&1}")
        )

      {:noreply,
       socket
       |> put_flash(
         :info,
         gettext("An email was sent to %{email}, please access it to confirm your account.",
           email: user.email
         )
       )
       |> push_navigate(to: ~p"/users/log-in")}
    else
      {:error, :captcha_failed} ->
        changeset =
          Accounts.change_user_email(%User{}, user_params, validate_unique: false)
          |> Map.put(:action, :insert)
          |> Ecto.Changeset.add_error(
            :base,
            gettext("CAPTCHA verification failed. Please try again.")
          )

        {:noreply, assign_form(socket, changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_email(%User{}, user_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp verify_turnstile(false, _user_params), do: :ok

  defp verify_turnstile(true, user_params) do
    case Turnstile.verify(user_params) do
      {:ok, _response} -> :ok
      {:error, _reason} -> {:error, :captcha_failed}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
