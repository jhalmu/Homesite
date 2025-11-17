defmodule Homesite.Repo do
  use Ecto.Repo,
    otp_app: :homesite,
    adapter: Ecto.Adapters.Postgres
end
