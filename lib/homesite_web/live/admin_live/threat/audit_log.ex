defmodule HomesiteWeb.AdminLive.Threat.AuditLog do
  @moduledoc false
  use HomesiteWeb, :admin_live_view

  alias Homesite.Accounts
  alias Homesite.ThreatReputation
  alias Homesite.ThreatReputation.SecurityAuditLog
  import HomesiteWeb.Helpers.DateHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Security Audit Log")}
        <:subtitle>{gettext("History of admin security actions")}</:subtitle>
        <:actions>
          <.link navigate={~p"/admin/threats"} class="btn btn-ghost btn-sm">
            <.icon name="hero-arrow-left" class="h-4 w-4" /> {gettext("Back to Threats")}
          </.link>
        </:actions>
      </.header>

      <%!-- Filters --%>
      <div class="mt-[var(--space-md)]">
        <form phx-change="filter" class="gap-[var(--space-sm)] flex flex-wrap items-end">
          <div class="form-control">
            <label class="label">
              <span class="label-text">{gettext("Action Type")}</span>
            </label>
            <select name="action_type" class="select select-bordered select-sm">
              <option value="">{gettext("All Actions")}</option>
              <%= for action_type <- SecurityAuditLog.action_types() do %>
                <option value={action_type} selected={@filter_action_type == action_type}>
                  {SecurityAuditLog.describe_action(action_type)}
                </option>
              <% end %>
            </select>
          </div>
          <div class="form-control">
            <label class="label">
              <span class="label-text">{gettext("Admin")}</span>
            </label>
            <select name="admin_id" class="select select-bordered select-sm">
              <option value="">{gettext("All Admins")}</option>
              <%= for admin <- @admins do %>
                <option value={admin.id} selected={@filter_admin_id == to_string(admin.id)}>
                  {admin.display_name || admin.email}
                </option>
              <% end %>
            </select>
          </div>
        </form>
      </div>

      <%!-- Stats Summary --%>
      <div class="mt-[var(--space-md)] gap-[var(--space-sm)] flex flex-wrap">
        <div class="badge badge-lg badge-outline">
          {gettext("Total: %{count}", count: @total_count)}
        </div>
      </div>

      <%!-- Audit Log Table --%>
      <div class="mt-[var(--space-md)]">
        <div class="overflow-x-auto">
          <table class="table-sm table-zebra table">
            <thead>
              <tr>
                <th class="w-32">{gettext("Time")}</th>
                <th>{gettext("Admin")}</th>
                <th>{gettext("Action")}</th>
                <th>{gettext("Target")}</th>
                <th>{gettext("Details")}</th>
                <th>{gettext("IP Address")}</th>
              </tr>
            </thead>
            <tbody>
              <%= for log <- @logs do %>
                <tr>
                  <td class="text-[var(--text-xs)] text-base-content/60 whitespace-nowrap">
                    {format_relative_time(log.inserted_at)}
                  </td>
                  <td class="text-[var(--text-sm)]">
                    <%= if log.admin do %>
                      {log.admin.display_name || log.admin.email}
                    <% else %>
                      <span class="text-base-content/40">{gettext("Unknown")}</span>
                    <% end %>
                  </td>
                  <td>
                    <span class={["badge badge-sm", action_badge_class(log.action_type)]}>
                      {SecurityAuditLog.describe_action(log.action_type)}
                    </span>
                  </td>
                  <td class="font-mono text-[var(--text-sm)]">
                    <span class="text-base-content/60">{log.target_type}:</span>
                    {log.target_value}
                  </td>
                  <td class="text-[var(--text-xs)] max-w-xs truncate">
                    <%= if map_size(log.details) > 0 do %>
                      <span
                        class="cursor-help"
                        title={Jason.encode!(log.details, pretty: true)}
                      >
                        {format_details(log.details)}
                      </span>
                    <% else %>
                      <span class="text-base-content/40">-</span>
                    <% end %>
                  </td>
                  <td class="font-mono text-[var(--text-xs)] text-base-content/60">
                    {log.ip_address || "-"}
                  </td>
                </tr>
              <% end %>
              <%= if @logs == [] do %>
                <tr>
                  <td colspan="6" class="text-base-content/60 py-[var(--space-lg)] text-center">
                    {gettext("No audit log entries found")}
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>

      <%!-- Pagination --%>
      <%= if @total_count > @page_size do %>
        <div class="mt-[var(--space-md)] flex justify-center">
          <div class="btn-group">
            <button
              class="btn btn-sm"
              phx-click="prev_page"
              disabled={@page == 0}
            >
              <.icon name="hero-chevron-left" class="h-4 w-4" />
            </button>
            <button class="btn btn-sm btn-disabled">
              {gettext("Page %{current} of %{total}",
                current: @page + 1,
                total: ceil(@total_count / @page_size)
              )}
            </button>
            <button
              class="btn btn-sm"
              phx-click="next_page"
              disabled={(@page + 1) * @page_size >= @total_count}
            >
              <.icon name="hero-chevron-right" class="h-4 w-4" />
            </button>
          </div>
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    admins = Accounts.list_admins()

    {:ok,
     socket
     |> assign(:page_title, gettext("Security Audit Log"))
     |> assign(:current_url, "/admin/threats/audit-log")
     |> assign(:admins, admins)
     |> assign(:filter_action_type, nil)
     |> assign(:filter_admin_id, nil)
     |> assign(:page, 0)
     |> assign(:page_size, 50)
     |> load_logs()}
  end

  @impl true
  def handle_event("filter", params, socket) do
    action_type = if params["action_type"] == "", do: nil, else: params["action_type"]
    admin_id = if params["admin_id"] == "", do: nil, else: params["admin_id"]

    {:noreply,
     socket
     |> assign(:filter_action_type, action_type)
     |> assign(:filter_admin_id, admin_id)
     |> assign(:page, 0)
     |> load_logs()}
  end

  def handle_event("prev_page", _, socket) do
    {:noreply,
     socket
     |> assign(:page, max(0, socket.assigns.page - 1))
     |> load_logs()}
  end

  def handle_event("next_page", _, socket) do
    {:noreply,
     socket
     |> assign(:page, socket.assigns.page + 1)
     |> load_logs()}
  end

  defp load_logs(socket) do
    opts = [
      limit: socket.assigns.page_size,
      offset: socket.assigns.page * socket.assigns.page_size
    ]

    opts =
      if socket.assigns.filter_action_type do
        Keyword.put(opts, :action_type, socket.assigns.filter_action_type)
      else
        opts
      end

    opts =
      if socket.assigns.filter_admin_id do
        Keyword.put(opts, :admin_id, socket.assigns.filter_admin_id)
      else
        opts
      end

    logs = ThreatReputation.list_security_audit_logs(opts)

    count_opts =
      opts
      |> Keyword.delete(:limit)
      |> Keyword.delete(:offset)

    total_count = ThreatReputation.count_security_audit_logs(count_opts)

    socket
    |> assign(:logs, logs)
    |> assign(:total_count, total_count)
  end

  defp action_badge_class("ip_watchlist_add"), do: "badge-warning"
  defp action_badge_class("ip_watchlist_remove"), do: "badge-info"
  defp action_badge_class("country_watchlist_add"), do: "badge-warning"
  defp action_badge_class("country_watchlist_remove"), do: "badge-info"
  defp action_badge_class("ip_manual_block"), do: "badge-error"
  defp action_badge_class("ip_manual_unblock"), do: "badge-success"
  defp action_badge_class("threshold_change"), do: "badge-secondary"
  defp action_badge_class("alert_config_change"), do: "badge-secondary"
  defp action_badge_class(_), do: "badge-ghost"

  defp format_details(details) when is_map(details) do
    details
    |> Enum.take(3)
    |> Enum.map_join(", ", fn {k, v} -> "#{k}: #{inspect(v)}" end)
  end

  defp format_details(_), do: ""
end
