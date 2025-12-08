defmodule HomesiteWeb.PostLive.Show do
  use HomesiteWeb, :live_view

  alias Homesite.Content
  alias Homesite.Social
  alias HomesiteWeb.SEO.JsonLD
  alias HomesiteWeb.Components.TableOfContents
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
                <.button variant="primary" navigate={~p"/posts/#{@post}/edit?return_to=show"}>
                  <.icon name="hero-pencil-square" /> Edit post
                </.button>
              <% end %>
            </:actions>
          </.header>

          <div class="my-[var(--spacing-md)]">
            <.author_byline user={@post.user} date={@post.published_at} />
            <div class="gap-[var(--space-xs)] text-[var(--text-sm)] mt-2 flex flex-wrap items-center opacity-70">
              <.icon name="hero-clock" class="h-4 w-4" />
              <span>{@post.read_time_minutes} min read</span>

              <%= if @post.tags && length(@post.tags) > 0 do %>
                <span>•</span>
                <%= for tag <- @post.tags do %>
                  <.link
                    navigate={~p"/tags/#{tag.slug}"}
                    class="badge badge-ghost badge-sm gap-1 opacity-60 hover:opacity-100"
                  >
                    <.icon name="hero-tag" class="h-3 w-3" />
                    {tag.name}
                  </.link>
                <% end %>
              <% end %>
            </div>
          </div>
          
    <!-- Main Content with Sidebar -->
          <div class="my-[var(--spacing-lg)] flex gap-8">
            <!-- Article Content -->
            <div class="prose prose-slate max-w-none flex-1 prose-pre:bg-gray-900 prose-pre:text-gray-100 dark:prose-invert">
              {Phoenix.HTML.raw(@rendered_html)}
            </div>
            
    <!-- Sidebar with TOC (posts with 2+ min read time and headings) -->
            <%= if @post.read_time_minutes >= 2 && @headings != [] do %>
              <aside class="hidden lg:block lg:w-64">
                <TableOfContents.table_of_contents
                  headings={@headings}
                  title="On This Page"
                  sticky={true}
                  show_mobile={false}
                />
              </aside>
            <% end %>
          </div>

          <%= if @post.read_time_minutes >= 2 do %>
            <div class="my-[var(--spacing-lg)] border-base-300 border-t pt-6">
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
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    current_scope = socket.assigns.current_scope

    # Fetch post based on authentication status
    post =
      if current_scope do
        # Authenticated: can see public posts + own posts
        if connected?(socket), do: Content.subscribe_posts(current_scope)
        Content.get_post_by_id!(current_scope, id)
      else
        # Not authenticated: can only see public posts
        Content.get_public_post!(id)
      end

    # Check if current user can edit (only if authenticated and is owner)
    can_edit = current_scope && post.user_id == current_scope.user.id

    # Generate JSON-LD for SEO
    post_url = url(~p"/posts/#{id}")
    json_ld = JsonLD.article(post, post.user, post_url) |> Jason.encode!()

    # Render markdown and extract headings for TOC
    rendered_html = render_markdown(post.body)
    headings = TableOfContents.extract_headings(rendered_html)

    {:ok,
     socket
     |> assign(:page_title, post.title)
     |> assign(:post, post)
     |> assign(:can_edit, can_edit)
     |> assign(:current_url, "/posts/#{id}")
     |> assign(:json_ld, json_ld)
     |> assign(:rendered_html, rendered_html)
     |> assign(:headings, headings)}
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
end
