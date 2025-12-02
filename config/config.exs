# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :homesite, :scopes,
  user: [
    default: true,
    module: Homesite.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: Homesite.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :homesite,
  ecto_repos: [Homesite.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures Hammer rate limiting
config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10]}

# Configures Oban background jobs
config :homesite, Oban,
  repo: Homesite.Repo,
  queues: [default: 10, feeds: 5, analytics: 2],
  plugins: [
    Oban.Plugins.Pruner,
    {Oban.Plugins.Cron,
     crontab: [
       # Refresh all feeds every 30 minutes
       {"*/30 * * * *", Homesite.Workers.FeedRefreshWorker, args: %{refresh_all: true}}
     ]}
  ]

# Configures external feed adapters
config :homesite, :external_feeds,
  # Recommended Nitter instances for Twitter/X RSS feeds
  # Note: Twitter adapter is DORMANT but can be activated with Nitter
  # Nitter provides RSS feeds for Twitter without requiring API keys
  # Usage: https://{instance}/username/rss
  nitter_instances: [
    "nitter.net",
    "nitter.poast.org",
    "nitter.privacydev.net",
    "nitter.cz",
    "nitter.unixfox.eu"
  ]

# Configures the endpoint
config :homesite, HomesiteWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: HomesiteWeb.ErrorHTML, json: HomesiteWeb.ErrorJSON],
    layout: {HomesiteWeb.Layouts, :error}
  ],
  pubsub_server: Homesite.PubSub,
  live_view: [signing_salt: "Dt4eUel3"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :homesite, Homesite.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.27.0",
  homesite: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  homesite: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure Gettext for internationalization
config :homesite, HomesiteWeb.Gettext,
  default_locale: "fi",
  locales: ~w(en fi)

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
