defmodule HomesiteWeb.Components.TableOfContents do
  @moduledoc """
  Table of Contents component for generating navigation from HTML headings.

  Extracts h2 and h3 headings from HTML content, builds a nested structure,
  and renders as a navigable sidebar with active section tracking.

  ## Usage

      # In your LiveView
      def mount(_params, _session, socket) do
        html_content = render_markdown(post.body)
        headings = TableOfContents.extract_headings(html_content)

        {:ok, assign(socket, headings: headings, html_content: html_content)}
      end

      # In your template
      <.table_of_contents headings={@headings} />

      <div class="prose">
        {raw(@html_content)}
      </div>

  ## Features

  - Extracts h2 (sections) and h3 (subsections) headings
  - Builds nested structure (h3s as children of h2s)
  - Auto-generates IDs for headings without them
  - Sticky sidebar with DaisyUI menu styling
  - Active section tracking via JavaScript hook
  - Responsive: hidden on mobile, visible on larger screens
  - Accessible: proper ARIA labels and semantic HTML
  """

  use Phoenix.Component

  alias Floki

  @doc """
  Extracts headings from HTML content.

  Returns a list of heading maps with:
  - `:level` - heading level (2 or 3)
  - `:text` - heading text content
  - `:id` - heading ID for linking
  - `:children` - nested h3 headings (for h2 only)

  ## Examples

      iex> html = "<h2 id=\"intro\">Introduction</h2><p>Content</p><h3>Details</h3>"
      iex> TableOfContents.extract_headings(html)
      [
        %{
          level: 2,
          text: "Introduction",
          id: "intro",
          children: [
            %{level: 3, text: "Details", id: "details"}
          ]
        }
      ]
  """
  def extract_headings(html_content) when is_binary(html_content) do
    case Floki.parse_document(html_content) do
      {:ok, document} ->
        document
        |> Floki.find("h2, h3")
        |> Enum.map(&parse_heading/1)
        |> build_hierarchy()

      {:error, _reason} ->
        []
    end
  end

  def extract_headings(_), do: []

  # Parse a heading element into a map
  defp parse_heading({tag, attrs, children}) do
    level = String.to_integer(String.replace(tag, "h", ""))
    text = Floki.text(children)
    id = get_heading_id(attrs, text)

    %{
      level: level,
      text: text,
      id: id,
      children: []
    }
  end

  # Get heading ID from attributes or generate from text
  defp get_heading_id(attrs, text) do
    case List.keyfind(attrs, "id", 0) do
      {"id", id} -> id
      nil -> slugify(text)
    end
  end

  # Build nested structure (h3s as children of h2s)
  defp build_hierarchy(headings) do
    headings
    |> Enum.reduce({[], nil}, &reduce_heading/2)
    |> then(fn {acc, current_h2} ->
      # Add final h2 if exists
      if current_h2, do: [current_h2 | acc], else: acc
    end)
    |> Enum.reverse()
  end

  # New h2: save previous h2 (if exists) and start new one
  defp reduce_heading(%{level: 2} = heading, {acc, nil}), do: {acc, heading}
  defp reduce_heading(%{level: 2} = heading, {acc, current_h2}), do: {[current_h2 | acc], heading}

  # h3: add as child of current h2, or treat as top-level if orphaned
  defp reduce_heading(%{level: 3} = heading, {acc, nil}), do: {[heading | acc], nil}

  defp reduce_heading(%{level: 3} = heading, {acc, current_h2}) do
    updated_h2 = %{current_h2 | children: current_h2.children ++ [heading]}
    {acc, updated_h2}
  end

  # Convert text to URL-friendly slug
  defp slugify(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end

  @doc """
  Renders a table of contents sidebar.

  ## Attributes

  - `headings` (required) - List of heading maps from `extract_headings/1`
  - `title` (optional) - TOC title, defaults to "Table of Contents"
  - `class` (optional) - Additional CSS classes
  - `sticky` (optional) - Make sidebar sticky, defaults to true
  - `show_mobile` (optional) - Show on mobile, defaults to false
  """
  attr :headings, :list, required: true
  attr :title, :string, default: "Table of Contents"
  attr :class, :string, default: ""
  attr :sticky, :boolean, default: true
  attr :show_mobile, :boolean, default: false

  def table_of_contents(assigns) do
    ~H"""
    <%= if @headings != [] do %>
      <nav
        id="table-of-contents"
        phx-hook="TableOfContents"
        class={[
          "border-base-300 bg-base-200 p-[var(--space-md)] rounded-lg border",
          @sticky && "sticky top-4",
          !@show_mobile && "hidden lg:block",
          @class
        ]}
        aria-label={@title}
      >
        <h2 class="mb-[var(--space-md)] text-[var(--text-sm)] font-semibold uppercase tracking-wide opacity-60">
          {@title}
        </h2>

        <ul class="menu menu-sm w-full p-0">
          <.toc_item :for={heading <- @headings} heading={heading} />
        </ul>
      </nav>
    <% end %>
    """
  end

  # Recursive component for rendering TOC items
  attr :heading, :map, required: true

  defp toc_item(assigns) do
    ~H"""
    <li>
      <a
        href={"##{@heading.id}"}
        class="toc-link px-[var(--space-md)] py-[var(--space-xs)] text-[var(--text-sm)] rounded-md opacity-70 hover:bg-base-300 hover:opacity-100"
        data-target={@heading.id}
      >
        {@heading.text}
      </a>

      <%= if @heading.children != [] do %>
        <ul class="mt-[var(--space-inline)] ml-[var(--space-md)]">
          <.toc_item :for={child <- @heading.children} heading={child} />
        </ul>
      <% end %>
    </li>
    """
  end

  @doc """
  Adds IDs to headings in HTML content if they don't have them.

  This ensures all headings are linkable from the TOC. Call this before
  rendering HTML if your markdown processor doesn't add IDs automatically.

  ## Examples

      iex> html = "<h2>Introduction</h2>"
      iex> TableOfContents.add_heading_ids(html)
      "<h2 id=\"introduction\">Introduction</h2>"
  """
  def add_heading_ids(html_content) when is_binary(html_content) do
    case Floki.parse_document(html_content) do
      {:ok, document} ->
        document
        |> Floki.traverse_and_update(&add_id_to_heading/1)
        |> Floki.raw_html()

      {:error, _reason} ->
        html_content
    end
  end

  def add_heading_ids(content), do: content

  # Add ID to heading if missing
  defp add_id_to_heading({tag, attrs, children} = element)
       when tag in ["h1", "h2", "h3", "h4", "h5", "h6"] do
    case List.keyfind(attrs, "id", 0) do
      nil ->
        text = Floki.text(children)
        id = slugify(text)
        {tag, [{"id", id} | attrs], children}

      _ ->
        element
    end
  end

  defp add_id_to_heading(element), do: element
end
