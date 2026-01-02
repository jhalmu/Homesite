defmodule HomesiteWeb.FollowingLive.Index do
  @moduledoc """
  LiveView for displaying posts from users you follow.
  Shows a chronological feed of public posts from followed users.
  """
  use HomesiteWeb, :live_view

  alias Homesite.Content
  alias Homesite.Follows
  import HomesiteWeb.Helpers.DateHelpers

  @posts_per_page 10

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="technical-main">
        <.header>
          {gettext("Following")}
          <:subtitle>
            {ngettext(
              "Posts from %{count} user you follow",
              "Posts from %{count} users you follow",
              @following_count,
              count: @following_count
            )}
          </:subtitle>
        </.header>

        <%= if @following_count == 0 do %>
          <div class="alert alert-info mt-[var(--spacing-lg)]">
            <.icon name="hero-user-group" class="h-6 w-6" />
            <div>
              <p class="font-medium">{gettext("You're not following anyone yet")}</p>
              <p class="text-sm opacity-70">
                {gettext("Follow other users to see their posts here.")}
              </p>
            </div>
          </div>
        <% else %>
          <%= if Enum.empty?(@posts) do %>
            <div class="alert alert-info mt-[var(--spacing-lg)]">
              <.icon name="hero-document-text" class="h-6 w-6" />
              <span>{gettext("No posts from users you follow yet.")}</span>
            </div>
          <% else %>
            <div class="mt-[var(--spacing-lg)] space-y-[var(--spacing-md)]">
              <%= for post <- @posts do %>
                <article class="card bg-base-200 duration-[var(--duration-normal)] shadow-lg transition-shadow hover:shadow-xl">
                  <div class="card-body">
                    <div class="gap-[var(--spacing-md)] flex items-start">
                      <.link navigate={~p"/users/@#{post.user.username}"} class="flex-shrink-0">
                        <img
                          src={Homesite.Accounts.get_avatar_url(post.user)}
                          alt={post.user.display_name || post.user.username}
                          class="h-12 w-12 rounded-full object-cover"
                        />
                      </.link>

                      <div class="min-w-0 flex-1">
                        <div class="gap-[var(--spacing-sm)] mb-[var(--spacing-xs)] flex items-center text-sm">
                          <.link
                            navigate={~p"/users/@#{post.user.username}"}
                            class="font-medium hover:underline"
                          >
                            {post.user.display_name || post.user.username}
                          </.link>
                          <span class="opacity-50">@{post.user.username}</span>
                          <span class="opacity-50">·</span>
                          <time datetime={post.published_at} class="opacity-50">
                            {format_relative_time(post.published_at)}
                          </time>
                        </div>

                        <.link navigate={~p"/posts/#{post}"} class="group">
                          <h2 class="card-title mb-[var(--spacing-sm)] text-[var(--font-size-fluid-lg)] duration-[var(--duration-normal)] transition-colors group-hover:text-primary">
                            {post.title}
                          </h2>
                        </.link>

                        <p class="line-clamp-2 mb-[var(--spacing-sm)] text-[var(--text-sm)] opacity-70">
                          {preview_text(post.body)}
                        </p>

                        <div class="gap-[var(--spacing-sm)] text-[var(--text-sm)] flex flex-wrap items-center">
                          <span class="opacity-70">
                            <.icon name="hero-clock" class="inline h-4 w-4" />
                            {post.read_time_minutes} {gettext("min read")}
                          </span>

                          <%= if post.tags && length(post.tags) > 0 do %>
                            <div class="gap-[var(--spacing-inline)] flex flex-wrap">
                              <%= for tag <- Enum.take(post.tags, 3) do %>
                                <.link
                                  navigate={~p"/tags/#{tag.slug}"}
                                  class="badge badge-sm badge-primary gap-[var(--spacing-inline)] duration-[var(--duration-fast)] transition-colors hover:brightness-110"
                                >
                                  {tag.name}
                                </.link>
                              <% end %>
                            </div>
                          <% end %>
                        </div>
                      </div>
                    </div>
                  </div>
                </article>
              <% end %>
            </div>

            <%= if @has_more do %>
              <div class="mt-[var(--spacing-lg)] text-center">
                <button phx-click="load_more" class="btn btn-outline">
                  {gettext("Load More")}
                </button>
              </div>
            <% end %>
          <% end %>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      scope = socket.assigns.current_scope

      # Get following count
      %{following: following_count} = Follows.get_follow_counts(scope.user.id)

      # Load initial posts
      posts = Content.list_posts_from_following(scope, limit: @posts_per_page)
      has_more = length(posts) == @posts_per_page

      {:ok,
       socket
       |> assign(:page_title, gettext("Following"))
       |> assign(:following_count, following_count)
       |> assign(:posts, posts)
       |> assign(:has_more, has_more)}
    else
      {:ok,
       assign(socket,
         page_title: gettext("Following"),
         following_count: 0,
         posts: [],
         has_more: false
       )}
    end
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    current_count = length(socket.assigns.posts)

    new_posts =
      Content.list_posts_from_following(
        socket.assigns.current_scope,
        limit: @posts_per_page,
        offset: current_count
      )

    all_posts = socket.assigns.posts ++ new_posts
    has_more = length(new_posts) == @posts_per_page

    {:noreply, assign(socket, posts: all_posts, has_more: has_more)}
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
