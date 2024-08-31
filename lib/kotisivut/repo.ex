defmodule Kotisivut.Repo do
  use Ecto.Repo,
    otp_app: :kotisivut,
    adapter: Ecto.Adapters.Postgres
end
