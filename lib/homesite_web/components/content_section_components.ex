defmodule HomesiteWeb.ContentSectionComponents do
  @moduledoc """
  Components for rendering and editing content sections in projects.

  Provides type-specific rendering for:
  - rich_text - Markdown content with preview
  - code_block - Code with syntax highlighting
  - book_info - Structured book metadata form
  - chapter - Chapter/section content
  - gear_spec - Equipment specifications
  - movie_info - Film metadata
  """
  use Phoenix.Component
  use Gettext, backend: HomesiteWeb.Gettext
  import HomesiteWeb.CoreComponents

  @doc """
  Renders a content section card based on section type.
  Dispatches to type-specific renderers.
  """
  attr :section, :map, required: true
  attr :editing, :boolean, default: false
  attr :form, :any, default: nil
  attr :on_edit, :any, default: nil
  attr :on_save, :any, default: nil
  attr :on_delete, :any, default: nil

  def content_section_card(assigns) do
    ~H"""
    <div
      class="card bg-base-200 mb-[var(--space-sm)] shadow-sm"
      id={"section-#{@section.id}"}
      data-section-id={@section.id}
    >
      <div class="card-body p-[var(--space-sm)]">
        <div class="flex items-center justify-between">
          <h4 class="card-title text-[var(--text-base)] flex items-center gap-2">
            <%!-- Drag handle --%>
            <%= if !@editing do %>
              <span class="section-drag-handle text-base-content/40 -ml-1 cursor-grab hover:text-base-content/70 active:cursor-grabbing">
                <.icon name="hero-bars-3" class="h-4 w-4" />
              </span>
            <% end %>
            <.icon name={section_icon(@section.section_type)} class="text-base-content/60 h-5 w-5" />
            <span>{@section.title || section_default_title(@section.section_type)}</span>
          </h4>
          <div class="flex items-center gap-1">
            <%= if @editing do %>
              <button
                type="submit"
                form={"section-form-#{@section.id}"}
                class="btn btn-success btn-xs"
              >
                <.icon name="hero-check" class="h-3 w-3" />
              </button>
              <button
                type="button"
                phx-click="cancel_section_edit"
                class="btn btn-ghost btn-xs"
              >
                <.icon name="hero-x-mark" class="h-3 w-3" />
              </button>
            <% else %>
              <button
                type="button"
                phx-click="edit_section"
                phx-value-id={@section.id}
                class="btn btn-ghost btn-xs"
              >
                <.icon name="hero-pencil" class="h-3 w-3" />
              </button>
              <button
                type="button"
                phx-click="delete_section"
                phx-value-id={@section.id}
                class="btn btn-ghost btn-xs text-error"
                data-confirm={gettext("Delete this section?")}
              >
                <.icon name="hero-trash" class="h-3 w-3" />
              </button>
            <% end %>
          </div>
        </div>

        <div class="mt-[var(--space-xs)]">
          <%= if @editing && @form do %>
            <.form
              for={@form}
              id={"section-form-#{@section.id}"}
              phx-change="validate_section"
              phx-submit="save_section"
            >
              {render_section_form(assigns)}
            </.form>
          <% else %>
            {render_section_display(assigns)}
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # Form renderers (for editing mode)
  defp render_section_form(%{section: %{section_type: "book_info"}} = assigns) do
    ~H"<.book_info_form section={@section} form={@form} />"
  end

  defp render_section_form(%{section: %{section_type: "code_block"}} = assigns) do
    ~H"<.code_block_form section={@section} form={@form} />"
  end

  defp render_section_form(%{section: %{section_type: type}} = assigns)
       when type in ["rich_text", "chapter"] do
    ~H"<.rich_text_form section={@section} form={@form} />"
  end

  defp render_section_form(%{section: %{section_type: "gear_spec"}} = assigns) do
    ~H"<.gear_spec_form section={@section} form={@form} />"
  end

  defp render_section_form(%{section: %{section_type: "movie_info"}} = assigns) do
    ~H"<.movie_info_form section={@section} form={@form} />"
  end

  defp render_section_form(assigns) do
    ~H"<.rich_text_form section={@section} form={@form} />"
  end

  # Display renderers (for view mode)
  defp render_section_display(%{section: %{section_type: "book_info"}} = assigns) do
    ~H"<.book_info_display metadata={@section.metadata} />"
  end

  defp render_section_display(%{section: %{section_type: "code_block"}} = assigns) do
    ~H"<.code_block_display content={@section.content} metadata={@section.metadata} />"
  end

  defp render_section_display(%{section: %{section_type: type}} = assigns)
       when type in ["rich_text", "chapter"] do
    ~H"<.rich_text_display content={@section.content} />"
  end

  defp render_section_display(%{section: %{section_type: "gear_spec"}} = assigns) do
    ~H"<.gear_spec_display metadata={@section.metadata} content={@section.content} />"
  end

  defp render_section_display(%{section: %{section_type: "movie_info"}} = assigns) do
    ~H"<.movie_info_display metadata={@section.metadata} content={@section.content} />"
  end

  defp render_section_display(assigns) do
    ~H"<.rich_text_display content={@section.content} />"
  end

  # Book Info Components

  defp book_info_form(assigns) do
    metadata = assigns.section.metadata || %{}
    assigns = assign(assigns, :metadata, metadata)

    ~H"""
    <div class="space-y-[var(--space-xs)]">
      <%!-- Title field --%>
      <div class="form-control">
        <label class="label label-text text-[var(--text-xs)]">{gettext("Section Title")}</label>
        <input
          type="text"
          name="section[title]"
          value={@section.title}
          class="input input-bordered input-sm"
          placeholder={gettext("Book Information")}
        />
      </div>

      <div class="gap-[var(--space-xs)] grid grid-cols-2">
        <div class="form-control">
          <label class="label label-text text-[var(--text-xs)]">{gettext("ISBN")}</label>
          <input
            type="text"
            name="section[metadata][isbn]"
            value={@metadata["isbn"]}
            class="input input-bordered input-sm"
            placeholder="978-0-13-468599-1"
          />
        </div>
        <div class="form-control">
          <label class="label label-text text-[var(--text-xs)]">{gettext("Publisher")}</label>
          <input
            type="text"
            name="section[metadata][publisher]"
            value={@metadata["publisher"]}
            class="input input-bordered input-sm"
            placeholder="Addison-Wesley"
          />
        </div>
        <div class="form-control col-span-2">
          <label class="label label-text text-[var(--text-xs)]">{gettext("Author")}</label>
          <input
            type="text"
            name="section[metadata][author]"
            value={@metadata["author"]}
            class="input input-bordered input-sm"
            placeholder={gettext("Author name")}
          />
        </div>
        <div class="form-control">
          <label class="label label-text text-[var(--text-xs)]">{gettext("Pages")}</label>
          <input
            type="number"
            name="section[metadata][pages]"
            value={@metadata["pages"]}
            class="input input-bordered input-sm"
            placeholder="398"
          />
        </div>
        <div class="form-control">
          <label class="label label-text text-[var(--text-xs)]">{gettext("Language")}</label>
          <input
            type="text"
            name="section[metadata][language]"
            value={@metadata["language"]}
            class="input input-bordered input-sm"
            placeholder="en"
          />
        </div>
        <div class="form-control">
          <label class="label label-text text-[var(--text-xs)]">{gettext("Format")}</label>
          <select name="section[metadata][format]" class="select select-bordered select-sm">
            <option value="">{gettext("Select format")}</option>
            <option value="paperback" selected={@metadata["format"] == "paperback"}>
              {gettext("Paperback")}
            </option>
            <option value="hardcover" selected={@metadata["format"] == "hardcover"}>
              {gettext("Hardcover")}
            </option>
            <option value="ebook" selected={@metadata["format"] == "ebook"}>
              {gettext("E-book")}
            </option>
            <option value="audiobook" selected={@metadata["format"] == "audiobook"}>
              {gettext("Audiobook")}
            </option>
          </select>
        </div>
        <div class="form-control">
          <label class="label label-text text-[var(--text-xs)]">{gettext("Edition")}</label>
          <input
            type="text"
            name="section[metadata][edition]"
            value={@metadata["edition"]}
            class="input input-bordered input-sm"
            placeholder={gettext("2nd Edition")}
          />
        </div>
        <div class="form-control">
          <label class="label label-text text-[var(--text-xs)]">{gettext("Publication Year")}</label>
          <input
            type="number"
            name="section[metadata][publication_year]"
            value={@metadata["publication_year"]}
            class="input input-bordered input-sm"
            placeholder="2024"
          />
        </div>
        <div class="form-control">
          <label class="label label-text text-[var(--text-xs)]">{gettext("Reading Status")}</label>
          <select name="section[metadata][reading_status]" class="select select-bordered select-sm">
            <option value="">{gettext("Select status")}</option>
            <option value="want_to_read" selected={@metadata["reading_status"] == "want_to_read"}>
              {gettext("Want to read")}
            </option>
            <option value="reading" selected={@metadata["reading_status"] == "reading"}>
              {gettext("Reading")}
            </option>
            <option value="completed" selected={@metadata["reading_status"] == "completed"}>
              {gettext("Completed")}
            </option>
            <option value="dnf" selected={@metadata["reading_status"] == "dnf"}>
              {gettext("Did not finish")}
            </option>
          </select>
        </div>
      </div>
    </div>
    """
  end

  defp book_info_display(assigns) do
    metadata = assigns.metadata || %{}
    assigns = assign(assigns, :metadata, metadata)

    ~H"""
    <div class="gap-[var(--space-xs)] text-[var(--text-sm)] grid grid-cols-2">
      <%= if @metadata["isbn"] do %>
        <div>
          <span class="text-base-content/60">{gettext("ISBN")}:</span>
          <span class="ml-1">{@metadata["isbn"]}</span>
        </div>
      <% end %>
      <%= if @metadata["publisher"] do %>
        <div>
          <span class="text-base-content/60">{gettext("Publisher")}:</span>
          <span class="ml-1">{@metadata["publisher"]}</span>
        </div>
      <% end %>
      <%= if @metadata["author"] do %>
        <div class="col-span-2">
          <span class="text-base-content/60">{gettext("Author")}:</span>
          <span class="ml-1">{@metadata["author"]}</span>
        </div>
      <% end %>
      <%= if @metadata["pages"] do %>
        <div>
          <span class="text-base-content/60">{gettext("Pages")}:</span>
          <span class="ml-1">{@metadata["pages"]}</span>
        </div>
      <% end %>
      <%= if @metadata["language"] do %>
        <div>
          <span class="text-base-content/60">{gettext("Language")}:</span>
          <span class="ml-1">{@metadata["language"]}</span>
        </div>
      <% end %>
      <%= if @metadata["format"] do %>
        <div>
          <span class="text-base-content/60">{gettext("Format")}:</span>
          <span class="ml-1">{format_label(@metadata["format"])}</span>
        </div>
      <% end %>
      <%= if @metadata["edition"] do %>
        <div>
          <span class="text-base-content/60">{gettext("Edition")}:</span>
          <span class="ml-1">{@metadata["edition"]}</span>
        </div>
      <% end %>
      <%= if @metadata["publication_year"] do %>
        <div>
          <span class="text-base-content/60">{gettext("Year")}:</span>
          <span class="ml-1">{@metadata["publication_year"]}</span>
        </div>
      <% end %>
      <%= if @metadata["reading_status"] do %>
        <div>
          <span class="text-base-content/60">{gettext("Status")}:</span>
          <span class="ml-1">{reading_status_label(@metadata["reading_status"])}</span>
        </div>
      <% end %>
      <%= if map_size(@metadata) == 0 do %>
        <p class="text-base-content/50 col-span-2 italic">
          {gettext("No book information yet. Click edit to add details.")}
        </p>
      <% end %>
    </div>
    """
  end

  # Code Block Components

  defp code_block_form(assigns) do
    metadata = assigns.section.metadata || %{}
    assigns = assign(assigns, :metadata, metadata)

    ~H"""
    <div class="space-y-[var(--space-xs)]">
      <div class="form-control">
        <label class="label label-text text-[var(--text-xs)]">{gettext("Section Title")}</label>
        <input
          type="text"
          name="section[title]"
          value={@section.title}
          class="input input-bordered input-sm"
          placeholder={gettext("Code")}
        />
      </div>
      <div class="gap-[var(--space-xs)] grid grid-cols-2">
        <div class="form-control">
          <label class="label label-text text-[var(--text-xs)]">{gettext("Language")}</label>
          <select name="section[metadata][language]" class="select select-bordered select-sm">
            <option value="text">{gettext("Plain text")}</option>
            <option value="elixir" selected={@metadata["language"] == "elixir"}>Elixir</option>
            <option value="javascript" selected={@metadata["language"] == "javascript"}>
              JavaScript
            </option>
            <option value="typescript" selected={@metadata["language"] == "typescript"}>
              TypeScript
            </option>
            <option value="python" selected={@metadata["language"] == "python"}>Python</option>
            <option value="ruby" selected={@metadata["language"] == "ruby"}>Ruby</option>
            <option value="go" selected={@metadata["language"] == "go"}>Go</option>
            <option value="rust" selected={@metadata["language"] == "rust"}>Rust</option>
            <option value="html" selected={@metadata["language"] == "html"}>HTML</option>
            <option value="css" selected={@metadata["language"] == "css"}>CSS</option>
            <option value="sql" selected={@metadata["language"] == "sql"}>SQL</option>
            <option value="bash" selected={@metadata["language"] == "bash"}>Bash</option>
            <option value="json" selected={@metadata["language"] == "json"}>JSON</option>
          </select>
        </div>
        <div class="form-control">
          <label class="label label-text text-[var(--text-xs)]">{gettext("Filename")}</label>
          <input
            type="text"
            name="section[metadata][filename]"
            value={@metadata["filename"]}
            class="input input-bordered input-sm"
            placeholder="example.ex"
          />
        </div>
      </div>
      <div class="form-control">
        <label class="label label-text text-[var(--text-xs)]">{gettext("Code")}</label>
        <textarea
          name="section[content]"
          class="textarea textarea-bordered min-h-[150px] font-mono text-[var(--text-sm)]"
          placeholder={gettext("Paste your code here...")}
        >{@section.content}</textarea>
      </div>
    </div>
    """
  end

  defp code_block_display(assigns) do
    metadata = assigns.metadata || %{}
    content = assigns.content || ""
    language = metadata["language"] || "text"

    assigns =
      assigns
      |> assign(:metadata, metadata)
      |> assign(:content, content)
      |> assign(:language, language)

    ~H"""
    <div class="relative">
      <%= if @metadata["filename"] do %>
        <div class="bg-base-300 text-base-content/70 text-[var(--text-xs)] flex items-center gap-1 rounded-t-lg px-3 py-1">
          <.icon name="hero-document" class="h-3 w-3" />
          {@metadata["filename"]}
        </div>
      <% end %>
      <pre class={[
        "text-[var(--text-sm)] overflow-x-auto rounded-lg bg-gray-900 p-4 text-gray-100",
        @metadata["filename"] && "rounded-t-none"
      ]}><code class={"language-#{@language}"}>{@content}</code></pre>
    </div>
    """
  end

  # Rich Text / Chapter Components

  defp rich_text_form(assigns) do
    ~H"""
    <div class="space-y-[var(--space-xs)]">
      <div class="form-control">
        <label class="label label-text text-[var(--text-xs)]">{gettext("Section Title")}</label>
        <input
          type="text"
          name="section[title]"
          value={@section.title}
          class="input input-bordered input-sm"
          placeholder={gettext("Text Section")}
        />
      </div>
      <div class="form-control">
        <label class="label label-text text-[var(--text-xs)]">{gettext("Content")}</label>
        <textarea
          name="section[content]"
          class="textarea textarea-bordered min-h-[150px] font-mono text-[var(--text-sm)]"
          placeholder={gettext("Write your content here... (Markdown supported)")}
          phx-debounce="500"
        >{@section.content}</textarea>
        <label class="label">
          <span class="text-base-content/60 label-text-alt text-[var(--text-xs)]">
            {gettext("Supports Markdown: **bold**, *italic*, `code`, [links](url)")}
          </span>
        </label>
      </div>
    </div>
    """
  end

  defp rich_text_display(assigns) do
    content = assigns.content || ""
    html = render_markdown(content)
    assigns = assign(assigns, :html, html)

    ~H"""
    <%= if @content && @content != "" do %>
      <div class="prose prose-sm max-w-none">
        {Phoenix.HTML.raw(@html)}
      </div>
    <% else %>
      <p class="text-base-content/50 text-[var(--text-sm)] italic">
        {gettext("No content yet. Click edit to add text.")}
      </p>
    <% end %>
    """
  end

  # Gear Spec Components

  defp gear_spec_form(assigns) do
    metadata = assigns.section.metadata || %{}
    assigns = assign(assigns, :metadata, metadata)

    ~H"""
    <div class="space-y-[var(--space-xs)]">
      <div class="form-control">
        <label class="label label-text text-[var(--text-xs)]">{gettext("Section Title")}</label>
        <input
          type="text"
          name="section[title]"
          value={@section.title}
          class="input input-bordered input-sm"
          placeholder={gettext("Specifications")}
        />
      </div>
      <div class="gap-[var(--space-xs)] grid grid-cols-2">
        <div class="form-control">
          <label class="label label-text text-[var(--text-xs)]">{gettext("Brand")}</label>
          <input
            type="text"
            name="section[metadata][brand]"
            value={@metadata["brand"]}
            class="input input-bordered input-sm"
            placeholder="Sony"
          />
        </div>
        <div class="form-control">
          <label class="label label-text text-[var(--text-xs)]">{gettext("Model")}</label>
          <input
            type="text"
            name="section[metadata][model]"
            value={@metadata["model"]}
            class="input input-bordered input-sm"
            placeholder="A7 IV"
          />
        </div>
        <div class="form-control">
          <label class="label label-text text-[var(--text-xs)]">{gettext("Price")}</label>
          <input
            type="text"
            name="section[metadata][price]"
            value={@metadata["price"]}
            class="input input-bordered input-sm"
            placeholder="$2499"
          />
        </div>
        <div class="form-control">
          <label class="label label-text text-[var(--text-xs)]">{gettext("Purchase URL")}</label>
          <input
            type="url"
            name="section[metadata][purchase_url]"
            value={@metadata["purchase_url"]}
            class="input input-bordered input-sm"
            placeholder="https://..."
          />
        </div>
      </div>
      <div class="form-control">
        <label class="label label-text text-[var(--text-xs)]">{gettext("Notes")}</label>
        <textarea
          name="section[content]"
          class="textarea textarea-bordered min-h-[80px] text-[var(--text-sm)]"
          placeholder={gettext("Additional notes about this gear...")}
        >{@section.content}</textarea>
      </div>
    </div>
    """
  end

  defp gear_spec_display(assigns) do
    metadata = assigns.metadata || %{}
    assigns = assign(assigns, :metadata, metadata)

    ~H"""
    <div class="space-y-[var(--space-xs)] text-[var(--text-sm)]">
      <div class="gap-[var(--space-xs)] grid grid-cols-2">
        <%= if @metadata["brand"] do %>
          <div>
            <span class="text-base-content/60">{gettext("Brand")}:</span>
            <span class="ml-1 font-medium">{@metadata["brand"]}</span>
          </div>
        <% end %>
        <%= if @metadata["model"] do %>
          <div>
            <span class="text-base-content/60">{gettext("Model")}:</span>
            <span class="ml-1 font-medium">{@metadata["model"]}</span>
          </div>
        <% end %>
        <%= if @metadata["price"] do %>
          <div>
            <span class="text-base-content/60">{gettext("Price")}:</span>
            <span class="ml-1">{@metadata["price"]}</span>
          </div>
        <% end %>
        <%= if @metadata["purchase_url"] do %>
          <div>
            <a href={@metadata["purchase_url"]} target="_blank" class="link link-primary">
              {gettext("Purchase Link")} →
            </a>
          </div>
        <% end %>
      </div>
      <%= if @content && @content != "" do %>
        <div class="border-base-300 pt-[var(--space-xs)] border-t">
          <div class="prose prose-sm max-w-none">
            {Phoenix.HTML.raw(render_markdown(@content))}
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # Movie Info Components

  defp movie_info_form(assigns) do
    metadata = assigns.section.metadata || %{}
    assigns = assign(assigns, :metadata, metadata)

    ~H"""
    <div class="space-y-[var(--space-xs)]">
      <div class="form-control">
        <label class="label label-text text-[var(--text-xs)]">{gettext("Section Title")}</label>
        <input
          type="text"
          name="section[title]"
          value={@section.title}
          class="input input-bordered input-sm"
          placeholder={gettext("Movie Information")}
        />
      </div>
      <div class="gap-[var(--space-xs)] grid grid-cols-2">
        <div class="form-control">
          <label class="label label-text text-[var(--text-xs)]">{gettext("Director")}</label>
          <input
            type="text"
            name="section[metadata][director]"
            value={@metadata["director"]}
            class="input input-bordered input-sm"
            placeholder="Christopher Nolan"
          />
        </div>
        <div class="form-control">
          <label class="label label-text text-[var(--text-xs)]">{gettext("Year")}</label>
          <input
            type="number"
            name="section[metadata][year]"
            value={@metadata["year"]}
            class="input input-bordered input-sm"
            placeholder="2024"
          />
        </div>
        <div class="form-control">
          <label class="label label-text text-[var(--text-xs)]">{gettext("Runtime")}</label>
          <input
            type="text"
            name="section[metadata][runtime]"
            value={@metadata["runtime"]}
            class="input input-bordered input-sm"
            placeholder="148 min"
          />
        </div>
        <div class="form-control">
          <label class="label label-text text-[var(--text-xs)]">{gettext("IMDB URL")}</label>
          <input
            type="url"
            name="section[metadata][imdb_url]"
            value={@metadata["imdb_url"]}
            class="input input-bordered input-sm"
            placeholder="https://imdb.com/..."
          />
        </div>
      </div>
      <div class="form-control">
        <label class="label label-text text-[var(--text-xs)]">{gettext("Notes/Review")}</label>
        <textarea
          name="section[content]"
          class="textarea textarea-bordered min-h-[80px] text-[var(--text-sm)]"
          placeholder={gettext("Your thoughts about this movie...")}
        >{@section.content}</textarea>
      </div>
    </div>
    """
  end

  defp movie_info_display(assigns) do
    metadata = assigns.metadata || %{}
    assigns = assign(assigns, :metadata, metadata)

    ~H"""
    <div class="space-y-[var(--space-xs)] text-[var(--text-sm)]">
      <div class="gap-[var(--space-xs)] grid grid-cols-2">
        <%= if @metadata["director"] do %>
          <div>
            <span class="text-base-content/60">{gettext("Director")}:</span>
            <span class="ml-1 font-medium">{@metadata["director"]}</span>
          </div>
        <% end %>
        <%= if @metadata["year"] do %>
          <div>
            <span class="text-base-content/60">{gettext("Year")}:</span>
            <span class="ml-1">{@metadata["year"]}</span>
          </div>
        <% end %>
        <%= if @metadata["runtime"] do %>
          <div>
            <span class="text-base-content/60">{gettext("Runtime")}:</span>
            <span class="ml-1">{@metadata["runtime"]}</span>
          </div>
        <% end %>
        <%= if @metadata["imdb_url"] do %>
          <div>
            <a href={@metadata["imdb_url"]} target="_blank" class="link link-primary">
              {gettext("IMDB")} →
            </a>
          </div>
        <% end %>
      </div>
      <%= if @content && @content != "" do %>
        <div class="border-base-300 pt-[var(--space-xs)] border-t">
          <div class="prose prose-sm max-w-none">
            {Phoenix.HTML.raw(render_markdown(@content))}
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # Add Section Dropdown

  @doc """
  Renders a dropdown to add new content sections.
  """
  attr :available_types, :list, required: true

  def add_section_dropdown(assigns) do
    ~H"""
    <div class="dropdown dropdown-end">
      <label tabindex="0" class="btn btn-primary btn-sm">
        <.icon name="hero-plus" class="h-4 w-4" />
        {gettext("Add Section")}
      </label>
      <ul
        tabindex="0"
        class="menu dropdown-content bg-base-100 rounded-box z-50 mt-2 w-52 p-2 shadow-lg"
      >
        <%= for type <- @available_types do %>
          <li>
            <button
              type="button"
              phx-click="add_section"
              phx-value-type={type}
              class="flex items-center gap-2"
            >
              <.icon name={section_icon(type)} class="h-4 w-4" />
              {section_type_label(type)}
            </button>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  # Helper Functions

  defp section_icon("rich_text"), do: "hero-document-text"
  defp section_icon("code_block"), do: "hero-code-bracket"
  defp section_icon("book_info"), do: "hero-book-open"
  defp section_icon("chapter"), do: "hero-bookmark"
  defp section_icon("gear_spec"), do: "hero-wrench-screwdriver"
  defp section_icon("movie_info"), do: "hero-film"
  defp section_icon(_), do: "hero-square-3-stack-3d"

  defp section_default_title("rich_text"), do: gettext("Content")
  defp section_default_title("code_block"), do: gettext("Code")
  defp section_default_title("book_info"), do: gettext("Book Information")
  defp section_default_title("chapter"), do: gettext("Chapter")
  defp section_default_title("gear_spec"), do: gettext("Specifications")
  defp section_default_title("movie_info"), do: gettext("Movie Information")
  defp section_default_title(_), do: gettext("Section")

  defp section_type_label("rich_text"), do: gettext("Rich Text")
  defp section_type_label("code_block"), do: gettext("Code Block")
  defp section_type_label("book_info"), do: gettext("Book Info")
  defp section_type_label("chapter"), do: gettext("Chapter")
  defp section_type_label("gear_spec"), do: gettext("Gear Specs")
  defp section_type_label("movie_info"), do: gettext("Movie Info")
  defp section_type_label(type), do: type

  defp format_label("paperback"), do: gettext("Paperback")
  defp format_label("hardcover"), do: gettext("Hardcover")
  defp format_label("ebook"), do: gettext("E-book")
  defp format_label("audiobook"), do: gettext("Audiobook")
  defp format_label(other), do: other

  defp reading_status_label("want_to_read"), do: gettext("Want to read")
  defp reading_status_label("reading"), do: gettext("Reading")
  defp reading_status_label("completed"), do: gettext("Completed")
  defp reading_status_label("dnf"), do: gettext("Did not finish")
  defp reading_status_label(other), do: other

  defp render_markdown(nil), do: ""
  defp render_markdown(""), do: ""

  defp render_markdown(content) do
    MDEx.to_html!(content,
      extension: [
        strikethrough: true,
        table: true,
        tasklist: true,
        autolink: true
      ],
      render: [unsafe_: true],
      syntax_highlight: [
        formatter: {:html_inline, theme: "catppuccin_mocha"}
      ]
    )
  rescue
    # Fallback: escape HTML and wrap in <p> tags
    _ ->
      content
      |> Phoenix.HTML.html_escape()
      |> Phoenix.HTML.safe_to_string()
  end
end
