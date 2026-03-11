defmodule HomesiteWeb.AdminLive.Users.Index do
  @moduledoc """
  Admin user management interface with pagination, search, and role/flower permission editing.

  Requires admin role with minimum flower level 3 for access.
  """
  use HomesiteWeb, :admin_live_view

  import HomesiteWeb.Helpers.DateHelpers

  alias Homesite.Accounts
  alias Homesite.Moderation
  alias Phoenix.HTML.Form

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("User Management")}
        <:subtitle>{gettext("Manage users, roles, and permissions")}</:subtitle>
        <:actions>
          <.link navigate={~p"/admin"} class="btn btn-ghost btn-sm">
            <.icon name="hero-arrow-left" class="h-4 w-4" />
            {gettext("Back to Dashboard")}
          </.link>
        </:actions>
      </.header>

      <div class="mt-[var(--space-md)]">
        <%!-- Search and Filter Form --%>
        <.form for={%{}} phx-change="filter" phx-submit="filter" class="mb-[var(--space-md)]">
          <div class="gap-[var(--space-sm)] flex flex-wrap items-end">
            <div class="min-w-[200px] flex-1">
              <label class="label">
                <span class="label-text">{gettext("Search")}</span>
              </label>
              <input
                type="text"
                name="search"
                value={@search}
                placeholder={gettext("Search by email, username, or name...")}
                class="input input-bordered w-full"
                phx-debounce="300"
              />
            </div>
            <div class="w-40">
              <label class="label">
                <span class="label-text">{gettext("Status")}</span>
              </label>
              <select name="status_filter" class="select select-bordered w-full" phx-change="filter">
                <option value="all" selected={@status_filter == "all"}>{gettext("All users")}</option>
                <option value="active" selected={@status_filter == "active"}>
                  {gettext("Active")}
                </option>
                <option value="banned" selected={@status_filter == "banned"}>
                  {gettext("Banned")}
                </option>
                <option value="suspended" selected={@status_filter == "suspended"}>
                  {gettext("Suspended")}
                </option>
              </select>
            </div>
            <button type="button" phx-click="clear_filters" class="btn btn-ghost">
              <.icon name="hero-x-mark" class="h-5 w-5" /> {gettext("Clear")}
            </button>
          </div>
        </.form>

        <%!-- User Stats --%>
        <div class="stats stats-horizontal mb-[var(--space-md)] w-full shadow">
          <div class="stat">
            <div class="stat-title">{gettext("Total Users")}</div>
            <div class="stat-value text-primary">{@total_count}</div>
          </div>
          <div class="stat">
            <div class="stat-title">{gettext("Admin Users")}</div>
            <div class="stat-value text-secondary">{@admin_count}</div>
          </div>
          <div class="stat">
            <div class="stat-title">{gettext("Banned")}</div>
            <div class="stat-value text-error">{@banned_count}</div>
          </div>
          <div class="stat">
            <div class="stat-title">{gettext("Suspended")}</div>
            <div class="stat-value text-warning">{@suspended_count}</div>
          </div>
        </div>

        <%!-- Users Table --%>
        <div class="overflow-x-auto">
          <table class="table-zebra table w-full">
            <thead>
              <tr>
                <th>{gettext("User")}</th>
                <th>{gettext("Role")}</th>
                <th>{gettext("Status")}</th>
                <th>{gettext("Joined")}</th>
                <th>{gettext("Posts")}</th>
                <th class="text-right">{gettext("Actions")}</th>
              </tr>
            </thead>
            <tbody>
              <%= if @users == [] do %>
                <tr>
                  <td colspan="6" class="py-[var(--space-lg)] text-center">
                    <p class="text-base-content/70">{gettext("No users found")}</p>
                  </td>
                </tr>
              <% else %>
                <%= for user <- @users do %>
                  <tr id={"user-#{user.id}"}>
                    <td>
                      <div class="gap-[var(--space-xs)] flex items-center">
                        <.avatar user={user} class="h-10 w-10" />
                        <div>
                          <div class="font-medium">
                            {user.display_name || user.username || user.email}
                          </div>
                          <div class="text-[var(--text-sm)] text-base-content/60">{user.email}</div>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div class="gap-[var(--space-xs)] flex items-center">
                        <span class={[
                          "badge",
                          user.role == "admin" && "badge-primary",
                          user.role == "user" && "badge-ghost"
                        ]}>
                          {user.role}
                        </span>
                        <%= if user.role == "admin" && user.admin_flowers > 0 do %>
                          <span
                            class="text-[var(--text-sm)]"
                            title={gettext("Flower level %{level}", level: user.admin_flowers)}
                          >
                            {String.duplicate("🌸", user.admin_flowers)}
                          </span>
                        <% end %>
                      </div>
                    </td>
                    <td>
                      <.user_status_badge user={user} />
                    </td>
                    <td>
                      <span class="text-[var(--text-sm)]">
                        {format_date(user.inserted_at)}
                      </span>
                    </td>
                    <td>
                      <span class="badge badge-sm">{user.post_count || 0}</span>
                    </td>
                    <td class="text-right">
                      <.user_actions_dropdown user={user} current_user_id={@current_scope.user.id} />
                    </td>
                  </tr>
                <% end %>
              <% end %>
            </tbody>
          </table>
        </div>

        <%!-- Pagination --%>
        <%= if @total_pages > 1 do %>
          <div class="gap-[var(--space-xs)] mt-[var(--space-md)] flex justify-center">
            <button
              class="btn btn-sm"
              phx-click="prev_page"
              disabled={@page == 1}
            >
              <.icon name="hero-chevron-left" class="h-4 w-4" /> {gettext("Previous")}
            </button>

            <div class="gap-[var(--space-inline)] flex">
              <%= for page_num <- pagination_range(@page, @total_pages) do %>
                <%= if page_num == :ellipsis do %>
                  <span class="btn btn-sm btn-disabled">...</span>
                <% else %>
                  <button
                    class={["btn btn-sm", @page == page_num && "btn-primary"]}
                    phx-click="goto_page"
                    phx-value-page={page_num}
                  >
                    {page_num}
                  </button>
                <% end %>
              <% end %>
            </div>

            <button
              class="btn btn-sm"
              phx-click="next_page"
              disabled={@page == @total_pages}
            >
              {gettext("Next")} <.icon name="hero-chevron-right" class="h-4 w-4" />
            </button>
          </div>
        <% end %>
      </div>

      <%!-- Edit User Form --%>
      <%= if @selected_user do %>
        <div class="card bg-base-200 mt-[var(--space-md)] shadow-xl">
          <div class="card-body">
            <.header>
              {gettext("Edit User: %{email}", email: @selected_user.email)}
              <:subtitle>{gettext("Update role and flower permissions")}</:subtitle>
            </.header>

            <.form
              for={@form}
              phx-submit="save_user"
              class="mt-[var(--space-sm)] space-y-[var(--space-sm)]"
            >
              <.input
                field={@form[:role]}
                type="select"
                label={gettext("Role")}
                options={[{gettext("User"), "user"}, {gettext("Admin"), "admin"}]}
                phx-change="role_changed"
              />

              <%= if Phoenix.HTML.Form.input_value(@form, :role) == "admin" do %>
                <.input
                  field={@form[:admin_flowers]}
                  type="select"
                  label={gettext("Flower Permission Level")}
                  options={[
                    {gettext("🌸 Level 1 - Basic admin access"), 1},
                    {gettext("🌸🌸 Level 2 - Content moderation"), 2},
                    {gettext("🌸🌸🌸 Level 3 - User management"), 3},
                    {gettext("🌸🌸🌸🌸 Level 4 - System configuration"), 4},
                    {gettext("🌸🌸🌸🌸🌸 Level 5 - Full administrative access"), 5}
                  ]}
                />

                <div class="alert alert-info">
                  <.icon name="hero-information-circle" class="h-5 w-5" />
                  <span>{gettext("Flower permissions grant granular admin capabilities")}</span>
                </div>
              <% end %>

              <div class="gap-[var(--space-xs)] flex justify-end">
                <button type="button" phx-click="cancel_edit" class="btn btn-ghost">
                  {gettext("Cancel")}
                </button>
                <button type="submit" class="btn btn-primary" phx-disable-with={gettext("Saving...")}>
                  {gettext("Save Changes")}
                </button>
              </div>
            </.form>
          </div>
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  # Components for user status and actions
  defp user_status_badge(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-1">
      <%= cond do %>
        <% @user.is_banned -> %>
          <span class="badge badge-error badge-sm">{gettext("Banned")}</span>
        <% @user.is_suspended -> %>
          <span class="badge badge-warning badge-sm">{gettext("Suspended")}</span>
        <% true -> %>
          <span class="badge badge-success badge-sm">{gettext("Active")}</span>
      <% end %>
    </div>
    """
  end

  defp user_actions_dropdown(assigns) do
    ~H"""
    <div class="dropdown dropdown-end">
      <div tabindex="0" role="button" class="btn btn-ghost btn-sm">
        <.icon name="hero-ellipsis-vertical" class="h-5 w-5" />
      </div>
      <ul tabindex="0" class="dropdown-content menu bg-base-200 rounded-box z-[1] w-52 p-2 shadow">
        <li>
          <.link navigate={"/@#{@user.username || @user.id}"}>
            <.icon name="hero-user" class="h-4 w-4" /> {gettext("View Profile")}
          </.link>
        </li>
        <li>
          <button phx-click="edit_user" phx-value-id={@user.id}>
            <.icon name="hero-pencil" class="h-4 w-4" /> {gettext("Edit Role")}
          </button>
        </li>
        <%= if @user.id != @current_user_id do %>
          <li class="border-base-300 mt-1 border-t pt-1">
            <%= if @user.is_suspended do %>
              <button phx-click="unsuspend_user" phx-value-id={@user.id} class="text-success">
                <.icon name="hero-check-circle" class="h-4 w-4" /> {gettext("Unsuspend")}
              </button>
            <% else %>
              <.link
                navigate={~p"/admin/moderation/suspensions?user_id=#{@user.id}"}
                class="text-warning"
              >
                <.icon name="hero-clock" class="h-4 w-4" /> {gettext("Suspend")}
              </.link>
            <% end %>
          </li>
          <li>
            <%= if @user.is_banned do %>
              <button phx-click="unban_user" phx-value-id={@user.id} class="text-success">
                <.icon name="hero-check-circle" class="h-4 w-4" /> {gettext("Unban")}
              </button>
            <% else %>
              <.link navigate={~p"/admin/moderation/bans?user_id=#{@user.id}"} class="text-error">
                <.icon name="hero-no-symbol" class="h-4 w-4" /> {gettext("Ban")}
              </.link>
            <% end %>
          </li>
          <li class="border-base-300 mt-1 border-t pt-1">
            <button
              phx-click="delete_user"
              phx-value-id={@user.id}
              data-confirm={
                gettext("Are you sure you want to delete this user? This action cannot be undone.")
              }
              class="text-error"
            >
              <.icon name="hero-trash" class="h-4 w-4" /> {gettext("Delete User")}
            </button>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    # Verify admin access
    if Accounts.Scope.admin?(socket.assigns.current_scope) do
      # Check minimum flower level (3 for user management)
      if socket.assigns.current_scope.flower_count < 3 do
        {:ok,
         socket
         |> put_flash(
           :error,
           gettext("You need at least 🌸🌸🌸 (Level 3) flowers for user management")
         )
         |> redirect(to: ~p"/admin")}
      else
        {:ok,
         socket
         |> assign(:page, 1)
         |> assign(:per_page, 20)
         |> assign(:search, "")
         |> assign(:status_filter, "all")
         |> assign(:selected_user, nil)
         |> assign(:form, nil)
         |> load_users()
         |> load_moderation_stats()}
      end
    else
      {:ok,
       socket
       |> put_flash(:error, gettext("You must be an admin to access this page"))
       |> redirect(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("filter", params, socket) do
    search = Map.get(params, "search", socket.assigns.search)
    status_filter = Map.get(params, "status_filter", socket.assigns.status_filter)

    {:noreply,
     socket
     |> assign(:search, search)
     |> assign(:status_filter, status_filter)
     |> assign(:page, 1)
     |> load_users()}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:search, "")
     |> assign(:status_filter, "all")
     |> assign(:page, 1)
     |> load_users()}
  end

  def handle_event("unsuspend_user", %{"id" => user_id}, socket) do
    user_id = String.to_integer(user_id)
    scope = socket.assigns.current_scope

    case Moderation.unsuspend_user(scope, user_id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("User unsuspended successfully"))
         |> load_users()
         |> load_moderation_stats()}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, gettext("Suspension not found"))}
    end
  end

  def handle_event("unban_user", %{"id" => user_id}, socket) do
    user_id = String.to_integer(user_id)
    scope = socket.assigns.current_scope

    case Moderation.unban_user(scope, user_id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("User unbanned successfully"))
         |> load_users()
         |> load_moderation_stats()}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, gettext("Ban not found"))}
    end
  end

  def handle_event("delete_user", %{"id" => user_id}, socket) do
    user_id = String.to_integer(user_id)

    # Can't delete yourself
    if user_id == socket.assigns.current_scope.user.id do
      {:noreply,
       put_flash(socket, :error, gettext("You cannot delete your own account from here"))}
    else
      case Accounts.admin_delete_user(user_id) do
        {:ok, _} ->
          {:noreply,
           socket
           |> put_flash(:info, gettext("User deleted successfully"))
           |> load_users()
           |> load_moderation_stats()}

        {:error, reason} ->
          {:noreply,
           put_flash(
             socket,
             :error,
             gettext("Failed to delete user: %{reason}", reason: inspect(reason))
           )}
      end
    end
  end

  def handle_event("prev_page", _params, socket) do
    new_page = max(socket.assigns.page - 1, 1)

    {:noreply,
     socket
     |> assign(:page, new_page)
     |> load_users()}
  end

  def handle_event("next_page", _params, socket) do
    new_page = min(socket.assigns.page + 1, socket.assigns.total_pages)

    {:noreply,
     socket
     |> assign(:page, new_page)
     |> load_users()}
  end

  def handle_event("goto_page", %{"page" => page}, socket) do
    page = String.to_integer(page)

    {:noreply,
     socket
     |> assign(:page, page)
     |> load_users()}
  end

  def handle_event("edit_user", %{"id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    form =
      %{
        "role" => user.role || "user",
        "admin_flowers" => user.admin_flowers || 0
      }
      |> Phoenix.Component.to_form()

    {:noreply,
     socket
     |> assign(:selected_user, user)
     |> assign(:form, form)}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply,
     socket
     |> assign(:selected_user, nil)
     |> assign(:form, nil)}
  end

  def handle_event("role_changed", %{"role" => role}, socket) do
    # Update form when role changes
    current_flowers =
      Form.input_value(socket.assigns.form, :admin_flowers) || 0

    form =
      %{
        "role" => role,
        "admin_flowers" => current_flowers
      }
      |> Phoenix.Component.to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save_user", %{"role" => role, "admin_flowers" => flowers}, socket) do
    user = socket.assigns.selected_user
    flowers = String.to_integer(flowers)

    attrs = %{
      "role" => role,
      "admin_flowers" => if(role == "admin", do: flowers, else: 0)
    }

    case Accounts.update_user_admin_settings(user, attrs) do
      {:ok, _updated_user} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("User updated successfully"))
         |> assign(:selected_user, nil)
         |> assign(:form, nil)
         |> load_users()}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to update user"))}
    end
  end

  defp load_users(socket) do
    # Get banned and suspended user IDs for status display
    banned_ids = Moderation.list_bans(active_only: true) |> Enum.map(& &1.user_id) |> MapSet.new()

    suspended_ids =
      Moderation.list_suspensions(active_only: true) |> Enum.map(& &1.user_id) |> MapSet.new()

    opts = [
      page: socket.assigns.page,
      per_page: socket.assigns.per_page,
      search: socket.assigns.search,
      status_filter: socket.assigns.status_filter,
      banned_ids: banned_ids,
      suspended_ids: suspended_ids
    ]

    users = Accounts.list_users_paginated(opts)

    # Add post counts and status to users
    users_with_data =
      Enum.map(users, fn user ->
        stats = Accounts.get_user_with_stats(user.id)

        user
        |> Map.put(:post_count, stats.post_count)
        |> Map.put(:is_banned, MapSet.member?(banned_ids, user.id))
        |> Map.put(:is_suspended, MapSet.member?(suspended_ids, user.id))
      end)

    total_count = Accounts.count_users(search: socket.assigns.search)
    total_pages = ceil(total_count / socket.assigns.per_page)

    admin_count =
      Accounts.list_users()
      |> Enum.count(fn user -> user.role == "admin" end)

    socket
    |> assign(:users, users_with_data)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, max(total_pages, 1))
    |> assign(:admin_count, admin_count)
  end

  defp load_moderation_stats(socket) do
    banned_count = Moderation.list_bans(active_only: true) |> length()
    suspended_count = Moderation.list_suspensions(active_only: true) |> length()

    socket
    |> assign(:banned_count, banned_count)
    |> assign(:suspended_count, suspended_count)
  end

  # Helper to generate pagination range with ellipsis
  defp pagination_range(_current_page, total_pages) when total_pages <= 7 do
    1..total_pages |> Enum.to_list()
  end

  defp pagination_range(current_page, total_pages) do
    cond do
      current_page <= 4 ->
        [1, 2, 3, 4, 5, :ellipsis, total_pages]

      current_page >= total_pages - 3 ->
        [
          1,
          :ellipsis,
          total_pages - 4,
          total_pages - 3,
          total_pages - 2,
          total_pages - 1,
          total_pages
        ]

      true ->
        [1, :ellipsis, current_page - 1, current_page, current_page + 1, :ellipsis, total_pages]
    end
  end
end
