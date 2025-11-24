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
            <g transform="scale(-1, 1) translate(-100, 10)">
              <!-- Horse body -->
              <ellipse cx="55" cy="60" rx="22" ry="16" />

              <!-- Horse neck -->
              <path d="M 40 55 Q 32 50 28 42" stroke="#ff4500" stroke-width="8" fill="none" stroke-linecap="round" />

              <!-- Horse head (elongated, horizontal) -->
              <ellipse cx="22" cy="38" rx="8" ry="5.5" />

              <!-- Snout/muzzle -->
              <ellipse cx="15" cy="38" rx="3.5" ry="3" />

              <!-- Ear (pointed upward) -->
              <path d="M 26 32 L 28 26 L 24 30 Z" />

              <!-- Eye -->
              <circle cx="24" cy="37" r="1.5" fill="white" />
              <circle cx="24" cy="37" r="0.8" fill="#333" />

              <!-- Nostril -->
              <circle cx="15" cy="39" r="0.7" fill="#cc3300" opacity="0.6" />

              <!-- Front legs -->
              <rect x="42" y="68" width="4" height="20" rx="2" />
              <rect x="48" y="68" width="4" height="20" rx="2" />

              <!-- Back legs -->
              <rect x="62" y="68" width="4" height="20" rx="2" />
              <rect x="68" y="68" width="4" height="20" rx="2" />

              <!-- Tail -->
              <path d="M 75 58 Q 82 55 85 60 Q 84 65 80 68" stroke="#ff4500" stroke-width="3" fill="none" stroke-linecap="round" />

              <!-- Mane -->
              <path d="M 28 38 Q 32 34 36 38" stroke="#ff4500" stroke-width="2.5" fill="none" stroke-linecap="round" />
              <path d="M 32 42 Q 36 38 40 42" stroke="#ff4500" stroke-width="2.5" fill="none" stroke-linecap="round" />
              <path d="M 36 46 Q 40 42 44 46" stroke="#ff4500" stroke-width="2.5" fill="none" stroke-linecap="round" />

              <!-- Wings (on the back) -->
              <path d="M 60 52 Q 75 45 82 48 Q 80 54 75 58 Q 70 60 65 59 Q 61 56 60 53 Z" opacity="0.95" />
              <path d="M 61 54 Q 73 48 78 50 Q 77 55 72 58 Q 68 59 64 57 Z" opacity="0.8" />
              <path d="M 62 56 Q 70 51 74 53 Q 73 56 69 58 Q 66 58 63 56 Z" opacity="0.65" />
            </g>
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
