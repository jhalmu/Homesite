# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build/Lint/Test Commands

- **Setup:** `mix setup`
- **Server:** `mix phx.server`
- **Interactive shell:** `iex -S mix phx.server`
- **Tests:** `mix test`
- **Single test:** `mix test path/to/test.exs:line_number`
- **Format:** `mix format`
- **Check formatting:** `mix format --check-formatted`
- **Database setup:** `mix ecto.setup`
- **Database reset:** `mix ecto.reset`
- **Migrations:** `mix ecto.migrate`
- **Rollback:** `mix ecto.rollback`

## Code Style Guidelines

- **Formatting:** Use `mix format` - configured via `.formatter.exs`
- **Naming:** snake_case for variables/functions/atoms, PascalCase for modules
- **Documentation:** Add @moduledoc and @doc for public modules and functions
- **Pattern matching:** Prefer pattern matching over conditionals where appropriate
- **Pipelines:** Use the pipe operator `|>` for data transformations
- **Error handling:** Use tagged tuples `{:ok, result}` and `{:error, reason}` patterns
- **Testing:** Use descriptive test names with `describe` and `test` blocks
