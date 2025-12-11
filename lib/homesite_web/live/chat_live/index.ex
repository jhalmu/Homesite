defmodule HomesiteWeb.ChatLive.Index do
  @moduledoc """
  LiveView for displaying chat channel list.
  """
  use HomesiteWeb, :live_view

  alias Homesite.Chat

  @impl true
  def mount(_params, _session, socket) do
    # Filter channels based on user role (admin sees all, others see non-admin-only)
    channels = Chat.list_channels_for_user(socket.assigns.current_scope)

    {:ok,
     assign(socket,
       channels: channels,
       page_title: gettext("Chat")
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="technical-main">
        <.header>
          {gettext("Chat")}
          <:subtitle>
            {gettext("IRC-style channels for real-time discussion")}
          </:subtitle>
        </.header>

        <div class="mt-[var(--space-md)] space-y-[var(--space-sm)]">
          <%= if Enum.empty?(@channels) do %>
            <div class="alert">
              <.icon name="hero-information-circle" class="h-6 w-6" />
              <span>{gettext("No channels available yet.")}</span>
            </div>
          <% else %>
            <ul class="menu bg-base-200 rounded-box w-full">
              <%= for channel <- @channels do %>
                <li>
                  <.link
                    navigate={~p"/chat/#{channel.slug}"}
                    class="gap-[var(--space-sm)] flex items-center justify-between"
                  >
                    <div class="gap-[var(--space-xs)] flex items-center">
                      <span class="text-primary font-mono text-[var(--text-lg)]">#</span>
                      <span class="font-medium">{channel.name}</span>
                      <%= if channel.is_default do %>
                        <span class="badge badge-primary badge-xs">{gettext("default")}</span>
                      <% end %>
                      <%= if channel.is_admin_only do %>
                        <span class="badge badge-warning badge-xs">{gettext("admin")}</span>
                      <% end %>
                    </div>
                    <%= if channel.description do %>
                      <span class="text-base-content/60 text-[var(--text-sm)]">
                        {channel.description}
                      </span>
                    <% end %>
                  </.link>
                </li>
              <% end %>
            </ul>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
