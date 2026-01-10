defmodule HomesiteWeb.ContentComponents do
  @moduledoc """
  Provides reusable content display components for the application.

  This module contains components for displaying posts, tags, and other content
  in a consistent manner across the application.
  """
  use Phoenix.Component
  use Gettext, backend: HomesiteWeb.Gettext

  # Import verified routes for ~p sigil
  use Phoenix.VerifiedRoutes,
    endpoint: HomesiteWeb.Endpoint,
    router: HomesiteWeb.Router,
    statics: HomesiteWeb.static_paths()

  alias Phoenix.LiveView.JS
  import HomesiteWeb.CoreComponents
  import HomesiteWeb.Helpers.DateHelpers

  @doc """
  Renders a post card with title, preview, metadata, and optional actions.

  This component displays a post in a card format with status badges, tags,
  and action buttons for authenticated users.

  ## Examples

      <.post_card
        post={@post}
        current_scope={@current_scope}
        show_actions={true}
      />

      <.post_card
        post={@post}
        current_scope={nil}
        show_actions={false}
      />

  """
  attr :post, :map, required: true, doc: "post struct with preloaded associations"
  attr :current_scope, :map, default: nil, doc: "current user scope (nil for public views)"
  attr :show_actions, :boolean, default: true, doc: "show edit/delete action buttons"
  attr :show_preview, :boolean, default: true, doc: "show post body preview"
  attr :preview_length, :integer, default: 150, doc: "number of characters in preview"
  attr :id, :string, default: nil, doc: "DOM id for the card"
  attr :class, :string, default: nil, doc: "additional CSS classes"

  def post_card(assigns) do
    ~H"""
    <article
      id={@id}
      class={[
        "card bg-base-200 duration-[var(--duration-normal)] shadow-lg transition-shadow hover:shadow-xl",
        @class
      ]}
    >
      <div class="card-body">
        <div class="gap-[var(--spacing-md)] flex items-start justify-between">
          <div class="min-w-0 flex-1">
            <.link navigate={~p"/posts/#{@post.slug}"} class="group">
              <h2 class="card-title mb-[var(--spacing-sm)] text-[var(--font-size-fluid-xl)] duration-[var(--duration-normal)] transition-colors group-hover:text-primary">
                {@post.title}
              </h2>
            </.link>

            <%= if @show_preview do %>
              <p class="line-clamp-2 mb-[var(--spacing-sm)] text-[var(--text-sm)] opacity-70">
                {preview_text(@post.body, @preview_length)}
              </p>
            <% end %>

            <div class="gap-[var(--spacing-sm)] text-[var(--text-sm)] flex flex-wrap">
              <!-- Publication status -->
              <%= if @post.published_at do %>
                <div class="badge badge-success gap-[var(--spacing-inline)]">
                  <.icon name="hero-check-circle" class="h-3 w-3" />
                  {gettext("Published")}
                </div>
                <div class="opacity-70">
                  <.icon name="hero-calendar" class="inline h-4 w-4" />
                  <time datetime={@post.published_at}>
                    {format_date(@post.published_at)}
                  </time>
                </div>
                <div class="opacity-70">
                  <.icon name="hero-clock" class="inline h-4 w-4" />
                  {@post.read_time_minutes} {gettext("min read")}
                </div>
                <div class="opacity-70">
                  <span>{@post.user.display_name || @post.user.email}</span>
                </div>
                <%= if @post.is_public do %>
                  <div class="opacity-70">
                    <.link
                      navigate={~p"/posts/#{@post.slug}"}
                      class="gap-[var(--spacing-inline)] duration-[var(--duration-fast)] inline-flex items-center transition-colors hover:underline"
                    >
                      <.icon name="hero-share" class="h-4 w-4" /> {gettext("Share this post")}
                    </.link>
                    <span>.</span>
                  </div>
                <% end %>
              <% else %>
                <div class="badge badge-warning gap-[var(--spacing-inline)]">
                  <.icon name="hero-pencil" class="h-3 w-3" />
                  {gettext("Draft")}
                </div>
              <% end %>
              
    <!-- Visibility status -->
              <%= if @post.is_public do %>
                <div class="badge badge-ghost gap-[var(--spacing-inline)]">
                  <.icon name="hero-globe-alt" class="h-3 w-3" />
                  {gettext("Public")}
                </div>
              <% else %>
                <div class="badge badge-ghost gap-[var(--spacing-inline)]">
                  <.icon name="hero-lock-closed" class="h-3 w-3" />
                  {gettext("Private")}
                </div>
              <% end %>
            </div>
            
    <!-- Tags -->
            <%= if @post.tags && length(@post.tags) > 0 do %>
              <div class="mt-[var(--spacing-sm)] gap-[var(--spacing-inline)] flex flex-wrap">
                <%= for tag <- @post.tags do %>
                  <.link
                    navigate={~p"/tags/#{tag.slug}"}
                    class="badge badge-sm badge-primary gap-[var(--spacing-inline)] duration-[var(--duration-fast)] transition-colors hover:brightness-110"
                  >
                    <.icon name="hero-tag" class="h-3 w-3" />
                    {tag.name}
                  </.link>
                <% end %>
              </div>
            <% end %>
          </div>
          
    <!-- Actions for post owner -->
          <%= if @show_actions && @current_scope && @post.user_id == @current_scope.user.id do %>
            <div class="gap-[var(--spacing-inline)] flex flex-shrink-0">
              <.link
                navigate={~p"/posts/#{@post.slug}"}
                class="btn btn-sm btn-ghost"
                aria-label={gettext("View post")}
              >
                <.icon name="hero-eye" class="h-4 w-4" />
              </.link>
              <.link
                navigate={~p"/posts/#{@post}/edit"}
                class="btn btn-sm btn-ghost"
                aria-label={gettext("Edit post")}
              >
                <.icon name="hero-pencil-square" class="h-4 w-4" />
              </.link>
              <.link
                phx-click={JS.push("delete", value: %{id: @post.id}) |> hide("##{@id}")}
                data-confirm={gettext("Are you sure?")}
                class="btn btn-sm btn-ghost text-error"
                aria-label={gettext("Delete post")}
              >
                <.icon name="hero-trash" class="h-4 w-4" />
              </.link>
            </div>
          <% end %>
        </div>
      </div>
    </article>
    """
  end

  @doc """
  Renders a tag card with name, post count, and optional actions.

  This component displays a tag in a card format with associated metadata.

  ## Examples

      <.tag_card
        tag={@tag}
        post_count={@post_count}
        current_scope={@current_scope}
        show_actions={true}
      />

  """
  attr :tag, :map, required: true, doc: "tag struct"
  attr :post_count, :integer, default: 0, doc: "number of posts with this tag"
  attr :current_scope, :map, default: nil, doc: "current user scope"
  attr :show_actions, :boolean, default: true, doc: "show edit/delete actions"
  attr :id, :string, default: nil, doc: "DOM id for the card"
  attr :class, :string, default: nil, doc: "additional CSS classes"

  def tag_card(assigns) do
    ~H"""
    <article
      id={@id}
      class={["card bg-base-200 shadow-lg transition-shadow hover:shadow-xl", @class]}
    >
      <div class="card-body">
        <div class="gap-[var(--space-sm)] flex items-start justify-between">
          <div class="min-w-0 flex-1">
            <.link navigate={~p"/tags/#{@tag.slug}"} class="group">
              <h3 class="card-title mb-[var(--space-xs)] text-[var(--text-xl)] transition-colors duration-200 group-hover:text-primary">
                <.icon name="hero-tag" class="h-5 w-5" />
                {@tag.name}
              </h3>
            </.link>

            <div class="gap-[var(--space-xs)] text-[var(--text-sm)] flex">
              <div class="badge badge-neutral">
                {@post_count} {ngettext("post", "posts", @post_count)}
              </div>

              <%= if @tag.is_public do %>
                <div class="badge badge-ghost gap-[var(--space-inline)]">
                  <.icon name="hero-globe-alt" class="h-3 w-3" />
                  {gettext("Public")}
                </div>
              <% else %>
                <div class="badge badge-ghost gap-[var(--space-inline)]">
                  <.icon name="hero-lock-closed" class="h-3 w-3" />
                  {gettext("Private")}
                </div>
              <% end %>
            </div>
          </div>
          
    <!-- Actions for tag owner -->
          <%= if @show_actions && @current_scope && @tag.user_id == @current_scope.user.id do %>
            <div class="gap-[var(--space-inline)] flex flex-shrink-0">
              <.link
                navigate={~p"/tags/#{@tag}/edit"}
                class="btn btn-sm btn-ghost"
                aria-label={gettext("Edit tag")}
              >
                <.icon name="hero-pencil-square" class="h-4 w-4" />
              </.link>
              <.link
                phx-click={JS.push("delete", value: %{id: @tag.id}) |> hide("##{@id}")}
                data-confirm={gettext("Are you sure?")}
                class="btn btn-sm btn-ghost text-error"
                aria-label={gettext("Delete tag")}
              >
                <.icon name="hero-trash" class="h-4 w-4" />
              </.link>
            </div>
          <% end %>
        </div>
      </div>
    </article>
    """
  end

  @doc """
  Renders a horizontal divider with optional text.

  ## Examples

      <.divider />
      <.divider text={gettext("or")} />
      <.divider text="Section Break" class="my-[var(--space-lg)]" />

  """
  attr :text, :string, default: nil, doc: "optional text to display in divider"
  attr :class, :string, default: nil, doc: "additional CSS classes"

  def divider(assigns) do
    ~H"""
    <%= if @text do %>
      <div class={["divider", @class]}>{@text}</div>
    <% else %>
      <div class={["divider", @class]}></div>
    <% end %>
    """
  end

  # Helper to preview text from markdown body
  defp preview_text(body, length) do
    body
    |> MDEx.to_html!(extension: [], render: [unsafe_: true])
    |> Floki.parse_document!()
    |> Floki.text()
    |> String.slice(0, length)
    |> then(fn text ->
      if String.length(text) >= length, do: text <> "...", else: text
    end)
  end
end
