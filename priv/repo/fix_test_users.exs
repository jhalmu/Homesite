alias Homesite.Accounts
alias Homesite.Repo

# Update all admin users to have role "admin"
["admin1@example.com", "admin2@example.com", "admin3@example.com", "admin5@example.com"]
|> Enum.each(fn email ->
  user = Repo.get_by!(Homesite.Accounts.User, email: email)
  {:ok, updated} = Accounts.update_user_admin_settings(user, %{role: "admin", admin_flowers: user.admin_flowers})
  IO.puts("✅ Updated #{email} to admin role with #{updated.admin_flowers} flowers")
end)

# Confirm user with password for testing
user = Repo.get_by!(Homesite.Accounts.User, email: "user@example.com")
user = Repo.update!(Ecto.Changeset.change(user,
  hashed_password: Argon2.hash_pwd_salt("testpassword123"),
  confirmed_at: DateTime.truncate(DateTime.utc_now(), :second)
))
IO.puts("✅ Regular user user@example.com confirmed with password")

IO.puts("\n📋 All 5 test users ready:")
IO.puts("  1. user@example.com - Regular user (no admin)")
IO.puts("  2. admin1@example.com - Admin with 1 flower 🌸")
IO.puts("  3. admin2@example.com - Admin with 2 flowers 🌸🌸")
IO.puts("  4. admin3@example.com - Admin with 3 flowers 🌸🌸🌸 (can manage users)")
IO.puts("  5. admin5@example.com - Admin with 5 flowers 🌸🌸🌸🌸🌸 (full access)")
IO.puts("\nPassword for all: testpassword123")
