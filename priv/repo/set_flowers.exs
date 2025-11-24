alias Homesite.Accounts
alias Homesite.Repo

# Update admin users with correct flower levels
updates = [
  {"admin1@example.com", 1},
  {"admin2@example.com", 2},
  {"admin3@example.com", 3},
  {"admin5@example.com", 5}
]

Enum.each(updates, fn {email, flowers} ->
  user = Repo.get_by!(Homesite.Accounts.User, email: email)
  {:ok, updated} = Accounts.update_user_admin_settings(user, %{role: "admin", admin_flowers: flowers})
  IO.puts("✅ Set #{email} to #{flowers} flowers")
end)

IO.puts("\n📋 Final user list:")
Repo.all(Homesite.Accounts.User)
|> Enum.filter(fn u -> u.email in ["user@example.com", "admin1@example.com", "admin2@example.com", "admin3@example.com", "admin5@example.com"] end)
|> Enum.each(fn u ->
  role_display = if u.role == "admin", do: "Admin", else: "User"
  flowers_display = if u.admin_flowers > 0, do: String.duplicate("🌸", u.admin_flowers), else: "none"
  IO.puts("  #{u.email}: #{role_display} - #{flowers_display}")
end)

IO.puts("\nAll users have password: testpassword123")
