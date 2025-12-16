defmodule HomesiteWeb.AdminLive.Moderation.Bans do
  @moduledoc """
  Admin LiveView for managing user bans.

  Admins can view active bans, create new bans, and lift existing ones (rare).
  """
  use HomesiteWeb, :live_view

  alias Homesite.Moderation

  @impl true
  def mount(params, _session, socket) do
    bans = Moderation.list_bans(active_only: true)
    prefill_user_id = params["user_id"]

    {:ok,
     socket
     |> assign(:page_title, gettext("User Bans"))
     |> assign(:bans, bans)
     |> assign(:show_form, prefill_user_id != nil)
     |> assign(:prefill_user_id, prefill_user_id)
     |> assign(:form, to_form(%{"user_id" => prefill_user_id || "", "reason" => ""}))}
  end

  @impl true
  def handle_event("toggle_form", _params, socket) do
    {:noreply, assign(socket, :show_form, !socket.assigns.show_form)}
  end

  @impl true
  def handle_event("validate", %{"user_id" => user_id, "reason" => reason}, socket) do
    {:noreply, assign(socket, :form, to_form(%{"user_id" => user_id, "reason" => reason}))}
  end

  @impl true
  def handle_event("ban", %{"user_id" => user_id, "reason" => reason}, socket) do
    scope = socket.assigns.current_scope

    with {user_id, ""} <- Integer.parse(user_id),
         {:ok, _ban} <- Moderation.ban_user(scope, user_id, reason) do
      bans = Moderation.list_bans(active_only: true)

      {:noreply,
       socket
       |> assign(:bans, bans)
       |> assign(:show_form, false)
       |> assign(:form, to_form(%{"user_id" => "", "reason" => ""}))
       |> put_flash(:info, gettext("User banned successfully"))}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        errors = format_errors(changeset)
        {:noreply, put_flash(socket, :error, errors)}

      _ ->
        {:noreply, put_flash(socket, :error, gettext("Invalid input"))}
    end
  end

  @impl true
  def handle_event("unban", %{"user-id" => user_id}, socket) do
    user_id = String.to_integer(user_id)
    scope = socket.assigns.current_scope

    case Moderation.unban_user(scope, user_id) do
      {:ok, _} ->
        bans = Moderation.list_bans(active_only: true)

        {:noreply,
         socket
         |> assign(:bans, bans)
         |> put_flash(:info, gettext("User unbanned successfully"))}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, gettext("Ban not found"))}
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
        {gettext("User Bans")}
        <:subtitle>
          {gettext("Permanently restrict user access")}
        </:subtitle>
        <:actions>
          <.link navigate={~p"/admin/moderation"} class="btn btn-ghost btn-sm">
            <.icon name="hero-arrow-left" class="h-4 w-4" />
            {gettext("Back")}
          </.link>
          <button phx-click="toggle_form" class="btn btn-error btn-sm">
            <.icon name="hero-plus" class="h-4 w-4" />
            {gettext("Ban User")}
          </button>
        </:actions>
      </.header>

      <div class="mt-[var(--space-md)]">
        <%= if @show_form do %>
          <div class="card bg-base-200 mb-6">
            <div class="card-body">
              <h3 class="card-title text-error">{gettext("Ban User")}</h3>
              <div class="alert alert-error mb-4">
                <.icon name="hero-exclamation-triangle" class="h-5 w-5" />
                <span>
                  {gettext(
                    "Bans are permanent and should only be used for serious violations. Consider suspension for temporary issues."
                  )}
                </span>
              </div>
              <.form for={@form} phx-change="validate" phx-submit="ban" id="ban-form">
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
                <div class="form-control mt-4">
                  <label class="label">
                    <span class="label-text">{gettext("Reason")}</span>
                  </label>
                  <textarea
                    name="reason"
                    class="textarea textarea-bordered h-24"
                    placeholder={
                      gettext("Document the serious violation that warrants a permanent ban...")
                    }
                    required
                    minlength="10"
                  >{@form[:reason].value}</textarea>
                </div>
                <div class="mt-4 flex gap-2">
                  <button
                    type="submit"
                    class="btn btn-error"
                    data-confirm={
                      gettext("Are you absolutely sure? This action permanently bans the user.")
                    }
                  >
                    <.icon name="hero-no-symbol" class="h-4 w-4" />
                    {gettext("Ban User Permanently")}
                  </button>
                  <button type="button" phx-click="toggle_form" class="btn btn-ghost">
                    {gettext("Cancel")}
                  </button>
                </div>
              </.form>
            </div>
          </div>
        <% end %>

        <%= if @bans == [] do %>
          <div class="py-[var(--space-xl)] text-center">
            <.icon name="hero-no-symbol" class="text-base-content/40 mx-auto h-12 w-12" />
            <h3 class="mt-2 text-sm font-semibold">{gettext("No active bans")}</h3>
            <p class="text-base-content/60 mt-1 text-sm">
              {gettext("There are no users currently banned.")}
            </p>
          </div>
        <% else %>
          <div class="overflow-x-auto">
            <table class="table" id="bans-table">
              <thead>
                <tr>
                  <th>{gettext("User")}</th>
                  <th>{gettext("Reason")}</th>
                  <th>{gettext("Banned By")}</th>
                  <th>{gettext("Banned On")}</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <%= for ban <- @bans do %>
                  <tr id={"ban-#{ban.id}"}>
                    <td>
                      <div class="font-medium">
                        {ban.user.display_name || ban.user.email}
                      </div>
                      <div class="text-sm opacity-50">{ban.user.email}</div>
                    </td>
                    <td>
                      <div class="max-w-xs truncate text-sm">
                        {ban.reason}
                      </div>
                    </td>
                    <td class="text-sm">
                      {ban.banned_by.display_name || ban.banned_by.email}
                    </td>
                    <td class="text-base-content/60 text-sm">
                      {Calendar.strftime(ban.inserted_at, "%Y-%m-%d %H:%M")}
                    </td>
                    <td>
                      <button
                        phx-click="unban"
                        phx-value-user-id={ban.user_id}
                        data-confirm={
                          gettext(
                            "Are you sure you want to unban this user? This is rare and should only be done if the ban was issued in error."
                          )
                        }
                        class="btn btn-sm btn-warning"
                      >
                        {gettext("Unban")}
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
end
