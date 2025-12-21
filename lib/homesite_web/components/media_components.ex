defmodule HomesiteWeb.MediaComponents do
  @moduledoc """
  Media-related UI components for image galleries and lightbox views.
  """
  use Phoenix.Component
  use Gettext, backend: HomesiteWeb.Gettext
  use Phoenix.VerifiedRoutes, endpoint: HomesiteWeb.Endpoint, router: HomesiteWeb.Router

  import HomesiteWeb.CoreComponents, only: [icon: 1]

  alias Homesite.Media.ProjectTemplate

  @doc """
  Renders a lightbox component for full-screen image viewing.

  The lightbox displays images in a full-screen overlay with:
  - Previous/Next navigation
  - Keyboard support (Arrow keys, Escape)
  - Image counter
  - Close button

  ## Examples

      <.lightbox
        id="gallery-lightbox"
        images={@media_items}
        current_index={@lightbox_index}
        on_close="close_lightbox"
        on_prev="lightbox_prev"
        on_next="lightbox_next"
      />
  """
  attr :id, :string, required: true, doc: "Unique ID for the lightbox"
  attr :images, :list, required: true, doc: "List of media items with image data"
  attr :current_index, :integer, required: true, doc: "Current image index (0-based)"
  attr :on_close, :string, required: true, doc: "Event name for closing the lightbox"
  attr :on_prev, :string, required: true, doc: "Event name for previous image"
  attr :on_next, :string, required: true, doc: "Event name for next image"

  def lightbox(assigns) do
    assigns =
      assigns
      |> assign_new(:current_image, fn ->
        Enum.at(assigns.images, assigns.current_index)
      end)
      |> assign_new(:total_images, fn ->
        length(assigns.images)
      end)
      |> assign_new(:has_prev, fn ->
        assigns.current_index > 0
      end)
      |> assign_new(:has_next, fn ->
        assigns.current_index < length(assigns.images) - 1
      end)

    ~H"""
    <div
      id={@id}
      class="bg-black/95 fixed inset-0 z-50 flex items-center justify-center"
      phx-window-keydown="lightbox_keydown"
      phx-click={@on_close}
    >
      <%!-- Close button --%>
      <button
        type="button"
        class="btn btn-circle btn-ghost absolute top-4 right-4 z-10 text-white hover:bg-white/20"
        phx-click={@on_close}
        aria-label={gettext("Close lightbox")}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-8 w-8"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M6 18L18 6M6 6l12 12"
          />
        </svg>
      </button>

      <%!-- Image counter --%>
      <div class="text-white/80 text-[var(--text-sm)] absolute top-4 left-4 font-medium">
        {@current_index + 1} / {@total_images}
      </div>

      <%!-- Previous button --%>
      <button
        :if={@has_prev}
        type="button"
        class="btn btn-circle btn-ghost absolute top-1/2 left-4 -translate-y-1/2 text-white hover:bg-white/20"
        phx-click={@on_prev}
        aria-label={gettext("Previous image")}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-8 w-8"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
      </button>

      <%!-- Next button --%>
      <button
        :if={@has_next}
        type="button"
        class="btn btn-circle btn-ghost absolute top-1/2 right-4 -translate-y-1/2 text-white hover:bg-white/20"
        phx-click={@on_next}
        aria-label={gettext("Next image")}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-8 w-8"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
        </svg>
      </button>

      <%!-- Main image container --%>
      <div
        class="max-w-[90vw] max-h-[85vh] flex flex-col items-center"
        phx-click-away={@on_close}
        onclick="event.stopPropagation()"
      >
        <%= if @current_image do %>
          <img
            src={"data:#{@current_image.content_type};base64,#{Base.encode64(@current_image.large_data)}"}
            alt={@current_image.alt_text}
            class="max-h-[75vh] max-w-full rounded-lg object-contain shadow-2xl"
          />

          <%!-- Image info --%>
          <div class="mt-[var(--space-sm)] text-center text-white">
            <%= if @current_image.title do %>
              <h3 class="text-[var(--text-lg)] font-semibold">{@current_image.title}</h3>
            <% end %>
            <%= if @current_image.caption do %>
              <p class="text-white/70 mt-[var(--space-inline)] text-[var(--text-sm)] max-w-2xl">
                {@current_image.caption}
              </p>
            <% end %>
            <p class="text-white/50 mt-[var(--space-xs)] text-[var(--text-xs)]">
              {@current_image.width}&times;{@current_image.height}
            </p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Renders a clickable image thumbnail that opens the lightbox.

  ## Examples

      <.lightbox_thumbnail
        media={media_item}
        index={idx}
        on_click="open_lightbox"
      />
  """
  attr :media, :map, required: true, doc: "Media item with image data"
  attr :index, :integer, required: true, doc: "Index of this image in the gallery"
  attr :on_click, :string, required: true, doc: "Event name for opening lightbox"
  attr :class, :string, default: "", doc: "Additional CSS classes"

  def lightbox_thumbnail(assigns) do
    ~H"""
    <button
      type="button"
      class={[
        "cursor-zoom-in overflow-hidden rounded-lg focus:ring-primary focus:outline-none focus:ring-2",
        @class
      ]}
      phx-click={@on_click}
      phx-value-index={@index}
      aria-label={gettext("View %{title} in lightbox", title: @media.title || @media.alt_text)}
    >
      <img
        src={"data:#{@media.content_type};base64,#{Base.encode64(@media.medium_data)}"}
        alt={@media.alt_text}
        class="h-auto w-full object-cover transition-transform duration-200 hover:scale-105"
        loading="lazy"
      />
    </button>
    """
  end

  @doc """
  Renders a project card for use in profile pages, project lists, and portfolio galleries.

  ## Examples

      <.project_card project={project} />
      <.project_card project={project} show_template_badge={true} />
  """
  attr :project, :map, required: true, doc: "Project struct with name, slug, template_type, etc."

  attr :show_template_badge, :boolean,
    default: false,
    doc: "Whether to show the template type badge"

  attr :class, :string, default: "", doc: "Additional CSS classes"

  def project_card(assigns) do
    ~H"""
    <.link
      navigate={~p"/portfolio/#{@project.slug}"}
      class={["card bg-base-100 shadow transition-shadow hover:shadow-lg", @class]}
    >
      <figure class="bg-base-200 aspect-video">
        <%= if @project.cover_media_item do %>
          <img
            src={"data:#{@project.cover_media_item.content_type};base64,#{Base.encode64(@project.cover_media_item.medium_data)}"}
            alt={@project.name}
            class="h-full w-full object-cover"
          />
        <% else %>
          <div class="flex h-full w-full items-center justify-center">
            <.icon
              name={template_icon(@project.template_type)}
              class="text-base-content/30 h-12 w-12"
            />
          </div>
        <% end %>
      </figure>
      <div class="card-body p-4">
        <h3 class="card-title text-[var(--text-lg)]">{@project.name}</h3>
        <%= if @show_template_badge do %>
          <span class="badge badge-ghost badge-sm">{template_name(@project.template_type)}</span>
        <% end %>
        <%= if @project.categories && length(@project.categories) > 0 do %>
          <p class="text-base-content/60 text-[var(--text-sm)]">
            {Enum.join(@project.categories, ", ")}
          </p>
        <% end %>
      </div>
    </.link>
    """
  end

  # Helper functions for template icons and names
  defp template_icon(nil), do: "hero-folder"
  defp template_icon("photography"), do: "hero-camera"
  defp template_icon("coding"), do: "hero-code-bracket"
  defp template_icon("writing"), do: "hero-document-text"
  defp template_icon("books"), do: "hero-book-open"
  defp template_icon("gears"), do: "hero-wrench-screwdriver"
  defp template_icon("movies"), do: "hero-film"
  defp template_icon(_), do: "hero-squares-plus"

  defp template_name(nil), do: gettext("Project")

  defp template_name(type) when is_binary(type) do
    case ProjectTemplate.get(type) do
      nil -> type
      template -> template.name
    end
  end
end
