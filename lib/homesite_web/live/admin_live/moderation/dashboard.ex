defmodule HomesiteWeb.AdminLive.Moderation.Dashboard do
  @moduledoc """
  Admin moderation dashboard.

  Shows overview of moderation activity and quick access to all moderation features.
  """
  use HomesiteWeb, :live_view

  alias Homesite.Moderation
  import HomesiteWeb.Helpers.ModerationHelpers

  @impl true
  def mount(_params, _session, socket) do
    stats = Moderation.get_moderation_stats()
    recent_logs = Moderation.list_moderation_logs(limit: 10)

    {:ok,
     socket
     |> assign(:page_title, gettext("Moderation Dashboard"))
     |> assign(:stats, stats)
     |> assign(:recent_logs, recent_logs)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Moderation Dashboard")}
        <:subtitle>
          {gettext("Overview of moderation activity and actions")}
        </:subtitle>
        <:actions>
          <.link navigate={~p"/admin"} class="btn btn-ghost btn-sm">
            <.icon name="hero-arrow-left" class="h-4 w-4" />
            {gettext("Back to Admin")}
          </.link>
        </:actions>
      </.header>

      <div class="mt-[var(--space-md)]">
        <div class="mb-[var(--space-lg)] gap-[var(--space-sm)] grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4">
          <.moderation_stat_card
            title={gettext("Pending Reports")}
            value={@stats.pending_reports}
            icon="hero-flag"
            color={if @stats.pending_reports > 0, do: "text-warning", else: "text-success"}
            link={~p"/admin/moderation/reports"}
          />
          <.moderation_stat_card
            title={gettext("Active Suspensions")}
            value={@stats.active_suspensions}
            icon="hero-clock"
            color="text-warning"
            link={~p"/admin/moderation/suspensions"}
          />
          <.moderation_stat_card
            title={gettext("Active Bans")}
            value={@stats.active_bans}
            icon="hero-no-symbol"
            color="text-error"
            link={~p"/admin/moderation/bans"}
          />
          <.moderation_stat_card
            title={gettext("Total Mutes")}
            value={@stats.total_mutes}
            icon="hero-speaker-x-mark"
            color="text-info"
            link={~p"/admin/moderation/logs?action=mute_user"}
          />
        </div>

        <div class="gap-[var(--space-md)] grid grid-cols-1 lg:grid-cols-2">
          <div class="card bg-base-200">
            <div class="card-body">
              <h2 class="card-title">
                <.icon name="hero-bolt" class="h-5 w-5" />
                {gettext("Quick Actions")}
              </h2>
              <div class="gap-[var(--space-xs)] grid grid-cols-2">
                <.link navigate={~p"/admin/moderation/reports"} class="btn btn-outline btn-sm">
                  <.icon name="hero-flag" class="h-4 w-4" />
                  {gettext("Review Reports")}
                </.link>
                <.link navigate={~p"/admin/moderation/suspensions"} class="btn btn-outline btn-sm">
                  <.icon name="hero-clock" class="h-4 w-4" />
                  {gettext("Manage Suspensions")}
                </.link>
                <.link navigate={~p"/admin/moderation/bans"} class="btn btn-outline btn-sm">
                  <.icon name="hero-no-symbol" class="h-4 w-4" />
                  {gettext("Manage Bans")}
                </.link>
                <.link navigate={~p"/admin/moderation/banners"} class="btn btn-outline btn-sm">
                  <.icon name="hero-megaphone" class="h-4 w-4" />
                  {gettext("Send Warnings")}
                </.link>
                <.link navigate={~p"/admin/moderation/logs"} class="btn btn-outline btn-sm col-span-2">
                  <.icon name="hero-clipboard-document-list" class="h-4 w-4" />
                  {gettext("View Full Audit Log")}
                </.link>
              </div>
            </div>
          </div>

          <div class="card bg-base-200">
            <div class="card-body">
              <h2 class="card-title">
                <.icon name="hero-clock" class="h-5 w-5" />
                {gettext("Recent Activity")}
              </h2>
              <%= if @recent_logs == [] do %>
                <p class="text-base-content/60">{gettext("No recent moderation activity")}</p>
              <% else %>
                <div class="overflow-x-auto">
                  <table class="table-sm table">
                    <tbody>
                      <%= for log <- @recent_logs do %>
                        <tr>
                          <td class="whitespace-nowrap">
                            <span class={["badge badge-sm", action_badge_class(log.action)]}>
                              {format_action_short(log.action)}
                            </span>
                          </td>
                          <td>
                            <span class="text-sm">
                              {log.target_user &&
                                (log.target_user.display_name || log.target_user.email)}
                            </span>
                          </td>
                          <td class="text-base-content/60 text-[var(--text-xs)]">
                            {Calendar.strftime(log.inserted_at, "%m/%d %H:%M")}
                          </td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  attr :title, :string, required: true
  attr :value, :integer, required: true
  attr :icon, :string, required: true
  attr :color, :string, default: "text-base-content"
  attr :link, :string, required: true

  defp moderation_stat_card(assigns) do
    ~H"""
    <.link navigate={@link} class="card bg-base-200 transition-colors hover:bg-base-300">
      <div class="card-body">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-base-content/60 text-[var(--text-sm)]">{@title}</p>
            <p class={["text-3xl font-bold", @color]}>{@value}</p>
          </div>
          <.icon name={@icon} class={"#{@color} h-10 w-10 opacity-40"} />
        </div>
      </div>
    </.link>
    """
  end
end
