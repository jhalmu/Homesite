defmodule HomesiteWeb.UserLive.Projects do
  @moduledoc """
  Public page showcasing all of a user's public projects.
  """
  use HomesiteWeb, :live_view

  alias Homesite.Accounts
  alias Homesite.Media

  import HomesiteWeb.MediaComponents, only: [project_card: 1]

  @impl true
  def mount(%{"user_identifier" => user_identifier}, _session, socket) do
    case Accounts.get_user_by_identifier(user_identifier) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, gettext("User not found"))
         |> redirect(to: ~p"/")}

      user ->
        projects = Media.list_public_projects_for_user(user.id)

        {:ok,
         socket
         |> assign(:page_title, "#{user.display_name || user.email}'s Projects")
         |> assign(:user, user)
         |> assign(:projects, projects)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={assigns[:current_scope]}>
      <div class="mx-auto max-w-6xl px-4 py-[var(--space-lg)]">
        <header class="mb-[var(--space-lg)]">
          <%= if @user.username do %>
            <.link navigate={~p"/users/@#{@user.username}"} class="link text-[var(--text-sm)]">
              ← {gettext("Back to profile")}
            </.link>
          <% else %>
            <.link navigate={~p"/users/#{@user.id}"} class="link text-[var(--text-sm)]">
              ← {gettext("Back to profile")}
            </.link>
          <% end %>
          <h1 class="mt-2 text-[var(--text-3xl)] font-bold">
            {gettext("Projects by %{name}", name: @user.display_name || @user.email)}
          </h1>
        </header>

        <%= if Enum.empty?(@projects) do %>
          <div class="py-[var(--space-xl)] text-center">
            <.icon name="hero-folder" class="text-base-content/30 mx-auto mb-[var(--space-sm)] h-16 w-16" />
            <p class="text-base-content/60">{gettext("No public projects yet.")}</p>
          </div>
        <% else %>
          <div class="gap-[var(--space-md)] grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
            <.project_card
              :for={project <- @projects}
              project={project}
              show_template_badge={true}
            />
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
