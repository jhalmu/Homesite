defmodule HomesiteWeb.Components.NotificationBell do
  @moduledoc """
  Function component for the notification bell in the header.
  Shows unread notification count.

  The count should be passed from the LiveView which subscribes to notifications.
  """
  use HomesiteWeb, :html

  @doc """
  Renders a notification bell with optional unread count badge.

  ## Attributes

    * `unread_count` - The number of unread notifications (default: 0)

  ## Examples

      <NotificationBell.notification_bell unread_count={@unread_count} />
  """
  attr :unread_count, :integer, default: 0

  def notification_bell(assigns) do
    ~H"""
    <div class="indicator">
      <.link
        navigate={~p"/notifications"}
        class="btn btn-ghost btn-sm btn-circle"
        title={gettext("Notifications")}
      >
        <.icon name="hero-bell" class="h-5 w-5" />
      </.link>
      <%= if @unread_count > 0 do %>
        <span class="badge badge-primary badge-xs indicator-item">
          {if @unread_count > 9, do: "9+", else: @unread_count}
        </span>
      <% end %>
    </div>
    """
  end
end
