defmodule HomesiteWeb.DevFaqsLive.Index do
  @moduledoc """
  LiveView for displaying DEV FAQs (development environment only).
  """
  use HomesiteWeb, :live_view

  alias Homesite.DevFaqs

  @impl true
  def mount(_params, _session, socket) do
    # Only allow in development
    if DevFaqs.available?() do
      {:ok,
       socket
       |> assign(:page_title, "Developer FAQs")
       |> assign(:articles, DevFaqs.all_articles())
       |> assign(:categories, DevFaqs.categories())
       |> assign(:selected_category, nil)}
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

    {:noreply,
     socket
     |> assign(:selected_category, category)
     |> assign(:articles, articles)}
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
    <div class="mx-auto max-w-4xl px-4 py-8 sm:px-6 lg:px-8">
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
          class="rounded-md bg-gray-200 px-3 py-1.5 text-sm font-medium text-gray-900 hover:bg-gray-300"
        >
          All Categories
        </button>

        <button
          :for={category <- @categories}
          phx-click="filter_category"
          phx-value-category={category}
          class={[
            "rounded-md px-3 py-1.5 text-sm font-medium",
            if(@selected_category == category,
              do: "bg-blue-600 text-white",
              else: "bg-gray-100 text-gray-900 hover:bg-gray-200"
            )
          ]}
        >
          {String.capitalize(category)}
        </button>
      </div>
      
    <!-- Articles -->
      <div class="mt-8 space-y-8">
        <article
          :for={article <- @articles}
          id={"article-#{article.id}"}
          class="prose prose-sm max-w-none rounded-lg border border-gray-200 bg-white p-6 shadow-sm"
        >
          <div class="not-prose mb-4 flex items-center gap-2">
            <span class="rounded-md bg-blue-100 px-2 py-1 text-xs font-medium text-blue-800">
              {article.category}
            </span>
          </div>

          {raw(article.body)}
        </article>
      </div>
      
    <!-- Empty State -->
      <div
        :if={@articles == []}
        class="mt-8 rounded-lg border-2 border-dashed border-gray-300 p-12 text-center"
      >
        <.icon name="hero-document-text" class="mx-auto h-12 w-12 text-gray-400" />
        <h3 class="mt-2 text-sm font-semibold text-gray-900">No articles found</h3>
        <p class="mt-1 text-sm text-gray-500">
          Try selecting a different category or clearing the filter.
        </p>
      </div>
    </div>
    """
  end
end
