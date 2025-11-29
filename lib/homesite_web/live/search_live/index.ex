defmodule HomesiteWeb.SearchLive.Index do
  use HomesiteWeb, :live_view

  alias Homesite.Content

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Search Posts")
     |> assign(:query, "")
     |> assign(:results, [])
     |> assign(:searching, false)
     |> assign(:current_url, "/search")}
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
    assign(socket, results: [], searching: false)
  end

  defp perform_search(socket, query) when byte_size(query) < 2 do
    assign(socket, results: [], searching: false)
  end

  defp perform_search(socket, query) do
    results = Content.search_posts(query, limit: 50)

    socket
    |> assign(:results, results)
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
