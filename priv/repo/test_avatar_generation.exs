alias Homesite.Accounts
alias Homesite.Repo

# Get test user without avatar
user = Repo.get_by!(Accounts.User, email: "user@example.com")

IO.puts("Testing avatar generation for: #{user.email}")
IO.puts("User avatar field: #{inspect(user.avatar)}")
IO.puts("")

# Generate avatar URL
avatar_url = Accounts.get_avatar_url(user)

IO.puts("Generated Avatar URL (first 150 chars):")
IO.puts(String.slice(avatar_url, 0, 150))
IO.puts("...")
IO.puts("")
IO.puts("Full URL length: #{String.length(avatar_url)}")
IO.puts("")
IO.puts("Starts with data:image/svg+xml? #{String.starts_with?(avatar_url, "data:image/svg+xml")}")
