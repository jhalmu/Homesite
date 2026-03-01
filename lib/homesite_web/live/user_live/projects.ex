defmodule HomesiteWeb.UserLive.Projects do
  @moduledoc """
  Public page showcasing all of a user's public projects.
  """
  use HomesiteWeb, :live_view

  alias Homesite.Accounts
  alias Homesite.Media

  import HomesiteWeb.MediaComponents, only: [project_card: 1, template_icon: 1, template_name: 1]

  @template_display_order ~w(photography coding writing books gears movies custom)

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
        grouped_projects = group_projects_by_template(projects)

        {:ok,
         socket
         |> assign(:page_title, "#{user.display_name || user.email}'s Projects")
         |> assign(:user, user)
         |> assign(:projects, projects)
         |> assign(:grouped_projects, grouped_projects)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={assigns[:current_scope]}>
      <div class="px-[var(--space-sm)] py-[var(--space-lg)] mx-auto max-w-6xl">
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
          <h1 class="mt-[var(--space-xs)] text-[var(--text-3xl)] font-bold">
            {gettext("Projects by %{name}", name: @user.display_name || @user.email)}
          </h1>
        </header>

        <%= if Enum.empty?(@projects) do %>
          <div class="py-[var(--space-xl)] text-center">
            <.icon
              name="hero-folder"
              class="text-base-content/30 mb-[var(--space-sm)] mx-auto h-16 w-16"
            />
            <p class="text-base-content/60">{gettext("No public projects yet.")}</p>
          </div>
        <% else %>
          <div
            :for={{template_type, group_projects} <- @grouped_projects}
            class="mb-[var(--space-lg)]"
          >
            <h2 class="mb-[var(--space-sm)] gap-[var(--space-xs)] text-[var(--text-xl)] flex items-center font-semibold">
              <.icon name={template_icon(template_type)} class="h-5 w-5" />
              {template_name(template_type)}
            </h2>
            <div class="gap-[var(--space-md)] grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
              <.project_card :for={project <- group_projects} project={project} />
            </div>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  defp group_projects_by_template(projects) do
    grouped = Enum.group_by(projects, & &1.template_type)

    (@template_display_order ++ [nil])
    |> Enum.flat_map(fn type ->
      case Map.get(grouped, type) do
        nil -> []
        group -> [{type, group}]
      end
    end)
  end
end
