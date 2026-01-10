defmodule HomesiteWeb.PostLive.Show do
  use HomesiteWeb, :live_view

  import Ecto.Query

  alias Homesite.Content
  alias Homesite.Media.MediaItem
  alias Homesite.Repo
  alias Homesite.Social
  alias HomesiteWeb.Components.TableOfContents
  alias HomesiteWeb.SEO.JsonLD
  import HomesiteWeb.SocialComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="technical-main">
        <article>
          <.header>
            {@post.title}
            <:subtitle>Published post</:subtitle>
            <:actions>
              <.button navigate={~p"/"} aria-label={gettext("Back to home")}>
                <.icon name="hero-arrow-left" />
              </.button>
              <%= if @can_edit do %>
                <.button
                  variant="primary"
                  navigate={~p"/posts/#{@post.slug}/edit?return_to=show"}
                >
                  <.icon name="hero-pencil-square" /> Edit post
                </.button>
              <% end %>
            </:actions>
          </.header>

          <div class="my-[var(--spacing-md)]">
            <.author_byline user={@post.user} date={@post.published_at} />
            <div class="gap-[var(--space-xs)] text-[var(--text-sm)] mt-[var(--space-xs)] flex flex-wrap items-center opacity-70">
              <.icon name="hero-clock" class="h-4 w-4" />
              <span>{@post.read_time_minutes} min read</span>

              <%= if was_edited?(@post) do %>
                <span>•</span>
                <span
                  class="gap-[var(--space-inline)] flex items-center"
                  title={format_datetime(@post.updated_at)}
                >
                  <.icon name="hero-pencil" class="h-3 w-3" />
                  {gettext("Edited %{date}", date: format_relative_date(@post.updated_at))}
                </span>
              <% end %>

              <%= if @post.tags && length(@post.tags) > 0 do %>
                <span>•</span>
                <%= for tag <- @post.tags do %>
                  <.link
                    navigate={~p"/tags/#{tag.slug}"}
                    class="badge badge-ghost badge-sm gap-[var(--space-inline)] opacity-60 hover:opacity-100"
                  >
                    <.icon name="hero-tag" class="h-3 w-3" />
                    {tag.name}
                  </.link>
                <% end %>
              <% end %>
            </div>
          </div>

          <%= if @hero_image do %>
            <figure class="my-[var(--spacing-md)]">
              <img
                src={"data:#{@hero_image.content_type};base64,#{Base.encode64(@hero_image.large_data)}"}
                alt={@hero_image.alt_text || @post.title}
                class="max-h-96 w-full rounded-lg object-cover"
              />
              <%= if @hero_image.caption do %>
                <figcaption class="text-[var(--text-sm)] mt-[var(--space-xs)] text-center opacity-60">
                  {@hero_image.caption}
                </figcaption>
              <% end %>
            </figure>
          <% end %>
          
    <!-- Main Content with Sidebar -->
          <div class="my-[var(--spacing-lg)] gap-[var(--space-lg)] flex">
            <!-- Article Content -->
            <div class="prose prose-slate max-w-none flex-1 prose-pre:bg-gray-900 prose-pre:text-gray-100 dark:prose-invert">
              {Phoenix.HTML.raw(@rendered_html)}
            </div>
            
    <!-- Sidebar with TOC (posts with 2+ min read time and headings) -->
            <%= if @post.read_time_minutes >= 2 && @headings != [] do %>
              <aside class="hidden lg:block lg:w-64">
                <TableOfContents.table_of_contents
                  headings={@headings}
                  title={gettext("On This Page")}
                  sticky={true}
                  show_mobile={false}
                />
              </aside>
            <% end %>
          </div>

          <%= if @post.read_time_minutes >= 2 do %>
            <div class="my-[var(--spacing-lg)] border-base-300 pt-[var(--space-md)] border-t">
              <.platform_share_buttons url={@current_url} title={@post.title} />
            </div>
          <% end %>
        </article>
      </div>
    </Layouts.app>
    """
  end

  defp render_markdown(markdown) do
    MDEx.to_html!(markdown,
      extension: [
        strikethrough: true,
        table: true,
        tasklist: true,
        autolink: true,
        header_ids: ""
      ],
      render: [
        unsafe_: true
      ],
      syntax_highlight: [
        formatter: {:html_inline, theme: "catppuccin_mocha"}
      ]
    )
    |> HtmlSanitizeEx.markdown_html()
    # Re-add heading IDs after sanitization (sanitizer may strip them)
    |> TableOfContents.add_heading_ids()
  end

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    current_scope = socket.assigns.current_scope

    # Fetch post by slug based on authentication status
    post =
      if current_scope do
        # Authenticated: can see public posts + own posts
        if connected?(socket), do: Content.subscribe_posts(current_scope)
        Content.get_post_by_slug!(current_scope, slug)
      else
        # Not authenticated: can only see public posts
        Content.get_public_post_by_slug!(slug)
      end

    # Check if current user can edit (only if authenticated and is owner)
    can_edit = current_scope && post.user_id == current_scope.user.id

    # Generate JSON-LD for SEO
    post_url = url(~p"/posts/#{post.slug}")
    json_ld = JsonLD.article(post, post.user, post_url) |> Jason.encode!()

    # Render markdown and extract headings for TOC
    rendered_html = render_markdown(post.body)
    headings = TableOfContents.extract_headings(rendered_html)

    # Get hero image from media items
    hero_image = get_hero_image(post.id)

    {:ok,
     socket
     |> assign(:page_title, post.title)
     |> assign(:post, post)
     |> assign(:can_edit, can_edit)
     |> assign(:current_url, url(~p"/posts/#{post.slug}"))
     |> assign(:json_ld, json_ld)
     |> assign(:rendered_html, rendered_html)
     |> assign(:headings, headings)
     |> assign(:hero_image, hero_image)}
  end

  @impl true
  def handle_info(
        {:updated, %Homesite.Content.Post{id: id} = post},
        %{assigns: %{post: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :post, post)}
  end

  def handle_info(
        {:deleted, %Homesite.Content.Post{id: id}},
        %{assigns: %{post: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current post was deleted.")
     |> push_navigate(to: ~p"/posts")}
  end

  def handle_info({type, %Homesite.Content.Post{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end

  @impl true
  def handle_event("track_share", %{"platform" => platform, "url" => url}, socket) do
    # Get optional user and IP info
    user_id = if socket.assigns.current_scope, do: socket.assigns.current_scope.user.id, else: nil

    # Log the share event
    Social.log_share(%{
      platform: platform,
      shared_url: url,
      post_id: socket.assigns.post.id,
      user_id: user_id,
      ip_address: get_connect_params(socket)["remote_ip"],
      user_agent: get_connect_params(socket)["user_agent"]
    })

    {:noreply, socket}
  end

  defp get_hero_image(post_id) do
    from(m in MediaItem,
      join: pm in "post_media_items",
      on: pm.media_item_id == m.id,
      where: pm.post_id == ^post_id and pm.context == "hero",
      limit: 1
    )
    |> Repo.one()
  end

  # Check if post was edited (updated > 5 minutes after published_at or inserted_at)
  defp was_edited?(post) do
    reference_time = post.published_at || post.inserted_at

    if reference_time && post.updated_at do
      # Consider edited if updated more than 5 minutes after reference time
      diff_seconds = DateTime.diff(post.updated_at, reference_time, :second)
      diff_seconds > 300
    else
      false
    end
  end

  defp format_relative_date(datetime) do
    now = DateTime.utc_now()
    diff_days = DateTime.diff(now, datetime, :day)

    cond do
      diff_days == 0 ->
        gettext("today")

      diff_days == 1 ->
        gettext("yesterday")

      diff_days < 7 ->
        gettext("%{days} days ago", days: diff_days)

      diff_days < 30 ->
        weeks = div(diff_days, 7)

        if weeks == 1,
          do: gettext("1 week ago"),
          else: gettext("%{weeks} weeks ago", weeks: weeks)

      true ->
        Calendar.strftime(datetime, "%b %d, %Y")
    end
  end

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
  end
end
