defmodule HomesiteWeb.ProjectLive.SteppedForm do
  use HomesiteWeb, :live_view

  alias Homesite.Media
  alias Homesite.Media.Project
  alias Homesite.Media.ProjectTemplate

  @steps [:basics, :metadata, :team, :settings]

  # Whitelist of allowed field names to prevent atom exhaustion attacks
  @allowed_collaborator_fields ~w(name contact contact_type)a
  @allowed_link_fields ~w(title url)a

  @impl true
  def mount(params, _session, socket) do
    project_id = params["id"]

    {project, page_title} =
      if project_id do
        project = Media.get_project!(socket.assigns.current_scope, project_id)
        {project, gettext("Edit Project")}
      else
        # Set default project_date to today for new projects
        {%Project{project_date: Date.utc_today()}, gettext("New Project")}
      end

    {:ok,
     socket
     |> assign(:page_title, page_title)
     |> assign(:project, project)
     |> assign(:current_step, :basics)
     |> assign(:step_index, 0)
     |> assign(:collaborators, [])
     |> assign(:affiliation_links, [])
     |> assign(:linked_posts, [])
     |> assign(:available_posts, [])
     |> assign(:completion_percentage, project.completion_percentage || 0)
     |> assign(:editing_collaborator, nil)
     |> assign(:editing_link, nil)
     |> assign(:new_collaborator, %{name: "", contact: "", contact_type: "none"})
     |> assign(:new_link, %{title: "", url: ""})
     |> assign(:selected_post_id, nil)
     |> assign(:input_reset_key, 0)
     |> assign_form(project)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    # Set default project_date to today for new projects
    project = %Project{project_date: Date.utc_today()}

    socket
    |> assign(:project, project)
    |> assign(:page_title, gettext("New Project"))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    project = Media.get_project!(socket.assigns.current_scope, id)

    # Load collaborators, affiliation links, and linked posts
    collaborators = Media.list_collaborators(socket.assigns.current_scope, id)
    affiliation_links = Media.list_affiliation_links(socket.assigns.current_scope, id)
    linked_posts = Media.list_project_posts(socket.assigns.current_scope, id)
    available_posts = Media.list_available_posts_for_project(socket.assigns.current_scope, id)

    socket
    |> assign(:project, project)
    |> assign(:page_title, gettext("Edit Project"))
    |> assign(:collaborators, collaborators)
    |> assign(:affiliation_links, affiliation_links)
    |> assign(:linked_posts, linked_posts)
    |> assign(:available_posts, available_posts)
    |> assign(:completion_percentage, project.completion_percentage || 0)
  end

  @impl true
  def handle_event("validate", %{"project" => project_params}, socket) do
    # Convert comma-separated tags string to list
    project_params = convert_tags_param(project_params)

    changeset =
      socket.assigns.project
      |> Project.changeset(project_params, socket.assigns.current_scope)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  # Catch-all for validate events without project params (from non-form elements)
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

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

  def handle_event("skip_to_save", _params, socket) do
    # Jump to final step (settings)
    {:noreply,
     socket
     |> assign(:step_index, 3)
     |> assign(:current_step, :settings)}
  end

  def handle_event("save", %{"project" => project_params}, socket) do
    # Convert comma-separated tags string to list
    project_params = convert_tags_param(project_params)
    save_project(socket, socket.assigns.live_action, project_params)
  end

  # Collaborator events - reads from socket assigns (not form params)
  def handle_event("add_collaborator", _params, socket) do
    new_collab = socket.assigns.new_collaborator

    if new_collab.name == "" do
      {:noreply, put_flash(socket, :error, gettext("Collaborator name is required"))}
    else
      if socket.assigns.project.id do
        # Edit mode: persist immediately
        attrs = %{
          "name" => new_collab.name,
          "contact" => new_collab.contact,
          "contact_type" => new_collab.contact_type,
          "project_id" => socket.assigns.project.id
        }

        case Media.create_collaborator(socket.assigns.current_scope, attrs) do
          {:ok, _collaborator} ->
            collaborators =
              Media.list_collaborators(socket.assigns.current_scope, socket.assigns.project.id)

            {:noreply,
             socket
             |> assign(:collaborators, collaborators)
             |> assign(:new_collaborator, %{name: "", contact: "", contact_type: "none"})
             |> assign(:input_reset_key, socket.assigns.input_reset_key + 1)
             |> put_flash(:info, gettext("Collaborator added"))}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, gettext("Failed to add collaborator"))}
        end
      else
        # New mode: project doesn't exist yet, show message
        {:noreply,
         put_flash(
           socket,
           :info,
           gettext("Save the project first, then you can add collaborators")
         )}
      end
    end
  end

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

  # Affiliation link events - reads from socket assigns (not form params)
  def handle_event("add_affiliation_link", _params, socket) do
    new_link = socket.assigns.new_link

    if new_link.title == "" or new_link.url == "" do
      {:noreply, put_flash(socket, :error, gettext("Link title and URL are required"))}
    else
      if socket.assigns.project.id do
        # Edit mode: persist immediately
        attrs = %{
          "title" => new_link.title,
          "url" => new_link.url,
          "project_id" => socket.assigns.project.id
        }

        case Media.create_affiliation_link(socket.assigns.current_scope, attrs) do
          {:ok, _link} ->
            links =
              Media.list_affiliation_links(
                socket.assigns.current_scope,
                socket.assigns.project.id
              )

            {:noreply,
             socket
             |> assign(:affiliation_links, links)
             |> assign(:new_link, %{title: "", url: ""})
             |> assign(:input_reset_key, socket.assigns.input_reset_key + 1)
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
  end

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

  # Blog post linking events
  def handle_event("select_post", %{"value" => ""}, socket) do
    {:noreply, assign(socket, :selected_post_id, nil)}
  end

  def handle_event("select_post", %{"value" => post_id}, socket) when is_binary(post_id) do
    {:noreply, assign(socket, :selected_post_id, String.to_integer(post_id))}
  end

  def handle_event("select_post", %{"value" => post_id}, socket) when is_integer(post_id) do
    {:noreply, assign(socket, :selected_post_id, post_id)}
  end

  def handle_event("link_post", _params, socket) do
    case socket.assigns.selected_post_id do
      nil ->
        {:noreply, put_flash(socket, :error, gettext("Please select a blog post"))}

      post_id ->
        link_post_to_project(socket, post_id)
    end
  end

  def handle_event("unlink_post", %{"id" => id}, socket) do
    post_id = String.to_integer(id)

    Media.unlink_post_from_project(
      socket.assigns.current_scope,
      socket.assigns.project.id,
      post_id
    )

    linked_posts =
      Media.list_project_posts(socket.assigns.current_scope, socket.assigns.project.id)

    available_posts =
      Media.list_available_posts_for_project(
        socket.assigns.current_scope,
        socket.assigns.project.id
      )

    {:noreply,
     socket
     |> assign(:linked_posts, linked_posts)
     |> assign(:available_posts, available_posts)
     |> put_flash(:info, gettext("Blog post unlinked"))}
  end

  def handle_event("update_new_collaborator", %{"field" => field, "value" => value}, socket) do
    case safe_to_atom(field, @allowed_collaborator_fields) do
      {:ok, field_atom} ->
        new_collaborator = Map.put(socket.assigns.new_collaborator, field_atom, value)
        {:noreply, assign(socket, :new_collaborator, new_collaborator)}

      :error ->
        {:noreply, socket}
    end
  end

  def handle_event("update_new_link", %{"field" => field, "value" => value}, socket) do
    case safe_to_atom(field, @allowed_link_fields) do
      {:ok, field_atom} ->
        new_link = Map.put(socket.assigns.new_link, field_atom, value)
        {:noreply, assign(socket, :new_link, new_link)}

      :error ->
        {:noreply, socket}
    end
  end

  # Helper for linking posts to projects
  defp link_post_to_project(socket, post_id) do
    case Media.link_post_to_project(
           socket.assigns.current_scope,
           socket.assigns.project.id,
           post_id
         ) do
      {:ok, _} ->
        linked_posts =
          Media.list_project_posts(socket.assigns.current_scope, socket.assigns.project.id)

        available_posts =
          Media.list_available_posts_for_project(
            socket.assigns.current_scope,
            socket.assigns.project.id
          )

        {:noreply,
         socket
         |> assign(:linked_posts, linked_posts)
         |> assign(:available_posts, available_posts)
         |> assign(:selected_post_id, nil)
         |> put_flash(:info, gettext("Blog post linked"))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to link blog post"))}
    end
  end

  # Safely convert string to atom only if it's in the allowed list
  defp safe_to_atom(field, allowed_fields) when is_binary(field) do
    field_atom = String.to_existing_atom(field)

    if field_atom in allowed_fields do
      {:ok, field_atom}
    else
      :error
    end
  rescue
    ArgumentError -> :error
  end

  # Convert comma-separated tags string to list for Ecto
  defp convert_tags_param(%{"tags" => tags} = params) when is_binary(tags) do
    Map.put(params, "tags", string_to_tags(tags))
  end

  defp convert_tags_param(params), do: params

  defp string_to_tags(string) when is_binary(string) do
    string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp string_to_tags(_), do: []

  defp tags_to_string(tags) when is_list(tags), do: Enum.join(tags, ", ")
  defp tags_to_string(_), do: ""

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
        <.form for={@form} id="project-form" phx-submit="save" phx-change="validate" class="space-y-6">
          <%!-- Hidden fields to preserve data across steps --%>
          <%= if @current_step != :basics do %>
            <input type="hidden" name={@form[:name].name} value={@form[:name].value} />
            <input type="hidden" name={@form[:description].name} value={@form[:description].value} />
            <input
              type="hidden"
              name={@form[:template_type].name}
              value={@form[:template_type].value}
            />
          <% end %>
          <%= if @current_step != :metadata do %>
            <input type="hidden" name={@form[:category].name} value={@form[:category].value} />
            <input
              type="hidden"
              name={@form[:tags].name}
              value={tags_to_string(@form[:tags].value)}
            />
            <input type="hidden" name={@form[:project_date].name} value={@form[:project_date].value} />
          <% end %>

          <%= case @current_step do %>
            <% :basics -> %>
              <.render_basics_step form={@form} />
            <% :metadata -> %>
              <.render_metadata_step form={@form} />
            <% :team -> %>
              <.render_team_step
                project={@project}
                collaborators={@collaborators}
                affiliation_links={@affiliation_links}
                linked_posts={@linked_posts}
                available_posts={@available_posts}
                new_collaborator={@new_collaborator}
                new_link={@new_link}
                selected_post_id={@selected_post_id}
                input_reset_key={@input_reset_key}
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
    templates = ProjectTemplate.all()
    current_template = assigns.form[:template_type].value || "photography"
    assigns = assign(assigns, :templates, templates)
    assigns = assign(assigns, :current_template, current_template)

    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-semibold">{gettext("Step 1: Project Basics")}</h2>
      <p class="text-base-content/70">
        {gettext("Start with the essential information about your project.")}
      </p>

      <%!-- Template Selector --%>
      <div class="form-control">
        <label class="label">
          <span class="label-text font-medium">{gettext("Project Type")}</span>
        </label>
        <div class="grid grid-cols-2 gap-3 md:grid-cols-4">
          <%= for template <- @templates do %>
            <label class={[
              "card cursor-pointer border-2 p-4 text-center transition-all hover:shadow-md",
              @current_template == template.id && "border-primary bg-primary/10",
              @current_template != template.id && "border-base-300 bg-base-100"
            ]}>
              <input
                type="radio"
                name={@form[:template_type].name}
                value={template.id}
                checked={@current_template == template.id}
                class="hidden"
              />
              <.icon name={template.icon} class="mx-auto mb-2 h-8 w-8" />
              <span class="text-sm font-medium">{template.name}</span>
            </label>
          <% end %>
        </div>
        <p class="text-base-content/60 mt-2 text-sm">
          {gettext("Choose a project type to get customized labels and suggestions.")}
        </p>
      </div>

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
    # Get template-specific configuration
    template_type = assigns.form[:template_type].value || "photography"
    template = ProjectTemplate.get(template_type) || ProjectTemplate.get("photography")

    # Convert tags array to comma-separated string for display
    tags_value = tags_to_string(assigns.form[:tags].value)

    assigns =
      assigns
      |> assign(:tags_display, tags_value)
      |> assign(:template, template)
      |> assign(:suggested_tags, template.suggested_tags)

    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-semibold">{gettext("Step 2: Project Metadata")}</h2>
      <p class="text-base-content/70">
        {gettext("Add context to help viewers understand your project. All fields are optional.")}
      </p>

      <%!-- Template indicator --%>
      <div class="bg-base-200 flex items-center gap-2 rounded-lg p-3">
        <.icon name={@template.icon} class="text-primary h-5 w-5" />
        <span class="text-sm">{gettext("Project type:")} <strong>{@template.name}</strong></span>
      </div>

      <.input
        field={@form[:category]}
        type="text"
        label={@template.fields.category.label}
        placeholder={@template.fields.category.placeholder}
      />

      <div class="form-control">
        <label class="label">
          <span class="label-text">{@template.fields.tags.label} {gettext("(comma-separated)")}</span>
        </label>
        <input
          type="text"
          name={@form[:tags].name}
          value={@tags_display}
          placeholder={@template.fields.tags.placeholder}
          class="input input-bordered w-full"
        />
        <%= if @form[:tags].errors != [] do %>
          <p class="text-error mt-1 text-sm">
            <%= for {msg, opts} <- @form[:tags].errors do %>
              {translate_error({msg, opts})}
            <% end %>
          </p>
        <% end %>

        <%!-- Suggested tags --%>
        <%= if length(@suggested_tags) > 0 do %>
          <div class="mt-2">
            <span class="text-base-content/60 text-sm">{gettext("Suggestions:")}</span>
            <div class="mt-1 flex flex-wrap gap-1">
              <%= for tag <- @suggested_tags do %>
                <span class="badge badge-outline badge-sm">{tag}</span>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>

      <.input
        field={@form[:project_date]}
        type="date"
        label={@template.fields.project_date.label}
      />

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

        <%!-- Add Collaborator (using phx-click to avoid nested forms) --%>
        <div class="space-y-3" id={"collaborator-inputs-#{@input_reset_key}"}>
          <div class="grid grid-cols-1 gap-3 md:grid-cols-2">
            <input
              type="text"
              id={"collaborator-name-#{@input_reset_key}"}
              value={@new_collaborator.name}
              placeholder={gettext("Name")}
              class="input input-bordered w-full"
              phx-keyup="update_new_collaborator"
              phx-value-field="name"
            />
            <input
              type="text"
              id={"collaborator-contact-#{@input_reset_key}"}
              value={@new_collaborator.contact}
              placeholder={gettext("Contact (URL or email, optional)")}
              class="input input-bordered w-full"
              phx-keyup="update_new_collaborator"
              phx-value-field="contact"
            />
          </div>
          <div class="flex items-center gap-2">
            <select
              id={"collaborator-contact-type-#{@input_reset_key}"}
              class="select select-bordered select-sm"
              phx-hook="SelectValue"
              data-event="update_new_collaborator"
              data-field="contact_type"
            >
              <option value="none" selected={@new_collaborator.contact_type == "none"}>
                {gettext("No contact type")}
              </option>
              <option value="url" selected={@new_collaborator.contact_type == "url"}>
                {gettext("URL")}
              </option>
              <option value="email" selected={@new_collaborator.contact_type == "email"}>
                {gettext("Email")}
              </option>
            </select>
            <button
              type="button"
              phx-click="add_collaborator"
              class="btn btn-primary btn-sm"
              disabled={@new_collaborator.name == ""}
            >
              <.icon name="hero-plus" class="h-4 w-4" />
              {gettext("Add Collaborator")}
            </button>
          </div>
        </div>
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

        <%!-- Add Link (using phx-click to avoid nested forms) --%>
        <div class="space-y-3" id={"link-inputs-#{@input_reset_key}"}>
          <div class="grid grid-cols-1 gap-3 md:grid-cols-2">
            <input
              type="text"
              id={"link-title-#{@input_reset_key}"}
              value={@new_link.title}
              placeholder={gettext("Title")}
              class="input input-bordered w-full"
              phx-keyup="update_new_link"
              phx-value-field="title"
            />
            <input
              type="text"
              id={"link-url-#{@input_reset_key}"}
              value={@new_link.url}
              placeholder={gettext("URL (https://...)")}
              class="input input-bordered w-full"
              phx-keyup="update_new_link"
              phx-value-field="url"
            />
          </div>
          <button
            type="button"
            phx-click="add_affiliation_link"
            class="btn btn-primary btn-sm"
            disabled={@new_link.title == "" || @new_link.url == ""}
          >
            <.icon name="hero-plus" class="h-4 w-4" />
            {gettext("Add Link")}
          </button>
        </div>
      </div>

      <%!-- Related Blog Posts Section --%>
      <div class="border-base-300 rounded-lg border p-4">
        <h3 class="mb-4 text-lg font-semibold">
          <.icon name="hero-document-text" class="inline h-5 w-5" />
          {gettext("Related Blog Posts")}
        </h3>

        <%= if is_nil(@project.id) do %>
          <p class="text-base-content/60 text-sm">
            {gettext("Save the project first to link blog posts.")}
          </p>
        <% else %>
          <%= if Enum.empty?(@linked_posts) do %>
            <p class="text-base-content/60 mb-4 text-sm">
              {gettext("No blog posts linked. Connect your project to related articles.")}
            </p>
          <% else %>
            <div class="mb-4 space-y-2">
              <%= for post <- @linked_posts do %>
                <div class="bg-base-200 flex items-center justify-between rounded-lg p-3">
                  <div class="flex-1">
                    <.link navigate={~p"/posts/#{post.id}"} class="link link-hover font-medium">
                      {post.title}
                    </.link>
                    <%= if post.published_at do %>
                      <span class="text-base-content/60 ml-2 text-sm">
                        {Calendar.strftime(post.published_at, "%Y-%m-%d")}
                      </span>
                    <% end %>
                  </div>
                  <button
                    type="button"
                    phx-click="unlink_post"
                    phx-value-id={post.id}
                    class="btn btn-ghost btn-sm text-error"
                    data-confirm={gettext("Remove this blog post from the project?")}
                  >
                    <.icon name="hero-x-mark" class="h-4 w-4" />
                  </button>
                </div>
              <% end %>
            </div>
          <% end %>

          <%!-- Post Selector (using hook to avoid form conflicts) --%>
          <%= if not Enum.empty?(@available_posts) do %>
            <div class="flex gap-2">
              <select
                id="post-selector"
                class="select select-bordered flex-1"
                phx-hook="SelectValue"
                data-event="select_post"
                data-field="post_id"
              >
                <option value="">{gettext("Select a blog post to link...")}</option>
                <%= for post <- @available_posts do %>
                  <option value={post.id} selected={@selected_post_id == post.id}>
                    {post.title}
                  </option>
                <% end %>
              </select>
              <button
                type="button"
                phx-click="link_post"
                class="btn btn-primary btn-sm"
                disabled={is_nil(@selected_post_id)}
              >
                <.icon name="hero-plus" class="h-4 w-4" />
                {gettext("Link")}
              </button>
            </div>
          <% else %>
            <%= if Enum.empty?(@linked_posts) do %>
              <p class="text-base-content/60 text-sm">
                {gettext("No blog posts available to link. Create some blog posts first.")}
              </p>
            <% else %>
              <p class="text-base-content/60 text-sm">
                {gettext("All your blog posts are already linked to this project.")}
              </p>
            <% end %>
          <% end %>
        <% end %>
      </div>

      <%!-- Info Alert for New Projects --%>
      <%= if is_nil(@project.id) do %>
        <div class="alert alert-info">
          <.icon name="hero-information-circle" class="h-5 w-5" />
          <span>
            {gettext(
              "Save your project first to add collaborators, links, and blog posts. You can come back to this step after creating the project."
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
