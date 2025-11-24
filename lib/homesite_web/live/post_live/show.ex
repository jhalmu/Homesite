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

      <div class="my-[clamp(1.5rem,4vw,3rem)] prose max-w-none whitespace-pre-wrap">
        {@post.body}
      </div>

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Body">{@post.body}</:item>
        <:item title="Slug">{@post.slug}</:item>
        <:item title="Published at">{@post.published_at}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Content.subscribe_posts(socket.assigns.current_scope)
    end

    post = Content.get_post_by_id!(socket.assigns.current_scope, id)
    current_user_id = socket.assigns.current_scope.user.id
    can_edit = post.user_id == current_user_id

    {:ok,
     socket
     |> assign(:page_title, "Show Post")
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
