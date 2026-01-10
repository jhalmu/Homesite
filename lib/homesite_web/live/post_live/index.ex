defmodule HomesiteWeb.PostLive.Index do
  use HomesiteWeb, :live_view

  import HomesiteWeb.Helpers.DateHelpers

  alias Homesite.Content

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="technical-main" id="posts-page" phx-hook="OpenWindow">
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

        <div class="mt-[var(--spacing-lg)] space-y-[var(--spacing-md)]" id="posts" phx-update="stream">
          <%= for {id, post} <- @streams.posts do %>
            <article
              id={id}
              class="card bg-base-200 duration-[var(--duration-normal)] shadow-lg transition-shadow hover:shadow-xl"
            >
              <div class="card-body">
                <div class="gap-[var(--spacing-md)] flex items-start justify-between">
                  <div class="min-w-0 flex-1">
                    <.link navigate={~p"/posts/#{post.slug}"} class="group">
                      <h2 class="card-title mb-[var(--spacing-sm)] text-[var(--font-size-fluid-xl)] duration-[var(--duration-normal)] transition-colors group-hover:text-primary">
                        {post.title}
                      </h2>
                    </.link>

                    <p class="line-clamp-2 mb-[var(--spacing-sm)] text-[var(--text-sm)] opacity-70">
                      {preview_text(post.body)}
                    </p>

                    <div class="gap-[var(--spacing-sm)] text-[var(--text-sm)] flex flex-wrap">
                      <%= if post.published_at do %>
                        <div class="badge badge-success gap-[var(--spacing-inline)]">
                          <.icon name="hero-check-circle" class="h-3 w-3" />
                          {gettext("Published")}
                        </div>
                        <div class="opacity-70">
                          <.icon name="hero-calendar" class="inline h-4 w-4" />
                          <time datetime={post.published_at}>
                            {format_date(post.published_at)}
                          </time>
                        </div>
                        <div class="opacity-70">
                          <.icon name="hero-clock" class="inline h-4 w-4" />
                          {post.read_time_minutes} {gettext("min read")}
                        </div>
                        <div class="opacity-70">
                          <span>{post.user.display_name || post.user.email}</span>
                        </div>
                        <%= if post.is_public do %>
                          <div class="dropdown dropdown-end">
                            <button
                              tabindex="0"
                              class="gap-[var(--spacing-inline)] inline-flex items-center opacity-70 hover:underline"
                            >
                              <.icon name="hero-share" class="h-4 w-4" /> {gettext("Share")}
                            </button>
                            <ul
                              tabindex="0"
                              class="dropdown-content menu bg-base-200 rounded-box z-10 w-52 p-2 shadow-lg"
                            >
                              <li>
                                <a phx-click="share_bluesky" phx-value-id={post.id}>
                                  <.icon name="hero-chat-bubble-left-ellipsis" class="h-4 w-4" />
                                  {gettext("Share on Bluesky")}
                                </a>
                              </li>
                              <li>
                                <a phx-click="share_mastodon" phx-value-id={post.id}>
                                  <.icon name="hero-globe-alt" class="h-4 w-4" />
                                  {gettext("Share on Mastodon")}
                                </a>
                              </li>
                              <li>
                                <a phx-click="share_linkedin" phx-value-id={post.id}>
                                  <.icon name="hero-briefcase" class="h-4 w-4" />
                                  {gettext("Share on LinkedIn")}
                                </a>
                              </li>
                              <li>
                                <a phx-click="share_email" phx-value-id={post.id}>
                                  <.icon name="hero-envelope" class="h-4 w-4" />
                                  {gettext("Share via Email")}
                                </a>
                              </li>
                            </ul>
                          </div>
                        <% end %>
                      <% else %>
                        <div class="badge badge-warning gap-[var(--spacing-inline)]">
                          <.icon name="hero-pencil" class="h-3 w-3" />
                          {gettext("Draft")}
                        </div>
                      <% end %>

                      <%= if post.is_public do %>
                        <div class="badge badge-ghost gap-[var(--spacing-inline)]">
                          <.icon name="hero-globe-alt" class="h-3 w-3" />
                          {gettext("Public")}
                        </div>
                      <% else %>
                        <div class="badge badge-ghost gap-[var(--spacing-inline)]">
                          <.icon name="hero-lock-closed" class="h-3 w-3" />
                          {gettext("Private")}
                        </div>
                      <% end %>
                    </div>

                    <%= if post.tags && length(post.tags) > 0 do %>
                      <div class="mt-[var(--spacing-sm)] gap-[var(--spacing-inline)] flex flex-wrap">
                        <%= for tag <- post.tags do %>
                          <.link
                            navigate={~p"/tags/#{tag.slug}"}
                            class="badge badge-sm badge-primary gap-[var(--spacing-inline)] duration-[var(--duration-fast)] transition-colors hover:brightness-110"
                          >
                            <.icon name="hero-tag" class="h-3 w-3" />
                            {tag.name}
                          </.link>
                        <% end %>
                      </div>
                    <% end %>
                  </div>

                  <%= if @current_scope && post.user_id == @current_scope.user.id do %>
                    <div class="gap-[var(--spacing-inline)] flex flex-shrink-0">
                      <.link
                        navigate={~p"/posts/#{post.slug}"}
                        class="btn btn-sm btn-ghost"
                        aria-label={gettext("View post")}
                      >
                        <.icon name="hero-eye" class="h-4 w-4" />
                      </.link>
                      <.link
                        navigate={~p"/posts/#{post.slug}/edit"}
                        class="btn btn-sm btn-ghost"
                        aria-label={gettext("Edit post")}
                      >
                        <.icon name="hero-pencil-square" class="h-4 w-4" />
                      </.link>
                      <.link
                        phx-click={JS.push("delete", value: %{id: post.id}) |> hide("##{id}")}
                        data-confirm={gettext("Are you sure?")}
                        class="btn btn-sm btn-ghost text-error"
                        aria-label={gettext("Delete post")}
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
          <div class="alert alert-info mt-[var(--spacing-lg)]">
            <.icon name="hero-information-circle" class="h-6 w-6" />
            <span>{gettext("No posts yet. Create your first post to get started!")}</span>
          </div>
        <% end %>
      </div>
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
  def handle_event("share_bluesky", %{"id" => id}, socket) do
    post = Content.get_public_post!(id)
    post_url = url(~p"/posts/#{post.slug}")
    text = "#{post.title} #{post_url}"
    bluesky_url = "https://bsky.app/intent/compose?text=#{URI.encode_www_form(text)}"

    {:noreply, push_event(socket, "open_window", %{url: bluesky_url})}
  end

  @impl true
  def handle_event("share_mastodon", %{"id" => id}, socket) do
    post = Content.get_public_post!(id)
    post_url = url(~p"/posts/#{post.slug}")
    text = "#{post.title} #{post_url}"
    mastodon_url = "https://mastodonshare.com/?text=#{URI.encode_www_form(text)}"

    {:noreply, push_event(socket, "open_window", %{url: mastodon_url})}
  end

  @impl true
  def handle_event("share_linkedin", %{"id" => id}, socket) do
    post = Content.get_public_post!(id)
    post_url = url(~p"/posts/#{post.slug}")
    linkedin_url = "https://www.linkedin.com/sharing/share-offsite/?url=#{URI.encode(post_url)}"

    {:noreply, push_event(socket, "open_window", %{url: linkedin_url})}
  end

  @impl true
  def handle_event("share_email", %{"id" => id}, socket) do
    post = Content.get_public_post!(id)
    post_url = url(~p"/posts/#{post.slug}")
    subject = post.title
    body = "#{post.title}: #{post_url}"
    mailto = "mailto:?subject=#{URI.encode(subject)}&body=#{URI.encode(body)}"

    {:noreply, push_event(socket, "open_window", %{url: mailto})}
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
