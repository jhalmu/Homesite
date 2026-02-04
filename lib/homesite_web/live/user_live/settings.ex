defmodule HomesiteWeb.UserLive.Settings do
  use HomesiteWeb, :live_view

  on_mount {HomesiteWeb.UserAuth, :require_sudo_mode}

  alias Homesite.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="technical-main">
        <div class="text-center">
          <.header>
            {gettext("Account Settings")}
            <:subtitle>
              {gettext("Manage your profile, email address and password settings")}
            </:subtitle>
            <:actions>
              <.link
                href="https://github.com/jhalmu/Homesite/blob/main/docs/guides/USERNAME_ROUTING.md"
                target="_blank"
                class="text-sm font-semibold text-zinc-900 hover:text-zinc-700 dark:text-zinc-100 dark:hover:text-zinc-300"
              >
                <.icon name="hero-question-mark-circle" class="h-5 w-5" /> {gettext("Username Help")}
              </.link>
            </:actions>
          </.header>
        </div>

        <.form
          for={@profile_form}
          id="profile_form"
          phx-submit="update_profile"
          phx-change="validate_profile"
        >
          <div class="gap-[var(--space-md)] flex flex-col items-center">
            <div
              class="gap-[var(--space-md)] flex flex-col items-center"
              id="avatar-upload-container"
              phx-hook="AvatarPreview"
            >
              <.avatar user={@current_scope.user} class="h-24 w-24" id="avatar-preview" />
              <.live_file_input
                upload={@uploads.avatar}
                class="file-input file-input-bordered"
                style="min-width: 20rem;"
                aria-label={gettext("Choose avatar image file")}
              />
              <p class="mb-[var(--space-md)] text-[var(--text-sm)] text-gray-600 dark:text-gray-400">
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
          >
            <:help>
              {gettext(
                "Your display name appears on your posts and profile. This can be your real name or a pseudonym. Maximum 100 characters."
              )}
            </:help>
          </.input>
          <.input
            field={@profile_form[:username]}
            type="text"
            label={gettext("Username")}
            placeholder="johndoe"
          >
            <:help>
              {gettext(
                "Your unique username for your profile URL (e.g., /users/@johndoe). Must be 3-30 characters, start with a letter, and contain only lowercase letters, numbers, and underscores. Leave empty to use your user ID in URLs."
              )}
            </:help>
          </.input>
          <.input
            field={@profile_form[:bio]}
            type="textarea"
            label={gettext("Bio")}
            placeholder={gettext("Tell us about yourself (max 500 characters)")}
          >
            <:help>
              {gettext(
                "Write a brief description about yourself. This appears on your public profile. Maximum 500 characters."
              )}
            </:help>
          </.input>
          <.input
            field={@profile_form[:website_url]}
            type="url"
            label={gettext("Website URL")}
            placeholder="https://example.com"
          >
            <:help>
              {gettext(
                "Your personal website, blog, or portfolio URL. Must start with http:// or https://. This link will appear on your public profile."
              )}
            </:help>
          </.input>
          <.input
            field={@profile_form[:bluesky_handle]}
            type="text"
            label={gettext("Bluesky Handle")}
            placeholder="@username.bsky.social"
          >
            <:help>
              {gettext(
                "Your Bluesky username in the format @username.bsky.social or @username.custom-domain.com. This will be linked from your profile."
              )}
            </:help>
          </.input>
          <.input
            field={@profile_form[:mastodon_handle]}
            type="text"
            label={gettext("Mastodon Handle")}
            placeholder="@username@mastodon.social"
          >
            <:help>
              {gettext(
                "Your Mastodon handle in the format @username@instance.social. Include both your username and instance. This will be linked from your profile."
              )}
            </:help>
          </.input>
          <.input
            field={@profile_form[:preferred_language]}
            type="select"
            label={gettext("Preferred Language")}
            options={[{"English", "en"}, {"Suomi (Finnish)", "fi"}]}
          >
            <:help>
              {gettext(
                "Choose your preferred language for the user interface. This setting affects menus, buttons, and system messages throughout the application."
              )}
            </:help>
          </.input>
          <.input
            field={@profile_form[:timezone]}
            type="select"
            label={gettext("Timezone")}
            options={timezone_options()}
          >
            <:help>
              {gettext(
                "Your timezone affects how dates and times are displayed. The 'Now' button when creating posts will use this timezone."
              )}
            </:help>
          </.input>
          <%= if @avatar_pending do %>
            <div class="alert alert-warning mb-[var(--space-sm)]">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-6 w-6 shrink-0 stroke-current"
                fill="none"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                />
              </svg>
              <span>
                {gettext("Avatar image selected. Click 'Update Profile' below to save your changes!")}
              </span>
            </div>
          <% end %>
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
          >
            <:help>
              {gettext(
                "Your email address is used for login and notifications. Changing it will send a confirmation link to the new address. Your old email remains active until confirmed."
              )}
            </:help>
          </.input>
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
          >
            <:help>
              {gettext(
                "Choose a strong password with at least 12 characters. Use a mix of uppercase, lowercase, numbers, and special characters for better security."
              )}
            </:help>
          </.input>
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label={gettext("Confirm new password")}
            autocomplete="new-password"
          >
            <:help>
              {gettext(
                "Re-enter your new password exactly as above to confirm. This helps prevent typos when setting your password."
              )}
            </:help>
          </.input>
          <.button variant="primary" phx-disable-with={gettext("Saving...")}>
            {gettext("Save Password")}
          </.button>
        </.form>

        <div class="divider" />

        <%!-- Data Export Section (GDPR) --%>
        <div class="border-base-300 rounded-box p-[var(--space-md)] border">
          <h3 class="mb-[var(--space-sm)] text-[var(--text-lg)] font-bold">
            <.icon name="hero-arrow-down-tray" class="mr-2 inline h-5 w-5" />
            {gettext("Download my data")}
          </h3>
          <p class="text-base-content/70 mb-[var(--space-md)]">
            {gettext(
              "Download all your personal data in a ZIP file. Includes your profile, posts, and tags in JSON format."
            )}
          </p>

          <%= if @can_export_data do %>
            <button
              type="button"
              phx-click="export_data"
              phx-hook="Download"
              id="download-data-btn"
              class="btn btn-outline"
              phx-disable-with={gettext("Generating...")}
            >
              <.icon name="hero-arrow-down-tray" class="h-4 w-4" />
              {gettext("Download my data")}
            </button>
          <% else %>
            <div class="alert alert-info">
              <.icon name="hero-clock" class="h-5 w-5" />
              <span>
                {gettext(
                  "You can export your data once every 24 hours. Please try again later."
                )}
              </span>
            </div>
          <% end %>

          <p class="text-base-content/60 mt-[var(--space-sm)] text-[var(--text-sm)]">
            <.link navigate={~p"/privacy"} class="link link-hover">
              {gettext("Privacy Policy")}
            </.link>
          </p>
        </div>

        <div class="divider" />

        <%!-- Danger Zone: Delete Account --%>
        <div class="border-error/50 rounded-box p-[var(--space-md)] border-2">
          <h3 class="text-error mb-[var(--space-sm)] text-[var(--text-lg)] font-bold">
            <.icon name="hero-exclamation-triangle" class="mr-2 inline h-5 w-5" />
            {gettext("Danger Zone")}
          </h3>
          <p class="text-base-content/70 mb-[var(--space-md)]">
            {gettext("Permanently delete your account. This action cannot be undone.")}
          </p>

          <div class="gap-[var(--space-sm)] flex flex-wrap">
            <button
              type="button"
              phx-click="show_delete_modal"
              phx-value-mode="anonymize"
              class="btn btn-outline btn-error"
            >
              <.icon name="hero-user-minus" class="h-4 w-4" />
              {gettext("Delete Account (Keep Content)")}
            </button>
            <button
              type="button"
              phx-click="show_delete_modal"
              phx-value-mode="full"
              class="btn btn-error"
            >
              <.icon name="hero-trash" class="h-4 w-4" />
              {gettext("Delete Everything")}
            </button>
          </div>

          <p class="text-base-content/60 mt-[var(--space-sm)] text-[var(--text-sm)]">
            {gettext(
              "\"Keep Content\" anonymizes your posts (author shown as \"Deleted User\"). \"Delete Everything\" removes all your data."
            )}
          </p>
        </div>

        <%!-- Delete Account Confirmation Modal --%>
        <%= if @show_delete_modal do %>
          <div class="modal modal-open">
            <div class="modal-box">
              <h3 class="text-error text-[var(--text-lg)] font-bold">
                <%= if @delete_mode == "full" do %>
                  {gettext("Delete Account and All Content")}
                <% else %>
                  {gettext("Delete Account (Keep Content)")}
                <% end %>
              </h3>

              <div class="alert alert-error my-[var(--space-md)]">
                <.icon name="hero-exclamation-triangle" class="h-5 w-5" />
                <span>
                  <%= if @delete_mode == "full" do %>
                    {gettext(
                      "This will permanently delete your account and ALL your posts, tags, and other content. This cannot be undone!"
                    )}
                  <% else %>
                    {gettext(
                      "This will delete your account. Your posts will remain but will be shown as \"Deleted User\". This cannot be undone!"
                    )}
                  <% end %>
                </span>
              </div>

              <.form
                for={@delete_form}
                phx-submit="confirm_delete_account"
                class="space-y-[var(--space-sm)]"
              >
                <p class="text-base-content/70">
                  {gettext("Type your email address to confirm:")}
                </p>
                <.input
                  field={@delete_form[:email_confirmation]}
                  type="email"
                  placeholder={@current_email}
                  required
                  autocomplete="off"
                />
                <input type="hidden" name="delete_mode" value={@delete_mode} />

                <div class="modal-action">
                  <button type="button" phx-click="hide_delete_modal" class="btn">
                    {gettext("Cancel")}
                  </button>
                  <button
                    type="submit"
                    class="btn btn-error"
                    phx-disable-with={gettext("Deleting...")}
                  >
                    {gettext("Permanently Delete")}
                  </button>
                </div>
              </.form>
            </div>
            <div class="modal-backdrop" phx-click="hide_delete_modal"></div>
          </div>
        <% end %>

        <%!-- Username Celebration Modal --%>
        <%= if assigns[:show_celebration] && @show_celebration do %>
          <div class="modal modal-open">
            <div class="modal-box max-w-2xl">
              <h3 class="mb-[var(--space-sm)] text-[var(--text-2xl)] font-bold">
                🎉 {gettext("Congratulations! Your Username is Live!")}
              </h3>

              <p class="mb-[var(--space-md)] text-[var(--text-lg)]">
                {gettext("Your personal homepage is now available at:")}
              </p>

              <div class="bg-base-200 mb-[var(--space-md)] p-[var(--space-sm)] rounded-lg">
                <code class="text-[var(--text-lg)] break-all">
                  {url(~p"/users/@#{@current_scope.user.username}")}
                </code>
              </div>

              <p class="mb-[var(--space-md)]">{gettext("Share your new homepage with the world!")}</p>

              <div class="mb-[var(--space-sm)] gap-[var(--space-sm)] flex">
                <button
                  type="button"
                  phx-click="share_username"
                  phx-hook="Share"
                  id="share-username-btn"
                  class="btn btn-primary flex-1"
                >
                  <.icon name="hero-share" class="h-5 w-5" />
                  {gettext("Share")}
                </button>
                <button
                  type="button"
                  phx-click="copy_username_url"
                  phx-hook="CopyToClipboard"
                  id="copy-username-btn"
                  class="btn btn-outline"
                >
                  <.icon name="hero-clipboard" class="h-5 w-5" />
                  {gettext("Copy")}
                </button>
              </div>

              <div class="modal-action">
                <button type="button" phx-click="close_celebration" class="btn">
                  {gettext("Close")}
                </button>
              </div>
            </div>
          </div>
        <% end %>
      </div>
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
      |> assign(:avatar_pending, false)
      |> assign(:show_celebration, false)
      |> assign(:show_delete_modal, false)
      |> assign(:delete_mode, nil)
      |> assign(:delete_form, to_form(%{"email_confirmation" => ""}))
      |> assign(:can_export_data, Accounts.can_export_data?(user))
      |> allow_upload(:avatar,
        accept: ~w(.jpg .jpeg .png),
        max_entries: 1,
        max_file_size: 5_000_000,
        auto_upload: true
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_profile", params, socket) do
    %{"user" => user_params} = params

    # Check if an avatar file has been selected
    has_avatar_upload? = length(socket.assigns.uploads.avatar.entries) > 0

    socket =
      if has_avatar_upload? do
        socket
        |> assign(:avatar_pending, true)
        |> put_flash(
          :warning,
          gettext(
            "⚠️ Avatar selected but not saved yet. Click 'Update Profile' to save your changes!"
          )
        )
      else
        assign(socket, :avatar_pending, false)
      end

    profile_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_profile(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, profile_form: profile_form)}
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

  def handle_event("update_profile", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    old_username = user.username

    # Handle avatar upload and track if one was uploaded
    {user_params, avatar_uploaded?} =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
        # Generate unique filename
        ext = Path.extname(entry.client_name)
        filename = "#{user.id}_#{System.system_time(:millisecond)}#{ext}"

        # Use UPLOADS_PATH env var in production, fallback to priv/static for dev
        uploads_base = System.get_env("UPLOADS_PATH") || Path.join(["priv", "static", "uploads"])
        dest_dir = Path.join([uploads_base, "avatars"])
        File.mkdir_p!(dest_dir)
        dest = Path.join([dest_dir, filename])

        # Copy file to destination
        File.cp!(path, dest)

        # Return the public path
        {:ok, "/uploads/avatars/#{filename}"}
      end)
      |> case do
        [avatar_path] -> {Map.put(user_params, "avatar", avatar_path), true}
        [] -> {user_params, false}
      end

    case Accounts.update_user_profile(user, user_params) do
      {:ok, updated_user} ->
        # Update the current_scope with the new user data
        scope = %{socket.assigns.current_scope | user: updated_user}

        # Detect if username was just claimed (not just updated)
        show_celebration = old_username == nil && updated_user.username != nil

        # Show reminder if avatar was uploaded
        flash_message =
          if avatar_uploaded? do
            gettext(
              "Profile updated successfully. Remember to also update your display name, bio, and social links to complete your profile!"
            )
          else
            gettext("Profile updated successfully.")
          end

        socket
        |> assign(:current_scope, scope)
        |> assign(:profile_form, to_form(Accounts.change_user_profile(updated_user, %{})))
        |> assign(:avatar_pending, false)
        |> assign(:show_celebration, show_celebration)
        |> put_flash(:info, flash_message)
        |> then(&{:noreply, &1})

      {:error, changeset} ->
        {:noreply, assign(socket, profile_form: to_form(changeset, action: :insert))}
    end
  end

  def handle_event("close_celebration", _params, socket) do
    {:noreply, assign(socket, show_celebration: false)}
  end

  def handle_event("share_username", _params, socket) do
    user = socket.assigns.current_scope.user
    profile_url = url(~p"/users/@#{user.username}")
    title = "Check out my new homepage!"

    {:noreply,
     push_event(socket, "share", %{
       title: title,
       text: "I just set up my personal homepage at #{profile_url}",
       url: profile_url
     })}
  end

  def handle_event("copy_username_url", _params, socket) do
    user = socket.assigns.current_scope.user
    profile_url = url(~p"/users/@#{user.username}")

    {:noreply,
     socket
     |> put_flash(:info, "Profile URL copied to clipboard!")
     |> push_event("copy-to-clipboard", %{text: profile_url})}
  end

  def handle_event("show_delete_modal", %{"mode" => mode}, socket) do
    {:noreply,
     socket
     |> assign(:show_delete_modal, true)
     |> assign(:delete_mode, mode)
     |> assign(:delete_form, to_form(%{"email_confirmation" => ""}))}
  end

  def handle_event("hide_delete_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_delete_modal, false)
     |> assign(:delete_mode, nil)}
  end

  def handle_event(
        "confirm_delete_account",
        %{"email_confirmation" => email, "delete_mode" => mode},
        socket
      ) do
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    if String.downcase(email) == String.downcase(user.email) do
      case Accounts.delete_user_account(user, mode) do
        {:ok, _} ->
          {:noreply,
           socket
           |> put_flash(:info, gettext("Your account has been deleted. Goodbye!"))
           |> redirect(to: ~p"/")}

        {:error, reason} ->
          {:noreply,
           socket
           |> assign(:show_delete_modal, false)
           |> put_flash(
             :error,
             gettext("Failed to delete account: %{reason}", reason: inspect(reason))
           )}
      end
    else
      {:noreply,
       socket
       |> assign(:delete_form, to_form(%{"email_confirmation" => email}))
       |> put_flash(
         :error,
         gettext("Email does not match. Please enter your email address exactly.")
       )}
    end
  end

  @impl true
  def handle_event("export_data", _params, socket) do
    user = socket.assigns.current_scope.user

    if Accounts.can_export_data?(user) do
      {:ok, zip_binary} = Accounts.export_user_data(user)

      # Update last export timestamp
      now = DateTime.utc_now(:second)
      {:ok, _user} = Accounts.update_last_data_export(user, now)

      # Generate filename with timestamp
      timestamp = Calendar.strftime(now, "%Y%m%d_%H%M%S")
      filename = "data_export_#{timestamp}.zip"

      {:noreply,
       socket
       |> assign(:can_export_data, false)
       |> push_event("download", %{
         data: Base.encode64(zip_binary),
         filename: filename,
         content_type: "application/zip"
       })}
    else
      {:noreply,
       put_flash(
         socket,
         :error,
         gettext("You can only export data once every 24 hours.")
       )}
    end
  end

  # Build timezone options with friendly labels
  defp timezone_options do
    Homesite.Accounts.User.supported_timezones()
    |> Enum.map(fn tz ->
      label = tz |> String.replace("_", " ") |> String.replace("/", " / ")
      {label, tz}
    end)
  end
end
