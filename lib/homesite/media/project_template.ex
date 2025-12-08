defmodule Homesite.Media.ProjectTemplate do
  @moduledoc """
  Code-defined project templates for different project types.

  Templates provide customized field labels, placeholders, and suggested tags
  based on the project type. This approach keeps templates in code (not database)
  for easier maintenance, version control, and compile-time safety.

  ## Available Templates

  - `photography` - Image galleries, visual portfolios
  - `coding` - GitHub repos, technical projects
  - `writing` - Articles, publications
  - `books` - Book projects, reading lists
  - `gears` - Equipment, tech setups
  - `movies` - Film projects, video content
  - `custom` - User-defined, all fields available
  """

  @type template_id :: String.t()
  @type field_config :: %{label: String.t(), placeholder: String.t()}
  @type template :: %{
          id: template_id(),
          name: String.t(),
          icon: String.t(),
          description: String.t(),
          fields: %{atom() => field_config()},
          suggested_tags: [String.t()]
        }

  @templates %{
    "photography" => %{
      id: "photography",
      name: "Photography/Art",
      icon: "hero-camera",
      description: "Image galleries and visual portfolios",
      fields: %{
        project_date: %{label: "Shoot Date", placeholder: "When was the shoot?"},
        category: %{label: "Category", placeholder: "Wedding, Portrait, Landscape..."},
        tags: %{label: "Tags", placeholder: "nature, portrait, black-and-white"},
        collaborators: %{label: "Team/Models", placeholder: "Add team members or models"},
        affiliation_links: %{
          label: "Client/Press Links",
          placeholder: "Add client or press links"
        }
      },
      suggested_tags: [
        "portrait",
        "landscape",
        "wedding",
        "event",
        "studio",
        "outdoor",
        "editorial"
      ]
    },
    "coding" => %{
      id: "coding",
      name: "Coding/Software",
      icon: "hero-code-bracket",
      description: "GitHub repos and technical projects",
      fields: %{
        project_date: %{label: "Start Date", placeholder: "When did the project start?"},
        category: %{label: "Language/Framework", placeholder: "Elixir, React, Python..."},
        tags: %{label: "Technologies", placeholder: "phoenix, liveview, postgresql"},
        collaborators: %{label: "Contributors", placeholder: "Add project contributors"},
        affiliation_links: %{
          label: "Repo/Demo Links",
          placeholder: "GitHub, live demo, documentation"
        }
      },
      suggested_tags: [
        "elixir",
        "phoenix",
        "react",
        "typescript",
        "open-source",
        "api",
        "cli",
        "web-app"
      ]
    },
    "writing" => %{
      id: "writing",
      name: "Writing/Content",
      icon: "hero-document-text",
      description: "Articles and publications",
      fields: %{
        project_date: %{label: "Publication Date", placeholder: "When was it published?"},
        category: %{label: "Type", placeholder: "Article, Essay, Tutorial..."},
        tags: %{label: "Topics", placeholder: "elixir, web-development, tutorial"},
        collaborators: %{label: "Co-Authors", placeholder: "Add co-authors or editors"},
        affiliation_links: %{label: "Publication Links", placeholder: "Where it's published"}
      },
      suggested_tags: ["tutorial", "guide", "opinion", "review", "technical", "essay", "how-to"]
    },
    "books" => %{
      id: "books",
      name: "Books",
      icon: "hero-book-open",
      description: "Book projects and reading lists",
      fields: %{
        project_date: %{
          label: "Read/Published Date",
          placeholder: "When did you read or publish it?"
        },
        category: %{label: "Genre", placeholder: "Fiction, Non-fiction, Technical..."},
        tags: %{label: "Topics/Themes", placeholder: "programming, biography, sci-fi"},
        collaborators: %{label: "Authors/Co-Authors", placeholder: "Book authors"},
        affiliation_links: %{
          label: "Purchase/Review Links",
          placeholder: "Amazon, Goodreads, reviews"
        }
      },
      suggested_tags: [
        "fiction",
        "non-fiction",
        "technical",
        "biography",
        "sci-fi",
        "self-help",
        "programming",
        "philosophy"
      ]
    },
    "gears" => %{
      id: "gears",
      name: "Gears/Equipment",
      icon: "hero-wrench-screwdriver",
      description: "Equipment and tech setups",
      fields: %{
        project_date: %{label: "Acquired Date", placeholder: "When did you get it?"},
        category: %{label: "Category", placeholder: "Camera, Audio, Computer..."},
        tags: %{label: "Tags", placeholder: "sony, lens, audio, desk-setup"},
        collaborators: %{label: "Manufacturers/Brands", placeholder: "Brand or manufacturer info"},
        affiliation_links: %{
          label: "Product/Review Links",
          placeholder: "Product page, reviews, affiliate"
        }
      },
      suggested_tags: [
        "camera",
        "lens",
        "audio",
        "computer",
        "lighting",
        "accessories",
        "desk-setup",
        "mobile"
      ]
    },
    "movies" => %{
      id: "movies",
      name: "Movies/Video",
      icon: "hero-film",
      description: "Film projects and video content",
      fields: %{
        project_date: %{
          label: "Release/Watch Date",
          placeholder: "When was it released or watched?"
        },
        category: %{label: "Genre", placeholder: "Documentary, Short, Feature..."},
        tags: %{label: "Tags", placeholder: "documentary, music-video, vlog"},
        collaborators: %{label: "Cast/Crew", placeholder: "Add cast and crew members"},
        affiliation_links: %{label: "Watch/IMDB Links", placeholder: "YouTube, Vimeo, IMDB"}
      },
      suggested_tags: [
        "documentary",
        "short-film",
        "feature",
        "music-video",
        "vlog",
        "tutorial",
        "commercial"
      ]
    },
    "custom" => %{
      id: "custom",
      name: "Custom/Mixed",
      icon: "hero-squares-plus",
      description: "User-defined project type",
      fields: %{
        project_date: %{label: "Date", placeholder: "Project date"},
        category: %{label: "Category", placeholder: "Enter category"},
        tags: %{label: "Tags", placeholder: "Enter tags"},
        collaborators: %{label: "Collaborators", placeholder: "Add collaborators"},
        affiliation_links: %{label: "Links", placeholder: "Add relevant links"}
      },
      suggested_tags: []
    }
  }

  @valid_template_ids Map.keys(@templates)

  @doc """
  Returns all available templates as a list.
  """
  @spec all() :: [template()]
  def all do
    @templates
    |> Map.values()
    |> Enum.sort_by(fn t -> if t.id == "custom", do: "zzz", else: t.name end)
  end

  @doc """
  Returns a single template by ID, or nil if not found.
  """
  @spec get(template_id()) :: template() | nil
  def get(id) when is_binary(id) do
    Map.get(@templates, id)
  end

  def get(_), do: nil

  @doc """
  Returns a single template by ID, raises if not found.
  """
  @spec get!(template_id()) :: template()
  def get!(id) do
    case get(id) do
      nil -> raise ArgumentError, "Unknown template: #{inspect(id)}"
      template -> template
    end
  end

  @doc """
  Returns template options for select inputs as {name, id} tuples.
  """
  @spec options() :: [{String.t(), template_id()}]
  def options do
    all()
    |> Enum.map(fn t -> {t.name, t.id} end)
  end

  @doc """
  Returns list of valid template IDs.
  """
  @spec valid_ids() :: [template_id()]
  def valid_ids, do: @valid_template_ids

  @doc """
  Returns the default template ID.
  """
  @spec default_id() :: template_id()
  def default_id, do: "photography"

  @doc """
  Returns the field configuration for a specific template and field.
  Falls back to custom template's field config if not found.
  """
  @spec get_field(template_id(), atom()) :: field_config()
  def get_field(template_id, field_name) do
    template = get(template_id) || get("custom")
    Map.get(template.fields, field_name, %{label: to_string(field_name), placeholder: ""})
  end

  @doc """
  Returns suggested tags for a template.
  """
  @spec suggested_tags(template_id()) :: [String.t()]
  def suggested_tags(template_id) do
    case get(template_id) do
      nil -> []
      template -> template.suggested_tags
    end
  end
end
