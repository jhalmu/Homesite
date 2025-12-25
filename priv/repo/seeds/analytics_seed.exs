# Analytics seed data for development
# Generates realistic activity logs and search queries with geo data
#
# Run with: mix run priv/repo/seeds/analytics_seed.exs

import Ecto.Query

alias Homesite.Repo
alias Homesite.Accounts.User
alias Homesite.Analytics.ActivityLog
alias Homesite.Analytics.SearchQuery

# Only seed in development
if Mix.env() == :dev do
  IO.puts("")
  IO.puts("📊 Seeding analytics data...")

  # Get any admin user for activity logs (prefer admin@localhost, fall back to any user)
  admin =
    Repo.get_by(User, email: "admin@localhost") ||
      Repo.one(from u in User, where: u.admin_flowers > 0, limit: 1) ||
      Repo.one(from u in User, limit: 1)

  unless admin do
    IO.puts("   ⚠️  No user found. Run main seeds first: mix run priv/repo/seeds.exs")
    System.halt(1)
  end

  IO.puts("   Using user: #{admin.email}")

  # Country/city data with realistic distribution
  # Finland gets higher weight since this is a Finnish site
  geo_data = [
    # {country, cities, weight}
    {"FI", ["Helsinki", "Espoo", "Tampere", "Turku", "Oulu", "Vantaa", "Jyväskylä"], 40},
    {"US", ["New York", "San Francisco", "Los Angeles", "Seattle", "Austin", "Chicago", "Boston"], 20},
    {"DE", ["Berlin", "Munich", "Hamburg", "Frankfurt", "Cologne"], 10},
    {"SE", ["Stockholm", "Gothenburg", "Malmö", "Uppsala"], 8},
    {"GB", ["London", "Manchester", "Edinburgh", "Birmingham", "Bristol"], 7},
    {"NL", ["Amsterdam", "Rotterdam", "Utrecht", "The Hague"], 5},
    {"NO", ["Oslo", "Bergen", "Trondheim", "Stavanger"], 5},
    {"EE", ["Tallinn", "Tartu"], 3},
    {"FR", ["Paris", "Lyon", "Marseille"], 2}
  ]

  # Flatten with weights for weighted random selection
  weighted_geo =
    Enum.flat_map(geo_data, fn {country, cities, weight} ->
      for _ <- 1..weight, do: {country, cities}
    end)

  # Actions and their relative frequencies
  actions_with_weights = [
    {"view", 50},
    {"create", 15},
    {"update", 20},
    {"delete", 5},
    {"search", 25},
    {"share", 10},
    {"login", 15},
    {"publish", 8}
  ]

  weighted_actions =
    Enum.flat_map(actions_with_weights, fn {action, weight} ->
      for _ <- 1..weight, do: action
    end)

  # Resource types
  resource_types = ["post", "tag", "user", "search", "faq", "media", "project"]

  # User agents (realistic mix)
  user_agents = [
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0",
    "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
  ]

  # Generate random IP address (for realistic data)
  generate_ip = fn ->
    "#{Enum.random(1..223)}.#{Enum.random(0..255)}.#{Enum.random(0..255)}.#{Enum.random(1..254)}"
  end

  # Clear existing analytics data (optional - for clean re-seeding)
  {deleted_logs, _} = Repo.delete_all(ActivityLog)
  {deleted_queries, _} = Repo.delete_all(SearchQuery)
  IO.puts("   🗑️  Cleared #{deleted_logs} activity logs and #{deleted_queries} search queries")

  # Generate 300 activity logs over past 30 days
  IO.puts("   📈 Generating activity logs...")

  now = DateTime.utc_now()

  activity_logs =
    for _i <- 1..300 do
      {country, cities} = Enum.random(weighted_geo)
      city = Enum.random(cities)
      action = Enum.random(weighted_actions)
      resource_type = Enum.random(resource_types)

      # Distribute timestamps over 30 days with more recent bias
      # Use exponential distribution for more recent activity
      days_ago = :rand.uniform() |> :math.pow(2) |> Kernel.*(30) |> trunc()
      hours_ago = :rand.uniform(24) - 1
      minutes_ago = :rand.uniform(60) - 1

      inserted_at =
        now
        |> DateTime.add(-days_ago, :day)
        |> DateTime.add(-hours_ago, :hour)
        |> DateTime.add(-minutes_ago, :minute)
        |> DateTime.truncate(:second)

      %{
        user_id: admin.id,
        action: action,
        resource_type: resource_type,
        resource_id: Enum.random(1..100),
        country: country,
        city: city,
        ip_address: generate_ip.(),
        user_agent: Enum.random(user_agents),
        changes: %{},
        metadata: %{},
        inserted_at: inserted_at
      }
    end

  {count, _} = Repo.insert_all(ActivityLog, activity_logs)
  IO.puts("   ✅ Created #{count} activity logs")

  # Generate 150 search queries over past 30 days
  IO.puts("   🔍 Generating search queries...")

  # Realistic search terms (mix of Finnish and English)
  search_terms = [
    # Finnish terms
    "elixir", "phoenix", "liveview", "ohjelmointi", "koodaus", "blogi",
    "teknologia", "ohjelmistokehitys", "web-kehitys", "tietokanta",
    # English terms
    "programming", "tutorial", "guide", "howto", "tips", "best practices",
    "docker", "kubernetes", "database", "api", "rest", "graphql",
    # Mixed
    "phoenix liveview", "elixir tutorial", "ecto query", "tailwind css",
    "functional programming", "pattern matching", "genserver", "otp"
  ]

  search_queries =
    for _i <- 1..150 do
      {country, cities} = Enum.random(weighted_geo)
      city = Enum.random(cities)
      query = Enum.random(search_terms)

      # Simulate result counts (some queries find results, some don't)
      has_results = :rand.uniform(100) > 20
      posts_count = if has_results, do: Enum.random(0..8), else: 0
      tags_count = if has_results, do: Enum.random(0..3), else: 0
      faqs_count = if has_results, do: Enum.random(0..5), else: 0
      result_count = posts_count + tags_count + faqs_count

      # Distribute timestamps over 30 days
      days_ago = :rand.uniform() |> :math.pow(2) |> Kernel.*(30) |> trunc()
      hours_ago = :rand.uniform(24) - 1
      minutes_ago = :rand.uniform(60) - 1

      inserted_at =
        now
        |> DateTime.add(-days_ago, :day)
        |> DateTime.add(-hours_ago, :hour)
        |> DateTime.add(-minutes_ago, :minute)
        |> DateTime.truncate(:second)

      %{
        query: query,
        result_count: result_count,
        posts_count: posts_count,
        tags_count: tags_count,
        faqs_count: faqs_count,
        duration_ms: Enum.random(5..150),
        user_id: if(:rand.uniform(100) > 70, do: admin.id, else: nil),
        country: country,
        city: city,
        ip_address: generate_ip.(),
        user_agent: Enum.random(user_agents),
        inserted_at: inserted_at
      }
    end

  {count, _} = Repo.insert_all(SearchQuery, search_queries)
  IO.puts("   ✅ Created #{count} search queries")

  # Summary
  IO.puts("")
  IO.puts("╔════════════════════════════════════════════════════════════╗")
  IO.puts("║  📊 ANALYTICS SEEDING COMPLETE                             ║")
  IO.puts("╠════════════════════════════════════════════════════════════╣")

  # Query stats
  countries_count =
    Repo.one(from a in ActivityLog, select: count(fragment("DISTINCT ?", a.country)))

  cities_count =
    Repo.one(from a in ActivityLog, select: count(fragment("DISTINCT ?", a.city)))

  IO.puts("║  Activity Logs: 300                                        ║")
  IO.puts("║  Search Queries: 150                                       ║")
  IO.puts("║  Unique Countries: #{String.pad_trailing(to_string(countries_count), 38)}║")
  IO.puts("║  Unique Cities: #{String.pad_trailing(to_string(cities_count), 41)}║")
  IO.puts("╚════════════════════════════════════════════════════════════╝")
  IO.puts("")
end
