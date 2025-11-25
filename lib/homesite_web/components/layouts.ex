defmodule HomesiteWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use HomesiteWeb, :html

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
    ~H"""
    <main class="min-h-screen px-4 py-8 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-7xl space-y-4">{render_slot(@inner_block)}</div>
    </main>

    <footer class="from-base-200 to-base-300 border-base-300 mt-16 border-t bg-gradient-to-r">
      <div class="footer mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
        <div>
          <.pegasus class="h-20 w-20" />
          <p class="font-semibold">
            homesite <br />
            <span class="text-sm font-normal opacity-70">Personal blogging platform</span>
          </p>
        </div>
        <div>
          <span class="footer-title">Platform</span>
          <a href="/" class="link-hover link">Home</a>
          <%= if @current_scope do %>
            <a href="/dashboard" class="link-hover link">Dashboard</a>
            <a href="/posts" class="link-hover link">Posts</a>
            <a href="/tags" class="link-hover link">Tags</a>
          <% end %>
        </div>
        <div>
          <span class="footer-title">Built with</span>
          <p class="text-sm opacity-70">Phoenix Framework</p>
          <p class="text-sm opacity-70">Elixir</p>
          <p class="text-sm opacity-70">Tailwind CSS & DaisyUI</p>
        </div>
      </div>
      <div class="border-base-300 bg-base-200/50 border-t px-4 py-4 text-center text-sm opacity-70">
        <p>© {Date.utc_today().year} Homesite. Built with ❤️ and Elixir.</p>
      </div>
    </footer>

    <.flash_group flash={@flash} />
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
    <div class="navbar from-base-200 to-base-100 border-base-300 px-[clamp(1rem,5vw,4rem)] mt-4 border-b bg-gradient-to-r py-4 shadow-sm">
      <div class="flex-1">
        <.link
          navigate={~p"/"}
          class="btn btn-ghost text-[clamp(1rem,2.5vw,1.5rem)] gap-[clamp(0.5rem,2vw,1rem)] items-center"
        >
          <div class="relative overflow-visible rounded-full bg-white p-2 shadow-lg">
            <.pegasus class="absolute -inset-2 h-28 w-28" />
          </div>
          <span class="font-display">homesite</span>
        </.link>
      </div>
      <div class="gap-[clamp(0.5rem,2vw,1rem)] flex-none">
        <ul class="menu menu-horizontal gap-[clamp(0.25rem,1vw,0.5rem)]">
          <%= if @current_scope do %>
            <li>
              <.link navigate={~p"/dashboard"}>Dashboard</.link>
            </li>
            <li>
              <.link navigate={~p"/posts"}>Posts</.link>
            </li>
            <li>
              <.link navigate={~p"/tags"}>Tags</.link>
            </li>
            <%= if Homesite.Accounts.Scope.admin?(@current_scope) do %>
              <li>
                <.link navigate={~p"/admin"}>Admin</.link>
              </li>
            <% end %>
            <li>
              <details>
                <summary class="flex items-center gap-2">
                  <.avatar user={@current_scope.user} class="h-8 w-8" />
                  <span>{@current_scope.user.display_name || @current_scope.user.email}</span>
                </summary>
                <ul class="bg-base-100 z-50 rounded-t-none p-2">
                  <li>
                    <.link navigate={~p"/users/settings"}>
                      <.icon name="hero-cog-6-tooth" class="h-4 w-4" /> Settings
                    </.link>
                  </li>
                  <li>
                    <.link href={~p"/users/log-out"} method="delete">
                      <.icon name="hero-arrow-right-on-rectangle" class="h-4 w-4" /> Log out
                    </.link>
                  </li>
                </ul>
              </details>
            </li>
          <% else %>
            <%!-- Registration disabled for testing phase --%>
            <%!-- <li>
              <.link navigate={~p"/users/register"}>Register</.link>
            </li> --%>
            <li>
              <.link navigate={~p"/users/log-in"} class="btn btn-primary">Log in</.link>
            </li>
          <% end %>
          <li>
            <.theme_toggle />
          </li>
        </ul>
      </div>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card border-base-300 bg-base-300 relative flex flex-row items-center rounded-full border">
      <div class="border-1 border-base-200 bg-base-100 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left] absolute left-0 h-full w-1/3 rounded-full brightness-200" />

      <button
        class="flex w-1/3 cursor-pointer p-1"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-3 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex w-1/3 cursor-pointer p-1"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-3 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex w-1/3 cursor-pointer p-1"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-3 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
