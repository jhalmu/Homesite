alias Homesite.Accounts
alias Homesite.Repo

user = Repo.get_by!(Accounts.User, email: "user@example.com")
avatar_url = Accounts.get_avatar_url(user)

IO.puts("Full avatar URL:")
IO.puts(avatar_url)
IO.puts("\n" <> String.duplicate("=", 80) <> "\n")

[_prefix, base64] = String.split(avatar_url, ",", parts: 2)
decoded = Base.decode64!(base64)

IO.puts("Decoded SVG:")
IO.puts(decoded)
