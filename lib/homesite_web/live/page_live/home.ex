defmodule HomesiteWeb.PageLive.Home do
  use HomesiteWeb, :live_view

  alias Homesite.Content

  @impl true
  def mount(_params, _session, socket) do
    posts = Content.list_all_published_posts()

    socket =
      socket
      |> assign(:page_title, "Welcome")
      |> assign(:posts, posts)

    {:ok, socket}
  end

  def markdown_preview(markdown, length) do
    markdown
    |> MDEx.to_html!(extension: [], render: [unsafe_: true])
    |> Floki.parse_document!()
    |> Floki.text()
    |> String.slice(0, length)
    |> then(fn text ->
      if String.length(text) >= length, do: text <> "...", else: text
    end)
  end
end
