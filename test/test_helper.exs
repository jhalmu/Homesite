# Start Playwright browser pool only when playwright tests will run
# (not in CI where playwright isn't installed)
unless System.get_env("CI") do
  {:ok, _} = PhoenixTest.Playwright.Supervisor.start_link()
end

Application.put_env(:phoenix_test, :base_url, HomesiteWeb.Endpoint.url())

# Exclude external integration tests and playwright tests by default
# Run with: mix test --include external --include playwright
ExUnit.configure(exclude: [playwright: true, external: true])
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Homesite.Repo, :manual)
