defmodule HomesiteWeb.ChatLive.Show do
  @moduledoc """
  LiveView for the main chat interface in a specific channel.

  Features:
  - Real-time message display using streams
  - PubSub subscription for new messages
  - Message input with 280 character limit
  - Auto-scroll to bottom via JS hook
  - DaisyUI chat bubble styling
  """
  use HomesiteWeb, :live_view

  alias Homesite.Chat
  alias Homesite.Chat.Message

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    channel = Chat.get_channel_by_slug!(slug)

    if connected?(socket) do
      Chat.subscribe_channel(channel.id)
    end

    messages = Chat.list_messages(channel.id, limit: 50)

    {:ok,
     socket
     |> assign(:channel, channel)
     |> assign(:page_title, "##{channel.name}")
     |> assign(:char_count, 0)
     |> assign_form(Chat.change_message(%Message{}))
     |> stream(:messages, messages)}
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
    case Chat.create_message(
           socket.assigns.current_scope,
           socket.assigns.channel.id,
           message_params
         ) do
      {:ok, _message} ->
        {:noreply,
         socket
         |> assign(:char_count, 0)
         |> assign_form(Chat.change_message(%Message{}))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
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
    {:noreply,
     socket
     |> stream_insert(:messages, message)
     |> push_event("scroll_to_bottom", %{})}
  end

  @impl true
  def handle_info({:deleted_message, message_id}, socket) do
    {:noreply, stream_delete_by_dom_id(socket, :messages, "messages-#{message_id}")}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
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
                <%= if my_message?(message, @current_scope) do %>
                  <button
                    phx-click="delete"
                    phx-value-id={message.id}
                    data-confirm={gettext("Are you sure you want to delete this message?")}
                    class="text-error/50 text-[var(--text-xs)] hover:text-error"
                  >
                    <.icon name="hero-trash" class="h-3 w-3" />
                  </button>
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
        </div>
      </div>
    </Layouts.app>
    """
  end
end
