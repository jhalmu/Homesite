defmodule HomesiteWeb.UserLive.Profile do
  @moduledoc """
  Public profile page for viewing user information and their published posts.
  """
  use HomesiteWeb, :live_view

  alias Homesite.Accounts
  alias Homesite.Content
  alias Homesite.ExternalFeeds

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={assigns[:current_scope]}>
      <div class="w-[min(95vw,800px)] mx-auto">
        <div class="gap-[var(--spacing-card)] my-[var(--spacing-xl)] flex flex-col items-center">
          <.avatar user={@user} class="h-32 w-32" />

          <div class="text-center">
            <h1 class="text-[var(--font-size-fluid-xl)] font-bold">
              {@user.display_name || String.split(@user.email, "@") |> List.first()}
            </h1>
          </div>

          <p
            :if={@user.bio}
            class="text-[var(--font-size-fluid-base)] max-w-prose whitespace-pre-wrap text-center"
          >
            {@user.bio}
          </p>

          <div
            :if={has_social_links?(@user)}
            class="gap-[var(--spacing-card)] flex flex-wrap justify-center"
          >
            <.link
              :if={@user.website_url}
              href={@user.website_url}
              target="_blank"
              rel="noopener noreferrer"
              class="btn btn-outline btn-sm gap-2"
            >
              <.icon name="hero-globe-alt" class="h-4 w-4" /> Website
            </.link>

            <.link
              :if={@user.bluesky_handle}
              href={"https://bsky.app/profile/#{String.trim_leading(@user.bluesky_handle, "@")}"}
              target="_blank"
              rel="noopener noreferrer"
              class="btn btn-outline btn-sm gap-2"
            >
              <.icon name="hero-cloud" class="h-4 w-4" /> Bluesky
            </.link>

            <.link
              :if={@user.mastodon_handle}
              href={mastodon_url(@user.mastodon_handle)}
              target="_blank"
              rel="noopener noreferrer"
              class="btn btn-outline btn-sm gap-2"
            >
              <.icon name="hero-chat-bubble-left-right" class="h-4 w-4" /> Mastodon
            </.link>
          </div>
        </div>

        <!-- Recent Posts Highlight -->
        <div :if={@recent_posts != []} class="my-[var(--spacing-lg)]">
          <h2 class="text-[var(--font-size-fluid-lg)] mb-[var(--spacing-card)] font-bold flex items-center gap-2">
            <.icon name="hero-sparkles" class="w-5 h-5" />
            Recent Posts
          </h2>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <.link
              :for={post <- @recent_posts}
              navigate={~p"/posts/#{post}"}
              class="card card-compact bg-base-200 hover:bg-base-300 transition-colors group"
            >
              <div class="card-body p-4">
                <h3 class="font-semibold text-base line-clamp-2 mb-2 group-hover:text-primary transition-colors">
                  <%= post.title %>
                </h3>
                <p class="text-xs text-base-content/60 line-clamp-3 mb-3">
                  <%= String.slice(post.body, 0..120) %><%= if String.length(post.body) > 120,
                    do: "..." %>
                </p>
                <div class="flex items-center gap-2 text-xs text-base-content/50 mt-auto">
                  <time>
                    <%= Calendar.strftime(post.published_at, "%b %d") %>
                  </time>
                  <span>·</span>
                  <span><%= post.read_time_minutes %> min</span>
                </div>
              </div>
            </.link>
          </div>
        </div>

        <!-- Stats Section -->
        <div class="stats stats-vertical lg:stats-horizontal shadow w-full my-[var(--spacing-lg)]">
          <div class="stat">
            <div class="stat-figure text-primary">
              <.icon name="hero-document-text" class="w-8 h-8" />
            </div>
            <div class="stat-title">Published Posts</div>
            <div class="stat-value text-primary"><%= @stats.posts_count %></div>
            <div class="stat-desc"><%= @stats.total_words %> total words</div>
          </div>

          <div class="stat">
            <div class="stat-figure text-secondary">
              <.icon name="hero-clock" class="w-8 h-8" />
            </div>
            <div class="stat-title">Avg Read Time</div>
            <div class="stat-value text-secondary"><%= @stats.avg_read_time %> min</div>
            <div class="stat-desc">per post</div>
          </div>

          <div class="stat">
            <div class="stat-figure text-accent">
              <.icon name="hero-calendar" class="w-8 h-8" />
            </div>
            <div class="stat-title">Member Since</div>
            <div class="stat-value text-accent text-lg"><%= @stats.member_since %></div>
          </div>
        </div>

        <!-- Subscribe Section -->
        <div class="card bg-base-200 shadow-xl">
          <div class="card-body">
            <h3 class="card-title">
              <.icon name="hero-rss" class="w-6 h-6" />
              Subscribe to Updates
            </h3>
            <p class="text-base-content/70">
              Get notified when <%= @user.display_name || @user.username %> publishes new posts.
            </p>

            <div class="flex flex-wrap gap-2 mt-4">
              <%= if @user.username do %>
                <a href={~p"/users/@#{@user.username}/rss.xml"} class="btn btn-sm btn-primary">
                  <.icon name="hero-rss" class="w-4 h-4" />
                  RSS Feed
                </a>
                <a href={~p"/users/@#{@user.username}/feed.xml"} class="btn btn-sm btn-outline">
                  Atom Feed
                </a>
                <a href={~p"/users/@#{@user.username}/feed.json"} class="btn btn-sm btn-outline">
                  JSON Feed
                </a>
              <% else %>
                <a href={~p"/users/#{@user.id}/rss.xml"} class="btn btn-sm btn-primary">
                  <.icon name="hero-rss" class="w-4 h-4" />
                  RSS Feed
                </a>
              <% end %>
            </div>
          </div>
        </div>

        <!-- Share Profile Section -->
        <div class="mt-[var(--spacing-lg)] flex gap-3">
          <button
            type="button"
            phx-click="share_profile"
            class="btn btn-primary flex-1"
          >
            <.icon name="hero-share" class="w-5 h-5" />
            Share Profile
          </button>
          <button
            type="button"
            phx-click="copy_profile_url"
            class="btn btn-outline"
          >
            <.icon name="hero-clipboard" class="w-5 h-5" />
            Copy Link
          </button>
        </div>

        <!-- What I'm Reading Section -->
        <div :if={@feed_sources != []} class="mt-[var(--spacing-xl)]">
          <div class="divider">
            <h2 class="text-[var(--font-size-fluid-lg)] font-bold flex items-center gap-2">
              <.icon name="hero-newspaper" class="w-6 h-6" />
              What I'm Reading
            </h2>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
            <a
              :for={source <- @feed_sources}
              href={source.url}
              target="_blank"
              rel="noopener noreferrer"
              class="card card-compact bg-base-200 hover:bg-base-300 transition-colors"
            >
              <div class="card-body">
                <div class="flex items-center gap-3">
                  <span class="text-2xl"><%= source.icon %></span>
                  <div class="flex-1 min-w-0">
                    <h3 class="font-semibold truncate"><%= source.name %></h3>
                    <p class="text-xs text-base-content/60 truncate">
                      <%= source.feed_type |> String.upcase() %> Feed
                    </p>
                  </div>
                  <.icon name="hero-arrow-top-right-on-square" class="w-4 h-4 text-base-content/40" />
                </div>
              </div>
            </a>
          </div>
        </div>

        <div class="divider"></div>

        <div :if={@posts != []} class="my-[var(--spacing-xl)]">
          <h2 class="text-[var(--font-size-fluid-lg)] mb-[var(--spacing-card)] font-bold">
            Published Posts
          </h2>

          <div class="gap-[var(--spacing-lg)] grid">
            <article
              :for={post <- @posts}
              class="card bg-base-100 shadow-lg transition-shadow hover:shadow-xl"
            >
              <div class="card-body">
                <h3 class="card-title text-[var(--font-size-fluid-lg)]">
                  <.link navigate={~p"/posts/#{post}"} class="hover:underline">
                    {post.title}
                  </.link>
                </h3>

                <time class="text-sm text-gray-600 dark:text-gray-400">
                  {Calendar.strftime(post.published_at, "%B %d, %Y")}
                </time>

                <p class="text-[var(--font-size-fluid-sm)] line-clamp-3">
                  {String.slice(post.body, 0..200)}{if String.length(post.body) > 200, do: "..."}
                </p>

                <div class="card-actions mt-4 justify-end">
                  <.link navigate={~p"/posts/#{post}"} class="btn btn-primary btn-sm">
                    Read More
                  </.link>
                </div>
              </div>
            </article>
          </div>
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
        posts = Content.list_published_posts_for_user(user.id)

        # Get 6 most recent posts for highlight section (2 rows of 3 columns)
        recent_posts = Enum.take(posts, 6)

        # Load user's public feed sources (what they're reading)
        user_scope = Homesite.Accounts.Scope.for_user(user)

        feed_sources =
          ExternalFeeds.list_feed_sources(user_scope)
          |> Enum.filter(& &1.enabled)
          |> Enum.sort_by(& &1.display_order)
          |> Enum.take(12)

        # Calculate profile stats
        stats = %{
          posts_count: length(posts),
          member_since: Calendar.strftime(user.inserted_at, "%B %Y"),
          total_words: calculate_total_words(posts),
          avg_read_time: calculate_avg_read_time(posts)
        }

        {:ok,
         socket
         |> assign(:page_title, user.display_name || "User Profile")
         |> assign(:user, user)
         |> assign(:posts, posts)
         |> assign(:recent_posts, recent_posts)
         |> assign(:feed_sources, feed_sources)
         |> assign(:stats, stats)}
    end
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
