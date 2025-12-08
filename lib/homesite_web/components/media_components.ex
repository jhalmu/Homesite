defmodule HomesiteWeb.MediaComponents do
  @moduledoc """
  Media-related UI components for image galleries and lightbox views.
  """
  use Phoenix.Component
  use Gettext, backend: HomesiteWeb.Gettext

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
      <div class="text-white/80 absolute top-4 left-4 text-sm font-medium">
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
          <div class="mt-4 text-center text-white">
            <%= if @current_image.title do %>
              <h3 class="text-lg font-semibold">{@current_image.title}</h3>
            <% end %>
            <%= if @current_image.caption do %>
              <p class="text-white/70 mt-1 max-w-2xl text-sm">{@current_image.caption}</p>
            <% end %>
            <p class="text-white/50 mt-2 text-xs">
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
end
