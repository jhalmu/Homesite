defmodule HomesiteWeb.AdminLive.Moderation.Suspensions do
  @moduledoc """
  Admin LiveView for managing user suspensions.

  Admins can view active suspensions, create new suspensions, and lift existing ones.
  """
  use HomesiteWeb, :live_view

  alias Homesite.Moderation

  @impl true
  def mount(params, _session, socket) do
    suspensions = Moderation.list_suspensions(active_only: true)
    prefill_user_id = params["user_id"]

    {:ok,
     socket
     |> assign(:page_title, gettext("User Suspensions"))
     |> assign(:suspensions, suspensions)
     |> assign(:show_form, prefill_user_id != nil)
     |> assign(:prefill_user_id, prefill_user_id)
     |> assign(:form, build_form(prefill_user_id))}
  end

  defp build_form(user_id) do
    # Default to 24 hours from now
    default_expires = DateTime.utc_now() |> DateTime.add(86_400, :second) |> DateTime.to_iso8601()

    to_form(%{
      "user_id" => user_id || "",
      "reason" => "",
      "expires_at" => default_expires
    })
  end

  @impl true
  def handle_event("toggle_form", _params, socket) do
    {:noreply, assign(socket, :show_form, !socket.assigns.show_form)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"user_id" => user_id, "reason" => reason, "expires_at" => expires_at},
        socket
      ) do
    {:noreply,
     assign(
       socket,
       :form,
       to_form(%{"user_id" => user_id, "reason" => reason, "expires_at" => expires_at})
     )}
  end

  @impl true
  def handle_event(
        "suspend",
        %{"user_id" => user_id, "reason" => reason, "expires_at" => expires_at},
        socket
      ) do
    scope = socket.assigns.current_scope

    with {user_id, ""} <- Integer.parse(user_id),
         {:ok, expires_at, _} <- DateTime.from_iso8601(expires_at),
         {:ok, _suspension} <- Moderation.suspend_user(scope, user_id, reason, expires_at) do
      suspensions = Moderation.list_suspensions(active_only: true)

      {:noreply,
       socket
       |> assign(:suspensions, suspensions)
       |> assign(:show_form, false)
       |> assign(:form, build_form(nil))
       |> put_flash(:info, gettext("User suspended successfully"))}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        errors = format_errors(changeset)
        {:noreply, put_flash(socket, :error, errors)}

      _ ->
        {:noreply, put_flash(socket, :error, gettext("Invalid input"))}
    end
  end

  @impl true
  def handle_event("unsuspend", %{"user-id" => user_id}, socket) do
    user_id = String.to_integer(user_id)
    scope = socket.assigns.current_scope

    case Moderation.unsuspend_user(scope, user_id) do
      {:ok, _} ->
        suspensions = Moderation.list_suspensions(active_only: true)

        {:noreply,
         socket
         |> assign(:suspensions, suspensions)
         |> put_flash(:info, gettext("User unsuspended successfully"))}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, gettext("Suspension not found"))}
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("User Suspensions")}
        <:subtitle>
          {gettext("Temporarily restrict user access")}
        </:subtitle>
        <:actions>
          <.link navigate={~p"/admin/moderation"} class="btn btn-ghost btn-sm">
            <.icon name="hero-arrow-left" class="h-4 w-4" />
            {gettext("Back")}
          </.link>
          <button phx-click="toggle_form" class="btn btn-warning btn-sm">
            <.icon name="hero-plus" class="h-4 w-4" />
            {gettext("Suspend User")}
          </button>
        </:actions>
      </.header>

      <div class="mt-[var(--space-md)]">
        <%= if @show_form do %>
          <div class="card bg-base-200 mb-[var(--space-md)]">
            <div class="card-body">
              <h3 class="card-title">{gettext("Suspend User")}</h3>
              <.form for={@form} phx-change="validate" phx-submit="suspend" id="suspend-form">
                <div class="grid grid-cols-1 gap-[var(--space-sm)] md:grid-cols-2">
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
                      <span class="label-text">{gettext("Expires At")}</span>
                    </label>
                    <input
                      type="datetime-local"
                      name="expires_at"
                      value={format_datetime_local(@form[:expires_at].value)}
                      class="input input-bordered"
                      required
                    />
                  </div>
                </div>
                <div class="form-control mt-[var(--space-sm)]">
                  <label class="label">
                    <span class="label-text">{gettext("Reason")}</span>
                  </label>
                  <textarea
                    name="reason"
                    class="textarea textarea-bordered h-24"
                    placeholder={gettext("Explain why this user is being suspended...")}
                    required
                    minlength="10"
                  >{@form[:reason].value}</textarea>
                </div>
                <div class="mt-[var(--space-sm)] flex gap-[var(--space-xs)]">
                  <button type="submit" class="btn btn-warning">
                    <.icon name="hero-clock" class="h-4 w-4" />
                    {gettext("Suspend User")}
                  </button>
                  <button type="button" phx-click="toggle_form" class="btn btn-ghost">
                    {gettext("Cancel")}
                  </button>
                </div>
              </.form>
            </div>
          </div>
        <% end %>

        <%= if @suspensions == [] do %>
          <div class="py-[var(--space-xl)] text-center">
            <.icon name="hero-clock" class="text-base-content/40 mx-auto h-12 w-12" />
            <h3 class="mt-2 text-[var(--text-sm)] font-semibold">{gettext("No active suspensions")}</h3>
            <p class="text-base-content/60 mt-[var(--space-inline)] text-[var(--text-sm)]">
              {gettext("There are no users currently suspended.")}
            </p>
          </div>
        <% else %>
          <div class="overflow-x-auto">
            <table class="table" id="suspensions-table">
              <thead>
                <tr>
                  <th>{gettext("User")}</th>
                  <th>{gettext("Reason")}</th>
                  <th>{gettext("Suspended By")}</th>
                  <th>{gettext("Expires")}</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <%= for suspension <- @suspensions do %>
                  <tr id={"suspension-#{suspension.id}"}>
                    <td>
                      <div class="font-medium">
                        {suspension.user.display_name || suspension.user.email}
                      </div>
                      <div class="text-sm opacity-50">{suspension.user.email}</div>
                    </td>
                    <td>
                      <div class="max-w-xs truncate text-[var(--text-sm)]">
                        {suspension.reason}
                      </div>
                    </td>
                    <td class="text-sm">
                      {suspension.suspended_by.display_name || suspension.suspended_by.email}
                    </td>
                    <td>
                      <div class="text-sm">
                        {Calendar.strftime(suspension.expires_at, "%Y-%m-%d %H:%M")}
                      </div>
                      <div class="text-base-content/60 text-[var(--text-xs)]">
                        {time_remaining(suspension.expires_at)}
                      </div>
                    </td>
                    <td>
                      <button
                        phx-click="unsuspend"
                        phx-value-user-id={suspension.user_id}
                        data-confirm={gettext("Are you sure you want to unsuspend this user?")}
                        class="btn btn-sm btn-success"
                      >
                        {gettext("Unsuspend")}
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

  defp format_datetime_local(nil), do: ""

  defp format_datetime_local(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, dt, _} -> Calendar.strftime(dt, "%Y-%m-%dT%H:%M")
      _ -> datetime_string
    end
  end

  defp format_datetime_local(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%dT%H:%M")
  end

  defp time_remaining(expires_at) do
    now = DateTime.utc_now()
    diff = DateTime.diff(expires_at, now, :minute)

    cond do
      diff <= 0 -> gettext("Expired")
      diff < 60 -> gettext("%{count} minutes", count: diff)
      diff < 1440 -> gettext("%{count} hours", count: div(diff, 60))
      true -> gettext("%{count} days", count: div(diff, 1440))
    end
  end
end
