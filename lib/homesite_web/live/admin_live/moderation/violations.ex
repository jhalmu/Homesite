defmodule HomesiteWeb.AdminLive.Moderation.Violations do
  @moduledoc """
  LiveView for the violation tracking dashboard.

  Shows users with violations, sorted by total weight.
  Includes real-time alerts when users reach violation thresholds.
  """
  use HomesiteWeb, :admin_live_view

  alias Homesite.Accounts
  alias Homesite.Moderation

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Homesite.PubSub, "moderation:alerts")
    end

    {:ok,
     socket
     |> assign(:page_title, gettext("Violation Tracking"))
     |> assign(:alerts, [])
     |> assign(:selected_user, nil)
     |> assign(:user_violations, [])
     |> assign(:user_stats, nil)
     |> load_flagged_users()}
  end

  defp load_flagged_users(socket) do
    flagged = Moderation.list_users_with_violations(limit: 50)
    assign(socket, :flagged_users, flagged)
  end

  @impl true
  def handle_info({:violation_threshold_reached, alert}, socket) do
    {:noreply, update(socket, :alerts, fn alerts -> [alert | alerts] end)}
  end

  @impl true
  def handle_event("select_user", %{"id" => user_id}, socket) do
    user_id = String.to_integer(user_id)
    user = Accounts.get_user!(user_id)
    violations = Moderation.list_user_violations(user_id)
    stats = Moderation.get_user_violation_stats(user_id)

    {:noreply,
     socket
     |> assign(:selected_user, user)
     |> assign(:user_violations, violations)
     |> assign(:user_stats, stats)}
  end

  @impl true
  def handle_event("view_alert_user", %{"user-id" => user_id}, socket) do
    user_id = String.to_integer(user_id)
    user = Accounts.get_user!(user_id)
    violations = Moderation.list_user_violations(user_id)
    stats = Moderation.get_user_violation_stats(user_id)

    # Remove this alert
    alerts = Enum.reject(socket.assigns.alerts, &(&1.user_id == user_id))

    {:noreply,
     socket
     |> assign(:selected_user, user)
     |> assign(:user_violations, violations)
     |> assign(:user_stats, stats)
     |> assign(:alerts, alerts)}
  end

  @impl true
  def handle_event("dismiss_alert", %{"user-id" => user_id}, socket) do
    user_id = String.to_integer(user_id)
    alerts = Enum.reject(socket.assigns.alerts, &(&1.user_id == user_id))
    {:noreply, assign(socket, :alerts, alerts)}
  end

  @impl true
  def handle_event("resolve_all", _params, socket) do
    user_id = socket.assigns.selected_user.id
    admin_id = socket.assigns.current_scope.user.id

    Moderation.resolve_all_violations(user_id, admin_id)

    {:noreply,
     socket
     |> put_flash(:info, gettext("All violations resolved"))
     |> assign(:user_violations, Moderation.list_user_violations(user_id))
     |> assign(:user_stats, Moderation.get_user_violation_stats(user_id))
     |> load_flagged_users()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Violation Tracking")}
        <:subtitle>
          {gettext("Monitor users with violations and take action")}
        </:subtitle>
        <:actions>
          <.link navigate={~p"/admin/moderation"} class="btn btn-ghost btn-sm">
            <.icon name="hero-arrow-left" class="h-4 w-4" />
            {gettext("Back to Dashboard")}
          </.link>
        </:actions>
      </.header>

      <div class="mt-[var(--space-md)]">
        <%!-- Alert notifications --%>
        <%= if length(@alerts) > 0 do %>
          <div class="mb-[var(--space-md)] space-y-[var(--space-xs)]">
            <%= for alert <- @alerts do %>
              <div class="alert alert-warning">
                <.icon name="hero-exclamation-triangle" class="h-5 w-5" />
                <span>
                  {gettext(
                    "User has reached %{weight} violation weight from %{reporters} different reporters",
                    weight: alert.total_weight,
                    reporters: alert.unique_reporters
                  )}
                </span>
                <div class="gap-[var(--space-xs)] flex">
                  <button
                    phx-click="view_alert_user"
                    phx-value-user-id={alert.user_id}
                    class="btn btn-sm btn-primary"
                  >
                    {gettext("View")}
                  </button>
                  <button
                    phx-click="dismiss_alert"
                    phx-value-user-id={alert.user_id}
                    class="btn btn-sm btn-ghost"
                  >
                    {gettext("Dismiss")}
                  </button>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>

        <div class="gap-[var(--space-md)] grid grid-cols-1 lg:grid-cols-3">
          <%!-- Flagged users list --%>
          <div class="lg:col-span-1">
            <div class="card bg-base-100 shadow">
              <div class="card-body">
                <h2 class="card-title">{gettext("Flagged Users")}</h2>
                <%= if length(@flagged_users) == 0 do %>
                  <p class="text-base-content/60">{gettext("No users with violations")}</p>
                <% else %>
                  <div class="max-h-96 overflow-y-auto">
                    <%= for user_data <- @flagged_users do %>
                      <div
                        class={[
                          "cursor-pointer rounded p-3 hover:bg-base-200",
                          @selected_user && @selected_user.id == user_data.user.id && "bg-base-200"
                        ]}
                        phx-click="select_user"
                        phx-value-id={user_data.user.id}
                      >
                        <div class="flex items-center justify-between">
                          <div class="gap-[var(--space-xs)] flex items-center">
                            <div class="avatar placeholder">
                              <div class="bg-neutral text-neutral-content w-8 rounded-full">
                                <span class="text-xs">
                                  {String.first(user_data.user.email) |> String.upcase()}
                                </span>
                              </div>
                            </div>
                            <span class="text-[var(--text-sm)] truncate">
                              {user_data.user.display_name || user_data.user.email}
                            </span>
                          </div>
                          <span class="badge badge-warning">{user_data.total_weight}</span>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>
          </div>

          <%!-- User detail panel --%>
          <div class="lg:col-span-2">
            <%= if @selected_user do %>
              <div class="card bg-base-100 shadow">
                <div class="card-body">
                  <div class="gap-[var(--space-sm)] flex items-center">
                    <div class="avatar placeholder">
                      <div class="bg-neutral text-neutral-content w-12 rounded-full">
                        <span>{String.first(@selected_user.email) |> String.upcase()}</span>
                      </div>
                    </div>
                    <div>
                      <h2 class="card-title">
                        {@selected_user.display_name || @selected_user.email}
                      </h2>
                      <%= if @selected_user.display_name do %>
                        <p class="text-sm opacity-60">{@selected_user.email}</p>
                      <% end %>
                    </div>
                  </div>

                  <%!-- Stats --%>
                  <%= if @user_stats do %>
                    <div class="stats stats-horizontal mt-[var(--space-sm)] mb-[var(--space-sm)] shadow">
                      <div class="stat">
                        <div class="stat-title">{gettext("Total Violations")}</div>
                        <div class="stat-value">{@user_stats.total_count}</div>
                      </div>
                      <div class="stat">
                        <div class="stat-title">{gettext("Unresolved Weight")}</div>
                        <div class="stat-value text-warning">
                          {@user_stats.total_unresolved_weight}
                        </div>
                      </div>
                    </div>

                    <%!-- By type breakdown --%>
                    <div class="mb-[var(--space-sm)] gap-[var(--space-xs)] flex flex-wrap">
                      <%= for {type, count} <- @user_stats.by_type do %>
                        <span class="badge badge-outline">{type}: {count}</span>
                      <% end %>
                    </div>
                  <% end %>

                  <%!-- Violation history --%>
                  <h3 class="mb-[var(--space-xs)] font-semibold">{gettext("Violation History")}</h3>
                  <div class="overflow-x-auto">
                    <table class="table-sm table">
                      <thead>
                        <tr>
                          <th>{gettext("Date")}</th>
                          <th>{gettext("Type")}</th>
                          <th>{gettext("Reporter")}</th>
                          <th>{gettext("Reason")}</th>
                          <th>{gettext("Weight")}</th>
                          <th>{gettext("Status")}</th>
                        </tr>
                      </thead>
                      <tbody>
                        <%= for violation <- @user_violations do %>
                          <tr>
                            <td>{Calendar.strftime(violation.inserted_at, "%Y-%m-%d %H:%M")}</td>
                            <td><span class="badge badge-sm">{violation.action_type}</span></td>
                            <td>
                              <%= if violation.reporter do %>
                                {violation.reporter.email}
                              <% else %>
                                <span class="opacity-50">{gettext("System")}</span>
                              <% end %>
                            </td>
                            <td class="max-w-xs truncate" title={violation.reason_text}>
                              {violation.reason_text || "-"}
                            </td>
                            <td>{violation.weight}</td>
                            <td>
                              <%= if violation.resolved_at do %>
                                <span class="badge badge-success badge-sm">
                                  {gettext("Resolved")}
                                </span>
                              <% else %>
                                <span class="badge badge-warning badge-sm">{gettext("Active")}</span>
                              <% end %>
                            </td>
                          </tr>
                        <% end %>
                      </tbody>
                    </table>
                  </div>

                  <%!-- Quick actions --%>
                  <div class="card-actions mt-[var(--space-sm)] justify-end">
                    <.link
                      navigate={~p"/admin/moderation/suspensions?user_id=#{@selected_user.id}"}
                      class="btn btn-warning btn-sm"
                    >
                      <.icon name="hero-clock" class="h-4 w-4" />
                      {gettext("Suspend")}
                    </.link>
                    <.link
                      navigate={~p"/admin/moderation/bans?user_id=#{@selected_user.id}"}
                      class="btn btn-error btn-sm"
                    >
                      <.icon name="hero-x-circle" class="h-4 w-4" />
                      {gettext("Ban")}
                    </.link>
                    <button phx-click="resolve_all" class="btn btn-success btn-sm">
                      <.icon name="hero-check-circle" class="h-4 w-4" />
                      {gettext("Resolve All")}
                    </button>
                  </div>
                </div>
              </div>
            <% else %>
              <div class="card bg-base-100 shadow">
                <div class="card-body">
                  <p class="text-base-content/60 text-center">
                    {gettext("Select a user to view details")}
                  </p>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
