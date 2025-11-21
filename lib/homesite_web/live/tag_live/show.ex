defmodule HomesiteWeb.TagLive.Show do
  use HomesiteWeb, :live_view

  alias Homesite.Content

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Tag {@tag.id}
        <:subtitle>This is a tag record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/tags"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/tags/#{@tag}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit tag
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@tag.name}</:item>
        <:item title="Slug">{@tag.slug}</:item>
        <:item title="Is public">{@tag.is_public}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Content.subscribe_tags(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Tag")
     |> assign(:tag, Content.get_tag!(socket.assigns.current_scope, id))}
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
