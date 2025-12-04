defmodule HomesiteWeb.UserLive.Profile do
  @moduledoc """
  Public profile page for viewing user information and their published posts.
  """
  use HomesiteWeb, :live_view

  alias Homesite.Accounts
  alias Homesite.Content
  alias Homesite.ExternalFeeds

  @posts_per_page 10

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={assigns[:current_scope]}>
      <div class="w-[min(95vw,800px)] mx-auto">
        <%!-- Profile Header - Compact layout with avatar beside bio --%>
        <div class="my-[var(--spacing-lg)]">
          <div class="flex flex-col items-center gap-4 sm:flex-row sm:items-start">
            <.avatar user={@user} class="h-20 w-20 shrink-0 sm:h-24 sm:w-24" />

            <div class="flex-1 text-center sm:text-left">
              <h1 class="text-[var(--font-size-fluid-xl)] font-bold">
                {@user.display_name || String.split(@user.email, "@") |> List.first()}
              </h1>

              <p
                :if={@user.bio}
                class="text-base-content/80 mt-2 whitespace-pre-wrap text-sm"
              >
                {@user.bio}
              </p>

              <%!-- Social links inline --%>
              <div
                :if={has_social_links?(@user)}
                class="mt-3 flex flex-wrap justify-center gap-2 sm:justify-start"
              >
                <.link
                  :if={@user.website_url}
                  href={@user.website_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="btn btn-outline btn-xs gap-1"
                >
                  <.icon name="hero-globe-alt" class="h-3 w-3" /> Website
                </.link>

                <.link
                  :if={@user.bluesky_handle}
                  href={"https://bsky.app/profile/#{String.trim_leading(@user.bluesky_handle, "@")}"}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="btn btn-outline btn-xs gap-1"
                >
                  <.icon name="hero-cloud" class="h-3 w-3" /> Bluesky
                </.link>

                <.link
                  :if={@user.mastodon_handle}
                  href={mastodon_url(@user.mastodon_handle)}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="btn btn-outline btn-xs gap-1"
                >
                  <.icon name="hero-chat-bubble-left-right" class="h-3 w-3" /> Mastodon
                </.link>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Recent Posts Highlight -->
        <div :if={@recent_posts != []} class="my-[var(--spacing-lg)]">
          <h2 class="text-[var(--font-size-fluid-lg)] mb-[var(--spacing-card)] flex items-center gap-2 font-bold">
            <.icon name="hero-sparkles" class="h-5 w-5" /> Recent Posts
          </h2>

          <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
            <.link
              :for={post <- @recent_posts}
              navigate={~p"/posts/#{post}"}
              class="card card-compact bg-base-200 group transition-colors hover:bg-base-300"
            >
              <div class="card-body p-4">
                <h3 class="line-clamp-2 mb-2 text-base font-semibold transition-colors group-hover:text-primary">
                  {post.title}
                </h3>
                <p class="text-base-content/60 line-clamp-3 mb-3 text-xs">
                  {String.slice(post.body, 0..120)}{if String.length(post.body) > 120,
                    do: "..."}
                </p>
                <div class="text-base-content/50 mt-auto flex items-center gap-2 text-xs">
                  <time>
                    {Calendar.strftime(post.published_at, "%b %d")}
                  </time>
                  <span>·</span>
                  <span>{post.read_time_minutes} min</span>
                </div>
              </div>
            </.link>
          </div>
        </div>
        
    <!-- Stats & Actions - Column layout -->
        <div class="bg-base-200 my-[var(--spacing-md)] rounded-lg p-4">
          <%!-- Stats in columns --%>
          <div class="mb-3 grid grid-cols-3 gap-4 text-center text-sm">
            <div>
              <div class="text-primary text-xl font-bold">{@stats.posts_count}</div>
              <div class="text-base-content/60 text-xs">posts</div>
            </div>
            <div>
              <div class="text-secondary text-xl font-bold">{@stats.avg_read_time}</div>
              <div class="text-base-content/60 text-xs">min avg</div>
            </div>
            <div>
              <div class="text-accent text-xl font-bold">{@stats.member_since}</div>
              <div class="text-base-content/60 text-xs">since</div>
            </div>
          </div>

          <%!-- Actions row --%>
          <div class="border-base-300 flex flex-wrap justify-center gap-2 border-t pt-3">
            <%= if @user.username do %>
              <a href={~p"/users/@#{@user.username}/rss.xml"} class="btn btn-xs btn-ghost gap-1">
                <.icon name="hero-rss" class="h-3 w-3" /> RSS
              </a>
            <% else %>
              <a href={~p"/users/#{@user.id}/rss.xml"} class="btn btn-xs btn-ghost gap-1">
                <.icon name="hero-rss" class="h-3 w-3" /> RSS
              </a>
            <% end %>
            <button type="button" phx-click="share_profile" class="btn btn-xs btn-ghost gap-1">
              <.icon name="hero-share" class="h-3 w-3" /> Share
            </button>
            <button type="button" phx-click="copy_profile_url" class="btn btn-xs btn-ghost gap-1">
              <.icon name="hero-clipboard" class="h-3 w-3" /> Copy
            </button>
          </div>
        </div>
        
    <!-- What I'm Reading Section -->
        <div :if={@feed_sources != []} class="my-[var(--spacing-md)]">
          <h2 class="text-base-content/60 mb-2 flex items-center gap-2 text-sm font-medium">
            <.icon name="hero-newspaper" class="h-4 w-4" /> What I'm Reading
          </h2>

          <div class="flex flex-wrap gap-2">
            <a
              :for={source <- @feed_sources}
              href={source.url}
              target="_blank"
              rel="noopener noreferrer"
              class="border-base-300 inline-flex items-center gap-1.5 rounded-full border px-3 py-1 text-sm transition-colors hover:border-primary hover:text-primary"
            >
              <span>{source.icon}</span>
              <span class="font-medium">{source.name}</span>
            </a>
          </div>
        </div>

        <div class="divider"></div>

        <div :if={@posts != []} class="my-[var(--spacing-lg)]">
          <h2 class="text-[var(--font-size-fluid-lg)] mb-3 font-bold">
            Published Posts
          </h2>

          <div class="divide-base-300 divide-y">
            <article :for={post <- @posts} class="flex items-end gap-4 py-3">
              <div class="min-w-0 flex-1">
                <.link navigate={~p"/posts/#{post}"} class="group">
                  <h3 class="text-base font-semibold transition-colors group-hover:text-primary">
                    {post.title}
                  </h3>
                </.link>

                <div class="text-base-content/60 mt-1 flex items-center gap-2 text-xs">
                  <time>{Calendar.strftime(post.published_at, "%B %d, %Y")}</time>
                  <span>·</span>
                  <span>{post.read_time_minutes} min</span>
                </div>

                <p class="text-base-content/70 line-clamp-2 mt-1 text-sm">
                  {String.slice(post.body, 0..150)}{if String.length(post.body) > 150, do: "..."}
                </p>
              </div>

              <div class="shrink-0">
                <.link navigate={~p"/posts/#{post}"} class="btn btn-primary btn-sm">
                  Read more
                </.link>
              </div>
            </article>
          </div>

          <%!-- Load More Button --%>
          <%= if @has_more_posts do %>
            <div class="mt-[var(--spacing-lg)] text-center">
              <button phx-click="load_more_posts" class="btn btn-outline btn-wide">
                {gettext("Load More Posts")}
              </button>
            </div>
          <% end %>
        </div>

        <div :if={@posts == []} class="my-[var(--spacing-xl)] text-center text-gray-600">
          <p class="text-[var(--font-size-fluid-base)]">No published posts yet.</p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"user_identifier" => user_identifier}, _session, socket) do
    case Accounts.get_user_by_identifier(user_identifier) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "User not found")
         |> redirect(to: ~p"/")}

      user ->
        # Get all posts for stats calculation (we need total count)
        all_posts = Content.list_published_posts_for_user(user.id)

        # Get paginated posts for display
        posts = Content.list_published_posts_for_user(user.id, limit: @posts_per_page)

        # Get 6 most recent posts for highlight section (2 rows of 3 columns)
        recent_posts = Enum.take(all_posts, 6)

        # Load user's public feed sources (what they're reading)
        user_scope = Homesite.Accounts.Scope.for_user(user)

        feed_sources =
          ExternalFeeds.list_feed_sources(user_scope)
          |> Enum.filter(& &1.enabled)
          |> Enum.sort_by(& &1.display_order)
          |> Enum.take(12)

        # Calculate profile stats (using all posts)
        stats = %{
          posts_count: length(all_posts),
          member_since: Calendar.strftime(user.inserted_at, "%B %Y"),
          total_words: calculate_total_words(all_posts),
          avg_read_time: calculate_avg_read_time(all_posts)
        }

        {:ok,
         socket
         |> assign(:page_title, user.display_name || "User Profile")
         |> assign(:user, user)
         |> assign(:posts, posts)
         |> assign(:recent_posts, recent_posts)
         |> assign(:feed_sources, feed_sources)
         |> assign(:stats, stats)
         |> assign(:has_more_posts, length(posts) == @posts_per_page)}
    end
  end

  @impl true
  def handle_event("load_more_posts", _params, socket) do
    user = socket.assigns.user
    current_count = length(socket.assigns.posts)

    new_posts =
      Content.list_published_posts_for_user(user.id,
        limit: @posts_per_page,
        offset: current_count
      )

    all_posts = socket.assigns.posts ++ new_posts
    has_more = length(new_posts) == @posts_per_page

    {:noreply, assign(socket, posts: all_posts, has_more_posts: has_more)}
  end

  @impl true
  def handle_event("share_profile", _params, socket) do
    user = socket.assigns.user
    profile_url = url(~p"/users/#{if user.username, do: "@#{user.username}", else: user.id}")
    title = "#{user.display_name || user.username || "User"}'s Blog"

    {:noreply,
     push_event(socket, "share", %{
       title: title,
       text: "Check out #{title}",
       url: profile_url
     })}
  end

  def handle_event("copy_profile_url", _params, socket) do
    user = socket.assigns.user
    profile_url = url(~p"/users/#{if user.username, do: "@#{user.username}", else: user.id}")

    {:noreply,
     socket
     |> put_flash(:info, "Profile URL copied!")
     |> push_event("copy-to-clipboard", %{text: profile_url})}
  end

  defp calculate_total_words(posts) do
    posts
    |> Enum.map(& &1.body)
    |> Enum.map(&(String.split(&1) |> length()))
    |> Enum.sum()
  end

  defp calculate_avg_read_time(posts) do
    if length(posts) > 0 do
      total = Enum.sum(Enum.map(posts, & &1.read_time_minutes))
      div(total, length(posts))
    else
      0
    end
  end

  defp has_social_links?(user) do
    user.website_url || user.bluesky_handle || user.mastodon_handle
  end

  defp mastodon_url(handle) do
    # Handle format: @username@instance.social
    case String.split(String.trim_leading(handle, "@"), "@") do
      [username, instance] -> "https://#{instance}/@#{username}"
      [username] -> "https://mastodon.social/@#{username}"
      _ -> "#"
    end
  end
end
