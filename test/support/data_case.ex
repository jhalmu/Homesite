defmodule Homesite.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Homesite.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Homesite.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Homesite.DataCase
    end
  end

  setup tags do
    Homesite.DataCase.setup_sandbox(tags)
    Homesite.DataCase.ensure_test_invitation()
    :ok
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  alias Ecto.Adapters.SQL.Sandbox

  def setup_sandbox(tags) do
    pid = Sandbox.start_owner!(Homesite.Repo, shared: not tags[:async])
    on_exit(fn -> Sandbox.stop_owner(pid) end)
  end

  @doc """
  Ensures a test invitation code exists in the database.
  This invitation is used by test fixtures for user registration.
  """
  def ensure_test_invitation do
    alias Homesite.Accounts.Invitation

    # Create a test admin user if needed
    test_admin =
      case Homesite.Repo.get_by(Homesite.Accounts.User, email: "test-admin@example.com") do
        nil ->
          {:ok, admin} =
            Homesite.Accounts.register_admin(%{
              email: "test-admin@example.com",
              password: "test-password-123",
              role: "admin",
              admin_flowers: 5
            })

          admin

        existing ->
          existing
      end

    # Create test invitation if it doesn't exist
    case Homesite.Repo.get_by(Invitation, code: "TEST-INVITE") do
      nil ->
        Homesite.Repo.insert!(%Invitation{
          code: "TEST-INVITE",
          created_by_user_id: test_admin.id,
          max_uses: nil,
          current_uses: 0,
          expires_at: nil,
          default_role: "user"
        })

      existing ->
        existing
    end
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
