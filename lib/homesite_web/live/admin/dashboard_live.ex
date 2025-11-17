defmodule HomesiteWeb.Admin.DashboardLive do
  use HomesiteWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Hallintapaneeli")
     |> assign_stats()}
  end

  defp assign_stats(socket) do
    # TODO: Calculate real stats from database
    socket
    |> assign(:user_count, 0)
    |> assign(:team_count, 0)
    |> assign(:blog_count, 0)
    |> assign(:image_count, 0)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <!-- Header -->
      <div class="navbar bg-base-100 shadow-lg">
        <div class="flex-1">
          <h1 class="text-2xl font-bold px-4">Hallintapaneeli</h1>
        </div>
        <div class="flex-none">
          <div class="dropdown dropdown-end">
            <label tabindex="0" class="btn btn-ghost btn-circle avatar">
              <div class="w-10 rounded-full bg-primary text-primary-content flex items-center justify-center">
                <span class="text-xl"><%= String.first(@current_user.email) |> String.upcase() %></span>
              </div>
            </label>
            <ul
              tabindex="0"
              class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52"
            >
              <li><.link navigate={~p"/users/settings"}>Asetukset</.link></li>
              <li><.link href={~p"/users/log-out"} method="delete">Kirjaudu ulos</.link></li>
            </ul>
          </div>
        </div>
      </div>

      <div class="container mx-auto p-6">
        <!-- Stats Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          <.stat_card title="Käyttäjät" value={@user_count} icon="hero-user-group" />
          <.stat_card title="Tiimit" value={@team_count} icon="hero-users" />
          <.stat_card title="Blogit" value={@blog_count} icon="hero-document-text" />
          <.stat_card title="Kuvat" value={@image_count} icon="hero-photo" />
        </div>

        <!-- Quick Actions -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <!-- Content Section -->
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Sisältö</h2>
              <div class="space-y-2">
                <.action_button href="#" icon="hero-document-text">
                  Kirjoita blogi
                </.action_button>
                <.action_button href="#" icon="hero-chat-bubble-left">
                  Luo lyhyt teksti
                </.action_button>
                <.action_button href="#" icon="hero-photo">
                  Lisää kuvia
                </.action_button>
              </div>
            </div>
          </div>

          <!-- Management Section -->
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Hallinta</h2>
              <div class="space-y-2">
                <.action_button href="#" icon="hero-users">
                  Tiimit
                </.action_button>
                <.action_button href="#" icon="hero-tag">
                  Tunnisteet
                </.action_button>
                <.action_button href="#" icon="hero-cog-6-tooth">
                  Asetukset
                </.action_button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Components
  attr :title, :string, required: true
  attr :value, :integer, required: true
  attr :icon, :string, required: true

  defp stat_card(assigns) do
    ~H"""
    <div class="stats shadow bg-base-100">
      <div class="stat">
        <div class="stat-figure text-primary">
          <.icon name={@icon} class="w-8 h-8" />
        </div>
        <div class="stat-title"><%= @title %></div>
        <div class="stat-value text-primary"><%= @value %></div>
      </div>
    </div>
    """
  end

  attr :href, :string, required: true
  attr :icon, :string, required: true
  slot :inner_block, required: true

  defp action_button(assigns) do
    ~H"""
    <a href={@href} class="btn btn-outline btn-block justify-start">
      <.icon name={@icon} class="w-5 h-5" />
      <%= render_slot(@inner_block) %>
    </a>
    """
  end
end
