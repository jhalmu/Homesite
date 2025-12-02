defmodule HomesiteWeb.AdminLive.Index do
  use HomesiteWeb, :live_view

  alias Homesite.Accounts

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    # Verify admin access
    if Accounts.Scope.admin?(scope) do
      # Get admin stats
      all_users = Accounts.list_users()
      admin_users = Enum.filter(all_users, &Accounts.User.admin?/1)

      socket =
        socket
        |> assign(:page_title, "Admin Dashboard")
        |> assign(:total_users, length(all_users))
        |> assign(:admin_count, length(admin_users))
        |> assign(:flowers, String.duplicate("🌸", scope.flower_count))
        |> assign(:flower_count, scope.flower_count)

      {:ok, socket}
    else
      socket =
        socket
        |> put_flash(:error, "You must be an admin to access this page.")
        |> redirect(to: ~p"/dashboard")

      {:ok, socket}
    end
  end
end
