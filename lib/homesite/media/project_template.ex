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

  use Gettext, backend: HomesiteWeb.Gettext

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

  # Templates are defined as functions to allow gettext to work at runtime
  defp templates do
    %{
      "photography" => %{
        id: "photography",
        name: gettext("Photography/Art"),
        icon: "hero-camera",
        description: gettext("Image galleries and visual portfolios"),
        fields: %{
          project_date: %{
            label: gettext("Shoot Date"),
            placeholder: gettext("When was the shoot?")
          },
          category: %{
            label: gettext("Category"),
            placeholder: gettext("Wedding, Portrait, Landscape...")
          },
          tags: %{
            label: gettext("Tags"),
            placeholder: gettext("nature, portrait, black-and-white")
          },
          collaborators: %{
            label: gettext("Team/Models"),
            placeholder: gettext("Add team members or models")
          },
          affiliation_links: %{
            label: gettext("Client/Press Links"),
            placeholder: gettext("Add client or press links")
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
        ],
        # Photography is image-focused, no default sections
        default_sections: [],
        available_section_types: ["rich_text"]
      },
      "coding" => %{
        id: "coding",
        name: gettext("Coding/Software"),
        icon: "hero-code-bracket",
        description: gettext("GitHub repos and technical projects"),
        fields: %{
          project_date: %{
            label: gettext("Start Date"),
            placeholder: gettext("When did the project start?")
          },
          category: %{
            label: gettext("Language/Framework"),
            placeholder: gettext("Elixir, React, Python...")
          },
          tags: %{
            label: gettext("Technologies"),
            placeholder: gettext("phoenix, liveview, postgresql")
          },
          collaborators: %{
            label: gettext("Contributors"),
            placeholder: gettext("Add project contributors")
          },
          affiliation_links: %{
            label: gettext("Repo/Demo Links"),
            placeholder: gettext("GitHub, live demo, documentation")
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
        ],
        default_sections: [
          %{section_type: "rich_text", title: gettext("Overview")},
          %{section_type: "code_block", title: gettext("Key Code")}
        ],
        available_section_types: ["code_block", "rich_text"]
      },
      "writing" => %{
        id: "writing",
        name: gettext("Writing/Content"),
        icon: "hero-document-text",
        description: gettext("Articles and publications"),
        fields: %{
          project_date: %{
            label: gettext("Publication Date"),
            placeholder: gettext("When was it published?")
          },
          category: %{
            label: gettext("Type"),
            placeholder: gettext("Article, Essay, Tutorial...")
          },
          tags: %{
            label: gettext("Topics"),
            placeholder: gettext("elixir, web-development, tutorial")
          },
          collaborators: %{
            label: gettext("Co-Authors"),
            placeholder: gettext("Add co-authors or editors")
          },
          affiliation_links: %{
            label: gettext("Publication Links"),
            placeholder: gettext("Where it's published")
          }
        },
        suggested_tags: ["tutorial", "guide", "opinion", "review", "technical", "essay", "how-to"],
        default_sections: [
          %{section_type: "chapter", title: gettext("Chapter 1")}
        ],
        available_section_types: ["chapter", "rich_text"]
      },
      "books" => %{
        id: "books",
        name: gettext("Books"),
        icon: "hero-book-open",
        description: gettext("Book projects and reading lists"),
        fields: %{
          project_date: %{
            label: gettext("Read/Published Date"),
            placeholder: gettext("When did you read or publish it?")
          },
          category: %{
            label: gettext("Genre"),
            placeholder: gettext("Fiction, Non-fiction, Technical...")
          },
          tags: %{
            label: gettext("Topics/Themes"),
            placeholder: gettext("programming, biography, sci-fi")
          },
          collaborators: %{
            label: gettext("Authors/Co-Authors"),
            placeholder: gettext("Book authors")
          },
          affiliation_links: %{
            label: gettext("Purchase/Review Links"),
            placeholder: gettext("Amazon, Goodreads, reviews")
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
        ],
        default_sections: [
          %{
            section_type: "book_info",
            title: gettext("Book Information")
          },
          %{section_type: "rich_text", title: gettext("Summary")},
          %{section_type: "rich_text", title: gettext("My Review")}
        ],
        available_section_types: ["book_info", "chapter", "rich_text"]
      },
      "gears" => %{
        id: "gears",
        name: gettext("Gears/Equipment"),
        icon: "hero-wrench-screwdriver",
        description: gettext("Equipment and tech setups"),
        fields: %{
          project_date: %{
            label: gettext("Acquired Date"),
            placeholder: gettext("When did you get it?")
          },
          category: %{
            label: gettext("Category"),
            placeholder: gettext("Camera, Audio, Computer...")
          },
          tags: %{
            label: gettext("Tags"),
            placeholder: gettext("sony, lens, audio, desk-setup")
          },
          collaborators: %{
            label: gettext("Manufacturers/Brands"),
            placeholder: gettext("Brand or manufacturer info")
          },
          affiliation_links: %{
            label: gettext("Product/Review Links"),
            placeholder: gettext("Product page, reviews, affiliate")
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
        ],
        default_sections: [
          %{
            section_type: "gear_spec",
            title: gettext("Specifications")
          }
        ],
        available_section_types: ["gear_spec", "rich_text"]
      },
      "movies" => %{
        id: "movies",
        name: gettext("Movies/Video"),
        icon: "hero-film",
        description: gettext("Film projects and video content"),
        fields: %{
          project_date: %{
            label: gettext("Release/Watch Date"),
            placeholder: gettext("When was it released or watched?")
          },
          category: %{
            label: gettext("Genre"),
            placeholder: gettext("Documentary, Short, Feature...")
          },
          tags: %{
            label: gettext("Tags"),
            placeholder: gettext("documentary, music-video, vlog")
          },
          collaborators: %{
            label: gettext("Cast/Crew"),
            placeholder: gettext("Add cast and crew members")
          },
          affiliation_links: %{
            label: gettext("Watch/IMDB Links"),
            placeholder: gettext("YouTube, Vimeo, IMDB")
          }
        },
        suggested_tags: [
          "documentary",
          "short-film",
          "feature",
          "music-video",
          "vlog",
          "tutorial",
          "commercial"
        ],
        default_sections: [
          %{
            section_type: "movie_info",
            title: gettext("Movie Information")
          }
        ],
        available_section_types: ["movie_info", "rich_text"]
      },
      "custom" => %{
        id: "custom",
        name: gettext("Custom/Mixed"),
        icon: "hero-squares-plus",
        description: gettext("User-defined project type"),
        fields: %{
          project_date: %{
            label: gettext("Date"),
            placeholder: gettext("Project date")
          },
          category: %{
            label: gettext("Category"),
            placeholder: gettext("Enter category")
          },
          tags: %{
            label: gettext("Tags"),
            placeholder: gettext("Enter tags")
          },
          collaborators: %{
            label: gettext("Collaborators"),
            placeholder: gettext("Add collaborators")
          },
          affiliation_links: %{
            label: gettext("Links"),
            placeholder: gettext("Add relevant links")
          }
        },
        suggested_tags: [],
        # Custom projects get all section types available
        default_sections: [],
        available_section_types: [
          "rich_text",
          "code_block",
          "book_info",
          "chapter",
          "gear_spec",
          "movie_info"
        ]
      }
    }
  end

  # Valid template IDs (hardcoded since they don't need translation)
  @valid_template_ids ~w(photography coding writing books gears movies custom)

  @doc """
  Returns all available templates as a list.
  """
  @spec all() :: [template()]
  def all do
    templates()
    |> Map.values()
    |> Enum.sort_by(fn t -> if t.id == "custom", do: "zzz", else: t.name end)
  end

  @doc """
  Returns a single template by ID, or nil if not found.
  """
  @spec get(template_id()) :: template() | nil
  def get(id) when is_binary(id) do
    Map.get(templates(), id)
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
