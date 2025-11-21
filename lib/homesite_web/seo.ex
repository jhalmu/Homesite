defmodule HomesiteWeb.SEO do
  @moduledoc """
  SEO configuration for the website.
  """
  use HomesiteWeb, :verified_routes

  use SEO,
    site: &__MODULE__.site_config/1,
    open_graph: &__MODULE__.open_graph_config/1

  @doc """
  Configures the Open Graph.
  """
  def open_graph_config(conn) do
    SEO.OpenGraph.build(
      title: conn.assigns.page_title,
      description: "Juha Halmun kotisivu ja blogi.",
      locale: "fi_FI",
      url: conn.assigns.current_url
    )
  end

  @doc """
  Configures the site.
  """
  def site_config(conn) do
    SEO.Site.build(
      canonical_url: conn.assigns.current_url,
      description: "Juha Halmun kotisivu ja blogi."
    )
  end
end
