defmodule HomesiteWeb.FormComponents do
  @moduledoc """
  Provides reusable form components for the application.

  This module contains specialized form input components that are more complex
  than basic inputs and are used across multiple features.
  """
  use Phoenix.Component
  use Gettext, backend: HomesiteWeb.Gettext

  import HomesiteWeb.CoreComponents

  @doc """
  Renders a tag input with search, suggestions, and tag management.

  This component allows users to search for existing tags, add them to a post,
  create new tags, and displays warnings for similar tags.

  ## Examples

      <.tag_input
        selected_tags={@selected_tags}
        tag_search_query={@tag_search_query}
        tag_suggestions={@tag_suggestions}
        similar_tags_warning={@similar_tags_warning}
        on_search="search-tags"
        on_add="add-tag"
        on_remove="remove-tag"
        on_create="create-and-add-tag"
      />

  """
  attr :selected_tags, :list, required: true, doc: "list of currently selected tag structs"

  attr :tag_search_query, :string,
    required: true,
    doc: "current search query string"

  attr :tag_suggestions, :list,
    required: true,
    doc: "list of {tag, post_count} tuples from search"

  attr :similar_tags_warning, :list,
    default: [],
    doc: "list of similar tag structs to warn about"

  attr :on_search, :string, required: true, doc: "phx event name for search"
  attr :on_add, :string, required: true, doc: "phx event name for adding tag"
  attr :on_remove, :string, required: true, doc: "phx event name for removing tag"
  attr :on_create, :string, required: true, doc: "phx event name for creating new tag"

  attr :label, :string, default: nil, doc: "label for the tag input"
  attr :help_text, :string, default: nil, doc: "help text displayed below input"

  attr :field_name, :string,
    default: "post[tag_ids][]",
    doc: "hidden field name for form submission"

  def tag_input(assigns) do
    assigns =
      assigns
      |> assign_new(:label, fn -> gettext("Tags") end)
      |> assign_new(:help_text, fn ->
        gettext("Search for tags or type to create new ones")
      end)

    ~H"""
    <div class="form-control">
      <label :if={@label} class="label">
        <span class="label-text font-semibold">{@label}</span>
      </label>
      
    <!-- Selected tags -->
      <%= if @selected_tags != [] do %>
        <div class="mb-[var(--space-sm)] gap-[var(--space-xs)] flex flex-wrap">
          <%= for tag <- @selected_tags do %>
            <div class="badge badge-primary badge-lg gap-[var(--space-xs)]">
              {tag.name}
              <button
                type="button"
                phx-click={@on_remove}
                phx-value-tag-id={tag.id}
                class="btn btn-xs btn-ghost btn-circle"
                aria-label={gettext("Remove tag %{name}", name: tag.name)}
              >
                <.icon name="hero-x-mark" class="h-3 w-3" />
              </button>
            </div>
            <input type="hidden" name={@field_name} value={tag.id} />
          <% end %>
        </div>
      <% else %>
        <input type="hidden" name={@field_name} value="" />
      <% end %>
      
    <!-- Tag search/add -->
      <div class="relative">
        <input
          type="text"
          name="tag_search"
          value={@tag_search_query}
          phx-keyup={@on_search}
          phx-debounce="300"
          placeholder={gettext("Search or create tags...")}
          autocomplete="off"
          class="input input-bordered w-full"
          aria-label={gettext("Search tags")}
        />
        
    <!-- Suggestions dropdown -->
        <%= if @tag_suggestions != [] or @tag_search_query != "" do %>
          <div
            class="border-base-300 bg-base-100 mt-[var(--space-xs)] absolute z-10 max-h-60 w-full overflow-y-auto rounded-lg border shadow-lg"
            role="listbox"
          >
            <%= for {tag, post_count} <- @tag_suggestions do %>
              <button
                type="button"
                phx-click={@on_add}
                phx-value-tag-id={tag.id}
                class="px-[var(--space-sm)] py-[var(--space-xs)] flex w-full items-center justify-between text-left hover:bg-base-200"
                role="option"
              >
                <span>{tag.name}</span>
                <span class="text-base-content/60 text-[var(--text-sm)]">{post_count} posts</span>
              </button>
            <% end %>
            
    <!-- Add exact match button OR create new option -->
            <%= cond do %>
              <% exact_tag = find_exact_match(@tag_suggestions, @tag_search_query) -> %>
                <!-- Show "Add" button for exact match -->
                <button
                  type="button"
                  phx-click={@on_add}
                  phx-value-tag-id={exact_tag.id}
                  class="border-base-300 text-primary gap-[var(--space-xs)] px-[var(--space-sm)] py-[var(--space-xs)] flex w-full items-center border-t text-left font-semibold hover:bg-base-200"
                  role="option"
                >
                  <.icon name="hero-check" class="h-4 w-4" />
                  {gettext("Add")} "{exact_tag.name}"
                </button>
              <% @tag_search_query != "" -> %>
                <!-- Show "Create" button for new tag -->
                <button
                  type="button"
                  phx-click={@on_create}
                  phx-value-name={@tag_search_query}
                  class="border-base-300 gap-[var(--space-xs)] px-[var(--space-sm)] py-[var(--space-xs)] flex w-full items-center border-t text-left font-semibold hover:bg-base-200"
                  role="option"
                >
                  <.icon name="hero-plus" class="h-4 w-4" />
                  {gettext("Create")} "{@tag_search_query}"
                </button>
              <% true -> %>
                <!-- Empty query, show nothing -->
            <% end %>
          </div>
        <% end %>
      </div>
      
    <!-- Similar tags warning -->
      <%= if @similar_tags_warning != [] do %>
        <div class="alert alert-warning mt-[var(--space-sm)]">
          <.icon name="hero-information-circle" />
          <div>
            <p class="font-semibold">{gettext("Similar tags exist:")}</p>
            <div class="mt-[var(--space-xs)] gap-[var(--space-xs)] flex flex-wrap">
              <%= for tag <- @similar_tags_warning do %>
                <button
                  type="button"
                  phx-click={@on_add}
                  phx-value-tag-id={tag.id}
                  class="badge badge-sm badge-outline"
                >
                  {tag.name}
                </button>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>

      <p :if={@help_text} class="text-base-content/60 mt-[var(--space-sm)] text-[var(--text-sm)]">
        <.icon name="hero-tag" class="inline h-4 w-4" />
        {@help_text}
      </p>
    </div>
    """
  end

  @doc """
  Renders a date and time input pair with a "Now" button.

  This component provides separate date and time inputs that combine into
  a DateTime value. Includes a convenience button to set current time.

  ## Examples

      <.datetime_input
        date_field={@form[:publish_date]}
        time_field={@form[:publish_time]}
        value={@form[:published_at].value}
        label={gettext("Publication Date & Time")}
        on_set_now="set-time-now"
      />

  """
  attr :date_field, Phoenix.HTML.FormField,
    required: true,
    doc: "form field for date input"

  attr :time_field, Phoenix.HTML.FormField,
    required: true,
    doc: "form field for time input"

  attr :value, :any, default: nil, doc: "DateTime value to display"
  attr :label, :string, required: true, doc: "label for the datetime input"
  attr :help_text, :string, default: nil, doc: "help text displayed below inputs"
  attr :on_set_now, :string, required: true, doc: "phx event name for 'Now' button"

  def datetime_input(assigns) do
    assigns =
      assigns
      |> assign_new(:help_text, fn ->
        gettext("Select when this post should be published")
      end)

    ~H"""
    <div class="form-control mb-[var(--space-sm)]">
      <label class="label">
        <span class="label-text font-semibold">{@label}</span>
      </label>
      <div class="gap-[var(--space-xs)] flex">
        <input
          type="date"
          name={@date_field.name}
          id={@date_field.id}
          value={format_date(@value)}
          class="input input-bordered w-40"
          aria-label={gettext("Date")}
        />
        <input
          type="time"
          name={@time_field.name}
          id={@time_field.id}
          value={format_time(@value)}
          class="input input-bordered w-32"
          aria-label={gettext("Time")}
        />
        <button
          type="button"
          phx-click={@on_set_now}
          class="btn btn-outline btn-sm"
          aria-label={gettext("Set to current time")}
        >
          {gettext("Now")}
        </button>
      </div>
      <p :if={@help_text} class="text-base-content/70 mt-[var(--space-xs)] text-[var(--text-sm)]">
        <.icon name="hero-information-circle" class="inline h-4 w-4" />
        {@help_text}
      </p>
    </div>
    """
  end

  @doc """
  Renders a warning alert for similar items (tags, posts, etc).

  This component displays a warning when similar items exist and allows
  users to select from the similar items instead of creating duplicates.

  ## Examples

      <.similar_items_alert
        items={@similar_tags}
        type="tags"
        on_select="add-tag"
        message={gettext("Similar tags exist:")}
      />

  """
  attr :items, :list, required: true, doc: "list of similar item structs"
  attr :type, :string, required: true, doc: "type of items (tags, posts, etc)"
  attr :on_select, :string, required: true, doc: "phx event name for selecting an item"

  attr :message, :string,
    default: nil,
    doc: "warning message (defaults to 'Similar {type} exist:')"

  def similar_items_alert(assigns) do
    message = assigns[:message] || gettext("Similar %{type} exist:", type: assigns.type)
    assigns = assign(assigns, :message, message)

    ~H"""
    <%= if @items != [] do %>
      <div class="alert alert-warning mt-[var(--space-xs)]">
        <.icon name="hero-information-circle" />
        <div>
          <p class="font-semibold">{@message}</p>
          <div class="mt-[var(--space-inline)] gap-[var(--space-xs)] flex flex-wrap">
            <%= for item <- @items do %>
              <button
                type="button"
                phx-click={@on_select}
                phx-value-id={item.id}
                class="badge badge-sm badge-outline"
              >
                {item.name}
              </button>
            <% end %>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  # Find exact matching tag from suggestions (case-insensitive)
  # Returns the tag struct or nil
  defp find_exact_match(suggestions, query) do
    query_lower = String.downcase(query)

    case Enum.find(suggestions, fn {tag, _count} ->
           String.downcase(tag.name) == query_lower
         end) do
      {tag, _count} -> tag
      nil -> nil
    end
  end

  # Helper to format DateTime for date input (YYYY-MM-DD)
  defp format_date(nil), do: Date.utc_today() |> Date.to_string()
  defp format_date(%DateTime{} = dt), do: DateTime.to_date(dt) |> Date.to_string()
  defp format_date(_), do: Date.utc_today() |> Date.to_string()

  # Helper to format DateTime for time input (HH:MM)
  defp format_time(nil), do: "12:00"

  defp format_time(%DateTime{} = dt),
    do: DateTime.to_time(dt) |> Time.to_string() |> String.slice(0, 5)

  defp format_time(_), do: "12:00"
end
