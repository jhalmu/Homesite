defmodule HomesiteWeb.AdminLive.Users.Index do
  @moduledoc """
  Admin user management interface with pagination, search, and role/flower permission editing.

  Requires admin role with minimum flower level 3 for access.
  """
  use HomesiteWeb, :live_view

  import HomesiteWeb.Helpers.DateHelpers

  alias Homesite.Accounts
  alias Phoenix.HTML.Form

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        User Management
        <:subtitle>Manage users, roles, and flower permissions</:subtitle>
      </.header>

      <div class="mt-[var(--space-md)]">
        <%!-- Search Form --%>
        <.form for={%{}} phx-change="search" phx-submit="search" class="mb-[var(--space-md)]">
          <div class="gap-[var(--space-md)] flex">
            <div class="flex-1">
              <input
                type="text"
                name="search"
                value={@search}
                placeholder="Search by email..."
                class="input w-full"
                phx-debounce="300"
              />
            </div>
            <button type="button" phx-click="clear_search" class="btn btn-ghost">
              <.icon name="hero-x-mark" class="h-5 w-5" /> Clear
            </button>
          </div>
        </.form>

        <%!-- User Stats --%>
        <div class="stats stats-horizontal mb-[var(--space-md)] w-full shadow">
          <div class="stat">
            <div class="stat-title">Total Users</div>
            <div class="stat-value text-primary">{@total_count}</div>
          </div>
          <div class="stat">
            <div class="stat-title">Admin Users</div>
            <div class="stat-value text-secondary">{@admin_count}</div>
          </div>
          <div class="stat">
            <div class="stat-title">Page</div>
            <div class="stat-value text-accent">{@page} / {@total_pages}</div>
          </div>
        </div>

        <%!-- Users Table --%>
        <div class="overflow-x-auto">
          <table class="table-zebra table w-full">
            <thead>
              <tr>
                <th>Avatar</th>
                <th>Email</th>
                <th>Display Name</th>
                <th>Role</th>
                <th>Flowers</th>
                <th>Joined</th>
                <th>Posts</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <%= if @users == [] do %>
                <tr>
                  <td colspan="8" class="py-[var(--space-lg)] text-center">
                    <p class="text-base-content/70">No users found</p>
                  </td>
                </tr>
              <% else %>
                <%= for user <- @users do %>
                  <tr>
                    <td>
                      <.avatar user={user} class="h-10 w-10" />
                    </td>
                    <td>{user.email}</td>
                    <td>{user.display_name || "-"}</td>
                    <td>
                      <span class={[
                        "badge",
                        user.role == "admin" && "badge-primary",
                        user.role == "user" && "badge-ghost"
                      ]}>
                        {user.role}
                      </span>
                    </td>
                    <td>
                      <%= if user.role == "admin" do %>
                        <span class="text-[var(--text-lg)]">
                          {String.duplicate("🌸", user.admin_flowers || 0)}
                        </span>
                      <% else %>
                        <span class="text-base-content/70">-</span>
                      <% end %>
                    </td>
                    <td>
                      <span class="text-[var(--text-sm)]">
                        {format_date(user.inserted_at)}
                      </span>
                    </td>
                    <td>
                      <span class="badge badge-sm">{user.post_count || 0}</span>
                    </td>
                    <td>
                      <button
                        phx-click="edit_user"
                        phx-value-id={user.id}
                        class="btn btn-sm btn-ghost"
                      >
                        <.icon name="hero-pencil" class="h-4 w-4" /> Edit
                      </button>
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
              <.icon name="hero-chevron-left" class="h-4 w-4" /> Previous
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
              Next <.icon name="hero-chevron-right" class="h-4 w-4" />
            </button>
          </div>
        <% end %>
      </div>

      <%!-- Edit User Form --%>
      <%= if @selected_user do %>
        <div class="card bg-base-200 mt-[var(--space-md)] shadow-xl">
          <div class="card-body">
            <.header>
              Edit User: {@selected_user.email}
              <:subtitle>Update role and flower permissions</:subtitle>
            </.header>

            <.form for={@form} phx-submit="save_user" class="mt-[var(--space-sm)] space-y-[var(--space-sm)]">
              <.input
                field={@form[:role]}
                type="select"
                label="Role"
                options={[{"User", "user"}, {"Admin", "admin"}]}
                phx-change="role_changed"
              />

              <%= if Phoenix.HTML.Form.input_value(@form, :role) == "admin" do %>
                <.input
                  field={@form[:admin_flowers]}
                  type="select"
                  label="Flower Permission Level"
                  options={[
                    {"🌸 Level 1 - Basic admin access", 1},
                    {"🌸🌸 Level 2 - Content moderation", 2},
                    {"🌸🌸🌸 Level 3 - User management", 3},
                    {"🌸🌸🌸🌸 Level 4 - System configuration", 4},
                    {"🌸🌸🌸🌸🌸 Level 5 - Full administrative access", 5}
                  ]}
                />

                <div class="alert alert-info">
                  <.icon name="hero-information-circle" class="h-5 w-5" />
                  <span>Flower permissions grant granular admin capabilities</span>
                </div>
              <% end %>

              <div class="gap-[var(--space-xs)] flex justify-end">
                <button type="button" phx-click="cancel_edit" class="btn btn-ghost">
                  Cancel
                </button>
                <button type="submit" class="btn btn-primary" phx-disable-with="Saving...">
                  Save Changes
                </button>
              </div>
            </.form>
          </div>
        </div>
      <% end %>
    </Layouts.app>
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
         |> put_flash(:error, "You need at least 🌸🌸🌸 (Level 3) flowers for user management")
         |> redirect(to: ~p"/admin")}
      else
        {:ok,
         socket
         |> assign(:page, 1)
         |> assign(:per_page, 20)
         |> assign(:search, "")
         |> assign(:selected_user, nil)
         |> assign(:form, nil)
         |> load_users()}
      end
    else
      {:ok,
       socket
       |> put_flash(:error, "You must be an admin to access this page")
       |> redirect(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply,
     socket
     |> assign(:search, search)
     |> assign(:page, 1)
     |> load_users()}
  end

  def handle_event("clear_search", _params, socket) do
    {:noreply,
     socket
     |> assign(:search, "")
     |> assign(:page, 1)
     |> load_users()}
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
         |> put_flash(:info, "User updated successfully")
         |> assign(:selected_user, nil)
         |> assign(:form, nil)
         |> load_users()}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to update user")}
    end
  end

  defp load_users(socket) do
    opts = [
      page: socket.assigns.page,
      per_page: socket.assigns.per_page,
      search: socket.assigns.search
    ]

    users = Accounts.list_users_paginated(opts)

    # Add post counts to users
    users_with_counts =
      Enum.map(users, fn user ->
        stats = Accounts.get_user_with_stats(user.id)
        Map.put(user, :post_count, stats.post_count)
      end)

    total_count = Accounts.count_users(search: socket.assigns.search)
    total_pages = ceil(total_count / socket.assigns.per_page)

    admin_count =
      Accounts.list_users()
      |> Enum.count(fn user -> user.role == "admin" end)

    socket
    |> assign(:users, users_with_counts)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, max(total_pages, 1))
    |> assign(:admin_count, admin_count)
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
