defmodule HomesiteWeb.PostLive.Index do
  use HomesiteWeb, :live_view

  # Note: "unused import" warning is false positive - gettext() used in HEEx template
  import HomesiteWeb.Gettext

  alias Homesite.Content

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Listing Posts")}
        <:actions>
          <%= if @current_scope do %>
            <.button variant="primary" navigate={~p"/posts/new"}>
              <.icon name="hero-plus" /> {gettext("New Post")}
            </.button>
          <% end %>
        </:actions>
      </.header>

      <div class="mt-8 space-y-4" id="posts" phx-update="stream">
        <%= for {id, post} <- @streams.posts do %>
          <article
            id={id}
            class="card bg-base-200 shadow-lg transition-shadow hover:shadow-xl"
          >
            <div class="card-body">
              <div class="flex items-start justify-between gap-4">
                <div class="min-w-0 flex-1">
                  <.link navigate={~p"/posts/#{post}"} class="group">
                    <h3 class="card-title mb-2 text-xl transition-colors group-hover:text-primary">
                      {post.title}
                    </h3>
                  </.link>

                  <p class="line-clamp-2 mb-3 text-sm opacity-70">
                    {preview_text(post.body)}
                  </p>

                  <div class="flex flex-wrap gap-3 text-sm">
                    <%= if post.published_at do %>
                      <div class="badge badge-success gap-2">
                        <.icon name="hero-check-circle" class="h-3 w-3" />
                        {gettext("Published")}
                      </div>
                      <div class="opacity-70">
                        <.icon name="hero-calendar" class="inline h-4 w-4" />
                        <time datetime={post.published_at}>
                          {Calendar.strftime(post.published_at, "%B %d, %Y")}
                        </time>
                      </div>
                    <% else %>
                      <div class="badge badge-warning gap-2">
                        <.icon name="hero-pencil" class="h-3 w-3" />
                        {gettext("Draft")}
                      </div>
                    <% end %>

                    <%= if post.is_public do %>
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

                  <%= if post.tags && length(post.tags) > 0 do %>
                    <div class="mt-2 flex flex-wrap gap-2">
                      <%= for tag <- post.tags do %>
                        <.link
                          navigate={~p"/tags/#{tag.slug}"}
                          class="badge badge-sm badge-primary gap-1"
                        >
                          <.icon name="hero-tag" class="h-3 w-3" />
                          {tag.name}
                        </.link>
                      <% end %>
                    </div>
                  <% end %>
                </div>

                <%= if @current_scope && post.user_id == @current_scope.user.id do %>
                  <div class="flex flex-shrink-0 gap-2">
                    <.link navigate={~p"/posts/#{post}"} class="btn btn-sm btn-ghost">
                      <.icon name="hero-eye" class="h-4 w-4" />
                    </.link>
                    <.link navigate={~p"/posts/#{post}/edit"} class="btn btn-sm btn-ghost">
                      <.icon name="hero-pencil-square" class="h-4 w-4" />
                    </.link>
                    <.link
                      phx-click={JS.push("delete", value: %{id: post.id}) |> hide("##{id}")}
                      data-confirm={gettext("Are you sure?")}
                      class="btn btn-sm btn-ghost text-error"
                    >
                      <.icon name="hero-trash" class="h-4 w-4" />
                    </.link>
                  </div>
                <% end %>
              </div>
            </div>
          </article>
        <% end %>
      </div>

      <%= if not @has_posts do %>
        <div class="alert alert-info mt-8">
          <.icon name="hero-information-circle" class="h-6 w-6" />
          <span>{gettext("No posts yet. Create your first post to get started!")}</span>
        </div>
      <% end %>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    current_scope = socket.assigns.current_scope

    if connected?(socket) && current_scope do
      Content.subscribe_posts(current_scope)
    end

    posts = list_posts(current_scope)

    {:ok,
     socket
     |> assign(:page_title, gettext("Listing Posts"))
     |> assign(:has_posts, length(posts) > 0)
     |> stream(:posts, posts)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Content.get_post!(socket.assigns.current_scope, id)
    {:ok, _} = Content.delete_post(socket.assigns.current_scope, post)

    {:noreply, stream_delete(socket, :posts, post)}
  end

  @impl true
  def handle_info({type, %Homesite.Content.Post{}}, socket)
      when type in [:created, :updated, :deleted] do
    posts = list_posts(socket.assigns.current_scope)

    {:noreply,
     socket
     |> assign(:has_posts, length(posts) > 0)
     |> stream(:posts, posts, reset: true)}
  end

  defp list_posts(nil) do
    # Non-authenticated users see only public posts
    Content.list_public_posts()
  end

  defp list_posts(current_scope) do
    # Authenticated users see their own posts
    Content.list_posts(current_scope)
  end

  defp preview_text(body) do
    body
    |> MDEx.to_html!(extension: [], render: [unsafe_: true])
    |> Floki.parse_document!()
    |> Floki.text()
    |> String.slice(0, 150)
    |> then(fn text ->
      if String.length(text) >= 150, do: text <> "...", else: text
    end)
  end
end
