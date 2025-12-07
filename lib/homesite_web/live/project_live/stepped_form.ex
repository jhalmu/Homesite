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
      <div class="w-full max-w-4xl mx-auto px-4 py-8">
        <%!-- Page Header --%>
        <div class="mb-8">
          <h1 class="text-3xl font-bold"><%= @page_title %></h1>
          <.link navigate={~p"/projects"} class="text-sm text-base-content/70 hover:text-base-content">
            <.icon name="hero-arrow-left" class="w-4 h-4 inline" /> {gettext("Back to projects")}
          </.link>
        </div>

        <%!-- Progress Steps --%>
        <ul class="steps steps-horizontal w-full mb-8">
          <li class={"step #{if @step_index >= 0, do: "step-primary"}"}>
            {gettext("Basics")}
          </li>
          <li class={"step #{if @step_index >= 1, do: "step-primary"}"}>
            {gettext("Metadata")}
            <span class="text-xs text-base-content/60 ml-1">({gettext("optional")})</span>
          </li>
          <li class={"step #{if @step_index >= 2, do: "step-primary"}"}>
            {gettext("Team")}
            <span class="text-xs text-base-content/60 ml-1">({gettext("optional")})</span>
          </li>
          <li class={"step #{if @step_index >= 3, do: "step-primary"}"}>
            {gettext("Settings")}
            <span class="text-xs text-base-content/60 ml-1">({gettext("optional")})</span>
          </li>
        </ul>

        <%!-- Completion Badge --%>
        <div class="alert alert-info mb-6">
          <.icon name="hero-information-circle" class="w-5 h-5" />
          <span>
            {gettext("Project completion")}: <%= @completion_percentage %>%
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
          <div class="flex justify-between mt-8 pt-6 border-t border-base-300">
            <%= if @step_index > 0 do %>
              <button type="button" phx-click="prev_step" class="btn btn-ghost">
                <.icon name="hero-arrow-left" class="w-4 h-4" /> {gettext("Back")}
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
                  {gettext("Next")} <.icon name="hero-arrow-right" class="w-4 h-4" />
                </button>
              <% else %>
                <button type="submit" class="btn btn-success">
                  <.icon name="hero-check" class="w-4 h-4" /> {gettext("Save Project")}
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
        <.icon name="hero-light-bulb" class="w-5 h-5" />
        <span>
          {gettext("Tip: Give your project a clear, descriptive name. You can add more details in the next steps.")}
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
        <.icon name="hero-information-circle" class="w-5 h-5" />
        <span>
          {gettext("Metadata helps viewers discover and understand your work. Add as much or as little as you want.")}
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
      <div class="border border-base-300 rounded-lg p-4">
        <h3 class="text-lg font-semibold mb-4">{gettext("Collaborators")}</h3>

        <%= if Enum.empty?(@collaborators) do %>
          <p class="text-sm text-base-content/60 mb-4">
            {gettext("No collaborators added yet. Add team members who worked on this project.")}
          </p>
        <% else %>
          <div class="space-y-2 mb-4">
            <%= for collaborator <- @collaborators do %>
              <div class="flex items-center justify-between p-2 bg-base-200 rounded">
                <div>
                  <span class="font-medium"><%= collaborator.name %></span>
                  <%= if collaborator.contact_type != "none" do %>
                    <span class="text-sm text-base-content/60 ml-2">
                      (<%= collaborator.contact_type %>: <%= collaborator.contact %>)
                    </span>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>

        <p class="text-sm text-base-content/60">
          {gettext("Note: Collaborator management coming in next update.")}
        </p>
      </div>

      <%!-- Affiliation Links Section --%>
      <div class="border border-base-300 rounded-lg p-4">
        <h3 class="text-lg font-semibold mb-4">{gettext("Related Links")}</h3>

        <%= if Enum.empty?(@affiliation_links) do %>
          <p class="text-sm text-base-content/60 mb-4">
            {gettext("No links added yet. Add client websites, press coverage, or related projects.")}
          </p>
        <% else %>
          <div class="space-y-2 mb-4">
            <%= for link <- @affiliation_links do %>
              <div class="flex items-center justify-between p-2 bg-base-200 rounded">
                <div>
                  <span class="font-medium"><%= link.title %></span>
                  <a href={link.url} target="_blank" class="text-sm text-primary ml-2">
                    <%= link.url %> <.icon name="hero-arrow-top-right-on-square" class="w-3 h-3 inline" />
                  </a>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>

        <p class="text-sm text-base-content/60">
          {gettext("Note: Link management coming in next update.")}
        </p>
      </div>
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
        <.icon name="hero-check-circle" class="w-5 h-5" />
        <span>
          {gettext("You're ready to save! Click 'Save Project' to create your project.")}
        </span>
      </div>
    </div>
    """
  end
end
