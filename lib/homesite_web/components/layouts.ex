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
    <header class="bg-gradient-to-r from-base-200 to-base-300 shadow-md">
      <div class="navbar mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div class="flex-1">
          <a href="/" class="text-slate-700 dark:text-slate-300 text-2xl font-semibold">
            homesite
          </a>
        </div>
        <div class="flex-none">
          <.theme_toggle />
        </div>
      </div>
    </header>

    <main class="min-h-screen px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-7xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <footer class="bg-gradient-to-r from-base-200 to-base-300 mt-16 border-t border-base-300">
      <div class="footer mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
        <div>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 100 100"
            class="h-12 w-12"
            fill="#ff4500"
          >
            <!-- Pegasus body and legs -->
            <ellipse cx="50" cy="55" rx="18" ry="12" />
            <rect x="44" y="60" width="4" height="20" rx="2" />
            <rect x="52" y="60" width="4" height="20" rx="2" />
            <rect x="48" y="64" width="4" height="16" rx="2" />
            <rect x="56" y="64" width="4" height="16" rx="2" />
            <!-- Pegasus head and neck -->
            <ellipse cx="38" cy="48" rx="6" ry="8" transform="rotate(-20 38 48)" />
            <path d="M 44 52 Q 40 50 38 48" stroke="#ff4500" stroke-width="4" fill="none" stroke-linecap="round" />
            <!-- Wings -->
            <path d="M 55 50 Q 70 45 75 48 Q 72 52 68 54 Q 64 56 60 56 Q 57 54 55 52 Z" opacity="0.9" />
            <path d="M 56 52 Q 68 48 72 50 Q 70 53 66 55 Q 62 56 58 55 Z" opacity="0.7" />
            <path d="M 57 54 Q 66 51 69 52 Q 68 54 64 55 Q 61 55 58 54 Z" opacity="0.5" />
            <!-- Eye -->
            <circle cx="36" cy="46" r="1.5" fill="white" />
          </svg>
          <p class="font-semibold">
            homesite
            <br />
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
      <div class="border-t border-base-300 bg-base-200/50 px-4 py-4 text-center text-sm opacity-70">
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
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card border-base-300 bg-base-300 relative flex flex-row items-center rounded-full border-2">
      <div class="border-1 border-base-200 bg-base-100 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left] absolute left-0 h-full w-1/3 rounded-full brightness-200" />

      <button
        class="flex w-1/3 cursor-pointer p-2"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex w-1/3 cursor-pointer p-2"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex w-1/3 cursor-pointer p-2"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
