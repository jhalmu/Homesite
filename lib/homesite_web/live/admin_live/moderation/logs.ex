defmodule HomesiteWeb.AdminLive.Moderation.Logs do
  @moduledoc """
  Admin LiveView for viewing moderation audit logs.

  Shows all moderation actions with filtering by action type and target user.
  """
  use HomesiteWeb, :live_view

  alias Homesite.Moderation
  import HomesiteWeb.Helpers.ModerationHelpers

  @actions [
    "mute_user",
    "unmute_user",
    "report_user",
    "report_resolve",
    "report_dismiss",
    "banner_create",
    "banner_dismiss",
    "suspend",
    "unsuspend",
    "ban",
    "unban"
  ]

  @impl true
  def mount(params, _session, socket) do
    action_filter = params["action"]
    logs = Moderation.list_moderation_logs(action: action_filter, limit: 100)

    {:ok,
     socket
     |> assign(:page_title, gettext("Moderation Logs"))
     |> assign(:logs, logs)
     |> assign(:action_filter, action_filter)
     |> assign(:actions, @actions)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    action_filter = params["action"]
    logs = Moderation.list_moderation_logs(action: action_filter, limit: 100)

    {:noreply,
     socket
     |> assign(:logs, logs)
     |> assign(:action_filter, action_filter)}
  end

  @impl true
  def handle_event("filter", %{"action" => action}, socket) do
    action = if action == "", do: nil, else: action

    {:noreply, push_patch(socket, to: build_path(action))}
  end

  defp build_path(nil), do: ~p"/admin/moderation/logs"
  defp build_path(action), do: ~p"/admin/moderation/logs?action=#{action}"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Moderation Logs")}
        <:subtitle>
          {gettext("Audit trail of all moderation actions")}
        </:subtitle>
        <:actions>
          <.link navigate={~p"/admin/moderation"} class="btn btn-ghost btn-sm">
            <.icon name="hero-arrow-left" class="h-4 w-4" />
            {gettext("Back")}
          </.link>
        </:actions>
      </.header>

      <div class="mt-[var(--space-md)]">
        <form phx-change="filter" class="mb-4">
          <div class="form-control w-full max-w-xs">
            <label class="label">
              <span class="label-text">{gettext("Filter by action")}</span>
            </label>
            <select name="action" class="select select-bordered">
              <option value="" selected={@action_filter == nil}>
                {gettext("All actions")}
              </option>
              <%= for action <- @actions do %>
                <option value={action} selected={@action_filter == action}>
                  {format_action(action)}
                </option>
              <% end %>
            </select>
          </div>
        </form>

        <%= if @logs == [] do %>
          <div class="py-[var(--space-xl)] text-center">
            <.icon name="hero-clipboard-document-list" class="text-base-content/40 mx-auto h-12 w-12" />
            <h3 class="mt-2 text-sm font-semibold">{gettext("No logs found")}</h3>
            <p class="text-base-content/60 mt-1 text-sm">
              {gettext("No moderation actions match the current filter.")}
            </p>
          </div>
        <% else %>
          <div class="overflow-x-auto">
            <table class="table" id="logs-table">
              <thead>
                <tr>
                  <th>{gettext("Time")}</th>
                  <th>{gettext("Action")}</th>
                  <th>{gettext("Target User")}</th>
                  <th>{gettext("Moderator")}</th>
                  <th>{gettext("Reason")}</th>
                </tr>
              </thead>
              <tbody>
                <%= for log <- @logs do %>
                  <tr id={"log-#{log.id}"}>
                    <td class="text-base-content/60 whitespace-nowrap text-sm">
                      {Calendar.strftime(log.inserted_at, "%Y-%m-%d %H:%M:%S")}
                    </td>
                    <td>
                      <span class={["badge badge-sm", action_badge_class(log.action)]}>
                        {format_action(log.action)}
                      </span>
                    </td>
                    <td>
                      <%= if log.target_user do %>
                        <div class="text-sm">
                          {log.target_user.display_name || log.target_user.email}
                        </div>
                      <% else %>
                        <span class="text-base-content/40 text-sm">{gettext("N/A")}</span>
                      <% end %>
                    </td>
                    <td>
                      <%= if log.moderator do %>
                        <div class="text-sm">
                          {log.moderator.display_name || log.moderator.email}
                        </div>
                      <% else %>
                        <span class="text-base-content/40 text-sm">{gettext("System")}</span>
                      <% end %>
                    </td>
                    <td>
                      <div class="text-base-content/70 max-w-md truncate text-sm">
                        {log.reason || "-"}
                      </div>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
