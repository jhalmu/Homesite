defmodule Mix.Tasks.BackfillReadTime do
  @moduledoc """
  Backfills read_time_minutes for all existing posts.

  Usage:
    mix backfill_read_time
  """
  use Mix.Task

  import Ecto.Query

  alias Homesite.Content.Post
  alias Homesite.Repo

  @shortdoc "Backfills read_time_minutes for all posts"
  def run(_args) do
    Mix.Task.run("app.start")

    IO.puts("Starting read time backfill...")

    # Get all posts
    posts = Repo.all(from(p in Post))

    IO.puts("Found #{length(posts)} posts to update")

    # Update each post
    Enum.each(posts, fn post ->
      # Calculate read time using the same logic as the changeset
      text = strip_markdown(post.body)
      word_count = text |> String.split(~r/\s+/) |> Enum.reject(&(&1 == "")) |> length()
      read_time = max(1, ceil(word_count / 200))

      # Update the post directly
      post
      |> Ecto.Changeset.change(%{read_time_minutes: read_time})
      |> Repo.update!()

      IO.puts(
        "Updated post ##{post.id} '#{String.slice(post.title, 0, 50)}' - #{read_time} min read"
      )
    end)

    IO.puts("Backfill complete!")
  end

  # Copy of strip_markdown from Post module
  defp strip_markdown(markdown) do
    markdown
    # Remove code blocks
    |> String.replace(~r/```[\s\S]*?```/m, "")
    |> String.replace(~r/`[^`]+`/, "")
    # Remove images
    |> String.replace(~r/!\[([^\]]*)\]\([^\)]+\)/, "\\1")
    # Remove links (keep text)
    |> String.replace(~r/\[([^\]]+)\]\([^\)]+\)/, "\\1")
    # Remove headers
    |> String.replace(~r/^[#]{1,6}\s+/m, "")
    # Remove emphasis
    |> String.replace(~r/\*\*([^\*]+)\*\*/, "\\1")
    |> String.replace(~r/__([^_]+)__/, "\\1")
    |> String.replace(~r/\*([^\*]+)\*/, "\\1")
    |> String.replace(~r/_([^_]+)_/, "\\1")
    # Remove list markers
    |> String.replace(~r/^[\*\-\+]\s+/m, "")
    |> String.replace(~r/^\d+\.\s+/m, "")
    # Remove blockquotes
    |> String.replace(~r/^>\s+/m, "")
    # Remove horizontal rules
    |> String.replace(~r/^[\*\-_]{3,}$/m, "")
  end
end
