defmodule HomesiteWeb.TagLive.Index do
  use HomesiteWeb, :live_view

  alias Homesite.Content

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="technical-main">
        <.header>
          {gettext("Listing Tags")}
          <:actions>
            <.button variant="primary" navigate={~p"/tags/new"}>
              <.icon name="hero-plus" /> {gettext("New Tag")}
            </.button>
          </:actions>
        </.header>
        
    <!-- Tabs -->
        <div role="tablist" class="tabs tabs-boxed mt-[var(--space-md)]">
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
          <div class="mt-[var(--space-sm)]">
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

        <div class="mt-[var(--spacing-lg)] space-y-[var(--spacing-md)]" id="tags" phx-update="stream">
          <%= for {id, tag} <- @streams.tags do %>
            <article
              id={id}
              class="card bg-base-200 duration-[var(--duration-normal)] shadow-lg transition-shadow hover:shadow-xl"
            >
              <div class="card-body">
                <div class="gap-[var(--spacing-md)] flex items-start justify-between">
                  <div class="min-w-0 flex-1">
                    <.link navigate={~p"/tags/#{tag}"} class="group">
                      <h2 class="card-title mb-[var(--spacing-sm)] text-[var(--font-size-fluid-xl)] duration-[var(--duration-normal)] transition-colors group-hover:text-primary">
                        {tag.name}
                      </h2>
                    </.link>

                    <%= if tag.description && @current_tab == "my" do %>
                      <p class="line-clamp-2 mb-[var(--spacing-sm)] text-[var(--text-sm)] opacity-70">
                        {tag.description}
                      </p>
                    <% end %>

                    <div class="gap-[var(--spacing-sm)] text-[var(--text-sm)] flex flex-wrap">
                      <%= if @current_tab == "my" do %>
                        <%= if tag.is_public do %>
                          <div class="badge badge-ghost gap-[var(--space-xs)]">
                            <.icon name="hero-globe-alt" class="h-3 w-3" />
                            {gettext("Public")}
                          </div>
                        <% else %>
                          <div class="badge badge-ghost gap-[var(--space-xs)]">
                            <.icon name="hero-lock-closed" class="h-3 w-3" />
                            {gettext("Private")}
                          </div>
                        <% end %>
                      <% else %>
                        <!-- Show post count in All Tags tab -->
                        <div class="badge badge-neutral gap-[var(--space-xs)]">
                          <.icon name="hero-document-text" class="h-3 w-3" />
                          {tag.post_count} {ngettext("post", "posts", tag.post_count)}
                        </div>
                      <% end %>
                    </div>
                  </div>

                  <%= if @current_tab == "my" do %>
                    <div class="gap-[var(--spacing-inline)] flex flex-shrink-0">
                      <.link
                        navigate={~p"/tags/#{tag}"}
                        class="btn btn-sm btn-ghost"
                        aria-label={gettext("View tag")}
                      >
                        <.icon name="hero-eye" class="h-4 w-4" />
                      </.link>
                      <.link
                        navigate={~p"/tags/#{tag}/edit"}
                        class="btn btn-sm btn-ghost"
                        aria-label={gettext("Edit tag")}
                      >
                        <.icon name="hero-pencil-square" class="h-4 w-4" />
                      </.link>
                      <.link
                        phx-click={JS.push("delete", value: %{id: tag.id}) |> hide("##{id}")}
                        data-confirm={gettext("Are you sure?")}
                        class="btn btn-sm btn-ghost text-error"
                        aria-label={gettext("Delete tag")}
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
          <div class="alert alert-info mt-[var(--spacing-lg)]">
            <.icon name="hero-information-circle" class="h-6 w-6" />
            <%= if @current_tab == "my" do %>
              <span>{gettext("No tags yet. Create your first tag to get started!")}</span>
            <% else %>
              <span>{gettext("No tags found.")}</span>
            <% end %>
          </div>
        <% end %>
      </div>
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
