defmodule HomesiteWeb.UserLive.Profile do
  @moduledoc """
  Public profile page for viewing user information and their published posts.
  """
  use HomesiteWeb, :live_view

  alias Homesite.Accounts
  alias Homesite.Content

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
  def mount(%{"id" => id}, _session, socket) do
    user = Accounts.get_user!(id)
    posts = Content.list_published_posts_for_user(user.id)

    {:ok,
     socket
     |> assign(:page_title, user.display_name || "User Profile")
     |> assign(:user, user)
     |> assign(:posts, posts)}
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
