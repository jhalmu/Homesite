defmodule HomesiteWeb.SEO.JsonLD do
  @moduledoc """
  Generates JSON-LD structured data for SEO.
  """

  @doc """
  Generates JSON-LD for a blog post (Article type).
  """
  def article(post, author, url) do
    %{
      "@context" => "https://schema.org",
      "@type" => "BlogPosting",
      "headline" => post.title,
      "articleBody" => strip_html(post.body),
      "datePublished" => format_date(post.published_at || post.inserted_at),
      "dateModified" => format_date(post.updated_at),
      "author" => %{
        "@type" => "Person",
        "name" => author.display_name || author.email
      },
      "publisher" => publisher(),
      "mainEntityOfPage" => %{
        "@type" => "WebPage",
        "@id" => url
      },
      "url" => url
    }
    |> maybe_add_image(post)
  end

  @doc """
  Generates JSON-LD for FAQ page.
  """
  def faq_page(faqs) do
    %{
      "@context" => "https://schema.org",
      "@type" => "FAQPage",
      "mainEntity" =>
        Enum.map(faqs, fn faq ->
          %{
            "@type" => "Question",
            "name" => faq.question,
            "acceptedAnswer" => %{
              "@type" => "Answer",
              "text" => strip_html(faq.answer)
            }
          }
        end)
    }
  end

  @doc """
  Generates JSON-LD for website (Organization).
  """
  def organization(url) do
    %{
      "@context" => "https://schema.org",
      "@type" => "Organization",
      "name" => "Juha Halmun kotisivu",
      "url" => url,
      "logo" => "#{url}/images/logo.png",
      "sameAs" => []
    }
  end

  @doc """
  Generates JSON-LD for WebSite schema (homepage).

  Includes search action for site search.
  """
  def website(url) do
    %{
      "@context" => "https://schema.org",
      "@type" => "WebSite",
      "name" => "Juha Halmun kotisivu ja blogi",
      "alternateName" => "Orangedinos",
      "url" => url,
      "potentialAction" => %{
        "@type" => "SearchAction",
        "target" => "#{url}/search?q={search_term_string}",
        "query-input" => "required name=search_term_string"
      }
    }
  end

  @doc """
  Generates JSON-LD for breadcrumb navigation.
  """
  def breadcrumbs(items, base_url) do
    %{
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" =>
        items
        |> Enum.with_index(1)
        |> Enum.map(fn {{name, path}, position} ->
          %{
            "@type" => "ListItem",
            "position" => position,
            "name" => name,
            "item" => "#{base_url}#{path}"
          }
        end)
    }
  end

  @doc """
  Encodes JSON-LD to safe HTML script tag.
  """
  def to_script_tag(json_ld) do
    json_ld
    |> Jason.encode!()
    |> Phoenix.HTML.raw()
  end

  # Private helpers

  defp publisher do
    %{
      "@type" => "Organization",
      "name" => "Juha Halmun kotisivu",
      "logo" => %{
        "@type" => "ImageObject",
        "url" => "https://example.com/logo.png"
      }
    }
  end

  defp maybe_add_image(json_ld, post) do
    case post.featured_image_url do
      url when is_binary(url) and url != "" ->
        Map.put(json_ld, "image", url)

      _ ->
        # Default OG image when no featured image set
        json_ld
    end
  end

  defp strip_html(html) when is_binary(html) do
    HtmlSanitizeEx.strip_tags(html)
  end

  defp strip_html(_), do: ""

  defp format_date(%DateTime{} = datetime) do
    DateTime.to_iso8601(datetime)
  end

  defp format_date(_), do: DateTime.to_iso8601(DateTime.utc_now())
end
