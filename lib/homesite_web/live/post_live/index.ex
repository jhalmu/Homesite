defmodule HomesiteWeb.PostLive.Index do
  use HomesiteWeb, :live_view

  # Gettext is used in ~H sigil templates (compiler can't detect usage in templates)
  import HomesiteWeb.Gettext

  alias Homesite.Content

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
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

      <.table
        id="posts"
        rows={@streams.posts}
        row_click={fn {_id, post} -> JS.navigate(~p"/posts/#{post}") end}
      >
        <:col :let={{_id, post}} label={gettext("Title")}>{post.title}</:col>
        <:col :let={{_id, post}} label={gettext("Body")}>{post.body}</:col>
        <:col :let={{_id, post}} label={gettext("Slug")}>{post.slug}</:col>
        <:col :let={{_id, post}} label={gettext("Published at")}>{post.published_at}</:col>
        <:action :let={{_id, post}}>
          <div class="sr-only">
            <.link navigate={~p"/posts/#{post}"}>{gettext("Show")}</.link>
          </div>
          <%= if @current_scope && post.user_id == @current_scope.user.id do %>
            <.link navigate={~p"/posts/#{post}/edit"}>{gettext("Edit")}</.link>
          <% end %>
        </:action>
        <:action :let={{id, post}}>
          <%= if @current_scope && post.user_id == @current_scope.user.id do %>
            <.link
              phx-click={JS.push("delete", value: %{id: post.id}) |> hide("##{id}")}
              data-confirm={gettext("Are you sure?")}
            >
              {gettext("Delete")}
            </.link>
          <% end %>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    current_scope = socket.assigns.current_scope

    if connected?(socket) && current_scope do
      Content.subscribe_posts(current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, gettext("Listing Posts"))
     |> stream(:posts, list_posts(current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Content.get_post!(socket.assigns.current_scope, id)
    {:ok, _} = Content.delete_post(socket.assigns.current_scope, post)

    {:noreply, stream_delete(socket, :posts, post)}
  end

  @impl true
  def handle_info({type, %Homesite.Content.Post{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :posts, list_posts(socket.assigns.current_scope), reset: true)}
  end

  defp list_posts(nil) do
    # Non-authenticated users see only public posts
    Content.list_public_posts()
  end

  defp list_posts(current_scope) do
    # Authenticated users see their own posts
    Content.list_posts(current_scope)
  end
end
