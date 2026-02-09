defmodule HomesiteWeb.AdminLive.Threat.Dashboard do
  @moduledoc false
  use HomesiteWeb, :live_view

  alias Homesite.Accounts.UserNotifier
  alias Homesite.Settings
  alias Homesite.ThreatReputation
  import HomesiteWeb.Helpers.DateHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Threat Reputation Dashboard")}
        <:subtitle>{gettext("Monitor and manage IP/country threat intelligence")}</:subtitle>
      </.header>

      <%!-- Quick Actions --%>
      <div class="mt-[var(--space-md)]">
        <div class="gap-[var(--space-sm)] flex flex-wrap">
          <.link navigate={~p"/admin/threats/ip-watchlist"} class="btn btn-outline btn-sm">
            <.icon name="hero-eye" class="h-4 w-4" /> {gettext("IP Watchlist")}
          </.link>
          <.link navigate={~p"/admin/threats/country-watchlist"} class="btn btn-outline btn-sm">
            <.icon name="hero-globe-alt" class="h-4 w-4" /> {gettext("Country Watchlist")}
          </.link>
          <.link navigate={~p"/admin/threats/audit-log"} class="btn btn-outline btn-sm">
            <.icon name="hero-clipboard-document-list" class="h-4 w-4" /> {gettext("Audit Log")}
          </.link>
          <.link navigate={~p"/admin/moderation"} class="btn btn-outline btn-sm">
            <.icon name="hero-shield-exclamation" class="h-4 w-4" /> {gettext("Moderation")}
          </.link>
        </div>
      </div>

      <%!-- Alert Configuration --%>
      <div class="collapse collapse-arrow mt-[var(--space-md)] bg-base-200">
        <input type="checkbox" />
        <div class="collapse-title font-medium">
          <div class="gap-[var(--space-sm)] flex items-center">
            <.icon name="hero-bell-alert" class="h-5 w-5" />
            {gettext("Email Alert Configuration")}
            <%= if @alert_config.enabled do %>
              <span class="badge badge-success badge-sm">{gettext("Enabled")}</span>
            <% else %>
              <span class="badge badge-ghost badge-sm">{gettext("Disabled")}</span>
            <% end %>
          </div>
        </div>
        <div class="collapse-content">
          <form phx-change="update_alert_config" class="space-y-[var(--space-md)]">
            <%!-- Enable/Disable Toggle --%>
            <div class="form-control">
              <label class="label gap-[var(--space-sm)] cursor-pointer justify-start">
                <input
                  type="checkbox"
                  name="enabled"
                  value="true"
                  checked={@alert_config.enabled}
                  class="toggle toggle-success"
                />
                <span class="label-text">{gettext("Enable email alerts")}</span>
              </label>
            </div>

            <%!-- Alert Level --%>
            <div class="form-control">
              <label class="label">
                <span class="label-text font-semibold">{gettext("Alert Level")}</span>
              </label>
              <div class="space-y-[var(--space-xs)]">
                <label class="label gap-[var(--space-sm)] cursor-pointer justify-start">
                  <input
                    type="radio"
                    name="level"
                    value="critical"
                    checked={@alert_config.level == :critical}
                    class="radio radio-sm"
                  />
                  <div>
                    <span class="label-text font-medium">{gettext("Critical only")}</span>
                    <p class="text-base-content/60 text-[var(--text-xs)]">
                      {gettext("Attack patterns: brute force, credential stuffing, distributed")}
                    </p>
                  </div>
                </label>
                <label class="label gap-[var(--space-sm)] cursor-pointer justify-start">
                  <input
                    type="radio"
                    name="level"
                    value="auto_blocks"
                    checked={@alert_config.level == :auto_blocks}
                    class="radio radio-sm"
                  />
                  <div>
                    <span class="label-text font-medium">{gettext("+ Auto-blocks")}</span>
                    <p class="text-base-content/60 text-[var(--text-xs)]">
                      {gettext("Critical + when IPs are automatically blocked")}
                    </p>
                  </div>
                </label>
                <label class="label gap-[var(--space-sm)] cursor-pointer justify-start">
                  <input
                    type="radio"
                    name="level"
                    value="threshold"
                    checked={@alert_config.level == :threshold}
                    class="radio radio-sm"
                  />
                  <div>
                    <span class="label-text font-medium">{gettext("+ Threshold exceeded")}</span>
                    <p class="text-base-content/60 text-[var(--text-xs)]">
                      {gettext("Above + daily threat count exceeds limit")}
                    </p>
                  </div>
                </label>
                <label class="label gap-[var(--space-sm)] cursor-pointer justify-start">
                  <input
                    type="radio"
                    name="level"
                    value="verbose"
                    checked={@alert_config.level == :verbose}
                    class="radio radio-sm"
                  />
                  <div>
                    <span class="label-text font-medium">{gettext("+ Warning level IPs")}</span>
                    <p class="text-base-content/60 text-[var(--text-xs)]">
                      {gettext("Above + when IPs reach 61-79%% score")}
                    </p>
                  </div>
                </label>
              </div>
            </div>

            <%!-- Threshold (only shown if level >= threshold) --%>
            <%= if @alert_config.level in [:threshold, :verbose] do %>
              <div class="form-control">
                <label class="label">
                  <span class="label-text">{gettext("Daily event threshold")}</span>
                </label>
                <input
                  type="number"
                  name="threshold"
                  value={@alert_config.threshold}
                  min="10"
                  max="1000"
                  class="input input-bordered input-sm w-32"
                />
                <label class="label">
                  <span class="label-text-alt text-base-content/60">
                    {gettext("Alert when daily events exceed this number")}
                  </span>
                </label>
              </div>
            <% end %>

            <%!-- Test Button --%>
            <div class="mt-[var(--space-md)]">
              <button type="button" phx-click="send_test_alert" class="btn btn-ghost btn-sm">
                <.icon name="hero-paper-airplane" class="h-4 w-4" />
                {gettext("Send Test Alert")}
              </button>
            </div>
          </form>
        </div>
      </div>

      <%!-- Key Metrics --%>
      <div class="mt-[var(--space-lg)] gap-[var(--space-md)] grid grid-cols-2 lg:grid-cols-6">
        <.threat_stat_card
          icon="hero-shield-exclamation"
          title={gettext("Blocked IPs")}
          value={@stats.blocked_ips}
          color="error"
        />
        <.threat_stat_card
          icon="hero-exclamation-triangle"
          title={gettext("High Risk IPs")}
          value={@stats.high_risk_ips}
          color="warning"
        />
        <.threat_stat_card
          icon="hero-bolt"
          title={gettext("Events (24h)")}
          value={@stats.threat_events_24h}
          color="info"
        />
        <.threat_stat_card
          icon="hero-no-symbol"
          title={gettext("Auto-blocks (24h)")}
          value={@stats.auto_blocks_24h}
          color="error"
        />
        <.threat_stat_card
          icon="hero-eye"
          title={gettext("IP Watchlist")}
          value={@stats.watchlist_ips}
          color="secondary"
        />
        <.threat_stat_card
          icon="hero-globe-alt"
          title={gettext("Country Watchlist")}
          value={@stats.watchlist_countries}
          color="secondary"
        />
      </div>

      <%!-- Real-time Monitor Stats --%>
      <div class="mt-[var(--space-md)] gap-[var(--space-md)] grid grid-cols-1 lg:grid-cols-2">
        <div class="alert alert-warning">
          <.icon name="hero-signal" class="h-5 w-5" />
          <div>
            <h4 class="font-semibold">{gettext("Real-time Monitor")} (5 min window)</h4>
            <p class="text-[var(--text-sm)]">
              <span class="font-mono">{@monitor_stats.events_in_window}</span> {gettext("events")} |
              <span class="font-mono">{@monitor_stats.unique_ips_in_window}</span> {gettext("IPs")} | <span class="font-mono">{@monitor_stats.events_per_minute}</span>/min
              <%= if @monitor_stats.recent_attack_count > 0 do %>
                |
                <span class="text-error font-bold">
                  {@monitor_stats.recent_attack_count} {gettext("attacks detected")}
                </span>
              <% end %>
            </p>
          </div>
        </div>
        <div class="alert alert-info">
          <.icon name="hero-server-stack" class="h-5 w-5" />
          <div>
            <h4 class="font-semibold">{gettext("External Reputation: AbuseIPDB")}</h4>
            <p class="text-[var(--text-sm)]">
              <%= if @stats.external_reputation.api_configured do %>
                <span class="badge badge-success badge-sm">{gettext("Connected")}</span>
                {gettext("Cache: %{entries} entries, TTL: %{hours}h",
                  entries: @stats.external_reputation.cache_entries,
                  hours: @stats.external_reputation.cache_ttl_hours
                )}
              <% else %>
                <span class="badge badge-warning badge-sm">{gettext("Not Configured")}</span>
                {gettext("Set ABUSEIPDB_API_KEY to enable external IP reputation scoring")}
              <% end %>
            </p>
          </div>
        </div>
      </div>

      <%!-- Top Threats & Recent Blocks --%>
      <div class="mt-[var(--space-lg)] gap-[var(--space-md)] grid grid-cols-1 lg:grid-cols-2">
        <%!-- Top Threats --%>
        <div class="card bg-base-200">
          <div class="card-body">
            <h3 class="card-title">
              <.icon name="hero-fire" class="text-error h-5 w-5" />
              {gettext("Top Threats")}
            </h3>
            <%= if @top_threats == [] do %>
              <p class="text-base-content/60 py-[var(--space-md)] text-center">
                {gettext("No active threats")}
              </p>
            <% else %>
              <div class="overflow-x-auto">
                <table class="table-sm table">
                  <thead>
                    <tr>
                      <th>{gettext("IP Address")}</th>
                      <th>{gettext("Country")}</th>
                      <th class="text-center">{gettext("Score")}</th>
                      <th class="text-center">{gettext("Status")}</th>
                      <th></th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= for ip_rep <- @top_threats do %>
                      <tr>
                        <td class="font-mono text-[var(--text-sm)]">{ip_rep.ip_address}</td>
                        <td>{country_flag(ip_rep.country_code)} {ip_rep.country_code || "-"}</td>
                        <td class="text-center">
                          <span class={["badge badge-sm", score_badge_class(ip_rep.score)]}>
                            {ip_rep.score}%
                          </span>
                        </td>
                        <td class="text-center">
                          <%= if ip_rep.blocked do %>
                            <span class="badge badge-error badge-sm">{gettext("Blocked")}</span>
                          <% else %>
                            <span class="badge badge-ghost badge-sm">{gettext("Active")}</span>
                          <% end %>
                        </td>
                        <td>
                          <%= if ip_rep.blocked do %>
                            <button
                              class="btn btn-xs btn-ghost"
                              phx-click="unblock_ip"
                              phx-value-ip={ip_rep.ip_address}
                            >
                              {gettext("Unblock")}
                            </button>
                          <% else %>
                            <button
                              class="btn btn-xs btn-error btn-ghost"
                              phx-click="block_ip"
                              phx-value-ip={ip_rep.ip_address}
                            >
                              {gettext("Block")}
                            </button>
                          <% end %>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            <% end %>
          </div>
        </div>

        <%!-- Recent Blocks --%>
        <div class="card bg-base-200">
          <div class="card-body">
            <h3 class="card-title">
              <.icon name="hero-no-symbol" class="text-error h-5 w-5" />
              {gettext("Recent Blocks")}
            </h3>
            <%= if @recent_blocks == [] do %>
              <p class="text-base-content/60 py-[var(--space-md)] text-center">
                {gettext("No recent blocks")}
              </p>
            <% else %>
              <div class="overflow-x-auto">
                <table class="table-sm table">
                  <thead>
                    <tr>
                      <th>{gettext("IP Address")}</th>
                      <th>{gettext("Blocked At")}</th>
                      <th>{gettext("Expires")}</th>
                      <th>{gettext("Count")}</th>
                      <th></th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= for ip_rep <- @recent_blocks do %>
                      <tr>
                        <td class="font-mono text-[var(--text-sm)]">{ip_rep.ip_address}</td>
                        <td class="text-[var(--text-xs)]">
                          {format_relative_time(ip_rep.blocked_at)}
                        </td>
                        <td class="text-[var(--text-xs)]">
                          <%= if ip_rep.block_expires_at do %>
                            {format_relative_time(ip_rep.block_expires_at)}
                          <% else %>
                            <span class="text-error">{gettext("Permanent")}</span>
                          <% end %>
                        </td>
                        <td class="text-center">{ip_rep.block_count}</td>
                        <td>
                          <button
                            class="btn btn-xs btn-ghost"
                            phx-click="unblock_ip"
                            phx-value-ip={ip_rep.ip_address}
                          >
                            {gettext("Unblock")}
                          </button>
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

      <%!-- Recent Events --%>
      <div class="mt-[var(--space-lg)]">
        <div class="card bg-base-200">
          <div class="card-body">
            <h3 class="card-title">
              <.icon name="hero-bolt" class="text-info h-5 w-5" />
              {gettext("Recent Threat Events")}
            </h3>
            <%= if @recent_events == [] do %>
              <p class="text-base-content/60 py-[var(--space-md)] text-center">
                {gettext("No recent events")}
              </p>
            <% else %>
              <div class="overflow-x-auto">
                <table class="table-sm table-zebra table">
                  <thead>
                    <tr>
                      <th>{gettext("Time")}</th>
                      <th>{gettext("IP Address")}</th>
                      <th>{gettext("Event")}</th>
                      <th>{gettext("Severity")}</th>
                      <th>{gettext("Score Impact")}</th>
                      <th>{gettext("Details")}</th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= for event <- @recent_events do %>
                      <tr>
                        <td class="text-[var(--text-xs)] whitespace-nowrap">
                          {format_relative_time(event.inserted_at)}
                        </td>
                        <td class="font-mono text-[var(--text-sm)]">{event.ip_address}</td>
                        <td>
                          <span class="badge badge-sm badge-ghost">
                            {format_event_type(event.event_type)}
                          </span>
                        </td>
                        <td>
                          <span class={["badge badge-sm", severity_badge_class(event.severity)]}>
                            {event.severity}
                          </span>
                        </td>
                        <td class="text-center">
                          <%= if event.score_impact > 0 do %>
                            <span class="text-error">+{event.score_impact}</span>
                          <% else %>
                            <span class="text-base-content/50">0</span>
                          <% end %>
                        </td>
                        <td class="text-[var(--text-xs)] max-w-xs truncate">
                          {format_event_details(event.details)}
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
    </Layouts.app>
    """
  end

  attr :icon, :string, required: true
  attr :title, :string, required: true
  attr :value, :any, required: true
  attr :color, :string, default: "primary"

  defp threat_stat_card(assigns) do
    assigns = assign(assigns, :icon_class, "h-6 w-6 text-#{assigns.color}")

    assigns =
      assign(assigns, :value_class, "text-[var(--text-xl)] font-bold text-#{assigns.color}")

    ~H"""
    <div class="card bg-base-200">
      <div class="card-body p-[var(--space-md)]">
        <div class="gap-[var(--space-sm)] flex items-center">
          <.icon name={@icon} class={@icon_class} />
          <div>
            <p class="text-base-content/60 text-[var(--text-xs)]">{@title}</p>
            <p class={@value_class}>{@value}</p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    # Subscribe to real-time threat monitor updates
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Homesite.PubSub, ThreatReputation.monitor_topic())
    end

    stats = ThreatReputation.get_dashboard_stats()
    monitor_stats = ThreatReputation.get_monitor_stats()
    top_threats = ThreatReputation.list_top_threats(limit: 10)
    recent_blocks = ThreatReputation.list_recent_blocks(limit: 10)
    recent_events = ThreatReputation.list_recent_events(limit: 20)
    alert_config = Settings.security_alert_config()

    {:ok,
     socket
     |> assign(:page_title, gettext("Threat Dashboard"))
     |> assign(:stats, stats)
     |> assign(:monitor_stats, monitor_stats)
     |> assign(:top_threats, top_threats)
     |> assign(:recent_blocks, recent_blocks)
     |> assign(:recent_events, recent_events)
     |> assign(:alert_config, alert_config)}
  end

  @impl true
  def handle_event("block_ip", %{"ip" => ip_address}, socket) do
    admin = socket.assigns.current_scope.user

    case ThreatReputation.manual_block_ip(ip_address, admin, reason: "Manual admin block") do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("IP %{ip} has been blocked", ip: ip_address))
         |> reload_data()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to block IP"))}
    end
  end

  def handle_event("unblock_ip", %{"ip" => ip_address}, socket) do
    admin = socket.assigns.current_scope.user

    case ThreatReputation.unblock_ip(ip_address, admin: admin) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("IP %{ip} has been unblocked", ip: ip_address))
         |> reload_data()}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, gettext("IP not found"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to unblock IP"))}
    end
  end

  def handle_event("update_alert_config", params, socket) do
    admin = socket.assigns.current_scope.user

    config = %{
      enabled: params["enabled"] == "true",
      level: params["level"] || "critical",
      threshold: parse_threshold(params["threshold"])
    }

    case Settings.update_security_alert_config(config) do
      {:ok, _} ->
        # Log the config change
        ThreatReputation.log_security_action(
          admin,
          "alert_config_change",
          "setting",
          "security_alerts",
          details: config
        )

        {:noreply, assign(socket, :alert_config, Settings.security_alert_config())}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to update alert configuration"))}
    end
  end

  def handle_event("send_test_alert", _, socket) do
    admin = socket.assigns.current_scope.user

    # Send a test alert to the current admin only
    UserNotifier.deliver_security_alert(
      admin,
      :attack_detected,
      %{
        attack_type: "Test Alert",
        ip_address: "127.0.0.1",
        country: "TEST",
        event_count: 0
      }
    )

    {:noreply, put_flash(socket, :info, gettext("Test alert sent to your email"))}
  end

  defp parse_threshold(nil), do: 100
  defp parse_threshold(""), do: 100

  defp parse_threshold(value) when is_binary(value) do
    case Integer.parse(value) do
      {num, _} when num >= 10 and num <= 1000 -> num
      _ -> 100
    end
  end

  defp parse_threshold(value) when is_integer(value), do: value

  # Handle real-time monitor updates
  @impl true
  def handle_info({:stats_updated, monitor_stats}, socket) do
    {:noreply, assign(socket, :monitor_stats, monitor_stats)}
  end

  def handle_info({:threat_event, _event}, socket) do
    # Reload recent events when new threat event arrives
    recent_events = ThreatReputation.list_recent_events(limit: 20)
    {:noreply, assign(socket, :recent_events, recent_events)}
  end

  def handle_info({:attack_detected, attack}, socket) do
    # Show flash notification for detected attacks
    attack_type = attack.type |> to_string() |> String.replace("_", " ") |> String.capitalize()

    socket =
      put_flash(
        socket,
        :error,
        gettext("Attack detected: %{type}", type: attack_type)
      )

    {:noreply, reload_data(socket)}
  end

  defp reload_data(socket) do
    stats = ThreatReputation.get_dashboard_stats()
    monitor_stats = ThreatReputation.get_monitor_stats()
    top_threats = ThreatReputation.list_top_threats(limit: 10)
    recent_blocks = ThreatReputation.list_recent_blocks(limit: 10)
    recent_events = ThreatReputation.list_recent_events(limit: 20)

    socket
    |> assign(:stats, stats)
    |> assign(:monitor_stats, monitor_stats)
    |> assign(:top_threats, top_threats)
    |> assign(:recent_blocks, recent_blocks)
    |> assign(:recent_events, recent_events)
  end

  defp country_flag(nil), do: ""

  defp country_flag(code) when is_binary(code) do
    code
    |> String.upcase()
    |> String.to_charlist()
    |> Enum.map(&(&1 - ?A + 0x1F1E6))
    |> List.to_string()
  end

  defp score_badge_class(score) when score >= 80, do: "badge-error"
  defp score_badge_class(score) when score >= 61, do: "badge-warning"
  defp score_badge_class(score) when score >= 31, do: "badge-info"
  defp score_badge_class(_score), do: "badge-success"

  defp severity_badge_class("critical"), do: "badge-error"
  defp severity_badge_class("high"), do: "badge-warning"
  defp severity_badge_class("medium"), do: "badge-info"
  defp severity_badge_class(_), do: "badge-ghost"

  defp format_event_type(type) do
    type
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_event_details(nil), do: "-"
  defp format_event_details(details) when details == %{}, do: "-"

  defp format_event_details(details) when is_map(details) do
    Enum.map_join(details, ", ", fn {k, v} -> "#{k}: #{v}" end)
  end
end
