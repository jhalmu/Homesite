defmodule HomesiteWeb.UserLive.Registration do
  use HomesiteWeb, :live_view

  alias Homesite.Accounts
  alias Homesite.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex min-h-[calc(100vh-200px)] items-center justify-center px-[var(--spacing-card)] py-[var(--spacing-xl)]">
        <div class="w-full max-w-[var(--card-max-width)]">
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

        <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
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

          <.input
            field={@form[:email]}
            type="email"
            label={gettext("Email")}
            autocomplete="username"
            required
            phx-mounted={if @invitation_code, do: JS.focus(), else: nil}
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

          <.button phx-disable-with={gettext("Creating account...")} class="btn btn-primary w-full">
            {gettext("Create an account")}
          </.button>
        </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: HomesiteWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(params, _session, socket) do
    # Get invitation code from URL params (e.g., /users/register?invite=ABC123XY)
    invitation_code = Map.get(params, "invite", "")

    changeset = Accounts.change_user_email(%User{}, %{}, validate_unique: false)

    socket =
      socket
      |> assign(:invitation_code, invitation_code)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    # register_user now handles invitation validation and consumption
    case Accounts.register_user(user_params) do
      {:ok, user} ->
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

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_email(%User{}, user_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
