defmodule HomesiteWeb.AdminLive.Moderation.Bans do
  @moduledoc """
  Admin LiveView for managing user bans.

  Admins can view active bans, create new bans, and lift existing ones (rare).
  """
  use HomesiteWeb, :live_view

  alias Homesite.Accounts
  alias Homesite.Moderation

  @impl true
  def mount(params, _session, socket) do
    bans = Moderation.list_bans(active_only: true)
    prefill_user_id = params["user_id"]

    # If prefilling, load the user
    selected_user =
      if prefill_user_id do
        case Integer.parse(prefill_user_id) do
          {id, ""} -> Accounts.get_user!(id)
          _ -> nil
        end
      else
        nil
      end

    {:ok,
     socket
     |> assign(:page_title, gettext("User Bans"))
     |> assign(:bans, bans)
     |> assign(:show_form, prefill_user_id != nil)
     |> assign(:user_search, "")
     |> assign(:user_suggestions, [])
     |> assign(:selected_user, selected_user)
     |> assign(:form, to_form(%{"reason" => ""}))}
  end

  @impl true
  def handle_event("toggle_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_form, !socket.assigns.show_form)
     |> assign(:user_search, "")
     |> assign(:user_suggestions, [])
     |> assign(:selected_user, nil)}
  end

  @impl true
  def handle_event("search_users", %{"query" => query}, socket) do
    suggestions =
      if String.length(query) >= 2 do
        # Exclude already banned users and current admin
        banned_ids = Enum.map(socket.assigns.bans, & &1.user_id)
        exclude_ids = [socket.assigns.current_scope.user.id | banned_ids]
        Accounts.search_users(query, limit: 8, exclude_ids: exclude_ids)
      else
        []
      end

    {:noreply,
     socket
     |> assign(:user_search, query)
     |> assign(:user_suggestions, suggestions)}
  end

  @impl true
  def handle_event("select_user", %{"id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    {:noreply,
     socket
     |> assign(:selected_user, user)
     |> assign(:user_search, "")
     |> assign(:user_suggestions, [])}
  end

  @impl true
  def handle_event("clear_user", _params, socket) do
    {:noreply, assign(socket, :selected_user, nil)}
  end

  @impl true
  def handle_event("validate", %{"reason" => reason}, socket) do
    {:noreply, assign(socket, :form, to_form(%{"reason" => reason}))}
  end

  @impl true
  def handle_event("ban", %{"reason" => reason}, socket) do
    scope = socket.assigns.current_scope
    selected_user = socket.assigns.selected_user

    if is_nil(selected_user) do
      {:noreply, put_flash(socket, :error, gettext("Please select a user to ban"))}
    else
      case Moderation.ban_user(scope, selected_user.id, reason) do
        {:ok, _ban} ->
          bans = Moderation.list_bans(active_only: true)

          {:noreply,
           socket
           |> assign(:bans, bans)
           |> assign(:show_form, false)
           |> assign(:selected_user, nil)
           |> assign(:form, to_form(%{"reason" => ""}))
           |> put_flash(:info, gettext("User banned successfully"))}

        {:error, %Ecto.Changeset{} = changeset} ->
          errors = format_errors(changeset)
          {:noreply, put_flash(socket, :error, errors)}
      end
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
          <div class="card bg-base-200 mb-[var(--space-md)]">
            <div class="card-body">
              <h3 class="card-title text-error">{gettext("Ban User")}</h3>
              <div class="alert alert-error mb-[var(--space-sm)]">
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
                    <span class="label-text">{gettext("User")}</span>
                  </label>
                  <%= if @selected_user do %>
                    <div class="gap-[var(--space-xs)] border-base-300 bg-base-100 flex items-center rounded-lg border p-3">
                      <.avatar user={@selected_user} class="h-10 w-10" />
                      <div class="flex-1">
                        <div class="font-medium">
                          {@selected_user.display_name || @selected_user.username ||
                            @selected_user.email}
                        </div>
                        <div class="text-[var(--text-sm)] text-base-content/60">
                          {@selected_user.email}
                        </div>
                      </div>
                      <button
                        type="button"
                        phx-click="clear_user"
                        class="btn btn-ghost btn-sm btn-circle"
                      >
                        <.icon name="hero-x-mark" class="h-4 w-4" />
                      </button>
                    </div>
                  <% else %>
                    <div class="relative">
                      <input
                        type="text"
                        value={@user_search}
                        phx-keyup="search_users"
                        phx-value-query={@user_search}
                        phx-debounce="200"
                        class="input input-bordered w-full"
                        placeholder={gettext("Search by email, username, or name...")}
                        autocomplete="off"
                        name="user_search"
                      />
                      <%= if @user_suggestions != [] do %>
                        <ul class="menu bg-base-200 rounded-box absolute z-50 mt-1 max-h-60 w-full overflow-auto shadow-lg">
                          <%= for user <- @user_suggestions do %>
                            <li>
                              <button
                                type="button"
                                phx-click="select_user"
                                phx-value-id={user.id}
                                class="gap-[var(--space-xs)] flex items-center"
                              >
                                <.avatar user={user} class="h-8 w-8" />
                                <div>
                                  <div class="font-medium">
                                    {user.display_name || user.username || user.email}
                                  </div>
                                  <div class="text-[var(--text-xs)] text-base-content/60">
                                    {user.email}
                                  </div>
                                </div>
                              </button>
                            </li>
                          <% end %>
                        </ul>
                      <% end %>
                    </div>
                  <% end %>
                </div>
                <div class="form-control mt-[var(--space-sm)]">
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
                <div class="mt-[var(--space-sm)] gap-[var(--space-xs)] flex">
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
            <h3 class="mt-[var(--space-xs)] text-[var(--text-sm)] font-semibold">
              {gettext("No active bans")}
            </h3>
            <p class="text-base-content/60 mt-[var(--space-inline)] text-[var(--text-sm)]">
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
                      <div class="text-[var(--text-sm)] max-w-xs truncate">
                        {ban.reason}
                      </div>
                    </td>
                    <td class="text-sm">
                      {ban.banned_by.display_name || ban.banned_by.email}
                    </td>
                    <td class="text-base-content/60 text-[var(--text-sm)]">
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
