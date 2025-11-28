defmodule Homesite.DevFaqs.Parser do
  @moduledoc """
  Custom parser for markdown files with YAML frontmatter.
  """

  def parse(_path, contents) do
    case :binary.split(contents, ["\n---\n", "\r\n---\r\n"]) do
      [frontmatter, body] ->
        parse_frontmatter_and_body(frontmatter, body)

      _ ->
        raise "Missing frontmatter in markdown file"
    end
  end

  defp parse_frontmatter_and_body("---\n" <> frontmatter, body) do
    parse_yaml_and_markdown(frontmatter, body)
  end

  defp parse_frontmatter_and_body("---\r\n" <> frontmatter, body) do
    parse_yaml_and_markdown(frontmatter, body)
  end

  defp parse_frontmatter_and_body(_, _) do
    raise "Invalid frontmatter format"
  end

  defp parse_yaml_and_markdown(frontmatter, body) do
    case YamlElixir.read_from_string(frontmatter) do
      {:ok, attrs} ->
        html_body = MDEx.to_html!(body, extension: [table: true, strikethrough: true])
        {Map.new(attrs, fn {k, v} -> {String.to_atom(k), v} end), html_body}

      {:error, reason} ->
        raise "Failed to parse YAML frontmatter: #{inspect(reason)}"
    end
  end
end
