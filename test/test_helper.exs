# Start Playwright browser pool (required for phoenix_test_playwright 0.10+)
{:ok, _} = PhoenixTest.Playwright.Supervisor.start_link()

Application.put_env(:phoenix_test, :base_url, HomesiteWeb.Endpoint.url())

# Exclude external integration tests and playwright tests by default
# Run with: mix test --include external --include playwright
ExUnit.configure(exclude: [playwright: true, external: true])
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Homesite.Repo, :manual)
