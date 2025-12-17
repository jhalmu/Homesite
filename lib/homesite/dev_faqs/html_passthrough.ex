defmodule Homesite.DevFaqs.HtmlPassthrough do
  @moduledoc """
  A no-op HTML converter for NimblePublisher.

  Our custom parser (Homesite.DevFaqs.Parser) already converts markdown to HTML
  using MDEx. This converter prevents NimblePublisher from running Earmark
  on the already-converted HTML, which would cause "Failed to find closing <pre>"
  warnings.
  """

  @doc """
  Returns the body unchanged since it's already HTML.
  """
  def convert(_path, body, _attrs, _opts), do: body
end
