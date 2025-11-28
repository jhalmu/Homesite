Application.put_env(:phoenix_test, :base_url, HomesiteWeb.Endpoint.url())

# Exclude external integration tests and playwright tests by default
# Run with: mix test --include external --include playwright
ExUnit.configure(exclude: [playwright: true, external: true])
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Homesite.Repo, :manual)
