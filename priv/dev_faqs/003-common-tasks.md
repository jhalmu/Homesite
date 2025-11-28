---
title: "Common Development Tasks"
order: 3
category: "development"
---

# Common Development Tasks

## Starting the Server

```bash
# Start Phoenix server
mix phx.server

# Start with IEx console
iex -S mix phx.server

# Server runs at http://localhost:4000
```

## Running Tests

```bash
# Run all tests
mix test

# Run specific test file
mix test test/homesite/faqs_test.exs

# Run specific test by line number
mix test test/homesite/faqs_test.exs:20

# Run only failed tests
mix test --failed

# Run with Playwright E2E tests
mix test --include playwright
```

## Code Quality

```bash
# Format code
mix format

# Check formatting
mix format --check-formatted

# Run Credo (code analysis)
mix credo --strict

# Pre-commit checks (compile + format + test)
mix precommit

# Full test suite with Credo
mix test.all
```

## Working with the Console

```elixir
# Start IEx with app loaded
iex -S mix

# Reload code after changes
recompile()

# Common aliases
alias Homesite.{Accounts, Content, Faqs, Repo}
alias Homesite.Accounts.{User, Invitation, Scope}

# Query examples
Repo.all(User)
Repo.get(User, 1)
User |> Repo.all() |> Enum.count()

# Get user scope
user = Repo.get_by(User, email: "test-admin@example.com")
scope = Scope.for_user(user)

# Test FAQ creation
{:ok, faq} = Faqs.create_faq(scope, %{
  category: "user",
  question_en: "How do I do this?",
  question_fi: "Miten teen taman?",
  answer_en: "Like this!",
  answer_fi: "Nain!"
})
```

## Building Assets

```bash
# Build assets (CSS + JS)
mix assets.build

# Deploy assets (minified for production)
mix assets.deploy
```

## Debugging Tips

### Enable Debug Logging
In `config/dev.exs`, set:
```elixir
config :logger, level: :debug
```

### Inspect Data
```elixir
# In code
IO.inspect(data, label: "DEBUG")

# Or use dbg/0
dbg(some_variable)

# In IEx
h Module.function  # View documentation
i some_variable    # Inspect variable
```

### Live Dashboard
Visit `http://localhost:4000/dev/dashboard` for:
- Request metrics
- Process info
- Ecto queries
- Memory usage
