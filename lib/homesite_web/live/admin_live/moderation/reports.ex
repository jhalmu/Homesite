defmodule HomesiteWeb.AdminLive.Moderation.Reports do
  @moduledoc """
  Admin LiveView for managing user reports.

  Supports listing reports with filtering and viewing/resolving individual reports.
  """
  use HomesiteWeb, :live_view

  alias Homesite.Moderation

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, gettext("User Reports"))
     |> assign(:status_filter, "pending")
     |> assign(:reports, Moderation.list_reports(status: "pending"))
     |> assign(:selected_report, nil)
     |> assign(:resolution_form, nil)}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    report = Moderation.get_report!(id)

    {:noreply,
     socket
     |> assign(:page_title, gettext("Report #%{id}", id: id))
     |> assign(:selected_report, report)
     |> assign(:resolution_form, to_form(%{"notes" => ""}))}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply,
     socket
     |> assign(:selected_report, nil)
     |> assign(:resolution_form, nil)}
  end

  @impl true
  def handle_event("filter", %{"status" => status}, socket) do
    status = if status == "all", do: nil, else: status
    reports = Moderation.list_reports(status: status)

    {:noreply,
     socket
     |> assign(:status_filter, status || "all")
     |> assign(:reports, reports)}
  end

  @impl true
  def handle_event("resolve", %{"notes" => notes}, socket) do
    report = socket.assigns.selected_report
    scope = socket.assigns.current_scope

    case Moderation.resolve_report(scope, report.id, notes) do
      {:ok, _updated_report} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Report resolved successfully"))
         |> push_navigate(to: ~p"/admin/moderation/reports")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to resolve report"))}
    end
  end

  @impl true
  def handle_event("dismiss", %{"notes" => notes}, socket) do
    report = socket.assigns.selected_report
    scope = socket.assigns.current_scope

    case Moderation.dismiss_report(scope, report.id, notes) do
      {:ok, _updated_report} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Report dismissed"))
         |> push_navigate(to: ~p"/admin/moderation/reports")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to dismiss report"))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <%= if @selected_report do %>
        <.render_report_detail report={@selected_report} resolution_form={@resolution_form} />
      <% else %>
        <.render_reports_list reports={@reports} status_filter={@status_filter} />
      <% end %>
    </Layouts.app>
    """
  end

  defp render_reports_list(assigns) do
    ~H"""
    <.header>
      {gettext("User Reports")}
      <:subtitle>
        {gettext("Review and manage user reports")}
      </:subtitle>
      <:actions>
        <.link navigate={~p"/admin/moderation"} class="btn btn-ghost btn-sm">
          <.icon name="hero-arrow-left" class="h-4 w-4" />
          {gettext("Back to Dashboard")}
        </.link>
      </:actions>
    </.header>

    <div class="mt-6">
      <div class="mb-4 flex gap-2">
        <button
          phx-click="filter"
          phx-value-status="pending"
          class={["btn btn-sm", @status_filter == "pending" && "btn-primary"]}
        >
          {gettext("Pending")}
        </button>
        <button
          phx-click="filter"
          phx-value-status="resolved"
          class={["btn btn-sm", @status_filter == "resolved" && "btn-primary"]}
        >
          {gettext("Resolved")}
        </button>
        <button
          phx-click="filter"
          phx-value-status="dismissed"
          class={["btn btn-sm", @status_filter == "dismissed" && "btn-primary"]}
        >
          {gettext("Dismissed")}
        </button>
        <button
          phx-click="filter"
          phx-value-status="all"
          class={["btn btn-sm", @status_filter == "all" && "btn-primary"]}
        >
          {gettext("All")}
        </button>
      </div>

      <%= if @reports == [] do %>
        <div class="py-12 text-center">
          <.icon name="hero-flag" class="text-base-content/40 mx-auto h-12 w-12" />
          <h3 class="mt-2 text-sm font-semibold">{gettext("No reports")}</h3>
          <p class="text-base-content/60 mt-1 text-sm">
            {gettext("No reports match the current filter.")}
          </p>
        </div>
      <% else %>
        <div class="overflow-x-auto">
          <table class="table" id="reports-table">
            <thead>
              <tr>
                <th>{gettext("Reported User")}</th>
                <th>{gettext("Reporter")}</th>
                <th>{gettext("Reason")}</th>
                <th>{gettext("Status")}</th>
                <th>{gettext("Created")}</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <%= for report <- @reports do %>
                <tr id={"report-#{report.id}"}>
                  <td>
                    <div class="font-medium">
                      {report.reported_user.display_name || report.reported_user.email}
                    </div>
                  </td>
                  <td>
                    <div class="text-sm">
                      {report.reporter.display_name || report.reporter.email}
                    </div>
                  </td>
                  <td>
                    <div class="text-base-content/70 max-w-xs truncate text-sm">
                      {report.reason}
                    </div>
                  </td>
                  <td>
                    <span class={["badge badge-sm", status_badge_class(report.status)]}>
                      {report.status}
                    </span>
                  </td>
                  <td class="text-base-content/60 text-sm">
                    {Calendar.strftime(report.inserted_at, "%Y-%m-%d %H:%M")}
                  </td>
                  <td>
                    <.link
                      navigate={~p"/admin/moderation/reports/#{report.id}"}
                      class="btn btn-sm btn-ghost"
                    >
                      {gettext("View")}
                    </.link>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_report_detail(assigns) do
    ~H"""
    <.header>
      {gettext("Report #%{id}", id: @report.id)}
      <:subtitle>
        {gettext("Submitted %{date}", date: Calendar.strftime(@report.inserted_at, "%Y-%m-%d %H:%M"))}
      </:subtitle>
      <:actions>
        <.link navigate={~p"/admin/moderation/reports"} class="btn btn-ghost btn-sm">
          <.icon name="hero-arrow-left" class="h-4 w-4" />
          {gettext("Back to Reports")}
        </.link>
      </:actions>
    </.header>

    <div class="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-2">
      <div class="space-y-4">
        <div class="card bg-base-200">
          <div class="card-body">
            <h3 class="card-title text-sm">{gettext("Reported User")}</h3>
            <div class="flex items-center gap-3">
              <div class="avatar placeholder">
                <div class="bg-error text-error-content w-12 rounded-full">
                  <span>{String.first(@report.reported_user.email) |> String.upcase()}</span>
                </div>
              </div>
              <div>
                <div class="font-bold">
                  {@report.reported_user.display_name || @report.reported_user.email}
                </div>
                <div class="text-sm opacity-50">{@report.reported_user.email}</div>
              </div>
            </div>
            <div class="mt-4 flex gap-2">
              <.link
                navigate={~p"/admin/moderation/suspensions?user_id=#{@report.reported_user_id}"}
                class="btn btn-warning btn-sm"
              >
                <.icon name="hero-clock" class="h-4 w-4" />
                {gettext("Suspend")}
              </.link>
              <.link
                navigate={~p"/admin/moderation/bans?user_id=#{@report.reported_user_id}"}
                class="btn btn-error btn-sm"
              >
                <.icon name="hero-no-symbol" class="h-4 w-4" />
                {gettext("Ban")}
              </.link>
              <.link
                navigate={~p"/admin/moderation/banners?user_id=#{@report.reported_user_id}"}
                class="btn btn-sm"
              >
                <.icon name="hero-megaphone" class="h-4 w-4" />
                {gettext("Warn")}
              </.link>
            </div>
          </div>
        </div>

        <div class="card bg-base-200">
          <div class="card-body">
            <h3 class="card-title text-sm">{gettext("Reporter")}</h3>
            <div class="flex items-center gap-3">
              <div class="avatar placeholder">
                <div class="bg-neutral text-neutral-content w-12 rounded-full">
                  <span>{String.first(@report.reporter.email) |> String.upcase()}</span>
                </div>
              </div>
              <div>
                <div class="font-bold">
                  {@report.reporter.display_name || @report.reporter.email}
                </div>
                <div class="text-sm opacity-50">{@report.reporter.email}</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="space-y-4">
        <div class="card bg-base-200">
          <div class="card-body">
            <h3 class="card-title text-sm">{gettext("Report Details")}</h3>
            <div class="mb-2">
              <span class={["badge", status_badge_class(@report.status)]}>
                {@report.status}
              </span>
            </div>
            <p class="whitespace-pre-wrap">{@report.reason}</p>
          </div>
        </div>

        <%= if @report.status == "pending" do %>
          <div class="card bg-base-200">
            <div class="card-body">
              <h3 class="card-title text-sm">{gettext("Resolution")}</h3>
              <.form for={@resolution_form} phx-submit="resolve" id="resolve-form">
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">{gettext("Resolution Notes")}</span>
                  </label>
                  <textarea
                    name="notes"
                    class="textarea textarea-bordered h-24"
                    placeholder={gettext("Describe what action was taken...")}
                  >{@resolution_form[:notes].value}</textarea>
                </div>
                <div class="mt-4 flex gap-2">
                  <button type="submit" class="btn btn-success btn-sm">
                    <.icon name="hero-check" class="h-4 w-4" />
                    {gettext("Resolve")}
                  </button>
                  <button
                    type="button"
                    phx-click="dismiss"
                    phx-value-notes={@resolution_form[:notes].value}
                    class="btn btn-ghost btn-sm"
                  >
                    <.icon name="hero-x-mark" class="h-4 w-4" />
                    {gettext("Dismiss")}
                  </button>
                </div>
              </.form>
            </div>
          </div>
        <% else %>
          <%= if @report.resolution_notes do %>
            <div class="card bg-base-200">
              <div class="card-body">
                <h3 class="card-title text-sm">{gettext("Resolution")}</h3>
                <p class="text-base-content/60 text-sm">
                  {gettext("Resolved by %{user} on %{date}",
                    user:
                      @report.resolved_by &&
                        (@report.resolved_by.display_name || @report.resolved_by.email),
                    date:
                      @report.resolved_at && Calendar.strftime(@report.resolved_at, "%Y-%m-%d %H:%M")
                  )}
                </p>
                <p class="whitespace-pre-wrap">{@report.resolution_notes}</p>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  defp status_badge_class(status) do
    case status do
      "pending" -> "badge-warning"
      "reviewing" -> "badge-info"
      "resolved" -> "badge-success"
      "dismissed" -> "badge-ghost"
      _ -> "badge-ghost"
    end
  end
end
