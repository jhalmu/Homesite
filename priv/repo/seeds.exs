# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Homesite.Repo.insert!(%Homesite.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Ecto.Query

alias Homesite.Repo
alias Homesite.Accounts.User
alias Homesite.ExternalFeeds.FeedSource

# Only seed in development
if Mix.env() == :dev do
  IO.puts("🌱 Seeding database...")

  # Get or create a test user for feeds
  test_user =
    case Repo.get_by(User, email: "test@example.com") do
      nil ->
        IO.puts("Creating test user...")

        {:ok, user} =
          Homesite.Accounts.register_admin(%{
            email: "test@example.com",
            password: "TestPassword123!",
            password_confirmation: "TestPassword123!"
          })

        # Confirm the user
        Repo.update!(Ecto.Changeset.change(user, confirmed_at: DateTime.utc_now(:second)))

      existing_user ->
        IO.puts("Test user already exists")
        existing_user
    end

  # Delete existing feed sources for test user to avoid duplicates
  from(f in FeedSource, where: f.user_id == ^test_user.id)
  |> Repo.delete_all()

  IO.puts("Creating test feed sources...")

  # RSS Feed Examples
  test_feeds = [
    %{
      user_id: test_user.id,
      feed_type: "rss",
      name: "Hacker News",
      url: "https://news.ycombinator.com/rss",
      icon: "🔥",
      enabled: true,
      refresh_interval: 30,
      display_order: 1
    },
    %{
      user_id: test_user.id,
      feed_type: "rss",
      name: "Phoenix Blog",
      url: "https://www.phoenixframework.org/blog.rss",
      icon: "🐦",
      enabled: true,
      refresh_interval: 60,
      display_order: 2
    },
    %{
      user_id: test_user.id,
      feed_type: "atom",
      name: "Elixir Forum",
      url: "https://elixirforum.com/latest.rss",
      icon: "💧",
      enabled: true,
      refresh_interval: 30,
      display_order: 3
    },
    %{
      user_id: test_user.id,
      feed_type: "rss",
      name: "Reddit - Elixir",
      url: "https://www.reddit.com/r/elixir.rss",
      icon: "🤖",
      enabled: true,
      refresh_interval: 45,
      display_order: 4
    },
    %{
      user_id: test_user.id,
      feed_type: "rss",
      name: "The Verge",
      url: "https://www.theverge.com/rss/index.xml",
      icon: "📰",
      enabled: true,
      refresh_interval: 30,
      display_order: 5
    },
    %{
      user_id: test_user.id,
      feed_type: "atom",
      name: "GitHub Elixir Releases",
      url: "https://github.com/elixir-lang/elixir/releases.atom",
      icon: "🚀",
      enabled: true,
      refresh_interval: 120,
      display_order: 6
    },

    # Social Media Feed Examples

    # Bluesky
    %{
      user_id: test_user.id,
      feed_type: "bluesky",
      name: "Bluesky Official",
      username: "bsky.app",
      icon: "🦋",
      enabled: true,
      refresh_interval: 15,
      display_order: 7,
      metadata: %{
        "limit" => 10
      }
    },

    # Mastodon
    %{
      user_id: test_user.id,
      feed_type: "mastodon",
      name: "Mastodon Creator",
      username: "Gargron",
      icon: "🐘",
      enabled: true,
      refresh_interval: 20,
      display_order: 8,
      metadata: %{
        "instance" => "mastodon.social",
        "limit" => 10
      }
    },

    # YouTube
    %{
      user_id: test_user.id,
      feed_type: "youtube",
      name: "Linus Tech Tips",
      icon: "📺",
      enabled: true,
      refresh_interval: 60,
      display_order: 9,
      metadata: %{
        "channel_id" => "UCXuqSBlHAE6Xw-yeJA0Tunw"
      }
    }
  ]

  Enum.each(test_feeds, fn feed_attrs ->
    case Repo.insert(%FeedSource{} |> FeedSource.changeset(feed_attrs)) do
      {:ok, feed} ->
        IO.puts("  ✅ Created feed: #{feed.name}")

      {:error, changeset} ->
        IO.puts("  ❌ Failed to create feed: #{inspect(changeset.errors)}")
    end
  end)

  # Seed Projects
  IO.puts("\n🎨 Creating test projects...")

  alias Homesite.Media.Project
  alias Homesite.Accounts.Scope

  # Create a scope for the test user
  test_scope = Scope.for_user(test_user)

  # Delete existing projects for test user to avoid duplicates
  from(p in Project, where: p.user_id == ^test_user.id)
  |> Repo.delete_all()

  # Create sample projects
  test_projects = [
    %{
      name: "My Photography Portfolio",
      description:
        "A collection of my best landscape and portrait photography from travels around the world.",
      slug: "photography-portfolio-#{System.unique_integer([:positive])}",
      template_type: "photography",
      category: "Landscape",
      tags: ["landscape", "portrait", "travel", "nature"],
      is_public: true,
      is_portfolio: true,
      completion_percentage: 85
    },
    %{
      name: "Homesite - Personal Website",
      description:
        "An Elixir/Phoenix web application for personal blogging and portfolio management. Built with LiveView and DaisyUI.",
      slug: "homesite-project-#{System.unique_integer([:positive])}",
      template_type: "coding",
      category: "Elixir/Phoenix",
      tags: ["elixir", "phoenix", "liveview", "postgresql", "open-source"],
      is_public: true,
      is_portfolio: true,
      completion_percentage: 70
    },
    %{
      name: "Technical Blog Writing",
      description:
        "Collection of technical articles about Elixir, Phoenix, and functional programming patterns.",
      slug: "technical-writing-#{System.unique_integer([:positive])}",
      template_type: "writing",
      category: "Technical Tutorial",
      tags: ["tutorial", "elixir", "phoenix", "technical"],
      is_public: true,
      is_portfolio: true,
      completion_percentage: 60
    },
    %{
      name: "My Camera Gear Setup",
      description:
        "The cameras, lenses, and accessories I use for professional and hobby photography.",
      slug: "camera-gear-#{System.unique_integer([:positive])}",
      template_type: "gears",
      category: "Photography Equipment",
      tags: ["camera", "lens", "sony", "accessories"],
      is_public: true,
      is_portfolio: true,
      completion_percentage: 50
    },
    %{
      name: "Book Reading List 2025",
      description:
        "Books I'm reading and have read this year - fiction, non-fiction, and technical books.",
      slug: "reading-list-2025-#{System.unique_integer([:positive])}",
      template_type: "books",
      category: "Technical & Fiction",
      tags: ["programming", "sci-fi", "non-fiction", "biography"],
      is_public: true,
      is_portfolio: true,
      completion_percentage: 40
    },
    %{
      name: "Short Film Project",
      description: "A documentary about local artisans and their traditional crafts.",
      slug: "short-film-#{System.unique_integer([:positive])}",
      template_type: "movies",
      category: "Documentary",
      tags: ["documentary", "short-film", "artisans"],
      is_public: true,
      is_portfolio: true,
      completion_percentage: 30
    }
  ]

  Enum.each(test_projects, fn project_attrs ->
    project_attrs = Map.put(project_attrs, :user_id, test_user.id)

    case Repo.insert(%Project{} |> Project.changeset(project_attrs, test_scope)) do
      {:ok, project} ->
        IO.puts("  ✅ Created project: #{project.name}")

      {:error, changeset} ->
        IO.puts("  ❌ Failed to create project: #{inspect(changeset.errors)}")
    end
  end)

  IO.puts("\n🎉 Seeding complete!")
  IO.puts("\n📋 Test User Credentials:")
  IO.puts("  Email: test@example.com")
  IO.puts("  Password: TestPassword123!")
  IO.puts("\n🔗 Access at:")
  IO.puts("  Feeds: http://localhost:4000/feeds")
  IO.puts("  Portfolio: http://localhost:4000/portfolio")
  IO.puts("  Projects: http://localhost:4000/projects")
else
  IO.puts("⏭️  Skipping seeds (not in development environment)")
end
