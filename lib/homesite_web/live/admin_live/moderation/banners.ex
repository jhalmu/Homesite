defmodule HomesiteWeb.AdminLive.Moderation.Banners do
  @moduledoc """
  Admin LiveView for managing warning banners.

  Admins can send warning messages to users that appear on their dashboard.
  """
  use HomesiteWeb, :admin_live_view

  alias Homesite.Moderation

  @impl true
  def mount(params, _session, socket) do
    banners = Moderation.list_banners()
    prefill_user_id = params["user_id"]

    {:ok,
     socket
     |> assign(:page_title, gettext("Warning Banners"))
     |> assign(:banners, banners)
     |> assign(:show_form, prefill_user_id != nil)
     |> assign(:form, build_form(prefill_user_id))}
  end

  defp build_form(user_id) do
    to_form(%{
      "user_id" => user_id || "",
      "message" => "",
      "severity" => "warning",
      "auto_dismiss_hours" => ""
    })
  end

  @impl true
  def handle_event("toggle_form", _params, socket) do
    {:noreply, assign(socket, :show_form, !socket.assigns.show_form)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    {:noreply, assign(socket, :form, to_form(params))}
  end

  @impl true
  def handle_event("create_banner", params, socket) do
    scope = socket.assigns.current_scope

    with {user_id, ""} <- Integer.parse(params["user_id"]),
         {:ok, _banner} <- create_banner(scope, user_id, params) do
      banners = Moderation.list_banners()

      {:noreply,
       socket
       |> assign(:banners, banners)
       |> assign(:show_form, false)
       |> assign(:form, build_form(nil))
       |> put_flash(:info, gettext("Warning banner sent successfully"))}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        errors = format_errors(changeset)
        {:noreply, put_flash(socket, :error, errors)}

      _ ->
        {:noreply, put_flash(socket, :error, gettext("Invalid input"))}
    end
  end

  @impl true
  def handle_event("delete_banner", %{"id" => id}, socket) do
    scope = socket.assigns.current_scope
    banner_id = String.to_integer(id)

    case Moderation.delete_banner(scope, banner_id) do
      {:ok, _} ->
        banners = Moderation.list_banners()

        {:noreply,
         socket
         |> assign(:banners, banners)
         |> put_flash(:info, gettext("Banner deleted"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to delete banner"))}
    end
  end

  defp create_banner(scope, user_id, params) do
    message = params["message"]
    severity = params["severity"]

    # Build keyword list opts
    opts = [severity: severity]

    # Add auto-dismiss if specified
    opts =
      case params["auto_dismiss_hours"] do
        "" ->
          opts

        nil ->
          opts

        hours_str ->
          case Integer.parse(hours_str) do
            {hours, ""} when hours > 0 ->
              expires_at = DateTime.utc_now() |> DateTime.add(hours * 3600, :second)
              Keyword.put(opts, :auto_dismiss_after, expires_at)

            _ ->
              opts
          end
      end

    Moderation.create_banner(scope, user_id, message, opts)
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map_join("; ", fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Warning Banners")}
        <:subtitle>
          {gettext("Send warning messages to users")}
        </:subtitle>
        <:actions>
          <.link navigate={~p"/admin/moderation"} class="btn btn-ghost btn-sm">
            <.icon name="hero-arrow-left" class="h-4 w-4" />
            {gettext("Back")}
          </.link>
          <button phx-click="toggle_form" class="btn btn-warning btn-sm">
            <.icon name="hero-plus" class="h-4 w-4" />
            {gettext("Send Warning")}
          </button>
        </:actions>
      </.header>

      <div class="mt-[var(--space-md)]">
        <%= if @show_form do %>
          <div class="card bg-base-200 mb-[var(--space-md)]">
            <div class="card-body">
              <h3 class="card-title">{gettext("Send Warning Banner")}</h3>
              <.form for={@form} phx-change="validate" phx-submit="create_banner" id="banner-form">
                <div class="gap-[var(--space-sm)] grid grid-cols-1 md:grid-cols-2">
                  <div class="form-control">
                    <label class="label">
                      <span class="label-text">{gettext("User ID")}</span>
                    </label>
                    <input
                      type="number"
                      name="user_id"
                      value={@form[:user_id].value}
                      class="input input-bordered"
                      placeholder={gettext("Enter user ID")}
                      required
                    />
                  </div>
                  <div class="form-control">
                    <label class="label">
                      <span class="label-text">{gettext("Severity")}</span>
                    </label>
                    <select name="severity" class="select select-bordered">
                      <option value="info" selected={@form[:severity].value == "info"}>
                        {gettext("Info")}
                      </option>
                      <option value="warning" selected={@form[:severity].value == "warning"}>
                        {gettext("Warning")}
                      </option>
                      <option value="error" selected={@form[:severity].value == "error"}>
                        {gettext("Error / Critical")}
                      </option>
                    </select>
                  </div>
                </div>
                <div class="form-control mt-[var(--space-sm)]">
                  <label class="label">
                    <span class="label-text">{gettext("Message")}</span>
                  </label>
                  <textarea
                    name="message"
                    class="textarea textarea-bordered h-24"
                    placeholder={gettext("Write a clear warning message for the user...")}
                    required
                    minlength="10"
                    maxlength="1000"
                  >{@form[:message].value}</textarea>
                </div>
                <div class="form-control mt-[var(--space-sm)]">
                  <label class="label">
                    <span class="label-text">{gettext("Auto-dismiss after (hours)")}</span>
                    <span class="label-text-alt">
                      {gettext("Leave empty for manual dismiss only")}
                    </span>
                  </label>
                  <input
                    type="number"
                    name="auto_dismiss_hours"
                    value={@form[:auto_dismiss_hours].value}
                    class="input input-bordered w-32"
                    min="1"
                    max="720"
                  />
                </div>
                <div class="mt-[var(--space-sm)] gap-[var(--space-xs)] flex">
                  <button type="submit" class="btn btn-warning">
                    <.icon name="hero-megaphone" class="h-4 w-4" />
                    {gettext("Send Warning")}
                  </button>
                  <button type="button" phx-click="toggle_form" class="btn btn-ghost">
                    {gettext("Cancel")}
                  </button>
                </div>
              </.form>
            </div>
          </div>
        <% end %>

        <%= if @banners == [] do %>
          <div class="py-[var(--space-xl)] text-center">
            <.icon name="hero-megaphone" class="text-base-content/40 mx-auto h-12 w-12" />
            <h3 class="mt-[var(--space-xs)] text-[var(--text-sm)] font-semibold">
              {gettext("No warning banners")}
            </h3>
            <p class="text-base-content/60 mt-[var(--space-inline)] text-[var(--text-sm)]">
              {gettext("No warning banners have been sent yet.")}
            </p>
          </div>
        <% else %>
          <div class="overflow-x-auto">
            <table class="table" id="banners-table">
              <thead>
                <tr>
                  <th>{gettext("User")}</th>
                  <th>{gettext("Message")}</th>
                  <th>{gettext("Severity")}</th>
                  <th>{gettext("Status")}</th>
                  <th>{gettext("Created")}</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <%= for banner <- @banners do %>
                  <tr id={"banner-#{banner.id}"}>
                    <td>
                      <div class="font-medium">
                        {banner.user.display_name || banner.user.email}
                      </div>
                    </td>
                    <td>
                      <div class="text-[var(--text-sm)] max-w-xs truncate">
                        {banner.message}
                      </div>
                    </td>
                    <td>
                      <span class={["badge badge-sm", severity_badge_class(banner.severity)]}>
                        {banner.severity}
                      </span>
                    </td>
                    <td>
                      <%= if banner.dismissed_at do %>
                        <span class="badge badge-sm badge-ghost">{gettext("Dismissed")}</span>
                      <% else %>
                        <%= if banner.auto_dismiss_after && DateTime.compare(banner.auto_dismiss_after, DateTime.utc_now()) == :lt do %>
                          <span class="badge badge-sm badge-ghost">{gettext("Expired")}</span>
                        <% else %>
                          <span class="badge badge-sm badge-success">{gettext("Active")}</span>
                        <% end %>
                      <% end %>
                    </td>
                    <td class="text-base-content/60 text-[var(--text-sm)]">
                      {Calendar.strftime(banner.inserted_at, "%Y-%m-%d %H:%M")}
                    </td>
                    <td>
                      <button
                        phx-click="delete_banner"
                        phx-value-id={banner.id}
                        data-confirm={gettext("Are you sure you want to delete this banner?")}
                        class="btn btn-sm btn-ghost text-error"
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
    </Layouts.app>
    """
  end

  defp severity_badge_class(severity) do
    case severity do
      "info" -> "badge-info"
      "warning" -> "badge-warning"
      "error" -> "badge-error"
      _ -> "badge-ghost"
    end
  end
end
