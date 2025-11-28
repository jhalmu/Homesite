defmodule Homesite.DevFaqs.Article do
  @moduledoc """
  Schema for DEV FAQ articles parsed from markdown files.
  """

  @enforce_keys [:id, :title, :body, :order, :category]
  defstruct [:id, :title, :body, :order, :category]

  def build(filename, attrs, body) do
    # Extract the article ID from filename (e.g., "001-test-users.md" -> "001-test-users")
    [id] =
      filename
      |> Path.rootname()
      |> Path.split()
      |> Enum.take(-1)

    struct!(__MODULE__, [id: id, body: body] ++ Map.to_list(attrs))
  end
end
