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
        <div class="mb-[var(--space-sm)]">
          <.input field={@form[:name]} type="text" label={gettext("Name")} />
          <%= if @form[:slug].value do %>
            <p class="text-base-content/60 mt-[var(--space-inline)] text-[var(--text-sm)]">
              <.icon name="hero-link" class="inline h-4 w-4" /> {gettext("Slug")}:
              <span class="font-mono">{@form[:slug].value}</span>
            </p>
          <% end %>
        </div>
        
    <!-- Similar tags warning -->
        <%= if @similar_tags != [] do %>
          <div class="alert alert-warning mb-[var(--space-sm)]">
            <.icon name="hero-information-circle" />
            <div>
              <p class="font-semibold">{gettext("Similar tags already exist:")}</p>
              <div class="mt-[var(--space-xs)] gap-[var(--space-xs)] flex flex-wrap">
                <%= for tag <- @similar_tags do %>
                  <.link navigate={~p"/tags/#{tag}"} class="badge badge-lg badge-outline gap-[var(--space-inline)]">
                    <.icon name="hero-tag" class="h-3 w-3" />
                    {tag.name}
                  </.link>
                <% end %>
              </div>
              <p class="mt-[var(--space-xs)] text-[var(--text-sm)]">
                {gettext("Consider using one of these existing tags instead of creating a new one.")}
              </p>
            </div>
          </div>
        <% end %>

        <.input
          field={@form[:description]}
          type="textarea"
          label={gettext("Description")}
          placeholder={gettext("Optional description for this tag")}
        />

        <div class="divider"></div>

        <div class="form-control">
          <label class="label gap-[var(--space-xs)] cursor-pointer justify-start">
            <input
              type="checkbox"
              name={@form[:is_public].name}
              value="true"
              checked={@is_public}
              class="toggle toggle-primary"
            />
            <span class="label-text font-semibold">{gettext("Make this tag publicly visible")}</span>
          </label>
          <p class="text-base-content/60 text-[var(--text-sm)] ml-14">
            {gettext("Public tags can be seen by everyone. Turn off to make this tag private.")}
          </p>
        </div>

        <div class="divider"></div>

        <footer class="gap-[var(--space-xs)] flex">
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

  defp apply_action(socket, :edit, %{"id" => slug}) do
    tag = Content.get_tag_by_slug!(slug)
    scope = socket.assigns.current_scope

    # Verify ownership
    true = tag.user_id == scope.user.id

    socket
    |> assign(:page_title, gettext("Edit Tag"))
    |> assign(:tag, tag)
    |> assign(:is_public, tag.is_public)
    |> assign(:similar_tags, [])
    |> assign(:form, to_form(Content.change_tag(scope, tag)))
  end

  defp apply_action(socket, :new, _params) do
    tag = %Tag{user_id: socket.assigns.current_scope.user.id, is_public: true}

    socket
    |> assign(:page_title, gettext("New Tag"))
    |> assign(:tag, tag)
    |> assign(:is_public, true)
    |> assign(:similar_tags, [])
    |> assign(:form, to_form(Content.change_tag(socket.assigns.current_scope, tag)))
  end

  @impl true
  def handle_event("validate", %{"tag" => tag_params}, socket) do
    # Update is_public from params if present, otherwise keep current value
    is_public =
      case tag_params["is_public"] do
        "true" -> true
        "false" -> false
        _ -> socket.assigns.is_public
      end

    # Always include is_public in params based on current state
    tag_params = Map.put(tag_params, "is_public", if(is_public, do: "true", else: "false"))

    changeset = Content.change_tag(socket.assigns.current_scope, socket.assigns.tag, tag_params)

    # Check for similar tags when creating new tag or when name changes during edit
    similar_tags =
      case tag_params["name"] do
        name when is_binary(name) and byte_size(name) >= 2 ->
          # When editing, exclude the current tag from similar results
          exclude_id =
            if socket.assigns.live_action == :edit, do: socket.assigns.tag.id, else: nil

          Content.find_similar_tags(name, exclude_id)

        _ ->
          []
      end

    {:noreply,
     socket
     |> assign(:is_public, is_public)
     |> assign(:similar_tags, similar_tags)
     |> assign(:form, to_form(changeset, action: :validate))}
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
