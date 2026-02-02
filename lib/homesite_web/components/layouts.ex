defmodule HomesiteWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use HomesiteWeb, :html

  import HomesiteWeb.Components.NotificationBell

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    # Fetch admins sorted by flower count (most to least)
    admins =
      Homesite.Accounts.list_admins()
      |> Enum.sort_by(& &1.admin_flowers, :desc)

    assigns = assign(assigns, :admins, admins)

    ~H"""
    <main
      id="main-content"
      tabindex="-1"
      role="main"
      class="px-[var(--spacing-card)] py-[var(--spacing-lg)] min-h-screen"
    >
      <div class="max-w-[var(--content-max-width)] space-y-[var(--spacing-md)] mx-auto">
        {render_slot(@inner_block)}
      </div>
    </main>

    <footer
      role="contentinfo"
      class="from-base-200 to-base-300 border-base-300 mt-[var(--spacing-section)] border-t bg-gradient-to-r"
    >
      <div class="max-w-[var(--content-max-width)] px-[var(--spacing-card)] py-[var(--spacing-lg)] mx-auto">
        <div class={[
          "gap-[var(--space-lg)] grid",
          "grid-cols-1",
          "sm:grid-cols-2",
          "lg:grid-cols-4",
          @current_scope && "lg:grid-cols-5"
        ]}>
          <div class="gap-[var(--space-sm)] flex flex-col">
            <.pegasus class="h-20 w-20" />
            <p class="font-semibold">
              Orangedinos <br />
              <span class="text-[var(--text-sm)] font-normal opacity-70">
                {gettext("Your personal space on the web")}
              </span>
            </p>
          </div>
          <div class="gap-[var(--space-xs)] flex flex-col">
            <span class="footer-title">{gettext("Platform")}</span>
            <a href="/" class="link-hover link">{gettext("Home")}</a>
            <%= if @current_scope do %>
              <a href="/dashboard" class="link-hover link">{gettext("Dashboard")}</a>
              <a href="/posts" class="link-hover link">{gettext("Posts")}</a>
              <a href="/tags" class="link-hover link">{gettext("Tags")}</a>
            <% end %>
          </div>
          <div class="gap-[var(--space-xs)] flex flex-col">
            <span class="footer-title">{gettext("Built with")}</span>
            <p class="text-[var(--text-sm)] opacity-70">{gettext("Phoenix Framework")}</p>
            <p class="text-[var(--text-sm)] opacity-70">{gettext("Elixir")}</p>
            <p class="text-[var(--text-sm)] opacity-70">{gettext("Tailwind CSS & DaisyUI")}</p>
          </div>
          <div class="gap-[var(--space-xs)] flex flex-col">
            <span class="footer-title">{gettext("Subscribe")}</span>
            <.link
              href={~p"/rss.xml"}
              target="_blank"
              rel="noopener noreferrer"
              class="link-hover link gap-[var(--spacing-inline)] flex items-center"
            >
              <.icon name="hero-rss" class="h-4 w-4" />
              {gettext("RSS Feed")}
            </.link>
            <.link
              href={~p"/feed.json"}
              target="_blank"
              rel="noopener noreferrer"
              class="link-hover link gap-[var(--spacing-inline)] flex items-center"
            >
              <.icon name="hero-code-bracket" class="h-4 w-4" />
              {gettext("JSON Feed")}
            </.link>
            <.link
              href={~p"/feed.xml"}
              target="_blank"
              rel="noopener noreferrer"
              class="link-hover link gap-[var(--spacing-inline)] flex items-center"
            >
              <.icon name="hero-rss" class="h-4 w-4" />
              {gettext("Atom Feed")}
            </.link>
          </div>
          <%= if @current_scope do %>
            <div class="gap-[var(--space-xs)] flex flex-col">
              <span class="footer-title">{gettext("Feedback")}</span>
              <.link
                href={~p"/feedback"}
                class="link-hover link gap-[var(--spacing-inline)] flex items-center"
              >
                <.icon name="hero-chat-bubble-left-right" class="h-4 w-4" />
                {gettext("Share Your Feedback")}
              </.link>
              <p class="text-[var(--text-sm)] opacity-70">
                {gettext("Help us improve!")}
              </p>
            </div>
          <% end %>
        </div>
        <%!-- Admin list --%>
        <%= if @admins != [] do %>
          <div class="mt-[var(--space-md)] pt-[var(--space-md)] border-base-300 border-t">
            <span class="footer-title">{gettext("Site Admins")}</span>
            <div class="gap-[var(--space-sm)] mt-[var(--space-xs)] flex flex-wrap">
              <%= for admin <- @admins do %>
                <span class="whitespace-nowrap opacity-70">
                  {admin.display_name || admin.email |> String.split("@") |> hd()}
                  <span class="ml-1">{String.duplicate("🌸", admin.admin_flowers || 1)}</span>
                </span>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
      <div class="border-base-300 bg-base-200/50 px-[var(--spacing-card)] py-[var(--spacing-md)] text-[var(--text-sm)] border-t text-center opacity-70">
        <p>
          © {Date.utc_today().year} Orangedinos. {gettext("Built with ❤️ and Elixir.")}
        </p>
      </div>
    </footer>

    <.flash_group flash={@flash} />

    <%!-- Feedback Prompt Modal (Active) --%>
    <%= if @current_scope && !@current_scope.admin_override? do %>
      <.live_component
        module={HomesiteWeb.FeedbackLive.PromptModal}
        id="feedback-prompt"
        current_scope={@current_scope}
      />
    <% end %>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="size-3 ml-1 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="size-3 ml-1 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders the main navigation bar.

  Displays the Pegasus logo, site name, navigation links, and user menu.
  Follows MODERN_CSS_GUIDE.md patterns with fluid sizing and spacing.

  ## Examples

      <.navbar current_scope={@current_scope} />
  """
  attr :current_scope, :map, default: nil, doc: "the current user scope"

  def navbar(assigns) do
    ~H"""
    <header class="technical-header" role="banner">
      <div class="header-content">
        <div class="flex-1">
          <.link
            navigate={~p"/"}
            class="btn btn-ghost text-[var(--font-size-fluid-lg)] gap-[var(--spacing-sm)] items-center"
          >
            <.pegasus class="h-20 w-20" />
            <span class="font-display">Orangedinos</span>
          </.link>
        </div>

        <%!-- Mobile menu button --%>
        <div class="flex-none lg:hidden">
          <button
            class="btn btn-square btn-ghost"
            onclick="mobile_menu.showModal()"
            aria-label={gettext("Open menu")}
            aria-controls="mobile_menu"
            aria-haspopup="dialog"
          >
            <.icon name="hero-bars-3" class="h-6 w-6" />
          </button>
        </div>

        <%!-- Desktop navigation --%>
        <nav
          class="gap-[var(--spacing-sm)] hidden flex-none lg:flex"
          role="navigation"
          aria-label={gettext("Main navigation")}
        >
          <ul class="menu menu-horizontal gap-[var(--spacing-xs)]">
            <li class="nav-item">
              <.link navigate={~p"/search"} class="nav-link">
                <.icon name="hero-magnifying-glass" class="h-5 w-5" />
                {gettext("Search")}
              </.link>
            </li>
            <li class="nav-item">
              <.link navigate={~p"/portfolio"} class="nav-link">
                <.icon name="hero-folder" class="h-5 w-5" />
                {gettext("Portfolio")}
              </.link>
            </li>
            <%= if @current_scope do %>
              <li class="nav-item">
                <.link navigate={~p"/dashboard"} class="nav-link">{gettext("Dashboard")}</.link>
              </li>
              <li class="nav-item">
                <.link navigate={~p"/feed"} class="nav-link">{gettext("Feed")}</.link>
              </li>
              <li class="nav-item">
                <.link navigate={~p"/following"} class="nav-link">{gettext("Following")}</.link>
              </li>
              <li class="nav-item">
                <.link navigate={~p"/posts"} class="nav-link">{gettext("Posts")}</.link>
              </li>
              <li class="nav-item">
                <.link navigate={~p"/tags"} class="nav-link">{gettext("Tags")}</.link>
              </li>
              <li class="nav-item">
                <.link navigate={~p"/chat"} class="nav-link relative">
                  {gettext("Chat")}
                  <.chat_online_indicator />
                </.link>
              </li>
              <li class="nav-item">
                <.link navigate={~p"/faqs"} class="nav-link">{gettext("FAQs")}</.link>
              </li>
              <%= if Homesite.Accounts.Scope.admin?(@current_scope) do %>
                <li class="nav-item">
                  <.link navigate={~p"/admin"} class="nav-link">{gettext("Admin")}</.link>
                </li>
              <% end %>
              <li>
                <.notification_bell unread_count={0} />
              </li>
              <li>
                <details>
                  <summary class="gap-[var(--space-xs)] flex items-center">
                    <.avatar user={@current_scope.user} class="h-8 w-8" />
                    <span>{@current_scope.user.display_name || @current_scope.user.email}</span>
                  </summary>
                  <ul class="bg-base-200 border-base-300 p-[var(--space-xs)] z-50 rounded-t-none border shadow-lg">
                    <li>
                      <.link navigate={
                        if @current_scope.user.username,
                          do: ~p"/users/@#{@current_scope.user.username}",
                          else: ~p"/users/#{@current_scope.user.id}"
                      }>
                        <.icon name="hero-user-circle" class="h-4 w-4" /> {gettext("My Profile")}
                      </.link>
                    </li>
                    <li>
                      <.link navigate={~p"/users/settings"}>
                        <.icon name="hero-cog-6-tooth" class="h-4 w-4" /> {gettext("Settings")}
                      </.link>
                    </li>
                    <li>
                      <.link href={~p"/users/log-out"} method="delete">
                        <.icon name="hero-arrow-right-on-rectangle" class="h-4 w-4" /> {gettext(
                          "Log out"
                        )}
                      </.link>
                    </li>
                  </ul>
                </details>
              </li>
            <% else %>
              <li class="nav-item">
                <.link navigate={~p"/faqs"} class="nav-link">{gettext("FAQs")}</.link>
              </li>
              <li class="nav-item">
                <.link navigate={~p"/users/register"} class="nav-link">{gettext("Register")}</.link>
              </li>
              <li class="nav-item">
                <.link navigate={~p"/users/log-in"} class="nav-link">
                  {gettext("Log in")}
                </.link>
              </li>
            <% end %>
            <%= if !@current_scope do %>
              <li>
                <.language_toggle />
              </li>
            <% end %>
            <li>
              <.theme_toggle />
            </li>
          </ul>
        </nav>
      </div>
    </header>

    <%!-- Mobile navigation modal --%>
    <dialog id="mobile_menu" class="modal" aria-label={gettext("Mobile navigation")}>
      <div class="modal-box">
        <form method="dialog">
          <button
            class="btn btn-sm btn-circle btn-ghost top-[var(--space-xs)] right-[var(--space-xs)] absolute"
            aria-label={gettext("Close menu")}
          >
            <.icon name="hero-x-mark" class="h-5 w-5" />
          </button>
        </form>

        <h3 class="font-display mb-[var(--space-sm)] text-[var(--text-lg)] font-bold">
          {gettext("Menu")}
        </h3>

        <ul class="menu menu-vertical gap-[var(--space-xs)]">
          <li>
            <.link navigate={~p"/portfolio"} class="text-base">
              <.icon name="hero-folder" class="h-5 w-5" /> {gettext("Portfolio")}
            </.link>
          </li>
          <%= if @current_scope do %>
            <li>
              <.link navigate={~p"/dashboard"} class="text-base">
                <.icon name="hero-home" class="h-5 w-5" /> {gettext("Dashboard")}
              </.link>
            </li>
            <li>
              <.link navigate={~p"/feed"} class="text-base">
                <.icon name="hero-rss" class="h-5 w-5" /> {gettext("Feed")}
              </.link>
            </li>
            <li>
              <.link navigate={~p"/following"} class="text-base">
                <.icon name="hero-user-group" class="h-5 w-5" /> {gettext("Following")}
              </.link>
            </li>
            <li>
              <.link navigate={~p"/posts"} class="text-base">
                <.icon name="hero-document-text" class="h-5 w-5" /> {gettext("Posts")}
              </.link>
            </li>
            <li>
              <.link navigate={~p"/tags"} class="text-base">
                <.icon name="hero-tag" class="h-5 w-5" /> {gettext("Tags")}
              </.link>
            </li>
            <li>
              <.link navigate={~p"/chat"} class="text-base">
                <.icon name="hero-chat-bubble-left-right" class="h-5 w-5" /> {gettext("Chat")}
              </.link>
            </li>
            <li>
              <.link navigate={~p"/faqs"} class="text-base">
                <.icon name="hero-question-mark-circle" class="h-5 w-5" /> {gettext("FAQs")}
              </.link>
            </li>
            <%= if Homesite.Accounts.Scope.admin?(@current_scope) do %>
              <li>
                <.link navigate={~p"/admin"} class="text-base">
                  <.icon name="hero-shield-check" class="h-5 w-5" /> {gettext("Admin")}
                </.link>
              </li>
            <% end %>

            <div class="divider my-[var(--space-xs)]"></div>

            <li>
              <div class="gap-[var(--space-sm)] px-[var(--space-sm)] py-[var(--space-xs)] flex items-center">
                <.avatar user={@current_scope.user} class="h-10 w-10" />
                <div class="flex flex-col">
                  <span class="text-[var(--text-sm)] font-semibold">
                    {@current_scope.user.display_name || @current_scope.user.email}
                  </span>
                  <span class="text-[var(--text-xs)] opacity-70">{@current_scope.user.email}</span>
                </div>
              </div>
            </li>

            <li>
              <.link
                navigate={
                  if @current_scope.user.username,
                    do: ~p"/users/@#{@current_scope.user.username}",
                    else: ~p"/users/#{@current_scope.user.id}"
                }
                class="text-[var(--text-base)]"
              >
                <.icon name="hero-user-circle" class="h-5 w-5" /> {gettext("My Profile")}
              </.link>
            </li>
            <li>
              <.link navigate={~p"/notifications"} class="text-base">
                <.icon name="hero-bell" class="h-5 w-5" /> {gettext("Notifications")}
              </.link>
            </li>
            <li>
              <.link navigate={~p"/users/settings"} class="text-base">
                <.icon name="hero-cog-6-tooth" class="h-5 w-5" /> {gettext("Settings")}
              </.link>
            </li>
            <li>
              <.link href={~p"/users/log-out"} method="delete" class="text-error text-base">
                <.icon name="hero-arrow-right-on-rectangle" class="h-5 w-5" /> {gettext("Log out")}
              </.link>
            </li>
          <% else %>
            <li>
              <.link navigate={~p"/faqs"} class="text-base">
                <.icon name="hero-question-mark-circle" class="h-5 w-5" /> {gettext("FAQs")}
              </.link>
            </li>
            <li>
              <.link navigate={~p"/users/register"} class="text-base">
                <.icon name="hero-user-plus" class="h-5 w-5" /> {gettext("Register")}
              </.link>
            </li>
            <li>
              <.link navigate={~p"/users/log-in"} class="btn btn-primary">
                <.icon name="hero-arrow-right-on-rectangle" class="h-5 w-5" /> {gettext("Log in")}
              </.link>
            </li>
          <% end %>

          <div class="divider my-[var(--space-xs)]"></div>

          <%= if !@current_scope do %>
            <li class="px-[var(--space-sm)]">
              <div class="flex items-center justify-between">
                <span class="text-[var(--text-sm)] opacity-70">{gettext("Language")}</span>
                <.language_toggle />
              </div>
            </li>
          <% end %>
          <li class="px-[var(--space-sm)]">
            <div class="flex items-center justify-between">
              <span class="text-[var(--text-sm)] opacity-70">{gettext("Theme")}</span>
              <.theme_toggle />
            </div>
          </li>
        </ul>
      </div>

      <form method="dialog" class="modal-backdrop">
        <button>close</button>
      </form>
    </dialog>
    """
  end

  @doc """
  Provides language toggle between English and Finnish.

  Persists selection in localStorage and reloads page to apply new locale.
  Styled similarly to theme_toggle for consistency.
  """
  def language_toggle(assigns) do
    ~H"""
    <div class="card border-base-300 bg-base-300 relative flex flex-row items-center rounded-full border">
      <div class="border-1 border-base-200 bg-base-100 [[data-locale=en]_&]:left-0 [[data-locale=fi]_&]:left-1/2 transition-[left] pointer-events-none absolute h-full w-1/2 rounded-full brightness-200" />

      <button
        type="button"
        class="p-[var(--space-inline)] text-[var(--text-xs)] relative z-10 flex w-1/2 cursor-pointer items-center justify-center font-semibold opacity-75 hover:opacity-100"
        phx-click={JS.dispatch("phx:set-locale")}
        data-phx-locale="en"
        aria-label={gettext("Switch to English")}
      >
        EN
      </button>

      <button
        type="button"
        class="p-[var(--space-inline)] text-[var(--text-xs)] relative z-10 flex w-1/2 cursor-pointer items-center justify-center font-semibold opacity-75 hover:opacity-100"
        phx-click={JS.dispatch("phx:set-locale")}
        data-phx-locale="fi"
        aria-label={gettext("Vaihda suomeksi")}
      >
        FI
      </button>
    </div>
    """
  end

  @doc """
  Provides theme switcher dropdown with all available DaisyUI themes.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="dropdown dropdown-end">
      <div
        tabindex="0"
        role="button"
        class="btn btn-sm btn-ghost gap-[var(--space-inline)]"
        aria-label={gettext("Change theme")}
        aria-haspopup="menu"
      >
        <!-- Sun icon (visible in light theme) -->
        <.icon name="hero-sun" class="h-5 w-5 dark:hidden" />
        <!-- Moon icon (visible in dark theme) -->
        <.icon name="hero-moon" class="hidden h-5 w-5 dark:block" />
        <.icon name="hero-chevron-down" class="h-3 w-3 opacity-60" />
      </div>
      <ul
        tabindex="0"
        role="menu"
        class="dropdown-content menu bg-base-200 rounded-box z-[1] border-base-300 mt-[var(--space-xs)] p-[var(--space-xs)] w-52 border shadow-lg"
      >
        <li role="none">
          <button
            type="button"
            role="menuitem"
            class="gap-[var(--space-xs)] flex items-center"
            phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "light"})}
          >
            <.icon name="hero-sun" class="h-4 w-4" />
            <span>{gettext("Light")}</span>
          </button>
        </li>
        <li role="none">
          <button
            type="button"
            role="menuitem"
            class="gap-[var(--space-xs)] flex items-center"
            phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "dark"})}
          >
            <.icon name="hero-moon" class="h-4 w-4" />
            <span>{gettext("Dark")}</span>
          </button>
        </li>
        <li role="none">
          <button
            type="button"
            role="menuitem"
            class="gap-[var(--space-xs)] flex items-center"
            phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "business"})}
          >
            <.icon name="hero-cake" class="h-4 w-4" />
            <span>{gettext("Brownie")}</span>
          </button>
        </li>
      </ul>
    </div>
    """
  end

  @doc """
  Renders an online indicator dot for chat.

  Shows a green dot when there are users online in chat.
  """
  def chat_online_indicator(assigns) do
    online_count = Homesite.Chat.Presence.online_count()
    assigns = assign(assigns, :online_count, online_count)

    ~H"""
    <%= if @online_count > 0 do %>
      <span
        class="absolute -top-1 -right-1 flex h-2 w-2"
        title={ngettext("1 user online", "%{count} users online", @online_count)}
      >
        <span class="bg-success absolute inline-flex h-full w-full animate-ping rounded-full opacity-75">
        </span>
        <span class="bg-success relative inline-flex h-2 w-2 rounded-full"></span>
      </span>
    <% end %>
    """
  end
end
