defmodule Mix.Tasks.SeedAdmin do
  @moduledoc """
  Seeds an admin user with specified flower permissions.

  ## Usage

      mix seed.admin email@example.com --flowers 5 --password MySecurePass123

  ## Options

    * email - Required. Admin user email address
    * --flowers - Optional. Flower permission level (1-5). Default: 5
    * --password - Optional. Admin password. If not provided, a random password will be generated

  ## Examples

      # Create admin with max flowers (5) and random password
      mix seed.admin admin@example.com

      # Create admin with specific flower level and custom password
      mix seed.admin admin@example.com --flowers 3 --password MyPass123

  ## Security Notes

  - This task requires command-line access to the server
  - Admin creation is logged for audit purposes
  - Random passwords are 20 characters with mixed case, numbers, and symbols
  - Use strong passwords for production environments
  """

  use Mix.Task
  alias Homesite.{Accounts, Repo}
  alias Homesite.Accounts.User

  @shortdoc "Seeds an admin user with flower permissions"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, args, _} =
      OptionParser.parse(args,
        strict: [flowers: :integer, password: :string],
        aliases: [f: :flowers, p: :password]
      )

    case args do
      [email] ->
        flowers = Keyword.get(opts, :flowers, 5)
        password = Keyword.get(opts, :password, generate_password())

        create_admin(email, password, flowers)

      _ ->
        Mix.shell().error("""
        Usage: mix seed.admin email@example.com [--flowers N] [--password PASSWORD]

        Example:
          mix seed.admin admin@example.com --flowers 5 --password MySecurePass123
        """)
    end
  end

  defp create_admin(email, password, flowers) do
    # Validate flower level
    unless flowers in 1..5 do
      Mix.shell().error("Error: Flower level must be between 1 and 5")
      System.halt(1)
    end

    # Check if user already exists
    case Repo.get_by(User, email: email) do
      nil ->
        # Create new admin user
        attrs = %{
          email: email,
          password: password,
          role: "admin",
          admin_flowers: flowers,
          display_name: "Admin User"
        }

        case Accounts.register_user(attrs) do
          {:ok, user} ->
            Mix.shell().info("""

            ✅ Admin user created successfully!

            Email:    #{user.email}
            Role:     #{user.role}
            Flowers:  #{"🌸" |> String.duplicate(flowers)}  (Level #{flowers})
            Password: #{password}

            ⚠️  IMPORTANT: Save this password securely!
            """)

            log_admin_creation(user, flowers)

          {:error, changeset} ->
            Mix.shell().error("Error creating admin user:")

            Enum.each(changeset.errors, fn {field, {msg, _}} ->
              Mix.shell().error("  - #{field}: #{msg}")
            end)

            System.halt(1)
        end

      existing_user ->
        # User exists, update to admin with flowers
        changeset =
          existing_user
          |> Ecto.Changeset.change(%{role: "admin", admin_flowers: flowers})

        case Repo.update(changeset) do
          {:ok, user} ->
            Mix.shell().info("""

            ✅ Existing user updated to admin!

            Email:    #{user.email}
            Role:     #{user.role}
            Flowers:  #{"🌸" |> String.duplicate(flowers)}  (Level #{flowers})

            Note: Password was not changed. Use existing password or reset via settings.
            """)

            log_admin_creation(user, flowers)

          {:error, changeset} ->
            Mix.shell().error("Error updating user to admin:")

            Enum.each(changeset.errors, fn {field, {msg, _}} ->
              Mix.shell().error("  - #{field}: #{msg}")
            end)

            System.halt(1)
        end
    end
  end

  defp generate_password do
    :crypto.strong_rand_bytes(20)
    |> Base.encode64()
    |> binary_part(0, 20)
  end

  defp log_admin_creation(user, flowers) do
    Mix.shell().info("""
    📝 Admin creation logged
    User ID: #{user.id}
    Email: #{user.email}
    Flower Level: #{flowers}
    Timestamp: #{DateTime.utc_now() |> DateTime.to_iso8601()}
    """)
  end
end
