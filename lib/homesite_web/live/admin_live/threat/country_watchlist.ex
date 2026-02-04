defmodule HomesiteWeb.AdminLive.Threat.CountryWatchlist do
  use HomesiteWeb, :live_view

  alias Homesite.ThreatReputation
  alias Homesite.ThreatReputation.CountryWatchlistEntry
  import HomesiteWeb.Helpers.DateHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Country Watchlist")}
        <:subtitle>{gettext("Apply score boosts to entire countries")}</:subtitle>
        <:actions>
          <.link navigate={~p"/admin/threats"} class="btn btn-ghost btn-sm">
            <.icon name="hero-arrow-left" class="h-4 w-4" /> {gettext("Back to Dashboard")}
          </.link>
        </:actions>
      </.header>

      <%!-- Add Country Form --%>
      <div class="mt-[var(--space-lg)]">
        <div class="card bg-base-200">
          <div class="card-body">
            <h3 class="card-title">{gettext("Add Country to Watchlist")}</h3>
            <.form
              for={@form}
              phx-submit="add_country"
              class="gap-[var(--space-md)] grid grid-cols-1 md:grid-cols-5"
            >
              <div>
                <.input
                  field={@form[:country_code]}
                  label={gettext("Country Code")}
                  placeholder="US"
                  maxlength="2"
                  required
                />
                <p class="text-base-content/50 text-[var(--text-xs)] mt-1">
                  {gettext("ISO 3166-1 alpha-2 code (e.g., US, RU, CN)")}
                </p>
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
                  placeholder={gettext("High threat traffic")}
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
                {gettext("No countries in watchlist")}
              </p>
            <% else %>
              <div class="overflow-x-auto">
                <table class="table-sm table-zebra table">
                  <thead>
                    <tr>
                      <th>{gettext("Country")}</th>
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
                        <td class="font-mono">
                          {country_flag(entry.country_code)} {entry.country_code}
                        </td>
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
                          <%= if CountryWatchlistEntry.active?(entry) do %>
                            <span class="badge badge-success badge-sm">{gettext("Active")}</span>
                          <% else %>
                            <span class="badge badge-ghost badge-sm">{gettext("Expired")}</span>
                          <% end %>
                        </td>
                        <td>
                          <button
                            class="btn btn-xs btn-ghost text-error"
                            phx-click="remove_country"
                            phx-value-code={entry.country_code}
                            data-confirm={gettext("Remove this country from watchlist?")}
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

      <%!-- Country Stats --%>
      <%= if @country_stats != [] do %>
        <div class="mt-[var(--space-lg)]">
          <div class="card bg-base-200">
            <div class="card-body">
              <h3 class="card-title">{gettext("Country Threat Statistics")}</h3>
              <div class="overflow-x-auto">
                <table class="table-sm table">
                  <thead>
                    <tr>
                      <th>{gettext("Country")}</th>
                      <th class="text-center">{gettext("Score")}</th>
                      <th class="text-center">{gettext("Total IPs")}</th>
                      <th class="text-center">{gettext("Blocked IPs")}</th>
                      <th class="text-center">{gettext("Events")}</th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= for stat <- @country_stats do %>
                      <tr>
                        <td>{country_flag(stat.country_code)} {stat.country_code}</td>
                        <td class="text-center">
                          <span class={["badge badge-sm", score_badge_class(stat.score)]}>
                            {stat.score}%
                          </span>
                        </td>
                        <td class="text-center">{stat.total_ips}</td>
                        <td class="text-error text-center">{stat.blocked_ips}</td>
                        <td class="text-center">{stat.threat_events_count}</td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    entries = ThreatReputation.list_country_watchlist()
    country_stats = ThreatReputation.list_country_stats(limit: 20)
    changeset = CountryWatchlistEntry.changeset(%CountryWatchlistEntry{}, %{boost_score: 15})

    {:ok,
     socket
     |> assign(:page_title, gettext("Country Watchlist"))
     |> assign(:entries, entries)
     |> assign(:country_stats, country_stats)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("add_country", %{"country_watchlist_entry" => params}, socket) do
    admin = socket.assigns.current_scope.user
    country_code = String.upcase(params["country_code"] || "")

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

    case ThreatReputation.add_country_to_watchlist(country_code, admin, opts) do
      {:ok, _entry} ->
        entries = ThreatReputation.list_country_watchlist()
        changeset = CountryWatchlistEntry.changeset(%CountryWatchlistEntry{}, %{boost_score: 15})

        {:noreply,
         socket
         |> put_flash(:info, gettext("Country added to watchlist"))
         |> assign(:entries, entries)
         |> assign(:form, to_form(changeset))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to add country"))
         |> assign(:form, to_form(changeset))}
    end
  end

  def handle_event("remove_country", %{"code" => country_code}, socket) do
    case ThreatReputation.remove_country_from_watchlist(country_code) do
      {:ok, _} ->
        entries = ThreatReputation.list_country_watchlist()

        {:noreply,
         socket
         |> put_flash(:info, gettext("Country removed from watchlist"))
         |> assign(:entries, entries)}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, gettext("Country not found in watchlist"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to remove country"))}
    end
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
end
