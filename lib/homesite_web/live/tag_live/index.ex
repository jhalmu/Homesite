defmodule HomesiteWeb.TagLive.Index do
  use HomesiteWeb, :live_view

  alias Homesite.Content

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Listing Tags")}
        <:actions>
          <.button variant="primary" navigate={~p"/tags/new"}>
            <.icon name="hero-plus" /> {gettext("New Tag")}
          </.button>
        </:actions>
      </.header>

      <div class="mt-8 space-y-4" id="tags" phx-update="stream">
        <%= for {id, tag} <- @streams.tags do %>
          <article
            id={id}
            class="card bg-base-200 shadow-lg transition-shadow hover:shadow-xl"
          >
            <div class="card-body">
              <div class="flex items-start justify-between gap-4">
                <div class="min-w-0 flex-1">
                  <.link navigate={~p"/tags/#{tag}"} class="group">
                    <h3 class="card-title mb-2 text-xl transition-colors group-hover:text-primary">
                      {tag.name}
                    </h3>
                  </.link>

                  <%= if tag.description do %>
                    <p class="line-clamp-2 mb-3 text-sm opacity-70">
                      {tag.description}
                    </p>
                  <% end %>

                  <div class="flex flex-wrap gap-3 text-sm">
                    <%= if tag.is_public do %>
                      <div class="badge badge-ghost gap-2">
                        <.icon name="hero-globe-alt" class="h-3 w-3" />
                        {gettext("Public")}
                      </div>
                    <% else %>
                      <div class="badge badge-ghost gap-2">
                        <.icon name="hero-lock-closed" class="h-3 w-3" />
                        {gettext("Private")}
                      </div>
                    <% end %>
                  </div>
                </div>

                <div class="flex flex-shrink-0 gap-2">
                  <.link navigate={~p"/tags/#{tag}"} class="btn btn-sm btn-ghost">
                    <.icon name="hero-eye" class="h-4 w-4" />
                  </.link>
                  <.link navigate={~p"/tags/#{tag}/edit"} class="btn btn-sm btn-ghost">
                    <.icon name="hero-pencil-square" class="h-4 w-4" />
                  </.link>
                  <.link
                    phx-click={JS.push("delete", value: %{id: tag.id}) |> hide("##{id}")}
                    data-confirm={gettext("Are you sure?")}
                    class="btn btn-sm btn-ghost text-error"
                  >
                    <.icon name="hero-trash" class="h-4 w-4" />
                  </.link>
                </div>
              </div>
            </div>
          </article>
        <% end %>
      </div>

      <%= if not @has_tags do %>
        <div class="alert alert-info mt-8">
          <.icon name="hero-information-circle" class="h-6 w-6" />
          <span>{gettext("No tags yet. Create your first tag to get started!")}</span>
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Content.subscribe_tags(socket.assigns.current_scope)
    end

    tags = list_tags(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, gettext("Listing Tags"))
     |> assign(:has_tags, length(tags) > 0)
     |> stream(:tags, tags)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    tag = Content.get_tag!(socket.assigns.current_scope, id)
    {:ok, _} = Content.delete_tag(socket.assigns.current_scope, tag)

    {:noreply, stream_delete(socket, :tags, tag)}
  end

  @impl true
  def handle_info({type, %Homesite.Content.Tag{}}, socket)
      when type in [:created, :updated, :deleted] do
    tags = list_tags(socket.assigns.current_scope)

    {:noreply,
     socket
     |> assign(:has_tags, length(tags) > 0)
     |> stream(:tags, tags, reset: true)}
  end

  defp list_tags(current_scope) do
    Content.list_tags(current_scope)
  end
end
