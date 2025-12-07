defmodule HomesiteWeb.ProjectLive.SteppedForm do
  use HomesiteWeb, :live_view

  alias Homesite.Media
  alias Homesite.Media.Project

  @steps [:basics, :metadata, :team, :settings]

  @impl true
  def mount(params, _session, socket) do
    project_id = params["id"]

    {project, page_title} =
      if project_id do
        project = Media.get_project!(socket.assigns.current_scope, project_id)
        {project, gettext("Edit Project")}
      else
        {%Project{}, gettext("New Project")}
      end

    {:ok,
     socket
     |> assign(:page_title, page_title)
     |> assign(:project, project)
     |> assign(:current_step, :basics)
     |> assign(:step_index, 0)
     |> assign(:collaborators, [])
     |> assign(:affiliation_links, [])
     |> assign(:completion_percentage, project.completion_percentage || 0)
     |> assign(:editing_collaborator, nil)
     |> assign(:editing_link, nil)
     |> assign(:new_collaborator, %{name: "", contact: "", contact_type: "none"})
     |> assign(:new_link, %{title: "", url: ""})
     |> assign_form(project)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:project, %Project{})
    |> assign(:page_title, gettext("New Project"))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    project = Media.get_project!(socket.assigns.current_scope, id)

    # Load collaborators and affiliation links
    collaborators = Media.list_collaborators(socket.assigns.current_scope, id)
    affiliation_links = Media.list_affiliation_links(socket.assigns.current_scope, id)

    socket
    |> assign(:project, project)
    |> assign(:page_title, gettext("Edit Project"))
    |> assign(:collaborators, collaborators)
    |> assign(:affiliation_links, affiliation_links)
    |> assign(:completion_percentage, project.completion_percentage || 0)
  end

  @impl true
  def handle_event("validate", %{"project" => project_params}, socket) do
    changeset =
      socket.assigns.project
      |> Project.changeset(project_params, socket.assigns.current_scope)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("next_step", _params, socket) do
    current_index = socket.assigns.step_index

    if current_index < length(@steps) - 1 do
      new_index = current_index + 1
      new_step = Enum.at(@steps, new_index)

      {:noreply,
       socket
       |> assign(:step_index, new_index)
       |> assign(:current_step, new_step)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("prev_step", _params, socket) do
    current_index = socket.assigns.step_index

    if current_index > 0 do
      new_index = current_index - 1
      new_step = Enum.at(@steps, new_index)

      {:noreply,
       socket
       |> assign(:step_index, new_index)
       |> assign(:current_step, new_step)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("skip_to_save", _params, socket) do
    # Jump to final step (settings)
    {:noreply,
     socket
     |> assign(:step_index, 3)
     |> assign(:current_step, :settings)}
  end

  @impl true
  def handle_event("save", %{"project" => project_params}, socket) do
    save_project(socket, socket.assigns.live_action, project_params)
  end

  # Collaborator events
  @impl true
  def handle_event("add_collaborator", %{"collaborator" => collab_params}, socket) do
    if socket.assigns.project.id do
      # Edit mode: persist immediately
      attrs = Map.put(collab_params, "project_id", socket.assigns.project.id)

      case Media.create_collaborator(socket.assigns.current_scope, attrs) do
        {:ok, _collaborator} ->
          collaborators =
            Media.list_collaborators(socket.assigns.current_scope, socket.assigns.project.id)

          {:noreply,
           socket
           |> assign(:collaborators, collaborators)
           |> assign(:new_collaborator, %{name: "", contact: "", contact_type: "none"})
           |> put_flash(:info, gettext("Collaborator added"))}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to add collaborator"))}
      end
    else
      # New mode: project doesn't exist yet, show message
      {:noreply,
       put_flash(socket, :info, gettext("Save the project first, then you can add collaborators"))}
    end
  end

  @impl true
  def handle_event("delete_collaborator", %{"id" => id}, socket) do
    id = String.to_integer(id)
    collaborator = Enum.find(socket.assigns.collaborators, &(&1.id == id))

    case Media.delete_collaborator(socket.assigns.current_scope, collaborator) do
      {:ok, _} ->
        collaborators =
          Media.list_collaborators(socket.assigns.current_scope, socket.assigns.project.id)

        {:noreply,
         socket
         |> assign(:collaborators, collaborators)
         |> put_flash(:info, gettext("Collaborator removed"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to remove collaborator"))}
    end
  end

  # Affiliation link events
  @impl true
  def handle_event("add_affiliation_link", %{"link" => link_params}, socket) do
    if socket.assigns.project.id do
      # Edit mode: persist immediately
      attrs = Map.put(link_params, "project_id", socket.assigns.project.id)

      case Media.create_affiliation_link(socket.assigns.current_scope, attrs) do
        {:ok, _link} ->
          links =
            Media.list_affiliation_links(socket.assigns.current_scope, socket.assigns.project.id)

          {:noreply,
           socket
           |> assign(:affiliation_links, links)
           |> assign(:new_link, %{title: "", url: ""})
           |> put_flash(:info, gettext("Link added"))}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to add link"))}
      end
    else
      # New mode: project doesn't exist yet, show message
      {:noreply,
       put_flash(socket, :info, gettext("Save the project first, then you can add links"))}
    end
  end

  @impl true
  def handle_event("delete_affiliation_link", %{"id" => id}, socket) do
    id = String.to_integer(id)
    link = Enum.find(socket.assigns.affiliation_links, &(&1.id == id))

    case Media.delete_affiliation_link(socket.assigns.current_scope, link) do
      {:ok, _} ->
        links =
          Media.list_affiliation_links(socket.assigns.current_scope, socket.assigns.project.id)

        {:noreply,
         socket
         |> assign(:affiliation_links, links)
         |> put_flash(:info, gettext("Link removed"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to remove link"))}
    end
  end

  @impl true
  def handle_event("update_new_collaborator", %{"field" => field, "value" => value}, socket) do
    new_collaborator = Map.put(socket.assigns.new_collaborator, String.to_atom(field), value)
    {:noreply, assign(socket, :new_collaborator, new_collaborator)}
  end

  @impl true
  def handle_event("update_new_link", %{"field" => field, "value" => value}, socket) do
    new_link = Map.put(socket.assigns.new_link, String.to_atom(field), value)
    {:noreply, assign(socket, :new_link, new_link)}
  end

  defp save_project(socket, :new, project_params) do
    case Media.create_project(socket.assigns.current_scope, project_params) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Project created successfully"))
         |> push_navigate(to: ~p"/projects/#{project.id}/edit")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_project(socket, :edit, project_params) do
    case Media.update_project(
           socket.assigns.current_scope,
           socket.assigns.project,
           project_params
         ) do
      {:ok, project} ->
        # Recalculate completion percentage with associations
        {:ok, project} =
          Media.update_project_completion(socket.assigns.current_scope, project.id)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Project updated successfully"))
         |> assign(:project, project)
         |> assign(:completion_percentage, project.completion_percentage)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp assign_form(socket, %Project{} = project) do
    changeset = Project.changeset(project, %{}, socket.assigns.current_scope)
    assign(socket, :form, to_form(changeset))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto w-full max-w-4xl px-4 py-8">
        <%!-- Page Header --%>
        <div class="mb-8">
          <h1 class="text-3xl font-bold">{@page_title}</h1>
          <.link navigate={~p"/projects"} class="text-base-content/70 text-sm hover:text-base-content">
            <.icon name="hero-arrow-left" class="inline h-4 w-4" /> {gettext("Back to projects")}
          </.link>
        </div>

        <%!-- Progress Steps --%>
        <ul class="steps steps-horizontal mb-8 w-full">
          <li class={"#{if @step_index >= 0, do: "step-primary"} step"}>
            {gettext("Basics")}
          </li>
          <li class={"#{if @step_index >= 1, do: "step-primary"} step"}>
            {gettext("Metadata")}
            <span class="text-base-content/60 ml-1 text-xs">({gettext("optional")})</span>
          </li>
          <li class={"#{if @step_index >= 2, do: "step-primary"} step"}>
            {gettext("Team")}
            <span class="text-base-content/60 ml-1 text-xs">({gettext("optional")})</span>
          </li>
          <li class={"#{if @step_index >= 3, do: "step-primary"} step"}>
            {gettext("Settings")}
            <span class="text-base-content/60 ml-1 text-xs">({gettext("optional")})</span>
          </li>
        </ul>

        <%!-- Completion Badge --%>
        <div class="alert alert-info mb-6">
          <.icon name="hero-information-circle" class="h-5 w-5" />
          <span>
            {gettext("Project completion")}: {@completion_percentage}%
            <%= if @completion_percentage < 100 do %>
              - {gettext("Add more details to make your project stand out!")}
            <% end %>
          </span>
        </div>

        <%!-- Step Content --%>
        <.form for={@form} phx-submit="save" phx-change="validate" class="space-y-6">
          <%= case @current_step do %>
            <% :basics -> %>
              <.render_basics_step form={@form} />
            <% :metadata -> %>
              <.render_metadata_step form={@form} />
            <% :team -> %>
              <.render_team_step
                collaborators={@collaborators}
                affiliation_links={@affiliation_links}
              />
            <% :settings -> %>
              <.render_settings_step form={@form} />
          <% end %>

          <%!-- Navigation Buttons --%>
          <div class="border-base-300 mt-8 flex justify-between border-t pt-6">
            <%= if @step_index > 0 do %>
              <button type="button" phx-click="prev_step" class="btn btn-ghost">
                <.icon name="hero-arrow-left" class="h-4 w-4" /> {gettext("Back")}
              </button>
            <% else %>
              <div></div>
            <% end %>

            <div class="flex gap-2">
              <%= if @step_index > 0 && @step_index < 3 do %>
                <button type="button" phx-click="skip_to_save" class="btn btn-ghost">
                  {gettext("Skip to Save")}
                </button>
              <% end %>

              <%= if @step_index < 3 do %>
                <button type="button" phx-click="next_step" class="btn btn-primary">
                  {gettext("Next")} <.icon name="hero-arrow-right" class="h-4 w-4" />
                </button>
              <% else %>
                <button type="submit" class="btn btn-success">
                  <.icon name="hero-check" class="h-4 w-4" /> {gettext("Save Project")}
                </button>
              <% end %>
            </div>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  defp render_basics_step(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-semibold">{gettext("Step 1: Project Basics")}</h2>
      <p class="text-base-content/70">
        {gettext("Start with the essential information about your project.")}
      </p>

      <.input field={@form[:name]} type="text" label={gettext("Project Name")} required />

      <.input
        field={@form[:description]}
        type="textarea"
        label={gettext("Description")}
        rows="4"
        phx-debounce="blur"
      />

      <div class="alert alert-warning">
        <.icon name="hero-light-bulb" class="h-5 w-5" />
        <span>
          {gettext(
            "Tip: Give your project a clear, descriptive name. You can add more details in the next steps."
          )}
        </span>
      </div>
    </div>
    """
  end

  defp render_metadata_step(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-semibold">{gettext("Step 2: Project Metadata")}</h2>
      <p class="text-base-content/70">
        {gettext("Add context to help viewers understand your project. All fields are optional.")}
      </p>

      <.input field={@form[:category]} type="text" label={gettext("Category")} />

      <.input field={@form[:tags]} type="text" label={gettext("Tags (comma-separated)")} />

      <.input field={@form[:project_date]} type="date" label={gettext("Project Date")} />

      <div class="alert alert-info">
        <.icon name="hero-information-circle" class="h-5 w-5" />
        <span>
          {gettext(
            "Metadata helps viewers discover and understand your work. Add as much or as little as you want."
          )}
        </span>
      </div>
    </div>
    """
  end

  defp render_team_step(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-semibold">{gettext("Step 3: Team & Links")}</h2>
      <p class="text-base-content/70">
        {gettext("Credit collaborators and add related links. All fields are optional.")}
      </p>

      <%!-- Collaborators Section --%>
      <div class="border-base-300 rounded-lg border p-4">
        <h3 class="mb-4 text-lg font-semibold">{gettext("Collaborators")}</h3>

        <%= if Enum.empty?(@collaborators) do %>
          <p class="text-base-content/60 mb-4 text-sm">
            {gettext("No collaborators added yet. Add team members who worked on this project.")}
          </p>
        <% else %>
          <div class="mb-4 space-y-2">
            <%= for collaborator <- @collaborators do %>
              <div class="bg-base-200 flex items-center justify-between rounded-lg p-3">
                <div class="flex-1">
                  <span class="font-medium">{collaborator.name}</span>
                  <%= if collaborator.contact_type != "none" do %>
                    <span class="text-base-content/60 ml-2 text-sm">
                      ({collaborator.contact_type}: {collaborator.contact})
                    </span>
                  <% end %>
                </div>
                <button
                  type="button"
                  phx-click="delete_collaborator"
                  phx-value-id={collaborator.id}
                  class="btn btn-ghost btn-sm text-error"
                  data-confirm={gettext("Remove this collaborator?")}
                >
                  <.icon name="hero-trash" class="h-4 w-4" />
                </button>
              </div>
            <% end %>
          </div>
        <% end %>

        <%!-- Add Collaborator Form --%>
        <form phx-submit="add_collaborator" class="space-y-3">
          <div class="grid grid-cols-1 gap-3 md:grid-cols-2">
            <input
              type="text"
              name="collaborator[name]"
              value={@new_collaborator.name}
              placeholder={gettext("Name")}
              class="input input-bordered w-full"
              required
            />
            <input
              type="text"
              name="collaborator[contact]"
              value={@new_collaborator.contact}
              placeholder={gettext("Contact (URL or email, optional)")}
              class="input input-bordered w-full"
            />
          </div>
          <button type="submit" class="btn btn-primary btn-sm">
            <.icon name="hero-plus" class="h-4 w-4" />
            {gettext("Add Collaborator")}
          </button>
        </form>
      </div>

      <%!-- Affiliation Links Section --%>
      <div class="border-base-300 rounded-lg border p-4">
        <h3 class="mb-4 text-lg font-semibold">{gettext("Related Links")}</h3>

        <%= if Enum.empty?(@affiliation_links) do %>
          <p class="text-base-content/60 mb-4 text-sm">
            {gettext("No links added yet. Add client websites, press coverage, or related projects.")}
          </p>
        <% else %>
          <div class="mb-4 space-y-2">
            <%= for link <- @affiliation_links do %>
              <div class="bg-base-200 flex items-center justify-between rounded-lg p-3">
                <div class="flex-1">
                  <span class="font-medium">{link.title}</span>
                  <a href={link.url} target="_blank" class="text-primary ml-2 text-sm hover:underline">
                    {link.url} <.icon name="hero-arrow-top-right-on-square" class="inline h-3 w-3" />
                  </a>
                </div>
                <button
                  type="button"
                  phx-click="delete_affiliation_link"
                  phx-value-id={link.id}
                  class="btn btn-ghost btn-sm text-error"
                  data-confirm={gettext("Remove this link?")}
                >
                  <.icon name="hero-trash" class="h-4 w-4" />
                </button>
              </div>
            <% end %>
          </div>
        <% end %>

        <%!-- Add Link Form --%>
        <form phx-submit="add_affiliation_link" class="space-y-3">
          <div class="grid grid-cols-1 gap-3 md:grid-cols-2">
            <input
              type="text"
              name="link[title]"
              value={@new_link.title}
              placeholder={gettext("Title")}
              class="input input-bordered w-full"
              required
            />
            <input
              type="url"
              name="link[url]"
              value={@new_link.url}
              placeholder={gettext("URL (https://...)")}
              class="input input-bordered w-full"
              required
            />
          </div>
          <button type="submit" class="btn btn-primary btn-sm">
            <.icon name="hero-plus" class="h-4 w-4" />
            {gettext("Add Link")}
          </button>
        </form>
      </div>

      <%!-- Info Alert for New Projects --%>
      <%= if is_nil(@project.id) do %>
        <div class="alert alert-info">
          <.icon name="hero-information-circle" class="h-5 w-5" />
          <span>
            {gettext(
              "Save your project first to add collaborators and links. You can come back to this step after creating the project."
            )}
          </span>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_settings_step(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-semibold">{gettext("Step 4: Visibility & Settings")}</h2>
      <p class="text-base-content/70">
        {gettext("Control how your project appears publicly. All settings are optional.")}
      </p>

      <.input field={@form[:is_public]} type="checkbox" label={gettext("Make this project public")} />

      <.input
        field={@form[:is_portfolio]}
        type="checkbox"
        label={gettext("Show in portfolio gallery")}
      />

      <div class="alert alert-success">
        <.icon name="hero-check-circle" class="h-5 w-5" />
        <span>
          {gettext("You're ready to save! Click 'Save Project' to create your project.")}
        </span>
      </div>
    </div>
    """
  end
end
