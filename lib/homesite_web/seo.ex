defmodule HomesiteWeb.SEO do
  @moduledoc """
  SEO configuration for the website.
  """
  use HomesiteWeb, :verified_routes

  use SEO,
    site: &__MODULE__.site_config/1,
    open_graph: &__MODULE__.open_graph_config/1,
    twitter: &__MODULE__.twitter_config/1

  @doc """
  Configures the Open Graph.
  """
  def open_graph_config(conn) do
    # Get post-specific data if available
    description = get_description(conn)
    image_url = get_image_url(conn)
    type = if conn.assigns[:post], do: "article", else: "website"

    SEO.OpenGraph.build(
      title: conn.assigns.page_title,
      description: description,
      locale: "fi_FI",
      url: conn.assigns.current_url,
      type: type,
      image: image_url
    )
  end

  @doc """
  Configures Twitter Card metadata.
  """
  def twitter_config(conn) do
    description = get_description(conn)
    image_url = get_image_url(conn)

    SEO.Twitter.build(
      card: "summary_large_image",
      title: conn.assigns.page_title,
      description: description,
      image: image_url
    )
  end

  @doc """
  Configures the site.
  """
  def site_config(conn) do
    description = get_description(conn)

    SEO.Site.build(
      canonical_url: conn.assigns.current_url,
      description: description
    )
  end

  # Helper to get description from post or use default
  defp get_description(conn) do
    cond do
      Map.has_key?(conn.assigns, :post) and conn.assigns.post ->
        conn.assigns.post.body
        |> HtmlSanitizeEx.strip_tags()
        |> String.slice(0, 160)
        |> Kernel.<>("...")

      Map.has_key?(conn.assigns, :seo_description) ->
        conn.assigns.seo_description

      true ->
        "Juha Halmun kotisivu ja blogi."
    end
  end

  # Helper to get image URL (placeholder for now, can be enhanced later)
  defp get_image_url(conn) do
    if Map.has_key?(conn.assigns, :seo_image) do
      conn.assigns.seo_image
    else
      # Default OG image (you can create one later)
      url(~p"/images/og-default.jpg")
    end
  end
end
