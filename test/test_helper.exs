Application.put_env(:phoenix_test, :base_url, HomesiteWeb.Endpoint.url())

ExUnit.configure(exclude: [playwright: true])
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Homesite.Repo, :manual)
