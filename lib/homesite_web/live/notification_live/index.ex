defmodule HomesiteWeb.NotificationLive.Index do
  @moduledoc """
  Notification Center LiveView.
  Displays all notifications with real-time updates via PubSub.
  """
  use HomesiteWeb, :live_view

  import HomesiteWeb.Helpers.DateHelpers

  alias Homesite.Accounts
  alias Homesite.Follows
  alias Homesite.Notifications

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="w-[min(95vw,600px)] my-[var(--space-lg)] mx-auto">
        <div class="mb-[var(--space-md)] flex items-center justify-between">
          <h1 class="text-[var(--font-size-fluid-xl)] font-bold">
            {gettext("Notifications")}
          </h1>

          <div class="gap-[var(--space-xs)] flex items-center">
            <%= if @unread_count > 0 do %>
              <button
                type="button"
                phx-click="mark_all_read"
                class="btn btn-ghost btn-sm"
              >
                <.icon name="hero-check-circle" class="h-4 w-4" />
                {gettext("Mark all read")}
              </button>
            <% end %>

            <.link
              navigate={~p"/notifications/settings"}
              class="btn btn-ghost btn-sm"
            >
              <.icon name="hero-cog-6-tooth" class="h-4 w-4" />
              {gettext("Settings")}
            </.link>
          </div>
        </div>

        <%!-- Unread count badge --%>
        <%= if @unread_count > 0 do %>
          <div class="alert alert-info mb-[var(--space-md)]">
            <.icon name="hero-bell" class="h-5 w-5" />
            <span>
              {ngettext(
                "You have %{count} unread notification",
                "You have %{count} unread notifications",
                @unread_count,
                count: @unread_count
              )}
            </span>
          </div>
        <% end %>

        <%!-- Notifications list --%>
        <div class="divide-base-300 divide-y">
          <%= if @notifications == [] do %>
            <div class="py-[var(--space-xl)] text-center">
              <.icon
                name="hero-bell-slash"
                class="text-base-content/30 mb-[var(--space-sm)] mx-auto h-12 w-12"
              />
              <p class="text-base-content/60">{gettext("No notifications yet")}</p>
              <p class="text-base-content/40 mt-[var(--space-xs)] text-[var(--text-sm)]">
                {gettext(
                  "When someone follows you or interacts with your content, you'll see it here."
                )}
              </p>
            </div>
          <% else %>
            <div
              :for={notification <- @notifications}
              class={[
                "gap-[var(--space-sm)] py-[var(--space-sm)] flex items-start",
                is_nil(notification.read_at) && "bg-primary/5"
              ]}
            >
              <%!-- Actor avatar or icon --%>
              <div class="shrink-0">
                <%= if notification.actor do %>
                  <.link navigate={
                    if notification.actor.username,
                      do: ~p"/users/@#{notification.actor.username}",
                      else: ~p"/users/#{notification.actor.id}"
                  }>
                    <.avatar user={notification.actor} class="h-10 w-10" />
                  </.link>
                <% else %>
                  <div class="bg-base-300 flex h-10 w-10 items-center justify-center rounded-full">
                    <.icon name={notification_icon(notification.type)} class="h-5 w-5" />
                  </div>
                <% end %>
              </div>

              <%!-- Notification content --%>
              <div class="min-w-0 flex-1">
                <p class="text-[var(--text-sm)]">
                  {notification_message(notification)}
                </p>
                <p class="text-base-content/50 mt-[var(--space-inline)] text-[var(--text-xs)]">
                  {format_relative_time(notification.inserted_at)}
                </p>

                <%!-- Action buttons for specific notification types --%>
                <%= if notification.type == "new_follower" && notification.actor do %>
                  <div class="mt-[var(--space-xs)]">
                    <%= if following_back?(notification.actor.id, @following_ids) do %>
                      <span class="text-base-content/60 text-[var(--text-xs)]">
                        <.icon name="hero-check" class="mr-[var(--space-inline)] inline h-3 w-3" />
                        {gettext("Following")}
                      </span>
                    <% else %>
                      <button
                        type="button"
                        phx-click="follow_back"
                        phx-value-user-id={notification.actor.id}
                        class="btn btn-primary btn-xs"
                      >
                        {gettext("Follow back")}
                      </button>
                    <% end %>
                  </div>
                <% end %>
              </div>

              <%!-- Actions --%>
              <div class="shrink-0">
                <%= if is_nil(notification.read_at) do %>
                  <button
                    type="button"
                    phx-click="mark_read"
                    phx-value-id={notification.id}
                    class="btn btn-ghost btn-xs"
                    title={gettext("Mark as read")}
                  >
                    <.icon name="hero-check" class="h-4 w-4" />
                  </button>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    current_scope = socket.assigns.current_scope

    # Subscribe to notification updates
    if connected?(socket) do
      Notifications.subscribe(current_scope)
    end

    # Load notifications
    notifications = Notifications.list_notifications(current_scope)
    unread_count = Notifications.unread_count(current_scope)

    # Get list of user IDs the current user is following (for "follow back" buttons)
    following_ids =
      Follows.list_following(current_scope)
      |> Enum.map(& &1.user.id)
      |> MapSet.new()

    {:ok,
     socket
     |> assign(:page_title, gettext("Notifications"))
     |> assign(:notifications, notifications)
     |> assign(:unread_count, unread_count)
     |> assign(:following_ids, following_ids)}
  end

  @impl true
  def handle_event("mark_read", %{"id" => id}, socket) do
    current_scope = socket.assigns.current_scope
    notification_id = String.to_integer(id)

    case Notifications.mark_as_read(current_scope, notification_id) do
      {:ok, updated_notification} ->
        notifications =
          replace_notification(socket.assigns.notifications, notification_id, updated_notification)

        unread_count = max(0, socket.assigns.unread_count - 1)

        {:noreply,
         socket
         |> assign(:notifications, notifications)
         |> assign(:unread_count, unread_count)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Could not mark notification as read"))}
    end
  end

  @impl true
  def handle_event("mark_all_read", _params, socket) do
    current_scope = socket.assigns.current_scope

    count = Notifications.mark_all_as_read(current_scope)

    # Reload notifications to reflect read status
    notifications = Notifications.list_notifications(current_scope)

    {:noreply,
     socket
     |> assign(:notifications, notifications)
     |> assign(:unread_count, 0)
     |> put_flash(
       :info,
       ngettext(
         "Marked %{count} notification as read",
         "Marked %{count} notifications as read",
         count,
         count: count
       )
     )}
  end

  @impl true
  def handle_event("follow_back", %{"user-id" => user_id}, socket) do
    current_scope = socket.assigns.current_scope
    user_id = String.to_integer(user_id)

    case Follows.follow_user(current_scope, user_id) do
      {:ok, _follower} ->
        notify_follow_back(user_id, current_scope)
        following_ids = MapSet.put(socket.assigns.following_ids, user_id)

        {:noreply,
         socket
         |> assign(:following_ids, following_ids)
         |> put_flash(:info, gettext("Followed back!"))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Could not follow user"))}
    end
  end

  defp notify_follow_back(user_id, current_scope) do
    user = Accounts.get_user!(user_id)

    if Accounts.notification_enabled?(user, "new_follower") do
      Notifications.notify_new_follower(user_id, current_scope.user)
    end
  end

  @impl true
  def handle_info({:new_notification, notification}, socket) do
    # Add new notification to the top of the list
    notifications = [notification | socket.assigns.notifications]
    unread_count = socket.assigns.unread_count + 1

    {:noreply,
     socket
     |> assign(:notifications, notifications)
     |> assign(:unread_count, unread_count)}
  end

  defp notification_icon("new_follower"), do: "hero-user-plus"
  defp notification_icon("post_published"), do: "hero-document-text"
  defp notification_icon("suspicious_activity"), do: "hero-exclamation-triangle"
  defp notification_icon("new_user_registered"), do: "hero-user-plus"
  defp notification_icon("report_submitted"), do: "hero-flag"
  defp notification_icon("follower_post"), do: "hero-pencil-square"
  defp notification_icon("system_alert"), do: "hero-exclamation-circle"
  defp notification_icon(_), do: "hero-bell"

  defp notification_message(%{type: "new_follower", actor: actor}) when not is_nil(actor) do
    name = actor.display_name || String.split(actor.email, "@") |> List.first()
    gettext("%{name} started following you", name: name)
  end

  defp notification_message(%{type: "new_follower"}) do
    gettext("Someone started following you")
  end

  defp notification_message(%{type: "post_published", data: data}) do
    title = Map.get(data, "post_title", gettext("a post"))
    gettext("Your post \"%{title}\" was published", title: title)
  end

  defp notification_message(%{type: "suspicious_activity", data: data}) do
    email = Map.get(data, "email", "unknown")
    reason = Map.get(data, "reason", "unknown")
    gettext("Suspicious activity detected: %{reason} from %{email}", reason: reason, email: email)
  end

  defp notification_message(%{type: "new_user_registered", data: data}) do
    email = Map.get(data, "user_email", "unknown")
    gettext("New user registered: %{email}", email: email)
  end

  defp notification_message(%{type: "report_submitted", data: data}) do
    reporter = Map.get(data, "reporter_email", "someone")
    reported = Map.get(data, "reported_user_email", "a user")

    gettext("New report: %{reporter} reported %{reported}",
      reporter: reporter,
      reported: reported
    )
  end

  defp notification_message(%{type: "follower_post", data: data, actor: actor}) do
    name =
      if actor,
        do: actor.display_name || String.split(actor.email, "@") |> List.first(),
        else: Map.get(data, "author_name", "Someone")

    title = Map.get(data, "post_title", "a new post")
    gettext("%{name} published \"%{title}\"", name: name, title: title)
  end

  defp notification_message(%{type: "system_alert", data: data}) do
    message = Map.get(data, "message", "System alert")
    message
  end

  defp notification_message(_notification) do
    gettext("You have a new notification")
  end

  defp replace_notification(notifications, notification_id, replacement) do
    Enum.map(notifications, fn n ->
      if n.id == notification_id, do: replacement, else: n
    end)
  end

  defp following_back?(actor_id, following_ids) do
    MapSet.member?(following_ids, actor_id)
  end
end
