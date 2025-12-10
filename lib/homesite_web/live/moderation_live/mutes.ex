defmodule HomesiteWeb.ModerationLive.Mutes do
  @moduledoc """
  LiveView for managing muted users.

  Users can view their muted users list and unmute users.
  """
  use HomesiteWeb, :live_view

  alias Homesite.Moderation

  @impl true
  def mount(_params, _session, socket) do
    muted_users = Moderation.list_muted_users(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, gettext("Muted Users"))
     |> assign(:muted_users, muted_users)}
  end

  @impl true
  def handle_event("unmute", %{"id" => id}, socket) do
    muted_user_id = String.to_integer(id)

    case Moderation.unmute_user(socket.assigns.current_scope, muted_user_id) do
      {:ok, _} ->
        muted_users = Moderation.list_muted_users(socket.assigns.current_scope)

        {:noreply,
         socket
         |> assign(:muted_users, muted_users)
         |> put_flash(:info, gettext("User unmuted successfully"))}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, gettext("User not found"))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Muted Users")}
        <:subtitle>
          {gettext("Users you've muted won't appear in your feed or chat")}
        </:subtitle>
      </.header>

      <div class="mt-6">
        <%= if @muted_users == [] do %>
          <div class="py-12 text-center">
            <.icon name="hero-speaker-x-mark" class="text-base-content/40 mx-auto h-12 w-12" />
            <h3 class="mt-2 text-sm font-semibold">{gettext("No muted users")}</h3>
            <p class="text-base-content/60 mt-1 text-sm">
              {gettext("You haven't muted anyone yet.")}
            </p>
          </div>
        <% else %>
          <div class="overflow-x-auto">
            <table class="table" id="muted-users-table">
              <thead>
                <tr>
                  <th>{gettext("User")}</th>
                  <th>{gettext("Muted On")}</th>
                  <th>{gettext("Reason")}</th>
                  <th class="text-right">{gettext("Actions")}</th>
                </tr>
              </thead>
              <tbody>
                <%= for mute <- @muted_users do %>
                  <tr id={"mute-#{mute.id}"}>
                    <td>
                      <div class="flex items-center gap-3">
                        <div class="avatar placeholder">
                          <div class="bg-neutral text-neutral-content w-10 rounded-full">
                            <span class="text-sm">
                              {String.first(mute.muted_user.email) |> String.upcase()}
                            </span>
                          </div>
                        </div>
                        <div>
                          <div class="font-bold">
                            {mute.muted_user.display_name || mute.muted_user.email}
                          </div>
                          <%= if mute.muted_user.display_name do %>
                            <div class="text-sm opacity-50">{mute.muted_user.email}</div>
                          <% end %>
                        </div>
                      </div>
                    </td>
                    <td>
                      <time datetime={DateTime.to_iso8601(mute.inserted_at)}>
                        {Calendar.strftime(mute.inserted_at, "%Y-%m-%d %H:%M")}
                      </time>
                    </td>
                    <td>
                      <span class="text-base-content/60 text-sm">
                        {mute.reason || gettext("No reason provided")}
                      </span>
                    </td>
                    <td class="text-right">
                      <button
                        phx-click="unmute"
                        phx-value-id={mute.muted_user_id}
                        data-confirm={gettext("Are you sure you want to unmute this user?")}
                        class="btn btn-sm btn-ghost"
                      >
                        <.icon name="hero-speaker-wave" class="h-4 w-4" />
                        {gettext("Unmute")}
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
