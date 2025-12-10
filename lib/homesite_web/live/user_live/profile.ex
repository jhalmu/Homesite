defmodule HomesiteWeb.UserLive.Profile do
  @moduledoc """
  Public profile page for viewing user information and their published posts.
  """
  use HomesiteWeb, :live_view

  import HomesiteWeb.Helpers.DateHelpers

  alias Homesite.Accounts
  alias Homesite.Accounts.Scope
  alias Homesite.Content
  alias Homesite.ExternalFeeds
  alias Homesite.Media

  import HomesiteWeb.MediaComponents, only: [project_card: 1]

  @posts_per_page 10

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={assigns[:current_scope]}>
      <div class="w-[min(95vw,800px)] mx-auto">
        <%!-- Profile Header - Compact layout with avatar beside bio --%>
        <div class="my-[var(--space-lg)]">
          <div class="gap-[var(--space-sm)] flex flex-col items-center sm:flex-row sm:items-start">
            <.avatar user={@user} class="h-20 w-20 shrink-0 sm:h-24 sm:w-24" />

            <div class="flex-1 text-center sm:text-left">
              <h1 class="text-[var(--font-size-fluid-xl)] font-bold">
                {@user.display_name || String.split(@user.email, "@") |> List.first()}
              </h1>

              <p
                :if={@user.bio}
                class="text-base-content/80 mt-[var(--space-xs)] text-[var(--text-sm)] whitespace-pre-wrap"
              >
                {@user.bio}
              </p>

              <%!-- Social links inline --%>
              <div
                :if={has_social_links?(@user)}
                class="mt-[var(--space-sm)] gap-[var(--space-xs)] flex flex-wrap justify-center sm:justify-start"
              >
                <.link
                  :if={@user.website_url}
                  href={@user.website_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="btn btn-outline btn-xs gap-[var(--space-inline)]"
                >
                  <.icon name="hero-globe-alt" class="h-3 w-3" /> Website
                </.link>

                <.link
                  :if={@user.bluesky_handle}
                  href={"https://bsky.app/profile/#{String.trim_leading(@user.bluesky_handle, "@")}"}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="btn btn-outline btn-xs gap-[var(--space-inline)]"
                >
                  <.icon name="hero-cloud" class="h-3 w-3" /> Bluesky
                </.link>

                <.link
                  :if={@user.mastodon_handle}
                  href={mastodon_url(@user.mastodon_handle)}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="btn btn-outline btn-xs gap-[var(--space-inline)]"
                >
                  <.icon name="hero-chat-bubble-left-right" class="h-3 w-3" /> Mastodon
                </.link>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Recent Posts Highlight -->
        <div :if={@recent_posts != []} class="my-[var(--space-lg)]">
          <h2 class="text-[var(--font-size-fluid-lg)] mb-[var(--space-md)] gap-[var(--space-xs)] flex items-center font-bold">
            <.icon name="hero-sparkles" class="h-5 w-5" /> Recent Posts
          </h2>

          <div class="gap-[var(--space-sm)] grid grid-cols-1 md:grid-cols-3">
            <.link
              :for={post <- @recent_posts}
              navigate={~p"/posts/#{post}"}
              class="card card-compact bg-base-200 group transition-colors hover:bg-base-300"
            >
              <div class="card-body p-[var(--space-sm)]">
                <h3 class="line-clamp-2 mb-[var(--space-xs)] text-[var(--text-base)]font-semibold transition-colors group-hover:text-primary">
                  {post.title}
                </h3>
                <p class="text-base-content/60 line-clamp-3 mb-[var(--space-sm)] text-[var(--text-xs)]">
                  {String.slice(post.body, 0..120)}{if String.length(post.body) > 120,
                    do: "..."}
                </p>
                <div class="text-base-content/70 gap-[var(--space-xs)] text-[var(--text-xs)] mt-auto flex items-center">
                  <time>
                    {format_date_short(post.published_at)}
                  </time>
                  <span>·</span>
                  <span>{post.read_time_minutes} min</span>
                </div>
              </div>
            </.link>
          </div>
        </div>
        
    <!-- Projects Section -->
        <div :if={@projects != []} class="my-[var(--space-lg)]">
          <div class="mb-[var(--space-md)] flex items-center justify-between">
            <h2 class="text-[var(--font-size-fluid-lg)] gap-[var(--space-xs)] flex items-center font-bold">
              <.icon name="hero-folder" class="h-5 w-5" /> Projects
            </h2>
            <%= if @user.username do %>
              <.link
                navigate={~p"/users/@#{@user.username}/projects"}
                class="link link-primary text-[var(--text-sm)]"
              >
                {gettext("View all")} →
              </.link>
            <% else %>
              <.link
                navigate={~p"/users/#{@user.id}/projects"}
                class="link link-primary text-[var(--text-sm)]"
              >
                {gettext("View all")} →
              </.link>
            <% end %>
          </div>

          <div class="gap-[var(--space-sm)] grid grid-cols-2 md:grid-cols-3">
            <.project_card :for={project <- @projects} project={project} />
          </div>
        </div>
        
    <!-- Stats & Actions - Column layout -->
        <div class="bg-base-200 my-[var(--space-md)] p-[var(--space-sm)] rounded-lg">
          <%!-- Stats in columns --%>
          <div class="mb-[var(--space-sm)] gap-[var(--space-sm)] text-[var(--text-sm)] grid grid-cols-3 text-center">
            <div>
              <div class="text-primary text-[var(--text-xl)]font-bold">{@stats.posts_count}</div>
              <div class="text-base-content/60 text-[var(--text-xs)]">posts</div>
            </div>
            <div>
              <div class="text-secondary text-[var(--text-xl)]font-bold">{@stats.avg_read_time}</div>
              <div class="text-base-content/60 text-[var(--text-xs)]">min avg</div>
            </div>
            <div>
              <div class="text-accent text-[var(--text-xl)]font-bold">{@stats.member_since}</div>
              <div class="text-base-content/60 text-[var(--text-xs)]">since</div>
            </div>
          </div>

          <%!-- Actions row --%>
          <div class="border-base-300 gap-[var(--space-xs)] pt-[var(--space-sm)] flex flex-wrap justify-center border-t">
            <%= if @user.username do %>
              <a
                href={~p"/users/@#{@user.username}/rss.xml"}
                class="btn btn-xs btn-ghost gap-[var(--space-inline)]"
              >
                <.icon name="hero-rss" class="h-3 w-3" /> RSS
              </a>
            <% else %>
              <a
                href={~p"/users/#{@user.id}/rss.xml"}
                class="btn btn-xs btn-ghost gap-[var(--space-inline)]"
              >
                <.icon name="hero-rss" class="h-3 w-3" /> RSS
              </a>
            <% end %>
            <button
              type="button"
              phx-click="share_profile"
              class="btn btn-xs btn-ghost gap-[var(--space-inline)]"
            >
              <.icon name="hero-share" class="h-3 w-3" /> Share
            </button>
            <button
              type="button"
              phx-click="copy_profile_url"
              class="btn btn-xs btn-ghost gap-[var(--space-inline)]"
            >
              <.icon name="hero-clipboard" class="h-3 w-3" /> Copy
            </button>
          </div>
        </div>
        
    <!-- What I'm Reading Section -->
        <div :if={@feed_sources != []} class="my-[var(--space-md)]">
          <h2 class="text-base-content/60 mb-[var(--space-xs)] gap-[var(--space-xs)] text-[var(--text-sm)] flex items-center font-medium">
            <.icon name="hero-newspaper" class="h-4 w-4" /> What I'm Reading
          </h2>

          <div class="gap-[var(--space-xs)] flex flex-wrap">
            <a
              :for={source <- @feed_sources}
              href={source.url}
              target="_blank"
              rel="noopener noreferrer"
              class="border-base-300 gap-[var(--space-inline)] px-[var(--space-sm)] py-[var(--space-inline)] text-[var(--text-sm)] inline-flex items-center rounded-full border transition-colors hover:border-primary hover:text-primary"
            >
              <span>{source.icon}</span>
              <span class="font-medium">{source.name}</span>
            </a>
          </div>
        </div>

        <div class="divider"></div>

        <div :if={@posts != []} class="my-[var(--space-lg)]">
          <h2 class="text-[var(--font-size-fluid-lg)] mb-[var(--space-sm)] font-bold">
            Published Posts
          </h2>

          <div class="divide-base-300 divide-y">
            <article
              :for={post <- @posts}
              class="gap-[var(--space-sm)] py-[var(--space-sm)] flex items-end"
            >
              <div class="min-w-0 flex-1">
                <.link navigate={~p"/posts/#{post}"} class="group">
                  <h3 class="text-base font-semibold transition-colors group-hover:text-primary">
                    {post.title}
                  </h3>
                </.link>

                <div class="text-base-content/60 mt-[var(--space-inline)] gap-[var(--space-xs)] text-[var(--text-xs)] flex items-center">
                  <time>{format_date(post.published_at)}</time>
                  <span>·</span>
                  <span>{post.read_time_minutes} min</span>
                </div>

                <p class="text-base-content/70 line-clamp-2 mt-[var(--space-inline)] text-[var(--text-sm)]">
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
            <div class="mt-[var(--space-lg)] text-center">
              <button phx-click="load_more_posts" class="btn btn-outline btn-wide">
                {gettext("Load More Posts")}
              </button>
            </div>
          <% end %>
        </div>

        <div :if={@posts == []} class="my-[var(--space-lg)] text-center text-gray-600">
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
        user_scope = Scope.for_user(user)

        feed_sources =
          ExternalFeeds.list_feed_sources(user_scope)
          |> Enum.filter(& &1.enabled)
          |> Enum.sort_by(& &1.display_order)
          |> Enum.take(12)

        # Load user's public projects (max 6 for profile)
        projects = Media.list_public_projects_for_user(user.id, limit: 6)

        # Calculate profile stats (using all posts)
        stats = %{
          posts_count: length(all_posts),
          member_since: format_month_year(user.inserted_at),
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
         |> assign(:projects, projects)
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
