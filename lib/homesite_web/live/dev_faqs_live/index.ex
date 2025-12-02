defmodule HomesiteWeb.DevFaqsLive.Index do
  @moduledoc """
  LiveView for displaying DEV FAQs (development environment only).
  """
  use HomesiteWeb, :live_view

  alias Homesite.DevFaqs
  alias HomesiteWeb.Components.TableOfContents

  @impl true
  def mount(_params, _session, socket) do
    # Only allow in development
    if DevFaqs.available?() do
      articles = DevFaqs.all_articles()
      # Extract headings from all articles for TOC
      headings = extract_all_headings(articles)

      {:ok,
       socket
       |> assign(:page_title, "Developer FAQs")
       |> assign(:articles, articles)
       |> assign(:categories, DevFaqs.categories())
       |> assign(:selected_category, nil)
       |> assign(:headings, headings)}
    else
      {:ok,
       socket
       |> put_flash(:error, "DEV FAQs are only available in development environment")
       |> redirect(to: ~p"/")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    category = params["category"]

    articles =
      if category do
        DevFaqs.articles_by_category(category)
      else
        DevFaqs.all_articles()
      end

    # Update headings when articles change
    headings = extract_all_headings(articles)

    {:noreply,
     socket
     |> assign(:selected_category, category)
     |> assign(:articles, articles)
     |> assign(:headings, headings)}
  end

  @impl true
  def handle_event("filter_category", %{"category" => category}, socket) do
    {:noreply, push_patch(socket, to: "/dev/faqs?category=#{category}")}
  end

  @impl true
  def handle_event("clear_filter", _params, socket) do
    {:noreply, push_patch(socket, to: "/dev/faqs")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
      <.header>
        <div class="flex items-center gap-2">
          <.icon name="hero-code-bracket" class="h-8 w-8" /> Developer FAQs
        </div>
        <:subtitle>
          Development environment documentation and quick reference
        </:subtitle>
      </.header>

    <!-- Category Filter -->
      <div class="mt-8 flex flex-wrap gap-2">
        <button
          :if={@selected_category}
          phx-click="clear_filter"
          class="btn btn-ghost btn-sm"
        >
          All Categories
        </button>

        <button
          :for={category <- @categories}
          phx-click="filter_category"
          phx-value-category={category}
          class={[
            "btn btn-sm",
            if(@selected_category == category, do: "btn-primary", else: "btn-ghost")
          ]}
        >
          {String.capitalize(category)}
        </button>
      </div>

    <!-- Main Content with Sidebar -->
      <div class="mt-8 flex gap-8">
        <!-- Main Content -->
        <div class="flex-1 space-y-8">
          <article
            :for={article <- @articles}
            id={"article-#{article.id}"}
            class="prose prose-slate max-w-none rounded-lg border border-base-300 bg-base-100 p-6 shadow-sm dark:prose-invert"
          >
            <div class="not-prose mb-4 flex items-center gap-2">
              <span class="badge badge-primary badge-sm">
                {article.category}
              </span>
            </div>

            {raw(article.body)}
          </article>

        <!-- Empty State -->
          <div
            :if={@articles == []}
            class="rounded-lg border-2 border-dashed border-base-300 p-12 text-center"
          >
            <.icon name="hero-document-text" class="mx-auto h-12 w-12 opacity-50" />
            <h3 class="mt-2 text-sm font-semibold">No articles found</h3>
            <p class="mt-1 text-sm opacity-70">
              Try selecting a different category or clearing the filter.
            </p>
          </div>
        </div>

      <!-- Sidebar with TOC -->
        <aside class="hidden lg:block lg:w-64">
          <TableOfContents.table_of_contents
            headings={@headings}
            title="On This Page"
            sticky={true}
            show_mobile={false}
          />
        </aside>
      </div>
    </div>
    """
  end

  # Extract headings from all articles combined
  defp extract_all_headings(articles) do
    articles
    |> Enum.flat_map(fn article ->
      TableOfContents.extract_headings(article.body)
    end)
  end
end
