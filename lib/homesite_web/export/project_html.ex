defmodule HomesiteWeb.Export.ProjectHTML do
  @moduledoc """
  Generates standalone HTML exports of portfolio projects.

  Creates self-contained HTML files with inline CSS and base64-encoded images.
  """

  @doc """
  Generates a standalone HTML file for a project.

  ## Options
    * `:include_metadata` - Include project metadata (default: true)
    * `:include_collaborators` - Include collaborators (default: true)
    * `:include_links` - Include affiliation links (default: true)
  """
  def generate(project, opts \\ []) do
    opts =
      Keyword.merge(
        [include_metadata: true, include_collaborators: true, include_links: true],
        opts
      )

    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>#{escape_html(project.name)}</title>
      <style>#{inline_css()}</style>
    </head>
    <body>
      #{render_project_content(project, opts)}
    </body>
    </html>
    """
  end

  defp inline_css do
    """
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
      line-height: 1.6;
      color: #333;
      background: #f8f9fa;
      padding: 2rem 1rem;
      max-width: 1400px;
      margin: 0 auto;
    }

    .project-header {
      background: white;
      padding: 2rem;
      border-radius: 8px;
      margin-bottom: 2rem;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    }

    .project-title {
      font-size: 2.5rem;
      font-weight: bold;
      margin-bottom: 1rem;
      color: #1a1a1a;
    }

    .project-description {
      font-size: 1.125rem;
      color: #666;
      margin-bottom: 1.5rem;
    }

    .project-meta {
      display: flex;
      flex-wrap: wrap;
      gap: 0.75rem;
      margin-top: 1rem;
    }

    .badge {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.5rem 1rem;
      border-radius: 9999px;
      font-size: 0.875rem;
      font-weight: 500;
    }

    .badge-primary {
      background: #3b82f6;
      color: white;
    }

    .badge-secondary {
      background: #8b5cf6;
      color: white;
    }

    .badge-outline {
      border: 1px solid #d1d5db;
      background: white;
      color: #374151;
    }

    .section {
      background: white;
      padding: 2rem;
      border-radius: 8px;
      margin-bottom: 2rem;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    }

    .section-title {
      font-size: 1.5rem;
      font-weight: 600;
      margin-bottom: 1.5rem;
      color: #1a1a1a;
    }

    .tags {
      display: flex;
      flex-wrap: wrap;
      gap: 0.5rem;
    }

    .collaborators {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 1rem;
    }

    .collaborator {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      padding: 1rem;
      background: #f9fafb;
      border-radius: 6px;
    }

    .collaborator-name {
      font-weight: 500;
      color: #374151;
    }

    .collaborator-contact {
      font-size: 0.875rem;
      color: #3b82f6;
      text-decoration: none;
    }

    .links {
      display: flex;
      flex-direction: column;
      gap: 0.75rem;
    }

    .link-item {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      padding: 1rem;
      background: #f9fafb;
      border-radius: 6px;
      text-decoration: none;
      color: #374151;
      transition: background 0.2s;
    }

    .link-item:hover {
      background: #e5e7eb;
    }

    .link-title {
      flex: 1;
      font-weight: 500;
    }

    .gallery {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
      gap: 1.5rem;
    }

    .gallery-item {
      background: white;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
      transition: transform 0.2s, box-shadow 0.2s;
    }

    .gallery-item:hover {
      transform: translateY(-4px);
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    }

    .gallery-item img {
      width: 100%;
      height: auto;
      display: block;
    }

    .gallery-item-caption {
      padding: 1rem;
    }

    .gallery-item-title {
      font-weight: 600;
      margin-bottom: 0.5rem;
      color: #1a1a1a;
    }

    .gallery-item-text {
      font-size: 0.875rem;
      color: #666;
    }

    .icon {
      width: 20px;
      height: 20px;
      color: #6b7280;
    }

    @media (max-width: 768px) {
      .project-title {
        font-size: 1.875rem;
      }

      .gallery {
        grid-template-columns: 1fr;
      }

      .collaborators {
        grid-template-columns: 1fr;
      }
    }
    """
  end

  defp render_project_content(project, opts) do
    """
    <div class="project-header">
      <h1 class="project-title">#{escape_html(project.name)}</h1>
      #{if show_field?(project, "description") && project.description, do: "<p class=\"project-description\">#{escape_html(project.description)}</p>", else: ""}

      <div class="project-meta">
        #{if show_field?(project, "category") && project.category, do: "<span class=\"badge badge-primary\">#{escape_html(project.category)}</span>", else: ""}
        #{if show_field?(project, "project_date") && project.project_date, do: "<span class=\"badge badge-secondary\">#{format_date(project.project_date)}</span>", else: ""}
      </div>

      #{if show_field?(project, "tags") && project.tags && length(project.tags) > 0, do: render_tags(project.tags), else: ""}
    </div>

    #{if opts[:include_collaborators] && show_field?(project, "collaborators") && length(project.collaborators) > 0, do: render_collaborators(project.collaborators), else: ""}

    #{if opts[:include_links] && show_field?(project, "affiliation_links") && length(project.affiliation_links) > 0, do: render_affiliation_links(project.affiliation_links), else: ""}

    #{if length(project.media_items) > 0, do: render_media_items(project.media_items), else: ""}
    """
  end

  defp render_tags(tags) do
    tags_html =
      Enum.map_join(tags, "\n", &"<span class=\"badge badge-outline\">#{escape_html(&1)}</span>")

    """
    <div class="project-meta" style="margin-top: 1rem;">
      #{tags_html}
    </div>
    """
  end

  defp render_collaborators(collaborators) do
    collaborators_html =
      collaborators
      |> Enum.sort_by(& &1.display_order)
      |> Enum.map_join("\n", &render_collaborator/1)

    """
    <div class="section">
      <h2 class="section-title">Collaborators</h2>
      <div class="collaborators">
        #{collaborators_html}
      </div>
    </div>
    """
  end

  defp render_collaborator(collab) do
    contact_link =
      case collab.contact_type do
        "url" ->
          "<a href=\"#{escape_html(collab.contact)}\" target=\"_blank\" class=\"collaborator-contact\">🔗</a>"

        "email" ->
          "<a href=\"mailto:#{escape_html(collab.contact)}\" class=\"collaborator-contact\">📧</a>"

        _ ->
          ""
      end

    """
    <div class="collaborator">
      <span class="icon">👤</span>
      <span class="collaborator-name">#{escape_html(collab.name)}</span>
      #{contact_link}
    </div>
    """
  end

  defp render_affiliation_links(links) do
    links_html =
      links
      |> Enum.sort_by(& &1.display_order)
      |> Enum.map_join("\n", &render_affiliation_link/1)

    """
    <div class="section">
      <h2 class="section-title">Related Links</h2>
      <div class="links">
        #{links_html}
      </div>
    </div>
    """
  end

  defp render_affiliation_link(link) do
    """
    <a href="#{escape_html(link.url)}" target="_blank" class="link-item">
      <span class="icon">🔗</span>
      <span class="link-title">#{escape_html(link.title)}</span>
      <span class="icon">↗</span>
    </a>
    """
  end

  defp render_media_items(media_items) do
    media_html = Enum.map_join(media_items, "\n", &render_media_item/1)

    """
    <div class="section">
      <h2 class="section-title">Media (#{length(media_items)} image#{if length(media_items) != 1, do: "s", else: ""})</h2>
      <div class="gallery">
        #{media_html}
      </div>
    </div>
    """
  end

  defp render_media_item(item) do
    caption =
      if item.title || item.caption do
        """
        <div class="gallery-item-caption">
          #{if item.title, do: "<div class=\"gallery-item-title\">#{escape_html(item.title)}</div>", else: ""}
          #{if item.caption, do: "<div class=\"gallery-item-text\">#{escape_html(item.caption)}</div>", else: ""}
        </div>
        """
      else
        ""
      end

    """
    <figure class="gallery-item">
      <img
        src="data:#{item.content_type};base64,#{Base.encode64(item.medium_data)}"
        alt="#{escape_html(item.alt_text)}"
        loading="lazy"
      />
      #{caption}
    </figure>
    """
  end

  defp show_field?(project, field_name) do
    Map.get(project.field_visibility || %{}, field_name, true)
  end

  defp format_date(date) do
    Calendar.strftime(date, "%B %Y")
  end

  defp escape_html(nil), do: ""

  defp escape_html(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end
end
