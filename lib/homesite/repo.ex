defmodule Homesite.Repo do
  use Ecto.Repo,
    otp_app: :homesite,
    adapter: Ecto.Adapters.Postgres

  import Ecto.Query, warn: false

  @doc """
  Fetches all records from a schema matching the given conditions.

  ## Examples

      iex> Repo.scoped_all(User, email: "user@example.com")
      [%User{}, ...]

      iex> Repo.scoped_all(Post, user_id: 123)
      [%Post{}, ...]
  """
  def scoped_all(schema, conditions) do
    query = from(s in schema, where: ^conditions)
    all(query)
  end
end
