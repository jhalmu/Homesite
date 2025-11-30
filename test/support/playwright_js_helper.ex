defmodule HomesiteWeb.PlaywrightJsHelper do
  @moduledoc """
  Helper module for executing JavaScript in Playwright tests.

  Provides utilities to run JavaScript code and get results back,
  enabling integration with tools like axe-core for accessibility testing.
  """

  alias PhoenixTest.Playwright.Frame

  @doc """
  Executes JavaScript code in the current Playwright session.

  Returns the result of the JavaScript execution.

  Automatically wraps code in an async function if it contains 'await' or 'return' statements.

  ## Examples

      session
      |> execute_js("document.title")
      # => "Page Title"

      session
      |> execute_js("return 1 + 1")
      # => 2

      session
      |> execute_js("return await axe.run()")
      # => axe results
  """
  def execute_js(session, javascript) do
    frame_id = get_frame_id(session)

    # Wrap in async function if code contains await or bare return statements
    wrapped_js =
      if needs_wrapping?(javascript) do
        "(async () => { #{javascript} })()"
      else
        javascript
      end

    case Frame.evaluate(frame_id, wrapped_js) do
      {:ok, result} -> {session, result}
      {:error, reason} -> raise "JavaScript execution failed: #{inspect(reason)}"
    end
  end

  # Check if JavaScript needs wrapping in an async function
  defp needs_wrapping?(javascript) do
    String.contains?(javascript, "await ") or
      (String.contains?(javascript, "return ") and not String.contains?(javascript, "function"))
  end

  @doc """
  Executes JavaScript and returns only the session (ignoring the result).

  Useful for running JavaScript that doesn't need a return value,
  like loading scripts or setting up state.
  """
  def run_js(session, javascript) do
    {session, _result} = execute_js(session, javascript)
    session
  end

  # Private function to extract frame_id from session
  defp get_frame_id(%{frame_id: frame_id}), do: frame_id

  defp get_frame_id(_session) do
    raise """
    Could not find frame_id in session.
    Make sure you're using PhoenixTest.Playwright.Case and have visited a page first.
    """
  end
end
