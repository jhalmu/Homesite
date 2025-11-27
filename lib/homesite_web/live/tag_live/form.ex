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
        <div class="mb-4">
          <.input field={@form[:name]} type="text" label={gettext("Name")} />
          <%= if @form[:slug].value do %>
            <p class="text-base-content/60 mt-1 text-sm">
              <.icon name="hero-link" class="inline h-4 w-4" /> {gettext("Slug")}:
              <span class="font-mono">{@form[:slug].value}</span>
            </p>
          <% end %>
        </div>

        <.input
          field={@form[:description]}
          type="textarea"
          label={gettext("Description")}
          placeholder={gettext("Optional description for this tag")}
        />

        <div class="divider"></div>

        <div class="form-control">
          <label class="label cursor-pointer justify-start gap-3">
            <input
              type="checkbox"
              name={@form[:is_public].name}
              value="true"
              checked={@form[:is_public].value == true}
              class="toggle toggle-primary"
            />
            <span class="label-text font-semibold">{gettext("Make this tag publicly visible")}</span>
          </label>
          <p class="text-base-content/60 ml-14 text-sm">
            {gettext("Public tags can be seen by everyone. Turn off to make this tag private.")}
          </p>
        </div>

        <div class="divider"></div>

        <footer class="flex gap-3">
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
    tag = %Tag{user_id: socket.assigns.current_scope.user.id, is_public: true}

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
    # Handle unchecked checkbox - when checkbox is unchecked, it doesn't send any value
    tag_params = Map.put_new(tag_params, "is_public", "false")

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
