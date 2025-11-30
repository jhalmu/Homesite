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

  IO.puts("\n🎉 Seeding complete!")
  IO.puts("\n📋 Test User Credentials:")
  IO.puts("  Email: test@example.com")
  IO.puts("  Password: TestPassword123!")
  IO.puts("\n🔗 Access feeds at: http://localhost:4000/feeds")
else
  IO.puts("⏭️  Skipping seeds (not in development environment)")
end
