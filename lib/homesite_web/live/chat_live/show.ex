defmodule HomesiteWeb.ChatLive.Show do
  @moduledoc """
  LiveView for the main chat interface in a specific channel.

  Features:
  - Real-time message display using streams
  - PubSub subscription for new messages
  - Message input with 280 character limit
  - Auto-scroll to bottom via JS hook
  - DaisyUI chat bubble styling
  - User blocking (personal)
  - Ban/mute checks before sending
  """
  use HomesiteWeb, :live_view

  alias Homesite.Accounts
  alias Homesite.Chat
  alias Homesite.Chat.Message

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    scope = socket.assigns.current_scope

    # Check if user can access this channel (admin-only check)
    case Chat.get_accessible_channel(scope, slug) do
      {:ok, channel} ->
        if connected?(socket) do
          Chat.subscribe_channel(channel.id)
        end

        # Use filtered messages that respect blocks
        messages = Chat.list_messages_for_user(scope, channel.id, limit: 50)

        # Check if user can send messages
        can_send = Chat.can_send_message?(scope, channel.id)

        # Get blocked user IDs for real-time filtering
        blocked_ids = Chat.blocked_user_ids(scope)

        # Check admin status
        is_admin = Accounts.Scope.admin?(scope)

        {:ok,
         socket
         |> assign(:channel, channel)
         |> assign(:page_title, "##{channel.name}")
         |> assign(:char_count, 0)
         |> assign(:can_send, can_send)
         |> assign(:blocked_ids, blocked_ids)
         |> assign(:is_admin, is_admin)
         |> assign_form(Chat.change_message(%Message{}))
         |> stream(:messages, messages)}

      {:error, :not_authorized} ->
        {:ok,
         socket
         |> put_flash(:error, gettext("You don't have access to this channel"))
         |> redirect(to: ~p"/chat")}
    end
  end

  @impl true
  def handle_event("validate", %{"message" => message_params}, socket) do
    body = message_params["body"] || ""
    char_count = String.length(body)

    changeset =
      %Message{}
      |> Chat.change_message(message_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:char_count, char_count)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("send", %{"message" => message_params}, socket) do
    case Chat.create_message_with_checks(
           socket.assigns.current_scope,
           socket.assigns.channel.id,
           message_params
         ) do
      {:ok, _message} ->
        {:noreply,
         socket
         |> assign(:char_count, 0)
         |> assign_form(Chat.change_message(%Message{}))}

      {:error, :banned} ->
        {:noreply, put_flash(socket, :error, gettext("You are banned from chat"))}

      {:error, :muted} ->
        {:noreply, put_flash(socket, :error, gettext("You are muted in this channel"))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("block_user", %{"user-id" => user_id}, socket) do
    user_id = String.to_integer(user_id)

    case Chat.block_user(socket.assigns.current_scope, user_id) do
      {:ok, _block} ->
        # Add to blocked IDs and filter existing messages
        blocked_ids = [user_id | socket.assigns.blocked_ids]

        {:noreply,
         socket
         |> assign(:blocked_ids, blocked_ids)
         |> put_flash(:info, gettext("User blocked. Their messages are now hidden."))
         |> reload_messages()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Could not block user"))}
    end
  end

  @impl true
  def handle_event("unblock_user", %{"user-id" => user_id}, socket) do
    user_id = String.to_integer(user_id)

    case Chat.unblock_user(socket.assigns.current_scope, user_id) do
      {:ok, _} ->
        blocked_ids = List.delete(socket.assigns.blocked_ids, user_id)

        {:noreply,
         socket
         |> assign(:blocked_ids, blocked_ids)
         |> put_flash(:info, gettext("User unblocked."))
         |> reload_messages()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Could not unblock user"))}
    end
  end

  # Admin moderation actions
  @impl true
  def handle_event("ban_user", %{"user-id" => user_id, "reason" => reason}, socket) do
    if socket.assigns.is_admin do
      user_id = String.to_integer(user_id)

      case Chat.ban_user(socket.assigns.current_scope, user_id, reason: reason) do
        {:ok, _ban} ->
          {:noreply, put_flash(socket, :info, gettext("User banned from chat"))}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Could not ban user"))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("Not authorized"))}
    end
  end

  @impl true
  def handle_event("mute_user", %{"user-id" => user_id, "duration" => duration}, socket) do
    if socket.assigns.is_admin do
      user_id = String.to_integer(user_id)
      duration = String.to_integer(duration)

      case Chat.mute_user(socket.assigns.current_scope, user_id,
             duration: duration,
             channel_id: socket.assigns.channel.id
           ) do
        {:ok, _mute} ->
          {:noreply,
           put_flash(
             socket,
             :info,
             gettext("User muted for %{minutes} minutes", minutes: duration)
           )}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Could not mute user"))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("Not authorized"))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    message = Chat.get_message!(id)

    case Chat.delete_message(socket.assigns.current_scope, message) do
      {:ok, _} ->
        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Could not delete message"))}
    end
  rescue
    MatchError ->
      {:noreply, put_flash(socket, :error, gettext("You can only delete your own messages"))}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    # Filter out messages from blocked users
    if message.user_id in socket.assigns.blocked_ids do
      {:noreply, socket}
    else
      {:noreply,
       socket
       |> stream_insert(:messages, message)
       |> push_event("scroll_to_bottom", %{})}
    end
  end

  @impl true
  def handle_info({:deleted_message, message_id}, socket) do
    {:noreply, stream_delete_by_dom_id(socket, :messages, "messages-#{message_id}")}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp reload_messages(socket) do
    messages =
      Chat.list_messages_for_user(
        socket.assigns.current_scope,
        socket.assigns.channel.id,
        limit: 50
      )

    socket
    |> stream(:messages, messages, reset: true)
  end

  defp my_message?(message, current_scope) do
    message.user_id == current_scope.user.id
  end

  defp format_time(datetime) do
    Calendar.strftime(datetime, "%H:%M")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="technical-main h-[calc(100vh-12rem)] flex flex-col">
        <%!-- Header --%>
        <div class="mb-[var(--space-sm)] flex items-center justify-between">
          <div class="gap-[var(--space-sm)] flex items-center">
            <.link navigate={~p"/chat"} class="btn btn-ghost btn-sm">
              <.icon name="hero-arrow-left" class="h-4 w-4" />
            </.link>
            <h1 class="text-[var(--text-xl)] font-bold">
              <span class="text-primary">#</span>{@channel.name}
            </h1>
          </div>
          <%= if @channel.description do %>
            <span class="text-base-content/60 text-[var(--text-sm)]">{@channel.description}</span>
          <% end %>
        </div>

        <%!-- Messages container --%>
        <div
          id="chat-messages"
          phx-hook="ChatScroll"
          class="bg-base-200/50 rounded-box p-[var(--space-md)] flex-1 overflow-y-auto"
          phx-update="stream"
        >
          <%= for {dom_id, message} <- @streams.messages do %>
            <div
              id={dom_id}
              class={["chat", (my_message?(message, @current_scope) && "chat-end") || "chat-start"]}
            >
              <div class="chat-header gap-[var(--space-xs)] flex items-center">
                <span class="font-medium">{message.user.email |> String.split("@") |> hd()}</span>
                <time class="text-base-content/50 text-[var(--text-xs)]">
                  {format_time(message.inserted_at)}
                </time>
                <%!-- Message actions --%>
                <%= if my_message?(message, @current_scope) do %>
                  <button
                    phx-click="delete"
                    phx-value-id={message.id}
                    data-confirm={gettext("Are you sure you want to delete this message?")}
                    class="text-error/50 text-[var(--text-xs)] hover:text-error"
                    title={gettext("Delete message")}
                  >
                    <.icon name="hero-trash" class="h-3 w-3" />
                  </button>
                <% else %>
                  <%!-- Block user button (for other users' messages) --%>
                  <div class="dropdown dropdown-end">
                    <button
                      tabindex="0"
                      class="text-base-content/50 text-[var(--text-xs)] hover:text-base-content"
                    >
                      <.icon name="hero-ellipsis-horizontal" class="h-3 w-3" />
                    </button>
                    <ul
                      tabindex="0"
                      class="dropdown-content menu bg-base-100 rounded-box text-[var(--text-sm)] z-10 w-48 p-1 shadow-lg"
                    >
                      <li>
                        <button
                          phx-click="block_user"
                          phx-value-user-id={message.user_id}
                          data-confirm={gettext("Block this user? You won't see their messages.")}
                          class="text-warning"
                        >
                          <.icon name="hero-no-symbol" class="h-4 w-4" />
                          {gettext("Block user")}
                        </button>
                      </li>
                      <li>
                        <.link
                          navigate={
                            ~p"/moderation/report/#{message.user_id}?source=chat&content_type=chat_message&content_id=#{message.id}"
                          }
                          class="text-error"
                        >
                          <.icon name="hero-flag" class="h-4 w-4" />
                          {gettext("Report user")}
                        </.link>
                      </li>
                      <%!-- Admin actions --%>
                      <%= if @is_admin do %>
                        <li>
                          <button
                            phx-click="mute_user"
                            phx-value-user-id={message.user_id}
                            phx-value-duration="10"
                            data-confirm={gettext("Mute this user for 10 minutes?")}
                            class="text-warning"
                          >
                            <.icon name="hero-speaker-x-mark" class="h-4 w-4" />
                            {gettext("Mute 10 min")}
                          </button>
                        </li>
                        <li>
                          <button
                            phx-click="mute_user"
                            phx-value-user-id={message.user_id}
                            phx-value-duration="60"
                            data-confirm={gettext("Mute this user for 1 hour?")}
                            class="text-warning"
                          >
                            <.icon name="hero-speaker-x-mark" class="h-4 w-4" />
                            {gettext("Mute 1 hour")}
                          </button>
                        </li>
                        <li>
                          <button
                            phx-click="ban_user"
                            phx-value-user-id={message.user_id}
                            phx-value-reason="Violation of chat rules"
                            data-confirm={gettext("Ban this user from chat? This is permanent.")}
                            class="text-error"
                          >
                            <.icon name="hero-x-circle" class="h-4 w-4" />
                            {gettext("Ban user")}
                          </button>
                        </li>
                      <% end %>
                    </ul>
                  </div>
                <% end %>
              </div>
              <div class={[
                "chat-bubble",
                (my_message?(message, @current_scope) && "chat-bubble-primary") ||
                  "chat-bubble-secondary"
              ]}>
                {message.body}
              </div>
            </div>
          <% end %>
        </div>

        <%!-- Message input form --%>
        <div class="mt-[var(--space-sm)]">
          <%= case @can_send do %>
            <% :ok -> %>
              <.form
                for={@form}
                id="message-form"
                phx-change="validate"
                phx-submit="send"
                class="gap-[var(--space-sm)] flex items-end"
              >
                <div class="flex-1">
                  <.input
                    field={@form[:body]}
                    type="textarea"
                    placeholder={gettext("Type a message...")}
                    rows="2"
                    class="textarea textarea-bordered w-full resize-none"
                    phx-debounce="100"
                  />
                  <div class="mt-[var(--space-xs)] flex justify-end">
                    <span class={[
                      "text-[var(--text-xs)]",
                      (@char_count > 280 && "text-error") || "text-base-content/50"
                    ]}>
                      {@char_count}/280
                    </span>
                  </div>
                </div>
                <.button
                  type="submit"
                  class="btn-primary"
                  disabled={@char_count == 0 || @char_count > 280}
                >
                  <.icon name="hero-paper-airplane" class="h-5 w-5" />
                </.button>
              </.form>
            <% {:error, :banned} -> %>
              <div class="alert alert-error">
                <.icon name="hero-x-circle" class="h-5 w-5" />
                <span>{gettext("You are banned from chat and cannot send messages.")}</span>
              </div>
            <% {:error, :muted} -> %>
              <div class="alert alert-warning">
                <.icon name="hero-speaker-x-mark" class="h-5 w-5" />
                <span>{gettext("You are temporarily muted in this channel.")}</span>
              </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
