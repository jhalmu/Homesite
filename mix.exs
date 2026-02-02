defmodule Homesite.MixProject do
  use Mix.Project

  def project do
    [
      app: :homesite,
      version: "0.0.0",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: elixirc_options(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader],
      dialyzer: dialyzer()
    ]
  end

  defp dialyzer do
    [
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      plt_add_apps: [:mix, :ex_unit],
      flags: [
        :error_handling,
        :underspecs,
        :unknown
      ],
      ignore_warnings: ".dialyzer_ignore.exs"
    ]
  end

  # Compiler options
  # Note: warnings_as_errors disabled because of false positive "unused import"
  # warnings for Gettext in HEEx templates (compiler can't detect macro usage in templates)
  defp elixirc_options(_), do: []

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Homesite.Application, []},
      extra_applications: [:logger, :runtime_tools],
      included_applications: included_applications(Mix.env())
    ]
  end

  defp included_applications(_), do: []

  def cli do
    [
      preferred_envs: [precommit: :test, "test.all": :test, "test.full": :test, lighthouse: :dev]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:argon2_elixir, "~> 4.0"},
      {:phoenix, "~> 1.8.1"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.1.0"},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.16"},
      {:gen_smtp, "~> 1.2"},
      {:req, "~> 0.5"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},

      # Extra adds
      {:phoenix_seo, "0.1.11"},
      {:atomex, "0.5.1"},
      {:mdex, "0.10.0"},
      {:yaml_elixir, "2.12.0"},
      {:nimble_publisher, "1.1.1"},
      {:nimble_csv, "~> 1.1"},
      {:floki, "0.38.0"},

      # Monitoring and Telemetry
      {:phoenix_live_dashboard, "0.8.7"},
      {:telemetry_metrics, "1.1.0"},
      {:telemetry_poller, "1.3.0"},

      # Security
      {:hammer, "~> 6.2"},
      {:hammer_plug, "~> 3.1"},
      {:phoenix_turnstile, "~> 1.0"},

      # IP Geolocation (MaxMind GeoLite2)
      {:locus, "~> 2.3"},

      # Background Jobs & Feed Processing
      {:oban, "~> 2.18"},
      {:html_sanitize_ex, "~> 1.4"},
      {:timex, "~> 3.7"},
      {:sweet_xml, "~> 0.7"},

      # Image Processing
      {:mogrify, "~> 0.9.3"},

      # Dev and Test
      {:phoenix_test, "0.9.1", only: :test, runtime: false},
      {:phoenix_test_playwright, "0.9.1", only: :test, runtime: false},
      {:a11y_audit, "0.3.0", only: :test, runtime: false},
      {:esbuild, "0.10.0", runtime: Mix.env() == :dev},
      {:tailwind, "0.4.1", runtime: Mix.env() == :dev},
      {:phoenix_live_reload, "1.6.1", only: :dev},
      {:tailwind_formatter, "0.4.2", only: [:dev, :test], runtime: false},
      {:credo, "1.7.13", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:lazy_html, "0.1.8", only: :test},
      {:tidewave, "~> 0.5", only: :dev},
      # {:tidewave_formatter, "~> 0.5", only: [:dev, :test], runtime: false},
      {:igniter, "0.7.0", only: [:dev, :test]},
      {:usage_rules, "~> 0.1", only: [:dev]}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["compile", "tailwind homesite", "esbuild homesite"],
      "assets.deploy": [
        "tailwind homesite --minify",
        "esbuild homesite --minify",
        "phx.digest"
      ],
      precommit: ["compile --warning-as-errors", "deps.unlock --unused", "format", "test"],
      "test.all": ["precommit", "credo --strict"],
      "test.full": ["test.all", "lighthouse --start-server"]
    ]
  end
end
