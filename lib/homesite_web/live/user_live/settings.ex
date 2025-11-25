defmodule HomesiteWeb.UserLive.Settings do
  use HomesiteWeb, :live_view

  on_mount {HomesiteWeb.UserAuth, :require_sudo_mode}

  alias Homesite.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="text-center">
        <.header>
          {gettext("Account Settings")}
          <:subtitle>{gettext("Manage your profile, email address and password settings")}</:subtitle>
        </.header>
      </div>

      <.form
        for={@profile_form}
        id="profile_form"
        phx-submit="update_profile"
        phx-change="validate_profile"
      >
        <div class="gap-[clamp(1rem,3vw,2rem)] flex flex-col items-center">
          <div class="gap-[clamp(0.5rem,2vw,1rem)] flex flex-col items-center">
            <.avatar user={@current_scope.user} class="h-24 w-24" />
            <.live_file_input
              upload={@uploads.avatar}
              class="file-input file-input-bordered w-full max-w-xs"
            />
            <p class="text-sm text-gray-600 dark:text-gray-400">
              {gettext(
                "Upload a new avatar (JPG, PNG, max 5MB) or leave empty for auto-generated avatar"
              )}
            </p>
          </div>
        </div>

        <.input
          field={@profile_form[:display_name]}
          type="text"
          label={gettext("Display Name")}
          placeholder={gettext("Your public name")}
        />
        <.input
          field={@profile_form[:bio]}
          type="textarea"
          label={gettext("Bio")}
          placeholder={gettext("Tell us about yourself (max 500 characters)")}
        />
        <.input
          field={@profile_form[:website_url]}
          type="url"
          label={gettext("Website URL")}
          placeholder="https://example.com"
        />
        <.input
          field={@profile_form[:bluesky_handle]}
          type="text"
          label={gettext("Bluesky Handle")}
          placeholder="@username.bsky.social"
        />
        <.input
          field={@profile_form[:mastodon_handle]}
          type="text"
          label={gettext("Mastodon Handle")}
          placeholder="@username@mastodon.social"
        />
        <.input
          field={@profile_form[:preferred_language]}
          type="select"
          label={gettext("Preferred Language")}
          options={[{"English", "en"}, {"Suomi (Finnish)", "fi"}]}
        />
        <.button variant="primary" phx-disable-with={gettext("Saving...")}>
          {gettext("Update Profile")}
        </.button>
      </.form>

      <div class="divider" />

      <.form for={@email_form} id="email_form" phx-submit="update_email" phx-change="validate_email">
        <.input
          field={@email_form[:email]}
          type="email"
          label={gettext("Email")}
          autocomplete="username"
          required
        />
        <.button variant="primary" phx-disable-with={gettext("Changing...")}>
          {gettext("Change Email")}
        </.button>
      </.form>

      <div class="divider" />

      <.form
        for={@password_form}
        id="password_form"
        action={~p"/users/update-password"}
        method="post"
        phx-change="validate_password"
        phx-submit="update_password"
        phx-trigger-action={@trigger_submit}
      >
        <input
          name={@password_form[:email].name}
          type="hidden"
          id="hidden_user_email"
          autocomplete="username"
          value={@current_email}
        />
        <.input
          field={@password_form[:password]}
          type="password"
          label={gettext("New password")}
          autocomplete="new-password"
          required
        />
        <.input
          field={@password_form[:password_confirmation]}
          type="password"
          label={gettext("Confirm new password")}
          autocomplete="new-password"
        />
        <.button variant="primary" phx-disable-with={gettext("Saving...")}>
          {gettext("Save Password")}
        </.button>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, gettext("Email changed successfully."))

        {:error, _} ->
          put_flash(socket, :error, gettext("Email change link is invalid or it has expired."))
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)
    profile_changeset = Accounts.change_user_profile(user, %{})

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:profile_form, to_form(profile_changeset))
      |> assign(:trigger_submit, false)
      |> allow_upload(:avatar,
        accept: ~w(.jpg .jpeg .png),
        max_entries: 1,
        max_file_size: 5_000_000,
        auto_upload: true
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        info = gettext("A link to confirm your email change has been sent to the new address.")
        {:noreply, socket |> put_flash(:info, info)}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_profile", params, socket) do
    %{"user" => user_params} = params

    profile_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_profile(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, profile_form: profile_form)}
  end

  def handle_event("update_profile", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user

    # Handle avatar upload
    user_params =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
        # Generate unique filename
        ext = Path.extname(entry.client_name)
        filename = "#{user.id}_#{System.system_time(:millisecond)}#{ext}"
        dest = Path.join(["priv", "static", "uploads", "avatars", filename])

        # Copy file to destination
        File.cp!(path, dest)

        # Return the public path
        {:ok, "/uploads/avatars/#{filename}"}
      end)
      |> case do
        [avatar_path] -> Map.put(user_params, "avatar", avatar_path)
        [] -> user_params
      end

    case Accounts.update_user_profile(user, user_params) do
      {:ok, updated_user} ->
        # Update the current_scope with the new user data
        scope = %{socket.assigns.current_scope | user: updated_user}

        socket
        |> assign(:current_scope, scope)
        |> assign(:profile_form, to_form(Accounts.change_user_profile(updated_user, %{})))
        |> put_flash(:info, gettext("Profile updated successfully."))
        |> then(&{:noreply, &1})

      {:error, changeset} ->
        {:noreply, assign(socket, profile_form: to_form(changeset, action: :insert))}
    end
  end
end
