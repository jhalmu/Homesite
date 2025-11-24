defmodule HomesiteWeb.TagLive.Show do
  use HomesiteWeb, :live_view

  alias Homesite.Content

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="container mx-auto px-[clamp(1rem,4vw,2rem)] py-[clamp(1.5rem,5vw,3rem)]">
        <!-- Header -->
        <div class="flex flex-col gap-[clamp(1rem,3vw,1.5rem)] mb-[clamp(2rem,5vw,3rem)]">
          <div class="flex items-center justify-between flex-wrap gap-4">
            <div class="flex items-center gap-4">
              <.link navigate={~p"/tags"} class="btn btn-circle btn-ghost">
                <.icon name="hero-arrow-left" class="w-6 h-6" />
              </.link>
              <div>
                <h1 class="text-[clamp(2rem,6vw,3rem)] font-bold">
                  {@tag.name}
                </h1>
                <p class="text-sm text-gray-600 dark:text-gray-400">
                  Slug: {@tag.slug}
                  <%= if @tag.is_public do %>
                    <span class="badge badge-success ml-2">Public</span>
                  <% else %>
                    <span class="badge badge-ghost ml-2">Private</span>
                  <% end %>
                </p>
              </div>
            </div>
            <.link navigate={~p"/tags/#{@tag}/edit?return_to=show"} class="btn btn-primary gap-2">
              <.icon name="hero-pencil-square" class="w-5 h-5" />
              Edit Tag
            </.link>
          </div>
        </div>

        <!-- User's Posts with this Tag -->
        <div class="mb-[clamp(2rem,5vw,3rem)]">
          <h2 class="text-[clamp(1.5rem,4vw,2rem)] font-semibold mb-[clamp(1rem,3vw,1.5rem)]">
            Your Posts
          </h2>

          <div :if={length(@user_posts) == 0} class="alert alert-info">
            <.icon name="hero-information-circle" class="w-6 h-6" />
            <span>You don't have any posts with this tag yet.</span>
          </div>

          <div :if={length(@user_posts) > 0} class="space-y-4">
            <%= for post <- @user_posts do %>
              <div class="card bg-base-200 shadow-md">
                <div class="card-body">
                  <h3 class="card-title">
                    <.link navigate={~p"/posts/#{post}"} class="link link-hover">
                      <%= post.title %>
                    </.link>
                  </h3>
                  <p :if={post.body} class="text-sm line-clamp-2">
                    <%= String.slice(post.body, 0, 150) %><%= if String.length(post.body) > 150, do: "..." %>
                  </p>
                  <div class="card-actions justify-between items-center">
                    <div class="text-sm text-gray-600 dark:text-gray-400">
                      <%= if post.published_at do %>
                        <%= Calendar.strftime(post.published_at, "%B %d, %Y") %>
                      <% else %>
                        <span class="badge badge-ghost">Draft</span>
                      <% end %>
                    </div>
                    <div class="flex gap-2">
                      <.link navigate={~p"/posts/#{post}"} class="btn btn-sm btn-ghost">
                        View
                      </.link>
                      <.link navigate={~p"/posts/#{post}/edit"} class="btn btn-sm btn-primary">
                        Edit
                      </.link>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <!-- Public Posts from Others -->
        <div :if={length(@public_posts) > 0}>
          <h2 class="text-[clamp(1.5rem,4vw,2rem)] font-semibold mb-[clamp(1rem,3vw,1.5rem)]">
            Community Posts
          </h2>

          <div class="space-y-4">
            <%= for post <- @public_posts do %>
              <div class="card bg-base-200 shadow-md">
                <div class="card-body">
                  <div class="flex items-start justify-between gap-4">
                    <div class="flex-1">
                      <h3 class="card-title">
                        <.link navigate={~p"/users/#{post.user.id}"} class="link link-hover">
                          <%= post.title %>
                        </.link>
                      </h3>
                      <.author_byline user={post.user} date={post.published_at} class="mt-2" />
                    </div>
                  </div>
                  <p :if={post.body} class="text-sm line-clamp-2 mt-2">
                    <%= String.slice(post.body, 0, 150) %><%= if String.length(post.body) > 150, do: "..." %>
                  </p>
                  <div class="card-actions justify-end">
                    <.link navigate={~p"/users/#{post.user.id}"} class="btn btn-sm btn-ghost">
                      View Profile
                    </.link>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    scope = socket.assigns.current_scope

    if connected?(socket) do
      Content.subscribe_tags(scope)
    end

    tag = Content.get_tag!(scope, id)
    user_posts = Content.list_user_posts_by_tag(scope, tag.id)
    public_posts = Content.list_public_posts_by_tag(tag.id, scope.user.id)

    {:ok,
     socket
     |> assign(:page_title, "Tag: #{tag.name}")
     |> assign(:tag, tag)
     |> assign(:user_posts, user_posts)
     |> assign(:public_posts, public_posts)}
  end

  @impl true
  def handle_info(
        {:updated, %Homesite.Content.Tag{id: id} = tag},
        %{assigns: %{tag: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :tag, tag)}
  end

  def handle_info(
        {:deleted, %Homesite.Content.Tag{id: id}},
        %{assigns: %{tag: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current tag was deleted.")
     |> push_navigate(to: ~p"/tags")}
  end

  def handle_info({type, %Homesite.Content.Tag{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
