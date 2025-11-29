defmodule HomesiteWeb.SearchLive.Index do
  use HomesiteWeb, :live_view

  alias Homesite.Search

  @impl true
  def mount(_params, _session, socket) do
    locale = Gettext.get_locale(HomesiteWeb.Gettext)

    {:ok,
     socket
     |> assign(:page_title, "Search")
     |> assign(:query, "")
     |> assign(:posts, [])
     |> assign(:tags, [])
     |> assign(:faqs, [])
     |> assign(:total_count, 0)
     |> assign(:searching, false)
     |> assign(:current_url, "/search")
     |> assign(:locale, locale)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    query = params["q"] || ""

    socket =
      socket
      |> assign(:query, query)
      |> perform_search(query)

    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, push_patch(socket, to: ~p"/search?#{[q: query]}")}
  end

  @impl true
  def handle_event("clear", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/search")}
  end

  defp perform_search(socket, "") do
    socket
    |> assign(:posts, [])
    |> assign(:tags, [])
    |> assign(:faqs, [])
    |> assign(:total_count, 0)
    |> assign(:searching, false)
  end

  defp perform_search(socket, query) when byte_size(query) < 2 do
    socket
    |> assign(:posts, [])
    |> assign(:tags, [])
    |> assign(:faqs, [])
    |> assign(:total_count, 0)
    |> assign(:searching, false)
  end

  defp perform_search(socket, query) do
    locale = socket.assigns.locale
    results = Search.search_all(query, limit: 20, locale: locale)

    socket
    |> assign(:posts, results.posts)
    |> assign(:tags, results.tags)
    |> assign(:faqs, results.faqs)
    |> assign(:total_count, results.total_count)
    |> assign(:searching, true)
  end

  defp truncate_html(html, length) do
    html
    |> HtmlSanitizeEx.strip_tags()
    |> String.slice(0, length)
    |> then(fn text ->
      if String.length(html) > length, do: text <> "...", else: text
    end)
  end
end
