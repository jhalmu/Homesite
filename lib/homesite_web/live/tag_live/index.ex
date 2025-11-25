defmodule HomesiteWeb.TagLive.Index do
  use HomesiteWeb, :live_view

  alias Homesite.Content

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Listing Tags")}
        <:actions>
          <.button variant="primary" navigate={~p"/tags/new"}>
            <.icon name="hero-plus" /> {gettext("New Tag")}
          </.button>
        </:actions>
      </.header>

      <.table
        id="tags"
        rows={@streams.tags}
        row_click={fn {_id, tag} -> JS.navigate(~p"/tags/#{tag}") end}
      >
        <:col :let={{_id, tag}} label={gettext("Name")}>{tag.name}</:col>
        <:col :let={{_id, tag}} label={gettext("Slug")}>{tag.slug}</:col>
        <:col :let={{_id, tag}} label={gettext("Is public")}>{tag.is_public}</:col>
        <:action :let={{_id, tag}}>
          <div class="sr-only">
            <.link navigate={~p"/tags/#{tag}"}>{gettext("Show")}</.link>
          </div>
          <.link navigate={~p"/tags/#{tag}/edit"}>{gettext("Edit")}</.link>
        </:action>
        <:action :let={{id, tag}}>
          <.link
            phx-click={JS.push("delete", value: %{id: tag.id}) |> hide("##{id}")}
            data-confirm={gettext("Are you sure?")}
          >
            {gettext("Delete")}
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Content.subscribe_tags(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, gettext("Listing Tags"))
     |> stream(:tags, list_tags(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    tag = Content.get_tag!(socket.assigns.current_scope, id)
    {:ok, _} = Content.delete_tag(socket.assigns.current_scope, tag)

    {:noreply, stream_delete(socket, :tags, tag)}
  end

  @impl true
  def handle_info({type, %Homesite.Content.Tag{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :tags, list_tags(socket.assigns.current_scope), reset: true)}
  end

  defp list_tags(current_scope) do
    Content.list_tags(current_scope)
  end
end
