defmodule HomesiteWeb.ProjectLive.SteppedForm do
  use HomesiteWeb, :live_view

  alias Homesite.Content
  alias Homesite.Media
  alias Homesite.Media.Project
  alias Homesite.Media.ProjectTemplate

  import HomesiteWeb.ContentSectionComponents

  @steps [:basics, :metadata, :team, :settings, :content]

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
     # Tag-related state
     |> assign(:selected_tags, [])
     |> assign(:tag_search_query, "")
     |> assign(:tag_suggestions, [])
     |> assign(:similar_tags_warning, nil)
     # Media picker state
     |> assign(:media_items, [])
     |> assign(:gallery_items, [])
     |> assign(:show_media_picker, false)
     |> assign(:media_picker_mode, :cover)
     # Content sections state
     |> assign(:content_sections, [])
     |> assign(:editing_section_id, nil)
     |> assign(:section_form, nil)
     # Section modal state (for editing outside nested form)
     |> assign(:show_section_modal, false)
     |> assign(:modal_section, nil)
     |> assign(:modal_section_form, nil)
     |> assign_form(project)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    # Restore step from URL params if present (survives reconnection)
    step_index = parse_step_param(params["step"], socket.assigns.step_index)
    step = Enum.at(@steps, step_index)

    socket =
      socket
      |> assign(:step_index, step_index)
      |> assign(:current_step, step)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp parse_step_param(nil, current), do: current
  defp parse_step_param(step_str, _current) do
    case Integer.parse(step_str) do
      {n, ""} when n >= 0 and n < length(@steps) -> n
      _ -> 0
    end
  end

  defp apply_action(socket, :new, _params) do
    # Set default project_date to today for new projects
    project = %Project{project_date: Date.utc_today()}

    socket
    |> assign(:project, project)
    |> assign(:page_title, gettext("New Project"))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    project =
      Media.get_project!(socket.assigns.current_scope, id)
      |> Homesite.Repo.preload([:tags, :media_items, :cover_media_item])

    # Load collaborators, affiliation links, and linked posts
    collaborators = Media.list_collaborators(socket.assigns.current_scope, id)
    affiliation_links = Media.list_affiliation_links(socket.assigns.current_scope, id)
    linked_posts = Media.list_project_posts(socket.assigns.current_scope, id)
    available_posts = Media.list_available_posts_for_project(socket.assigns.current_scope, id)

    # Load user's media items for picker
    media_items = Media.list_media_items(socket.assigns.current_scope)

    # Load content sections
    content_sections = Media.list_content_sections(socket.assigns.current_scope, id)

    socket
    |> assign(:project, project)
    |> assign(:page_title, gettext("Edit Project"))
    |> assign(:collaborators, collaborators)
    |> assign(:affiliation_links, affiliation_links)
    |> assign(:linked_posts, linked_posts)
    |> assign(:available_posts, available_posts)
    |> assign(:completion_percentage, project.completion_percentage || 0)
    |> assign(:selected_tags, project.tags || [])
    |> assign(:media_items, media_items)
    |> assign(:gallery_items, project.media_items || [])
    |> assign(:content_sections, content_sections)
  end

  @impl true
  def handle_event("validate", %{"project" => project_params}, socket) do
    # Add tag_ids from selected_tags
    project_params = add_tag_ids(project_params, socket.assigns.selected_tags)

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
      {:noreply, navigate_to_step(socket, new_index)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("prev_step", _params, socket) do
    current_index = socket.assigns.step_index

    if current_index > 0 do
      new_index = current_index - 1
      {:noreply, navigate_to_step(socket, new_index)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("skip_to_save", _params, socket) do
    # Jump to settings step (index 3)
    {:noreply, navigate_to_step(socket, 3)}
  end

  def handle_event("skip_to_content", _params, socket) do
    # Jump to content step (index 4)
    {:noreply, navigate_to_step(socket, 4)}
  end

  # Navigate to a step and update URL to preserve state across reconnects
  defp navigate_to_step(socket, step_index) do
    new_step = Enum.at(@steps, step_index)

    socket
    |> assign(:step_index, step_index)
    |> assign(:current_step, new_step)
    |> push_patch_with_step(step_index)
  end

  defp push_patch_with_step(socket, step_index) do
    case socket.assigns.live_action do
      :edit ->
        push_patch(socket, to: ~p"/projects/#{socket.assigns.project.id}/edit?step=#{step_index}")
      :new ->
        push_patch(socket, to: ~p"/projects/new?step=#{step_index}")
    end
  end

  def handle_event(
        "save",
        %{"action" => "save_and_add_content", "project" => project_params},
        socket
      ) do
    # Handle "Save & Add Content" button click
    project_params = add_tag_ids(project_params, socket.assigns.selected_tags)

    case save_project_and_continue(socket, project_params) do
      {:ok, socket} ->
        {:noreply, navigate_to_step(socket, 4)}

      {:error, socket} ->
        {:noreply, socket}
    end
  end

  def handle_event("save", %{"project" => project_params}, socket) do
    # Handle regular "Save Project" button click
    # Note: action may be "save" or absent depending on which button was clicked
    project_params = add_tag_ids(project_params, socket.assigns.selected_tags)
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

  # Tag search and selection events
  def handle_event("search-tags", %{"value" => query}, socket) do
    if String.length(query) >= 2 do
      suggestions = Content.list_all_public_tags(query)
      similar_warning = if query != "", do: Content.find_similar_tags(query, nil, 3), else: []

      {:noreply,
       socket
       |> assign(:tag_search_query, query)
       |> assign(:tag_suggestions, suggestions)
       |> assign(:similar_tags_warning, similar_warning)}
    else
      {:noreply,
       socket
       |> assign(:tag_search_query, query)
       |> assign(:tag_suggestions, [])
       |> assign(:similar_tags_warning, nil)}
    end
  end

  def handle_event("add-tag", %{"id" => tag_id}, socket) do
    tag_id = String.to_integer(tag_id)
    {tag, _count} = Enum.find(socket.assigns.tag_suggestions, fn {t, _} -> t.id == tag_id end)

    if tag && not Enum.any?(socket.assigns.selected_tags, &(&1.id == tag_id)) do
      {:noreply,
       socket
       |> assign(:selected_tags, socket.assigns.selected_tags ++ [tag])
       |> assign(:tag_search_query, "")
       |> assign(:tag_suggestions, [])
       |> assign(:similar_tags_warning, nil)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("remove-tag", %{"id" => tag_id}, socket) do
    tag_id = String.to_integer(tag_id)
    selected_tags = Enum.reject(socket.assigns.selected_tags, &(&1.id == tag_id))
    {:noreply, assign(socket, :selected_tags, selected_tags)}
  end

  def handle_event("create-and-add-tag", %{"name" => name}, socket) do
    case Content.get_or_create_tag(socket.assigns.current_scope, %{"name" => name}) do
      {:ok, tag} ->
        if not Enum.any?(socket.assigns.selected_tags, &(&1.id == tag.id)) do
          {:noreply,
           socket
           |> assign(:selected_tags, socket.assigns.selected_tags ++ [tag])
           |> assign(:tag_search_query, "")
           |> assign(:tag_suggestions, [])
           |> assign(:similar_tags_warning, nil)}
        else
          {:noreply,
           socket
           |> assign(:tag_search_query, "")
           |> assign(:tag_suggestions, [])
           |> put_flash(:info, gettext("Tag already selected"))}
        end

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to create tag"))}
    end
  end

  # Media picker events
  def handle_event("open_media_picker", %{"mode" => mode}, socket) do
    {:noreply,
     socket
     |> assign(:show_media_picker, true)
     |> assign(:media_picker_mode, safe_to_atom(mode))}
  end

  def handle_event("close_media_picker", _params, socket) do
    {:noreply, assign(socket, :show_media_picker, false)}
  end

  def handle_event("select_cover", %{"id" => id}, socket) do
    media_item_id = String.to_integer(id)

    case Media.update_project(
           socket.assigns.current_scope,
           socket.assigns.project,
           %{"cover_media_item_id" => media_item_id}
         ) do
      {:ok, project} ->
        project = Homesite.Repo.preload(project, [:cover_media_item], force: true)

        {:noreply,
         socket
         |> assign(:project, project)
         |> assign(:show_media_picker, false)
         |> put_flash(:info, gettext("Cover image updated"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to update cover image"))}
    end
  end

  def handle_event("remove_cover", _params, socket) do
    case Media.update_project(
           socket.assigns.current_scope,
           socket.assigns.project,
           %{"cover_media_item_id" => nil}
         ) do
      {:ok, project} ->
        {:noreply,
         socket
         |> assign(:project, %{project | cover_media_item: nil})
         |> put_flash(:info, gettext("Cover image removed"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to remove cover image"))}
    end
  end

  def handle_event("toggle_gallery_item", %{"id" => id}, socket) do
    media_item_id = String.to_integer(id)
    gallery_ids = Enum.map(socket.assigns.gallery_items, & &1.id)

    if media_item_id in gallery_ids do
      # Remove from gallery
      Media.remove_media_from_project(
        socket.assigns.current_scope,
        socket.assigns.project.id,
        media_item_id
      )

      gallery_items = Enum.reject(socket.assigns.gallery_items, &(&1.id == media_item_id))
      {:noreply, assign(socket, :gallery_items, gallery_items)}
    else
      # Add to gallery
      display_order = length(gallery_ids)

      Media.add_media_to_project(
        socket.assigns.current_scope,
        socket.assigns.project.id,
        media_item_id,
        display_order
      )

      media_item = Enum.find(socket.assigns.media_items, &(&1.id == media_item_id))
      gallery_items = socket.assigns.gallery_items ++ [media_item]

      # Auto-set cover if none set
      socket =
        if is_nil(socket.assigns.project.cover_media_item_id) do
          {:ok, project} =
            Media.update_project(
              socket.assigns.current_scope,
              socket.assigns.project,
              %{"cover_media_item_id" => media_item_id}
            )

          project = Homesite.Repo.preload(project, [:cover_media_item], force: true)
          assign(socket, :project, project)
        else
          socket
        end

      {:noreply, assign(socket, :gallery_items, gallery_items)}
    end
  end

  # Content Section Events
  def handle_event("add_section", %{"type" => section_type}, socket) do
    project_id = socket.assigns.project.id

    if project_id do
      # Get next display_order
      sections = socket.assigns.content_sections

      next_order =
        if Enum.empty?(sections),
          do: 0,
          else: Enum.max_by(sections, & &1.display_order).display_order + 1

      attrs = %{
        "section_type" => section_type,
        "title" => default_section_title(section_type),
        "project_id" => project_id,
        "display_order" => next_order
      }

      case Media.create_content_section(socket.assigns.current_scope, attrs) do
        {:ok, section} ->
          sections = Media.list_content_sections(socket.assigns.current_scope, project_id)
          section_form = build_section_form(section, socket.assigns.current_scope)

          {:noreply,
           socket
           |> assign(:content_sections, sections)
           |> assign(:editing_section_id, section.id)
           |> assign(:section_form, section_form)
           |> assign(:show_section_modal, true)
           |> assign(:modal_section, section)
           |> assign(:modal_section_form, section_form)
           |> put_flash(:info, gettext("Section added"))}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to add section"))}
      end
    else
      {:noreply,
       put_flash(socket, :info, gettext("Save the project first, then you can add sections"))}
    end
  end

  # Section editing via modal (avoids nested form issue)
  def handle_event("edit_section", %{"id" => id}, socket) do
    id = String.to_integer(id)
    section = Media.get_content_section!(socket.assigns.current_scope, id)
    section_form = build_section_form(section, socket.assigns.current_scope)

    {:noreply,
     socket
     |> assign(:show_section_modal, true)
     |> assign(:modal_section, section)
     |> assign(:modal_section_form, section_form)
     # Keep old assigns for compatibility
     |> assign(:editing_section_id, id)
     |> assign(:section_form, section_form)}
  end

  def handle_event("cancel_section_edit", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_section_modal, false)
     |> assign(:modal_section, nil)
     |> assign(:modal_section_form, nil)
     |> assign(:editing_section_id, nil)
     |> assign(:section_form, nil)}
  end

  def handle_event("close_section_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_section_modal, false)
     |> assign(:modal_section, nil)
     |> assign(:modal_section_form, nil)
     |> assign(:editing_section_id, nil)
     |> assign(:section_form, nil)}
  end

  def handle_event("validate_section", %{"section" => section_params}, socket) do
    section =
      socket.assigns.modal_section ||
        Media.get_content_section!(
          socket.assigns.current_scope,
          socket.assigns.editing_section_id
        )

    changeset =
      section
      |> Homesite.Media.ContentSection.changeset(section_params, socket.assigns.current_scope)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:modal_section_form, to_form(changeset))
     |> assign(:section_form, to_form(changeset))}
  end

  def handle_event("save_section", %{"section" => section_params}, socket) do
    section =
      socket.assigns.modal_section ||
        Media.get_content_section!(
          socket.assigns.current_scope,
          socket.assigns.editing_section_id
        )

    case Media.update_content_section(socket.assigns.current_scope, section, section_params) do
      {:ok, _section} ->
        sections =
          Media.list_content_sections(socket.assigns.current_scope, socket.assigns.project.id)

        {:noreply,
         socket
         |> assign(:content_sections, sections)
         |> assign(:show_section_modal, false)
         |> assign(:modal_section, nil)
         |> assign(:modal_section_form, nil)
         |> assign(:editing_section_id, nil)
         |> assign(:section_form, nil)
         |> put_flash(:info, gettext("Section updated"))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:modal_section_form, to_form(changeset))
         |> assign(:section_form, to_form(changeset))}
    end
  end

  def handle_event("delete_section", %{"id" => id}, socket) do
    id = String.to_integer(id)
    section = Media.get_content_section!(socket.assigns.current_scope, id)

    case Media.delete_content_section(socket.assigns.current_scope, section) do
      {:ok, _} ->
        sections =
          Media.list_content_sections(socket.assigns.current_scope, socket.assigns.project.id)

        {:noreply,
         socket
         |> assign(:content_sections, sections)
         |> assign(:editing_section_id, nil)
         |> assign(:section_form, nil)
         |> put_flash(:info, gettext("Section deleted"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to delete section"))}
    end
  end

  def handle_event("reorder_sections", %{"order" => order}, socket) do
    # order is a list of section IDs as strings
    ordered_ids = Enum.map(order, &String.to_integer/1)

    :ok =
      Media.reorder_content_sections(
        socket.assigns.current_scope,
        socket.assigns.project.id,
        ordered_ids
      )

    sections =
      Media.list_content_sections(socket.assigns.current_scope, socket.assigns.project.id)

    {:noreply, assign(socket, :content_sections, sections)}
  end

  defp default_section_title(section_type) do
    case section_type do
      "rich_text" -> gettext("Text Section")
      "code_block" -> gettext("Code")
      "book_info" -> gettext("Book Information")
      "chapter" -> gettext("Chapter")
      "gear_spec" -> gettext("Specifications")
      "movie_info" -> gettext("Movie Information")
      _ -> gettext("New Section")
    end
  end

  defp build_section_form(section, scope) do
    section
    |> Homesite.Media.ContentSection.changeset(%{}, scope)
    |> to_form()
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

  # Safely convert media picker mode to atom (whitelist approach)
  @allowed_media_picker_modes ~w(cover gallery section)a
  defp safe_to_atom(mode) when is_binary(mode) do
    atom = String.to_existing_atom(mode)
    if atom in @allowed_media_picker_modes, do: atom, else: :cover
  rescue
    ArgumentError -> :cover
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

  # Add tag_ids to params from selected tags
  defp add_tag_ids(params, selected_tags) do
    tag_ids = Enum.map(selected_tags, & &1.id)
    Map.put(params, "tag_ids", tag_ids)
  end

  # Save project and return socket for continuing to content step
  defp save_project_and_continue(socket, project_params) do
    case socket.assigns.live_action do
      :new ->
        case Media.create_project(socket.assigns.current_scope, project_params) do
          {:ok, project} ->
            project =
              project
              |> Homesite.Repo.preload([:tags, :media_items, :cover_media_item])

            media_items = Media.list_media_items(socket.assigns.current_scope)

            {:ok,
             socket
             |> assign(:project, project)
             |> assign(:live_action, :edit)
             |> assign(:media_items, media_items)
             |> assign(:gallery_items, [])
             |> put_flash(:info, gettext("Project created. Now add content!"))}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:error, assign_form(socket, changeset)}
        end

      :edit ->
        case Media.update_project(
               socket.assigns.current_scope,
               socket.assigns.project,
               project_params
             ) do
          {:ok, project} ->
            {:ok, project} =
              Media.update_project_completion(socket.assigns.current_scope, project.id)

            project =
              project
              |> Homesite.Repo.preload([:tags, :media_items, :cover_media_item], force: true)

            {:ok,
             socket
             |> assign(:project, project)
             |> assign(:gallery_items, project.media_items)
             |> assign(:completion_percentage, project.completion_percentage)
             |> put_flash(:info, gettext("Project saved. Now add content!"))}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:error, assign_form(socket, changeset)}
        end
    end
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
      <div class="px-[var(--space-sm)] py-[var(--space-lg)] mx-auto w-full max-w-4xl">
        <%!-- Page Header --%>
        <div class="mb-[var(--space-lg)]">
          <h1 class="text-[var(--text-2xl)] font-bold">{@page_title}</h1>
          <.link
            navigate={~p"/projects"}
            class="text-base-content/70 text-[var(--text-sm)] hover:text-base-content"
          >
            <.icon name="hero-arrow-left" class="inline h-4 w-4" /> {gettext("Back to projects")}
          </.link>
        </div>

        <%!-- Progress Steps --%>
        <ul class="steps steps-horizontal mb-[var(--space-lg)] w-full">
          <li class={"#{if @step_index >= 0, do: "step-primary"} step"}>
            {gettext("Basics")}
          </li>
          <li class={"#{if @step_index >= 1, do: "step-primary"} step"}>
            {gettext("Metadata")}
          </li>
          <li class={"#{if @step_index >= 2, do: "step-primary"} step"}>
            {gettext("Team")}
          </li>
          <li class={"#{if @step_index >= 3, do: "step-primary"} step"}>
            {gettext("Settings")}
          </li>
          <li class={"#{if @step_index >= 4, do: "step-primary"} step"}>
            {gettext("Content")}
          </li>
        </ul>

        <%!-- Completion Badge --%>
        <div class="alert alert-info mb-[var(--space-md)]">
          <.icon name="hero-information-circle" class="h-5 w-5" />
          <span>
            {gettext("Project completion")}: {@completion_percentage}%
            <%= if @completion_percentage < 100 do %>
              - {gettext("Add more details to make your project stand out!")}
            <% end %>
          </span>
        </div>

        <%!-- Step Content --%>
        <.form
          for={@form}
          id="project-form"
          phx-submit="save"
          phx-change="validate"
          class="space-y-[var(--space-md)]"
        >
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
            <input type="hidden" name={@form[:project_date].name} value={@form[:project_date].value} />
          <% end %>

          <%= case @current_step do %>
            <% :basics -> %>
              <.render_basics_step form={@form} />
            <% :metadata -> %>
              <.render_metadata_step
                form={@form}
                selected_tags={@selected_tags}
                tag_search_query={@tag_search_query}
                tag_suggestions={@tag_suggestions}
                similar_tags_warning={@similar_tags_warning}
              />
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
              <.render_settings_step form={@form} project={@project} />
            <% :content -> %>
              <.render_content_step
                project={@project}
                media_items={@media_items}
                gallery_items={@gallery_items}
                show_media_picker={@show_media_picker}
                media_picker_mode={@media_picker_mode}
                content_sections={@content_sections}
                editing_section_id={@editing_section_id}
                section_form={@section_form}
              />
          <% end %>

          <%!-- Navigation Buttons --%>
          <div class="border-base-300 mt-[var(--space-lg)] pt-[var(--space-md)] flex justify-between border-t">
            <%= if @step_index > 0 && @step_index < 4 do %>
              <button type="button" phx-click="prev_step" class="btn btn-ghost">
                <.icon name="hero-arrow-left" class="h-4 w-4" /> {gettext("Back")}
              </button>
            <% else %>
              <div></div>
            <% end %>

            <div class="gap-[var(--space-xs)] flex flex-wrap justify-end">
              <%= cond do %>
                <% @step_index < 3 -> %>
                  <%!-- Steps 1-3: Next button + Skip to Content for existing projects --%>
                  <%= if @project.id do %>
                    <button type="button" phx-click="skip_to_content" class="btn btn-ghost">
                      {gettext("Skip to Content")}
                    </button>
                  <% end %>
                  <button type="button" phx-click="next_step" class="btn btn-primary">
                    {gettext("Next")} <.icon name="hero-arrow-right" class="h-4 w-4" />
                  </button>
                <% @step_index == 3 -> %>
                  <%!-- Step 4 (Settings): Save options --%>
                  <%= if @project.id do %>
                    <button type="button" phx-click="skip_to_content" class="btn btn-ghost">
                      {gettext("Skip to Content")}
                    </button>
                  <% end %>
                  <button type="submit" name="action" value="save" class="btn btn-outline">
                    <.icon name="hero-check" class="h-4 w-4" /> {gettext("Save Project")}
                  </button>
                  <button
                    type="submit"
                    name="action"
                    value="save_and_add_content"
                    class="btn btn-primary"
                  >
                    <.icon name="hero-photo" class="h-4 w-4" /> {gettext("Save & Add Content")}
                  </button>
                <% @step_index == 4 -> %>
                  <%!-- Step 5 (Content): Done button --%>
                  <.link navigate={~p"/projects/#{@project.id}"} class="btn btn-success">
                    <.icon name="hero-check" class="h-4 w-4" /> {gettext("Done")}
                  </.link>
              <% end %>
            </div>
          </div>
        </.form>

        <%!-- Section Edit Modal - rendered OUTSIDE the main form to avoid nested form issues --%>
        <%= if @show_section_modal && @modal_section do %>
          <.section_edit_modal section={@modal_section} form={@modal_section_form} />
        <% end %>
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
    <div class="space-y-[var(--space-md)]">
      <h2 class="text-[var(--text-2xl)] font-semibold">{gettext("Step 1: Project Basics")}</h2>
      <p class="text-base-content/70">
        {gettext("Start with the essential information about your project.")}
      </p>

      <%!-- Template Selector --%>
      <div class="form-control">
        <label class="label">
          <span class="label-text font-medium">{gettext("Project Type")}</span>
        </label>
        <div class="gap-[var(--space-xs)] grid grid-cols-2 md:grid-cols-4">
          <%= for template <- @templates do %>
            <label class={[
              "card p-[var(--space-sm)] cursor-pointer border-2 text-center transition-all hover:shadow-md",
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
              <.icon name={template.icon} class="mb-[var(--space-xs)] mx-auto h-8 w-8" />
              <span class="text-[var(--text-sm)] font-medium">{template.name}</span>
            </label>
          <% end %>
        </div>
        <p class="text-base-content/60 text-[var(--text-sm)] mt-[var(--space-xs)]">
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
      <p class="text-[var(--text-xs)] text-base-content/60 -mt-2">
        {gettext("Maximum 1000 characters")}
      </p>

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

    assigns = assign(assigns, :template, template)

    ~H"""
    <div class="space-y-[var(--space-md)]">
      <h2 class="text-[var(--text-2xl)] font-semibold">{gettext("Step 2: Project Metadata")}</h2>
      <p class="text-base-content/70">
        {gettext("Add context to help viewers understand your project. All fields are optional.")}
      </p>

      <%!-- Template indicator --%>
      <div class="bg-base-200 gap-[var(--space-xs)] p-[var(--space-xs)] flex items-center rounded-lg">
        <.icon name={@template.icon} class="text-primary h-5 w-5" />
        <span class="text-[var(--text-sm)]">
          {gettext("Project type:")} <strong>{@template.name}</strong>
        </span>
      </div>

      <.input
        field={@form[:category]}
        type="text"
        label={@template.fields.category.label}
        placeholder={@template.fields.category.placeholder}
      />

      <%!-- Tag Picker --%>
      <div class="form-control">
        <label class="label">
          <span class="label-text font-medium">{@template.fields.tags.label}</span>
        </label>

        <%!-- Selected Tags Display --%>
        <%= if length(@selected_tags) > 0 do %>
          <div class="gap-[var(--space-xs)] mb-[var(--space-xs)] flex flex-wrap">
            <%= for tag <- @selected_tags do %>
              <span class="badge badge-primary gap-[var(--space-inline)]">
                {tag.name}
                <button
                  type="button"
                  phx-click="remove-tag"
                  phx-value-id={tag.id}
                  class="hover:text-error"
                >
                  <.icon name="hero-x-mark" class="h-3 w-3" />
                </button>
              </span>
            <% end %>
          </div>
        <% end %>

        <%!-- Tag Search Input --%>
        <div class="relative">
          <input
            type="text"
            value={@tag_search_query}
            placeholder={gettext("Search or create tags...")}
            class="input input-bordered w-full"
            phx-keyup="search-tags"
            phx-debounce="300"
            autocomplete="off"
          />

          <%!-- Suggestions Dropdown --%>
          <%= if length(@tag_suggestions) > 0 || (@tag_search_query != "" && String.length(@tag_search_query) >= 2) do %>
            <div class="bg-base-100 border-base-300 absolute z-10 mt-1 w-full rounded-lg border shadow-lg">
              <%= for {tag, count} <- @tag_suggestions do %>
                <button
                  type="button"
                  phx-click="add-tag"
                  phx-value-id={tag.id}
                  class="w-full px-4 py-2 text-left first:rounded-t-lg last:rounded-b-lg hover:bg-base-200"
                >
                  <span class="font-medium">{tag.name}</span>
                  <span class="text-base-content/60 text-[var(--text-sm)] ml-2">
                    ({count} {ngettext("use", "uses", count)})
                  </span>
                </button>
              <% end %>

              <%!-- Create new tag option --%>
              <%= if @tag_search_query != "" && String.length(@tag_search_query) >= 2 && !Enum.any?(@tag_suggestions, fn {t, _} -> String.downcase(t.name) == String.downcase(@tag_search_query) end) do %>
                <button
                  type="button"
                  phx-click="create-and-add-tag"
                  phx-value-name={@tag_search_query}
                  class="text-primary w-full px-4 py-2 text-left hover:bg-primary/10"
                >
                  <.icon name="hero-plus" class="mr-1 inline h-4 w-4" />
                  {gettext("Create")} "<strong>{@tag_search_query}</strong>"
                </button>
              <% end %>
            </div>
          <% end %>
        </div>

        <%!-- Similar tags warning --%>
        <%= if @similar_tags_warning && length(@similar_tags_warning) > 0 do %>
          <div class="mt-[var(--space-xs)] text-[var(--text-sm)] text-warning">
            <.icon name="hero-exclamation-triangle" class="inline h-4 w-4" />
            {gettext("Similar tags exist:")}
            <%= for similar <- @similar_tags_warning do %>
              <span class="badge badge-warning badge-sm ml-1">{similar.name}</span>
            <% end %>
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
    <div class="space-y-[var(--space-md)]">
      <h2 class="text-[var(--text-2xl)] font-semibold">{gettext("Step 3: Team & Links")}</h2>
      <p class="text-base-content/70">
        {gettext("Credit collaborators and add related links. All fields are optional.")}
      </p>

      <%!-- Collaborators Section --%>
      <div class="border-base-300 p-[var(--space-sm)] rounded-lg border">
        <h3 class="text-[var(--text-lg)] mb-[var(--space-sm)] font-semibold">
          {gettext("Collaborators")}
        </h3>

        <%= if Enum.empty?(@collaborators) do %>
          <p class="text-base-content/60 text-[var(--text-sm)] mb-[var(--space-sm)]">
            {gettext("No collaborators added yet. Add team members who worked on this project.")}
          </p>
        <% else %>
          <div class="mb-[var(--space-sm)] space-y-[var(--space-xs)]">
            <%= for collaborator <- @collaborators do %>
              <div class="bg-base-200 p-[var(--space-xs)] flex items-center justify-between rounded-lg">
                <div class="flex-1">
                  <span class="font-medium">{collaborator.name}</span>
                  <%= if collaborator.contact_type != "none" do %>
                    <span class="text-base-content/60 text-[var(--text-sm)] ml-[var(--space-xs)]">
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
        <div class="space-y-[var(--space-xs)]" id={"collaborator-inputs-#{@input_reset_key}"}>
          <div class="gap-[var(--space-xs)] grid grid-cols-1 md:grid-cols-2">
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
          <div class="gap-[var(--space-xs)] flex items-center">
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
      <div class="border-base-300 p-[var(--space-sm)] rounded-lg border">
        <h3 class="text-[var(--text-lg)] mb-[var(--space-sm)] font-semibold">
          {gettext("Related Links")}
        </h3>

        <%= if Enum.empty?(@affiliation_links) do %>
          <p class="text-base-content/60 text-[var(--text-sm)] mb-[var(--space-sm)]">
            {gettext("No links added yet. Add client websites, press coverage, or related projects.")}
          </p>
        <% else %>
          <div class="mb-[var(--space-sm)] space-y-[var(--space-xs)]">
            <%= for link <- @affiliation_links do %>
              <div class="bg-base-200 p-[var(--space-xs)] flex items-center justify-between rounded-lg">
                <div class="flex-1">
                  <span class="font-medium">{link.title}</span>
                  <a
                    href={link.url}
                    target="_blank"
                    class="text-primary text-[var(--text-sm)] ml-[var(--space-xs)] hover:underline"
                  >
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
        <div class="space-y-[var(--space-xs)]" id={"link-inputs-#{@input_reset_key}"}>
          <div class="gap-[var(--space-xs)] grid grid-cols-1 md:grid-cols-2">
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
      <div class="border-base-300 p-[var(--space-sm)] rounded-lg border">
        <h3 class="text-[var(--text-lg)] mb-[var(--space-sm)] font-semibold">
          <.icon name="hero-document-text" class="inline h-5 w-5" />
          {gettext("Related Blog Posts")}
        </h3>

        <%= if is_nil(@project.id) do %>
          <p class="text-base-content/60 text-[var(--text-sm)]">
            {gettext("Save the project first to link blog posts.")}
          </p>
        <% else %>
          <%= if Enum.empty?(@linked_posts) do %>
            <p class="text-base-content/60 text-[var(--text-sm)] mb-[var(--space-sm)]">
              {gettext("No blog posts linked. Connect your project to related articles.")}
            </p>
          <% else %>
            <div class="mb-[var(--space-sm)] space-y-[var(--space-xs)]">
              <%= for post <- @linked_posts do %>
                <div class="bg-base-200 p-[var(--space-xs)] flex items-center justify-between rounded-lg">
                  <div class="flex-1">
                    <.link navigate={~p"/posts/#{post.id}"} class="link link-hover font-medium">
                      {post.title}
                    </.link>
                    <%= if post.published_at do %>
                      <span class="text-base-content/60 text-[var(--text-sm)] ml-[var(--space-xs)]">
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
            <div class="gap-[var(--space-xs)] flex">
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
              <p class="text-base-content/60 text-[var(--text-sm)]">
                {gettext("No blog posts available to link. Create some blog posts first.")}
              </p>
            <% else %>
              <p class="text-base-content/60 text-[var(--text-sm)]">
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
    <div class="space-y-[var(--space-md)]">
      <h2 class="text-[var(--text-2xl)] font-semibold">{gettext("Step 4: Visibility & Settings")}</h2>
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
        <div>
          <p class="font-medium">{gettext("Ready to save!")}</p>
          <p class="text-[var(--text-sm)] opacity-80">
            {gettext("Save your project, or save and continue to add images and content.")}
          </p>
        </div>
      </div>
    </div>
    """
  end

  defp render_content_step(assigns) do
    template_type = assigns.project.template_type || "photography"
    template = ProjectTemplate.get(template_type) || ProjectTemplate.get("photography")

    tip =
      case template_type do
        "photography" -> gettext("Add your best shots. First image becomes cover.")
        "coding" -> gettext("Screenshots, architecture diagrams, or demo GIFs work great.")
        "writing" -> gettext("Add cover art or related imagery.")
        "books" -> gettext("Book covers and interior shots.")
        "gears" -> gettext("Product photos from multiple angles.")
        "movies" -> gettext("Posters, stills, or behind-the-scenes.")
        _ -> gettext("Add images to showcase your project.")
      end

    assigns =
      assigns
      |> assign(:template, template)
      |> assign(:tip, tip)

    ~H"""
    <div class="space-y-[var(--space-md)]">
      <h2 class="text-[var(--text-2xl)] font-semibold">{gettext("Step 5: Content")}</h2>
      <p class="text-base-content/70">
        {gettext("Add images to your project gallery.")}
      </p>

      <%!-- Template tip --%>
      <div class="alert alert-info">
        <.icon name={@template.icon} class="h-5 w-5" />
        <span>{@tip}</span>
      </div>

      <%!-- Cover Image Section --%>
      <div class="border-base-300 p-[var(--space-sm)] rounded-lg border">
        <h3 class="text-[var(--text-lg)] mb-[var(--space-sm)] font-semibold">
          <.icon name="hero-star" class="inline h-5 w-5" />
          {gettext("Cover Image")}
        </h3>

        <%= if @project.cover_media_item do %>
          <div class="flex items-start gap-4">
            <img
              src={"data:#{@project.cover_media_item.content_type};base64,#{Base.encode64(@project.cover_media_item.thumb_data)}"}
              alt={@project.cover_media_item.alt_text}
              class="h-32 w-32 rounded-lg object-cover"
            />
            <div class="flex flex-col gap-2">
              <p class="text-base-content/70 text-[var(--text-sm)]">
                {@project.cover_media_item.alt_text}
              </p>
              <div class="flex gap-2">
                <button
                  type="button"
                  phx-click="open_media_picker"
                  phx-value-mode="cover"
                  class="btn btn-sm btn-ghost"
                >
                  <.icon name="hero-arrow-path" class="h-4 w-4" />
                  {gettext("Change")}
                </button>
                <button type="button" phx-click="remove_cover" class="btn btn-sm btn-ghost text-error">
                  <.icon name="hero-trash" class="h-4 w-4" />
                  {gettext("Remove")}
                </button>
              </div>
            </div>
          </div>
        <% else %>
          <p class="text-base-content/60 text-[var(--text-sm)] mb-[var(--space-sm)]">
            {gettext("No cover image selected. The first gallery image will be used as cover.")}
          </p>
          <button
            type="button"
            phx-click="open_media_picker"
            phx-value-mode="cover"
            class="btn btn-primary btn-sm"
          >
            <.icon name="hero-photo" class="h-4 w-4" />
            {gettext("Select Cover Image")}
          </button>
        <% end %>
      </div>

      <%!-- Gallery Section --%>
      <div class="border-base-300 p-[var(--space-sm)] rounded-lg border">
        <h3 class="text-[var(--text-lg)] mb-[var(--space-sm)] font-semibold">
          <.icon name="hero-squares-2x2" class="inline h-5 w-5" />
          {gettext("Gallery Images")}
          <span class="text-base-content/60 text-[var(--text-sm)] ml-2">
            ({length(@gallery_items)} {ngettext("image", "images", length(@gallery_items))})
          </span>
        </h3>

        <%= if length(@gallery_items) > 0 do %>
          <div class="gap-[var(--space-sm)] mb-[var(--space-sm)] grid grid-cols-3 md:grid-cols-4 lg:grid-cols-5">
            <%= for item <- @gallery_items do %>
              <div class="group aspect-square relative">
                <img
                  src={"data:#{item.content_type};base64,#{Base.encode64(item.thumb_data)}"}
                  alt={item.alt_text}
                  class="h-full w-full rounded-lg object-cover"
                />
                <button
                  type="button"
                  phx-click="toggle_gallery_item"
                  phx-value-id={item.id}
                  class="bg-error absolute top-1 right-1 rounded-full p-1 text-white opacity-0 transition-opacity group-hover:opacity-100"
                >
                  <.icon name="hero-x-mark" class="h-4 w-4" />
                </button>
              </div>
            <% end %>
          </div>
        <% else %>
          <p class="text-base-content/60 text-[var(--text-sm)] mb-[var(--space-sm)]">
            {gettext("No images in gallery yet. Add images from your media library.")}
          </p>
        <% end %>

        <button
          type="button"
          phx-click="open_media_picker"
          phx-value-mode="gallery"
          class="btn btn-primary btn-sm"
        >
          <.icon name="hero-plus" class="h-4 w-4" />
          {gettext("Add Images")}
        </button>
      </div>

      <%!-- Content Sections --%>
      <div class="border-base-300 p-[var(--space-sm)] rounded-lg border">
        <div class="mb-[var(--space-sm)] flex items-center justify-between">
          <h3 class="text-[var(--text-lg)] font-semibold">
            <.icon name="hero-document-text" class="inline h-5 w-5" />
            {gettext("Content Sections")}
            <span class="text-base-content/60 text-[var(--text-sm)] ml-2">
              ({length(@content_sections)}
              {ngettext("section", "sections", length(@content_sections))})
            </span>
          </h3>
          <.add_section_dropdown available_types={@template.available_section_types} />
        </div>

        <div id="sections-list" phx-hook="SortableSections" class="space-y-[var(--space-sm)]">
          <%= for section <- @content_sections do %>
            <.content_section_card section={section} />
          <% end %>
        </div>
        <%= if Enum.empty?(@content_sections) do %>
          <p class="text-base-content/60 text-[var(--text-sm)]">
            {gettext(
              "No content sections yet. Use the dropdown above to add text, code, or structured data."
            )}
          </p>
        <% end %>
      </div>

      <%!-- Media Picker Modal --%>
      <%= if @show_media_picker do %>
        <div class="bg-black/50 fixed inset-0 z-50 flex items-center justify-center p-4">
          <div class="bg-base-100 max-h-[80vh] w-full max-w-4xl overflow-hidden rounded-xl shadow-2xl">
            <div class="border-base-300 flex items-center justify-between border-b p-4">
              <h3 class="text-[var(--text-lg)] font-semibold">
                <%= if @media_picker_mode == :cover do %>
                  {gettext("Select Cover Image")}
                <% else %>
                  {gettext("Add Gallery Images")}
                <% end %>
              </h3>
              <button type="button" phx-click="close_media_picker" class="btn btn-ghost btn-sm">
                <.icon name="hero-x-mark" class="h-5 w-5" />
              </button>
            </div>

            <div class="max-h-[60vh] overflow-y-auto p-4">
              <%= if length(@media_items) > 0 do %>
                <div class="gap-[var(--space-sm)] grid grid-cols-3 md:grid-cols-4 lg:grid-cols-5">
                  <%= for item <- @media_items do %>
                    <% in_gallery = Enum.any?(@gallery_items, &(&1.id == item.id)) %>
                    <button
                      type="button"
                      phx-click={
                        if @media_picker_mode == :cover,
                          do: "select_cover",
                          else: "toggle_gallery_item"
                      }
                      phx-value-id={item.id}
                      class={[
                        "group aspect-square relative overflow-hidden rounded-lg border-2 transition-all",
                        in_gallery && "border-primary ring-primary ring-2",
                        !in_gallery && "border-transparent hover:border-base-300"
                      ]}
                    >
                      <img
                        src={"data:#{item.content_type};base64,#{Base.encode64(item.thumb_data)}"}
                        alt={item.alt_text}
                        class="h-full w-full object-cover"
                      />
                      <%= if in_gallery do %>
                        <div class="bg-primary absolute top-1 right-1 rounded-full p-1 text-white">
                          <.icon name="hero-check" class="h-3 w-3" />
                        </div>
                      <% end %>
                    </button>
                  <% end %>
                </div>
              <% else %>
                <div class="py-8 text-center">
                  <.icon name="hero-photo" class="text-base-content/30 mx-auto mb-2 h-12 w-12" />
                  <p class="text-base-content/60">
                    {gettext("No media items yet.")}
                    <.link navigate={~p"/media"} class="link link-primary">
                      {gettext("Upload some images first.")}
                    </.link>
                  </p>
                </div>
              <% end %>
            </div>

            <div class="border-base-300 border-t p-4">
              <button type="button" phx-click="close_media_picker" class="btn btn-primary">
                {gettext("Done")}
              </button>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
