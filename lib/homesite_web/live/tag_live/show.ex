defmodule HomesiteWeb.TagLive.Show do
  use HomesiteWeb, :live_view

  # Note: "unused import" warning is false positive - gettext() used in HEEx template
  import HomesiteWeb.Gettext

  alias Homesite.Content

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="px-[clamp(1rem,4vw,2rem)] py-[clamp(1.5rem,5vw,3rem)] container mx-auto">
        <!-- Header -->
        <div class="gap-[clamp(1rem,3vw,1.5rem)] mb-[clamp(2rem,5vw,3rem)] flex flex-col">
          <div class="flex flex-wrap items-center justify-between gap-4">
            <div class="flex items-center gap-4">
              <.link navigate={~p"/tags"} class="btn btn-circle btn-ghost">
                <.icon name="hero-arrow-left" class="h-6 w-6" />
              </.link>
              <div>
                <h1 class="text-[clamp(2rem,6vw,3rem)] font-bold">
                  {@tag.name}
                </h1>
                <p class="text-sm text-gray-600 dark:text-gray-400">
                  {gettext("Slug")}: {@tag.slug}
                  <%= if @tag.is_public do %>
                    <span class="badge badge-success ml-2">{gettext("Public")}</span>
                  <% else %>
                    <span class="badge badge-ghost ml-2">{gettext("Private")}</span>
                  <% end %>
                </p>
              </div>
            </div>
            <%= if @can_edit do %>
              <.link navigate={~p"/tags/#{@tag}/edit?return_to=show"} class="btn btn-primary gap-2">
                <.icon name="hero-pencil-square" class="h-5 w-5" /> {gettext("Edit Tag")}
              </.link>
            <% end %>
          </div>
        </div>

        <%= if @tag.description && @can_edit do %>
          <div class="mb-[clamp(2rem,5vw,3rem)]">
            <p class="text-base-content/70">{@tag.description}</p>
          </div>
        <% end %>
        
    <!-- User's Posts with this Tag -->
        <div class="mb-[clamp(2rem,5vw,3rem)]">
          <h2 class="text-[clamp(1.5rem,4vw,2rem)] mb-[clamp(1rem,3vw,1.5rem)] font-semibold">
            {gettext("Your Posts")}
          </h2>

          <div :if={length(@user_posts) == 0} class="alert alert-info">
            <.icon name="hero-information-circle" class="h-6 w-6" />
            <span>{gettext("You don't have any posts with this tag yet.")}</span>
          </div>

          <div :if={length(@user_posts) > 0} class="space-y-4">
            <%= for post <- @user_posts do %>
              <div class="card bg-base-200 shadow-md">
                <div class="card-body">
                  <h3 class="card-title">
                    <.link navigate={~p"/posts/#{post}"} class="link link-hover">
                      {post.title}
                    </.link>
                  </h3>
                  <p :if={post.body} class="line-clamp-2 text-sm">
                    {String.slice(post.body, 0, 150)}{if String.length(post.body) > 150, do: "..."}
                  </p>
                  <div class="card-actions items-center justify-between">
                    <div class="text-sm text-gray-600 dark:text-gray-400">
                      <%= if post.published_at do %>
                        {Calendar.strftime(post.published_at, "%B %d, %Y")}
                      <% else %>
                        <span class="badge badge-ghost">{gettext("Draft")}</span>
                      <% end %>
                    </div>
                    <div class="flex gap-2">
                      <.link navigate={~p"/posts/#{post}"} class="btn btn-sm btn-ghost">
                        {gettext("View")}
                      </.link>
                      <.link navigate={~p"/posts/#{post}/edit"} class="btn btn-sm btn-primary">
                        {gettext("Edit")}
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
          <h2 class="text-[clamp(1.5rem,4vw,2rem)] mb-[clamp(1rem,3vw,1.5rem)] font-semibold">
            {gettext("Community Posts")}
          </h2>

          <div class="space-y-4">
            <%= for post <- @public_posts do %>
              <div class="card bg-base-200 shadow-md">
                <div class="card-body">
                  <div class="flex items-start justify-between gap-4">
                    <div class="flex-1">
                      <h3 class="card-title">
                        <.link navigate={~p"/users/#{post.user.id}"} class="link link-hover">
                          {post.title}
                        </.link>
                      </h3>
                      <.author_byline user={post.user} date={post.published_at} class="mt-2" />
                    </div>
                  </div>
                  <p :if={post.body} class="line-clamp-2 mt-2 text-sm">
                    {String.slice(post.body, 0, 150)}{if String.length(post.body) > 150, do: "..."}
                  </p>
                  <div class="card-actions justify-end">
                    <.link navigate={~p"/users/#{post.user.id}"} class="btn btn-sm btn-ghost">
                      {gettext("View Profile")}
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
  def mount(%{"id" => slug}, _session, socket) do
    scope = socket.assigns.current_scope

    if connected?(socket) && scope do
      Content.subscribe_tags(scope)
    end

    # Get tag by slug (public access, no scope required)
    tag = Content.get_tag_by_slug!(slug)

    # Check if current user can edit (only if authenticated and is owner)
    can_edit = scope && tag.user_id == scope.user.id

    # Get posts with this tag
    {user_posts, public_posts} =
      if scope do
        {
          Content.list_user_posts_by_tag(scope, tag.id),
          Content.list_public_posts_by_tag(tag.id, scope.user.id)
        }
      else
        # Not authenticated: show only public posts
        {[], Content.list_public_posts_by_tag(tag.id, nil)}
      end

    {:ok,
     socket
     |> assign(:page_title, "#{gettext("Tag")}: #{tag.name}")
     |> assign(:tag, tag)
     |> assign(:can_edit, can_edit)
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
     |> put_flash(:error, gettext("The current tag was deleted."))
     |> push_navigate(to: ~p"/tags")}
  end

  def handle_info({type, %Homesite.Content.Tag{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
