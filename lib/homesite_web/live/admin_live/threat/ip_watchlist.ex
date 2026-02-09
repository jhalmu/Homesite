defmodule HomesiteWeb.AdminLive.Threat.IpWatchlist do
  @moduledoc false
  use HomesiteWeb, :live_view

  alias Homesite.ThreatReputation
  alias Homesite.ThreatReputation.IpWatchlistEntry
  import HomesiteWeb.Helpers.DateHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("IP Watchlist")}
        <:subtitle>{gettext("Manually manage suspicious IP addresses")}</:subtitle>
        <:actions>
          <.link navigate={~p"/admin/threats"} class="btn btn-ghost btn-sm">
            <.icon name="hero-arrow-left" class="h-4 w-4" /> {gettext("Back to Dashboard")}
          </.link>
        </:actions>
      </.header>

      <%!-- Add IP Form --%>
      <div class="mt-[var(--space-lg)]">
        <div class="card bg-base-200">
          <div class="card-body">
            <h3 class="card-title">{gettext("Add IP to Watchlist")}</h3>
            <.form
              for={@form}
              phx-submit="add_ip"
              class="gap-[var(--space-md)] grid grid-cols-1 md:grid-cols-5"
            >
              <div>
                <.input
                  field={@form[:ip_address]}
                  label={gettext("IP Address")}
                  placeholder="192.168.1.1"
                  required
                />
              </div>
              <div>
                <.input
                  field={@form[:boost_score]}
                  type="number"
                  label={gettext("Score Boost")}
                  min="0"
                  max="15"
                />
              </div>
              <div>
                <.input
                  field={@form[:reason]}
                  label={gettext("Reason")}
                  placeholder={gettext("Suspicious activity")}
                />
              </div>
              <div>
                <.input
                  field={@form[:expires_at]}
                  type="datetime-local"
                  label={gettext("Expires At")}
                />
              </div>
              <div class="flex items-end">
                <.button type="submit" class="btn-primary">
                  <.icon name="hero-plus" class="h-4 w-4" /> {gettext("Add")}
                </.button>
              </div>
            </.form>
          </div>
        </div>
      </div>

      <%!-- Watchlist Table --%>
      <div class="mt-[var(--space-lg)]">
        <div class="card bg-base-200">
          <div class="card-body">
            <h3 class="card-title">{gettext("Current Watchlist")}</h3>
            <%= if @entries == [] do %>
              <p class="text-base-content/60 py-[var(--space-md)] text-center">
                {gettext("No IPs in watchlist")}
              </p>
            <% else %>
              <div class="overflow-x-auto">
                <table class="table-sm table-zebra table">
                  <thead>
                    <tr>
                      <th>{gettext("IP Address")}</th>
                      <th class="text-center">{gettext("Boost")}</th>
                      <th>{gettext("Reason")}</th>
                      <th>{gettext("Added By")}</th>
                      <th>{gettext("Expires")}</th>
                      <th class="text-center">{gettext("Status")}</th>
                      <th></th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= for entry <- @entries do %>
                      <tr>
                        <td class="font-mono text-[var(--text-sm)]">{entry.ip_address}</td>
                        <td class="text-center">
                          <span class="badge badge-warning badge-sm">+{entry.boost_score}</span>
                        </td>
                        <td class="text-[var(--text-sm)] max-w-xs truncate">{entry.reason || "-"}</td>
                        <td class="text-[var(--text-sm)]">
                          <%= if entry.added_by do %>
                            {entry.added_by.email}
                          <% else %>
                            <span class="text-base-content/50">{gettext("System")}</span>
                          <% end %>
                        </td>
                        <td class="text-[var(--text-xs)]">
                          <%= if entry.expires_at do %>
                            {format_relative_time(entry.expires_at)}
                          <% else %>
                            <span class="text-base-content/50">{gettext("Never")}</span>
                          <% end %>
                        </td>
                        <td class="text-center">
                          <%= if IpWatchlistEntry.active?(entry) do %>
                            <span class="badge badge-success badge-sm">{gettext("Active")}</span>
                          <% else %>
                            <span class="badge badge-ghost badge-sm">{gettext("Expired")}</span>
                          <% end %>
                        </td>
                        <td>
                          <button
                            class="btn btn-xs btn-ghost text-error"
                            phx-click="remove_ip"
                            phx-value-ip={entry.ip_address}
                            data-confirm={gettext("Remove this IP from watchlist?")}
                          >
                            <.icon name="hero-trash" class="h-4 w-4" />
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
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    entries = ThreatReputation.list_ip_watchlist()
    changeset = IpWatchlistEntry.changeset(%IpWatchlistEntry{}, %{boost_score: 15})

    {:ok,
     socket
     |> assign(:page_title, gettext("IP Watchlist"))
     |> assign(:entries, entries)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("add_ip", %{"ip_watchlist_entry" => params}, socket) do
    admin = socket.assigns.current_scope.user

    # Parse expires_at if provided
    opts =
      params
      |> Map.take(["boost_score", "reason", "notes"])
      |> Enum.map(fn
        {"boost_score", v} when is_binary(v) -> {:boost_score, String.to_integer(v)}
        {"boost_score", v} -> {:boost_score, v}
        {k, v} -> {String.to_existing_atom(k), v}
      end)

    opts =
      case params["expires_at"] do
        "" ->
          opts

        nil ->
          opts

        datetime_str ->
          case NaiveDateTime.from_iso8601(datetime_str <> ":00") do
            {:ok, naive} ->
              {:ok, dt} = DateTime.from_naive(naive, "Etc/UTC")
              Keyword.put(opts, :expires_at, dt)

            _ ->
              opts
          end
      end

    case ThreatReputation.add_ip_to_watchlist(params["ip_address"], admin, opts) do
      {:ok, _entry} ->
        entries = ThreatReputation.list_ip_watchlist()
        changeset = IpWatchlistEntry.changeset(%IpWatchlistEntry{}, %{boost_score: 15})

        {:noreply,
         socket
         |> put_flash(:info, gettext("IP added to watchlist"))
         |> assign(:entries, entries)
         |> assign(:form, to_form(changeset))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to add IP"))
         |> assign(:form, to_form(changeset))}
    end
  end

  def handle_event("remove_ip", %{"ip" => ip_address}, socket) do
    case ThreatReputation.remove_ip_from_watchlist(ip_address) do
      {:ok, _} ->
        entries = ThreatReputation.list_ip_watchlist()

        {:noreply,
         socket
         |> put_flash(:info, gettext("IP removed from watchlist"))
         |> assign(:entries, entries)}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, gettext("IP not found in watchlist"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to remove IP"))}
    end
  end
end
