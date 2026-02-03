defmodule HomesiteWeb.LiveHelpers do
  @moduledoc """
  Helper functions for LiveView modules.
  """

  @doc """
  Extracts connection info from socket for activity logging.

  Returns a keyword list with `:ip_address` and `:user_agent` that can be
  merged with other options when calling analytics/content functions.

  ## Examples

      # In a LiveView
      opts = connection_opts(socket)
      Content.create_post(scope, post_params, opts)

      # Merge with other options
      opts = connection_opts(socket, metadata: %{title: "My Post"})
      Content.update_post(scope, post, post_params, opts)

  """
  def connection_opts(socket, extra_opts \\ []) do
    Keyword.merge(
      [
        ip_address: Map.get(socket.assigns, :ip_address),
        user_agent: Map.get(socket.assigns, :user_agent)
      ],
      extra_opts
    )
  end
end
