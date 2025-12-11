defmodule HomesiteWeb.Components.ToastNotification do
  @moduledoc """
  Function component for showing toast notifications.
  Appears top-center (like Phoenix flash) and can be dismissed by clicking.

  The toast data should be passed from the LiveView which handles PubSub messages.
  """
  use HomesiteWeb, :html

  @doc """
  Renders a toast notification.

  ## Attributes

    * `toast` - The notification to display (map with :type, :actor, :data keys). Set to nil to hide.

  ## Examples

      <ToastNotification.toast_notification toast={@toast_notification} />
  """
  attr :toast, :map, default: nil

  def toast_notification(assigns) do
    ~H"""
    <div
      :if={@toast}
      id="toast-notification"
      class="toast toast-top toast-center z-50"
      phx-click={Phoenix.LiveView.JS.push("dismiss_toast")}
    >
      <div class="alert alert-info gap-[var(--space-sm)] cursor-pointer shadow-lg">
        <%= if @toast[:actor] do %>
          <.avatar user={@toast.actor} class="h-8 w-8" />
        <% else %>
          <.icon name="hero-bell" class="h-5 w-5" />
        <% end %>
        <div>
          <p class="text-[var(--text-sm)] font-medium">{toast_message(@toast)}</p>
          <p class="text-[var(--text-xs)] opacity-70">{gettext("Click to dismiss")}</p>
        </div>
      </div>
    </div>
    """
  end

  defp toast_message(%{type: "new_follower", actor: actor}) when not is_nil(actor) do
    name = actor.display_name || String.split(actor.email, "@") |> List.first()
    gettext("%{name} started following you", name: name)
  end

  defp toast_message(%{type: "new_follower"}) do
    gettext("Someone started following you")
  end

  defp toast_message(%{type: "post_published", data: data}) do
    title = Map.get(data, "post_title", gettext("a post"))
    gettext("Your post \"%{title}\" was published", title: title)
  end

  defp toast_message(_notification) do
    gettext("You have a new notification")
  end
end
