defmodule HomesiteWeb.TagLive.Form do
  use HomesiteWeb, :live_view

  alias Homesite.Content
  alias Homesite.Content.Tag

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>{gettext("Use this form to manage tag records in your database.")}</:subtitle>
      </.header>

      <.form for={@form} id="tag-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label={gettext("Name")} />
        <.input field={@form[:slug]} type="text" label={gettext("Slug")} />
        <.input field={@form[:is_public]} type="checkbox" label={gettext("Is public")} />
        <footer>
          <.button phx-disable-with={gettext("Saving...")} variant="primary">
            {gettext("Save Tag")}
          </.button>
          <.button navigate={return_path(@current_scope, @return_to, @tag)}>
            {gettext("Cancel")}
          </.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    tag = Content.get_tag!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, gettext("Edit Tag"))
    |> assign(:tag, tag)
    |> assign(:form, to_form(Content.change_tag(socket.assigns.current_scope, tag)))
  end

  defp apply_action(socket, :new, _params) do
    tag = %Tag{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, gettext("New Tag"))
    |> assign(:tag, tag)
    |> assign(:form, to_form(Content.change_tag(socket.assigns.current_scope, tag)))
  end

  @impl true
  def handle_event("validate", %{"tag" => tag_params}, socket) do
    changeset = Content.change_tag(socket.assigns.current_scope, socket.assigns.tag, tag_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"tag" => tag_params}, socket) do
    save_tag(socket, socket.assigns.live_action, tag_params)
  end

  defp save_tag(socket, :edit, tag_params) do
    case Content.update_tag(socket.assigns.current_scope, socket.assigns.tag, tag_params) do
      {:ok, tag} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Tag updated successfully"))
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, tag)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_tag(socket, :new, tag_params) do
    case Content.create_tag(socket.assigns.current_scope, tag_params) do
      {:ok, tag} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Tag created successfully"))
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, tag)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _tag), do: ~p"/tags"
  defp return_path(_scope, "show", tag), do: ~p"/tags/#{tag}"
end
