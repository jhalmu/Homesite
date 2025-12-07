defmodule HomesiteWeb.UserLive.Login do
  use HomesiteWeb, :live_view

  alias Homesite.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-[calc(100vh-200px)] px-[var(--spacing-card)] py-[var(--spacing-xl)] flex items-center justify-center">
        <div class="max-w-[var(--card-max-width)] w-full">
          <%!-- Header --%>
          <div class="mb-[var(--space-lg)] text-center">
            <h1 class="text-[var(--font-size-fluid-2xl)] text-base-content font-bold">
              {gettext("Log in")}
            </h1>
            <p
              :if={@current_scope}
              class="text-[var(--font-size-fluid-sm)] mt-[var(--spacing-sm)] text-base-content/70"
            >
              {gettext("You need to reauthenticate to perform sensitive actions on your account.")}
            </p>
            <p
              :if={!@current_scope}
              class="text-[var(--font-size-fluid-sm)] mt-[var(--spacing-sm)] text-base-content/70"
            >
              {gettext("Welcome back! Please sign in to continue.")}
            </p>
          </div>

          <%!-- Dev mail adapter notice --%>
          <div :if={local_mail_adapter?()} class="alert alert-info mb-[var(--space-md)]">
            <.icon name="hero-information-circle" class="size-6 shrink-0" />
            <div>
              <p class="text-[var(--font-size-fluid-sm)] font-semibold">
                {gettext("Development Mode")}
              </p>
              <p class="text-[var(--font-size-fluid-sm)]">
                {gettext("To see sent emails, visit")} <.link
                  href="/dev/mailbox"
                  class="link link-primary"
                >{gettext("the mailbox page")}</.link>.
              </p>
            </div>
          </div>

          <%!-- Magic Link Login Card --%>
          <div class="card bg-base-100 mb-[var(--space-md)] shadow-xl">
            <div class="card-body gap-[var(--space-md)]">
              <div>
                <h2 class="text-[var(--font-size-fluid-lg)] card-title">
                  <.icon name="hero-envelope" class="h-6 w-6" />
                  {gettext("Log in with email")}
                </h2>
                <p class="text-[var(--font-size-fluid-sm)] mt-[var(--spacing-xs)] text-base-content/70">
                  {gettext("We'll send you a magic link to sign in instantly")}
                </p>
              </div>

              <.form
                :let={f}
                for={@form}
                id="login_form_magic"
                action={~p"/users/log-in"}
                phx-submit="submit_magic"
                class="space-y-4"
              >
                <.input
                  readonly={!!@current_scope}
                  field={f[:email]}
                  type="email"
                  label={gettext("Email")}
                  autocomplete="username"
                  required
                  phx-mounted={JS.focus()}
                />
                <.button class="btn btn-primary w-full gap-2">
                  <.icon name="hero-paper-airplane" class="h-5 w-5" />
                  {gettext("Send magic link")}
                </.button>
              </.form>
            </div>
          </div>

          <div class="divider text-[var(--text-sm)] text-base-content/50">
            {gettext("or sign in with password")}
          </div>

          <%!-- Password Login Card --%>
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body gap-[var(--space-md)]">
              <div>
                <h2 class="text-[var(--font-size-fluid-lg)] card-title">
                  <.icon name="hero-lock-closed" class="h-6 w-6" />
                  {gettext("Password Login")}
                </h2>
                <p class="text-[var(--font-size-fluid-sm)] mt-[var(--spacing-xs)] text-base-content/70">
                  {gettext("Use your email and password")}
                </p>
              </div>

              <.form
                :let={f}
                for={@form}
                id="login_form_password"
                action={~p"/users/log-in"}
                phx-submit="submit_password"
                phx-trigger-action={@trigger_submit}
                class="space-y-4"
              >
                <.input
                  readonly={!!@current_scope}
                  field={f[:email]}
                  type="email"
                  label={gettext("Email")}
                  autocomplete="username"
                  required
                />
                <.input
                  field={@form[:password]}
                  type="password"
                  label={gettext("Password")}
                  autocomplete="current-password"
                  required
                />

                <div class="space-y-2">
                  <.button
                    class="btn btn-primary w-full gap-2"
                    name={@form[:remember_me].name}
                    value="true"
                  >
                    <.icon name="hero-clock" class="h-5 w-5" />
                    {gettext("Stay logged in")}
                  </.button>
                  <.button class="btn btn-outline w-full gap-2">
                    <.icon name="hero-arrow-right-on-rectangle" class="h-5 w-5" />
                    {gettext("Log in only this time")}
                  </.button>
                </div>
              </.form>
            </div>
          </div>

          <%!-- Security note --%>
          <div class="mt-[var(--space-md)] text-center">
            <p class="text-[var(--font-size-fluid-sm)] text-base-content/50">
              <.icon name="hero-shield-check" class="inline h-4 w-4" />
              {gettext("Your connection is secure and encrypted")}
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      gettext(
        "If your email is in our system, you will receive instructions for logging in shortly."
      )

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:homesite, Homesite.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
