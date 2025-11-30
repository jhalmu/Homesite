defmodule HomesiteWeb.TagLive.Index do
  use HomesiteWeb, :live_view

  # Note: "unused import" warning is false positive - gettext() used in HEEx template
  import HomesiteWeb.Gettext

  alias Homesite.Content

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <main>
        <.header>
          {gettext("Listing Tags")}
          <:actions>
            <.button variant="primary" navigate={~p"/tags/new"}>
              <.icon name="hero-plus" /> {gettext("New Tag")}
            </.button>
          </:actions>
        </.header>
        
    <!-- Tabs -->
        <div role="tablist" class="tabs tabs-boxed mt-6">
          <button
            role="tab"
            class={["tab", @current_tab == "my" && "tab-active"]}
            phx-click="switch-tab"
            phx-value-tab="my"
          >
            <.icon name="hero-user" class="mr-2 h-4 w-4" />
            {gettext("My Tags")}
          </button>
          <button
            role="tab"
            class={["tab", @current_tab == "all" && "tab-active"]}
            phx-click="switch-tab"
            phx-value-tab="all"
          >
            <.icon name="hero-globe-alt" class="mr-2 h-4 w-4" />
            {gettext("All Tags")}
          </button>
        </div>
        
    <!-- Search bar (only in All Tags tab) -->
        <%= if @current_tab == "all" do %>
          <div class="mt-4">
            <.input
              type="text"
              name="query"
              value={@search_query}
              phx-keyup="search"
              phx-debounce="300"
              placeholder={gettext("Search tags...")}
            />
          </div>
        <% end %>

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
                      <h2 class="card-title mb-2 text-xl transition-colors group-hover:text-primary">
                        {tag.name}
                      </h2>
                    </.link>

                    <%= if tag.description && @current_tab == "my" do %>
                      <p class="line-clamp-2 mb-3 text-sm opacity-70">
                        {tag.description}
                      </p>
                    <% end %>

                    <div class="flex flex-wrap gap-3 text-sm">
                      <%= if @current_tab == "my" do %>
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
                      <% else %>
                        <!-- Show post count in All Tags tab -->
                        <div class="badge badge-neutral gap-2">
                          <.icon name="hero-document-text" class="h-3 w-3" />
                          {tag.post_count} {ngettext("post", "posts", tag.post_count)}
                        </div>
                      <% end %>
                    </div>
                  </div>

                  <%= if @current_tab == "my" do %>
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
                  <% else %>
                    <div class="flex flex-shrink-0">
                      <.link navigate={~p"/tags/#{tag}"} class="btn btn-sm btn-primary">
                        {gettext("View Posts")}
                        <.icon name="hero-arrow-right" class="h-4 w-4" />
                      </.link>
                    </div>
                  <% end %>
                </div>
              </div>
            </article>
          <% end %>
        </div>

        <%= if not @has_tags do %>
          <div class="alert alert-info mt-8">
            <.icon name="hero-information-circle" class="h-6 w-6" />
            <%= if @current_tab == "my" do %>
              <span>{gettext("No tags yet. Create your first tag to get started!")}</span>
            <% else %>
              <span>{gettext("No tags found.")}</span>
            <% end %>
          </div>
        <% end %>
      </main>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Content.subscribe_tags(socket.assigns.current_scope)
    end

    current_tab = "my"
    tags = list_tags(socket.assigns.current_scope, current_tab, nil)

    {:ok,
     socket
     |> assign(:page_title, gettext("Listing Tags"))
     |> assign(:current_tab, current_tab)
     |> assign(:search_query, "")
     |> assign(:has_tags, length(tags) > 0)
     |> stream(:tags, tags)}
  end

  @impl true
  def handle_event("switch-tab", %{"tab" => tab}, socket) do
    tags = list_tags(socket.assigns.current_scope, tab, nil)

    {:noreply,
     socket
     |> assign(:current_tab, tab)
     |> assign(:search_query, "")
     |> assign(:has_tags, length(tags) > 0)
     |> stream(:tags, tags, reset: true)}
  end

  def handle_event("search", %{"query" => query}, socket) do
    tags = list_tags(socket.assigns.current_scope, socket.assigns.current_tab, query)

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:has_tags, length(tags) > 0)
     |> stream(:tags, tags, reset: true)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    tag = Content.get_tag!(socket.assigns.current_scope, id)
    {:ok, _} = Content.delete_tag(socket.assigns.current_scope, tag)

    {:noreply, stream_delete(socket, :tags, tag)}
  end

  @impl true
  def handle_info({type, %Homesite.Content.Tag{}}, socket)
      when type in [:created, :updated, :deleted] do
    tags =
      list_tags(
        socket.assigns.current_scope,
        socket.assigns.current_tab,
        socket.assigns.search_query
      )

    {:noreply,
     socket
     |> assign(:has_tags, length(tags) > 0)
     |> stream(:tags, tags, reset: true)}
  end

  defp list_tags(current_scope, "my", _search) do
    Content.list_tags(current_scope)
  end

  defp list_tags(_current_scope, "all", search) do
    tags_with_counts = Content.list_all_public_tags(search)

    # Convert tuples to maps with post_count field for template access
    Enum.map(tags_with_counts, fn {tag, count} ->
      Map.put(tag, :post_count, count || 0)
    end)
  end
end
