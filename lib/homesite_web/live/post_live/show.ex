defmodule HomesiteWeb.PostLive.Show do
  use HomesiteWeb, :live_view

  alias Homesite.Content

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@post.title}
        <:subtitle>Published post</:subtitle>
        <:actions>
          <.button navigate={~p"/posts"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <%= if @can_edit do %>
            <.button variant="primary" navigate={~p"/posts/#{@post}/edit?return_to=show"}>
              <.icon name="hero-pencil-square" /> Edit post
            </.button>
          <% end %>
        </:actions>
      </.header>

      <div class="my-[clamp(1rem,3vw,2rem)]">
        <.author_byline user={@post.user} date={@post.published_at} />
      </div>

      <%= if @post.tags && length(@post.tags) > 0 do %>
        <div class="my-4 flex flex-wrap gap-2">
          <%= for tag <- @post.tags do %>
            <.link navigate={~p"/tags/#{tag.slug}"} class="badge badge-lg badge-primary gap-2">
              <.icon name="hero-tag" class="h-4 w-4" />
              {tag.name}
            </.link>
          <% end %>
        </div>
      <% end %>

      <div class="my-[clamp(1.5rem,4vw,3rem)] prose prose-slate max-w-none prose-pre:bg-gray-900 prose-pre:text-gray-100 dark:prose-invert">
        {Phoenix.HTML.raw(render_markdown(@post.body))}
      </div>
    </Layouts.app>
    """
  end

  defp render_markdown(markdown) do
    MDEx.to_html!(markdown,
      extension: [
        strikethrough: true,
        table: true,
        tasklist: true,
        autolink: true
      ],
      render: [
        unsafe_: true
      ],
      syntax_highlight: [
        formatter: {:html_inline, theme: "catppuccin_mocha"}
      ]
    )
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    current_scope = socket.assigns.current_scope

    # Fetch post based on authentication status
    post =
      if current_scope do
        # Authenticated: can see public posts + own posts
        if connected?(socket), do: Content.subscribe_posts(current_scope)
        Content.get_post_by_id!(current_scope, id)
      else
        # Not authenticated: can only see public posts
        Content.get_public_post!(id)
      end

    # Check if current user can edit (only if authenticated and is owner)
    can_edit = current_scope && post.user_id == current_scope.user.id

    {:ok,
     socket
     |> assign(:page_title, post.title)
     |> assign(:post, post)
     |> assign(:can_edit, can_edit)}
  end

  @impl true
  def handle_info(
        {:updated, %Homesite.Content.Post{id: id} = post},
        %{assigns: %{post: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :post, post)}
  end

  def handle_info(
        {:deleted, %Homesite.Content.Post{id: id}},
        %{assigns: %{post: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current post was deleted.")
     |> push_navigate(to: ~p"/posts")}
  end

  def handle_info({type, %Homesite.Content.Post{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
