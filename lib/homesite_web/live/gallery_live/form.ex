defmodule HomesiteWeb.GalleryLive.Form do
  use HomesiteWeb, :live_view

  import HomesiteWeb.Gettext

  alias Homesite.Media
  alias Homesite.Media.Gallery

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <main class="technical-main">
        <.header>
          {@page_title}
          <:subtitle>
            {gettext("Create or update a gallery to organize your media.")}
          </:subtitle>
        </.header>

        <.form
          for={@form}
          id="gallery-form"
          phx-change="validate"
          phx-submit="save"
        >
          <div class="mb-[var(--space-md)]">
            <.input field={@form[:name]} type="text" label={gettext("Gallery Name")} required />
            <%= if @form[:slug].value do %>
              <p class="text-base-content/60 mt-[var(--space-inline)] text-[var(--text-sm)]">
                <.icon name="hero-link" class="inline h-4 w-4" /> {gettext("Slug")}:
                <span class="font-mono">{@form[:slug].value}</span>
              </p>
            <% end %>
          </div>

          <div class="mb-[var(--space-md)]">
            <.input
              field={@form[:description]}
              type="textarea"
              label={gettext("Description")}
              rows="3"
            />
          </div>

          <div class="mb-[var(--space-md)]">
            <.input
              field={@form[:display_order]}
              type="number"
              label={gettext("Display Order")}
              value={@form[:display_order].value || 0}
            />
            <p class="text-base-content/60 mt-[var(--space-inline)] text-[var(--text-sm)]">
              <.icon name="hero-information-circle" class="inline h-4 w-4" />
              {gettext("Lower numbers appear first")}
            </p>
          </div>

          <div class="divider"></div>

          <div class="form-control mb-[var(--space-md)]">
            <label class="label gap-[var(--space-md)] cursor-pointer justify-start">
              <input
                type="checkbox"
                name={@form[:is_portfolio].name}
                value="true"
                checked={Phoenix.HTML.Form.normalize_value("checkbox", @form[:is_portfolio].value)}
                class="toggle toggle-primary"
              />
              <span class="label-text font-semibold">
                {gettext("Portfolio Gallery")}
              </span>
            </label>
            <p class="text-base-content/60 ml-[calc(var(--space-md)+var(--space-sm))] text-[var(--text-sm)]">
              {gettext(
                "Portfolio galleries showcase your work publicly. Turn off for media libraries."
              )}
            </p>
          </div>

          <div class="form-control">
            <label class="label gap-[var(--space-md)] cursor-pointer justify-start">
              <input
                type="checkbox"
                name={@form[:is_public].name}
                value="true"
                checked={Phoenix.HTML.Form.normalize_value("checkbox", @form[:is_public].value)}
                class="toggle toggle-success"
              />
              <span class="label-text font-semibold">
                {gettext("Make this gallery publicly visible")}
              </span>
            </label>
            <p class="text-base-content/60 ml-[calc(var(--space-md)+var(--space-sm))] text-[var(--text-sm)]">
              {gettext("Public galleries are visible to everyone on your portfolio page.")}
            </p>
          </div>

          <div class="mt-[var(--space-lg)] gap-[var(--space-md)] flex items-center justify-end">
            <.link
              navigate={~p"/galleries"}
              class="btn btn-ghost"
            >
              {gettext("Cancel")}
            </.link>
            <.button type="submit" variant="primary" phx-disable-with={gettext("Saving...")}>
              {gettext("Save Gallery")}
            </.button>
          </div>
        </.form>
      </main>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    gallery = Media.get_gallery!(socket.assigns.current_scope, id)
    changeset = Media.change_gallery(gallery)

    socket
    |> assign(:page_title, gettext("Edit Gallery"))
    |> assign(:gallery, gallery)
    |> assign_form(changeset)
  end

  defp apply_action(socket, :new, _params) do
    gallery = %Gallery{}
    changeset = Media.change_gallery(gallery)

    socket
    |> assign(:page_title, gettext("New Gallery"))
    |> assign(:gallery, gallery)
    |> assign_form(changeset)
  end

  @impl true
  def handle_event("validate", %{"gallery" => gallery_params}, socket) do
    changeset =
      socket.assigns.gallery
      |> Media.change_gallery(gallery_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"gallery" => gallery_params}, socket) do
    save_gallery(socket, socket.assigns.live_action, gallery_params)
  end

  defp save_gallery(socket, :edit, gallery_params) do
    case Media.update_gallery(
           socket.assigns.current_scope,
           socket.assigns.gallery,
           gallery_params
         ) do
      {:ok, _gallery} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Gallery updated successfully"))
         |> push_navigate(to: ~p"/galleries")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_gallery(socket, :new, gallery_params) do
    case Media.create_gallery(socket.assigns.current_scope, gallery_params) do
      {:ok, _gallery} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Gallery created successfully"))
         |> push_navigate(to: ~p"/galleries")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
