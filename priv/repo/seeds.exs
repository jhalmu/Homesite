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
alias Homesite.Accounts
alias Homesite.Accounts.User
alias Homesite.ExternalFeeds.FeedSource

# Only seed in development
if Mix.env() == :dev do
  IO.puts("")
  IO.puts("╔════════════════════════════════════════════════════════════╗")
  IO.puts("║  🌱 HOMESITE DEVELOPMENT SEEDING                           ║")
  IO.puts("║                                                            ║")
  IO.puts("║  ⚠️  Admin credentials will be shown below - save them!    ║")
  IO.puts("╚════════════════════════════════════════════════════════════╝")
  IO.puts("")

  # ==========================================================================
  # Create or find DEV ADMIN with secure random password
  # ==========================================================================
  IO.puts("🔐 Setting up dev admin...")

  dev_admin =
    case Repo.get_by(User, email: "admin@localhost") do
      nil ->
        # Generate secure random password
        dev_admin_password =
          :crypto.strong_rand_bytes(16) |> Base.url_encode64() |> binary_part(0, 20)

        IO.puts("   Creating dev admin with random password...")

        {:ok, user} =
          Accounts.register_admin(%{
            email: "admin@localhost",
            password: dev_admin_password,
            password_confirmation: dev_admin_password
          })

        # Set 5 flowers and confirm
        user =
          Repo.update!(
            Ecto.Changeset.change(user, admin_flowers: 5, confirmed_at: DateTime.utc_now(:second))
          )

        IO.puts("")
        IO.puts("╔════════════════════════════════════════════════════════════╗")
        IO.puts("║  🔐 DEV ADMIN CREATED - SAVE THESE CREDENTIALS!            ║")
        IO.puts("╠════════════════════════════════════════════════════════════╣")
        IO.puts("║  Email:    admin@localhost                                 ║")
        IO.puts("║  Password: #{String.pad_trailing(dev_admin_password, 43)}║")
        IO.puts("║                                                            ║")
        IO.puts("║  ⚠️  This password is shown ONLY ONCE!                     ║")
        IO.puts("║  💡 You can reset via: mix run -e 'Homesite.Accounts...'   ║")
        IO.puts("╚════════════════════════════════════════════════════════════╝")
        IO.puts("")

        user

      existing_user ->
        IO.puts("   ✅ Dev admin already exists (admin@localhost)")
        existing_user
    end

  # ==========================================================================
  # Create test user for feeds/projects demo
  # ==========================================================================
  IO.puts("👤 Setting up test user...")

  test_user =
    case Repo.get_by(User, email: "test@example.com") do
      nil ->
        IO.puts("   Creating test user...")

        {:ok, user} =
          Accounts.register_admin(%{
            email: "test@example.com",
            password: "TestPassword123!",
            password_confirmation: "TestPassword123!"
          })

        # Confirm the user
        Repo.update!(Ecto.Changeset.change(user, confirmed_at: DateTime.utc_now(:second)))

      existing_user ->
        IO.puts("   ✅ Test user already exists")
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

  # ==========================================================================
  # Seed FAQs (bilingual user and admin FAQs)
  # ==========================================================================
  IO.puts("\n📚 Seeding FAQs...")

  # Run FAQ seed files - they handle idempotency via slug uniqueness
  faq_seed_files = [
    "priv/repo/seeds/comprehensive_faqs.exs",
    "priv/repo/seeds/user_guide_faqs.exs"
  ]

  Enum.each(faq_seed_files, fn file ->
    if File.exists?(file) do
      IO.puts("   Running #{Path.basename(file)}...")
      Code.eval_file(file)
    else
      IO.puts("   ⚠️  Skipping #{Path.basename(file)} (file not found)")
    end
  end)

  # ==========================================================================
  # Seed Analytics Data (activity logs and search queries with geo data)
  # ==========================================================================
  analytics_seed_file = "priv/repo/seeds/analytics_seed.exs"

  if File.exists?(analytics_seed_file) do
    Code.eval_file(analytics_seed_file)
  end

  IO.puts("")
  IO.puts("╔════════════════════════════════════════════════════════════╗")
  IO.puts("║  🎉 SEEDING COMPLETE!                                      ║")
  IO.puts("╠════════════════════════════════════════════════════════════╣")
  IO.puts("║  📋 Test User: test@example.com / TestPassword123!         ║")
  IO.puts("║  🔐 Dev Admin: admin@localhost (password shown above)      ║")
  IO.puts("╠════════════════════════════════════════════════════════════╣")
  IO.puts("║  🔗 Access at:                                             ║")
  IO.puts("║     http://localhost:4000/feeds                            ║")
  IO.puts("║     http://localhost:4000/portfolio                        ║")
  IO.puts("║     http://localhost:4000/faqs                             ║")
  IO.puts("║     http://localhost:4000/admin (admin only)               ║")
  IO.puts("╚════════════════════════════════════════════════════════════╝")
  IO.puts("")
else
  IO.puts("⏭️  Skipping seeds (not in development environment)")
end
