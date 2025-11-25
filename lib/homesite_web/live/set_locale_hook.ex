defmodule HomesiteWeb.SetLocaleHook do
  @moduledoc """
  LiveView hook to set locale based on user preference.

  This ensures locale is set correctly for LiveView WebSocket connections,
  not just the initial HTTP request.
  """
  import Phoenix.Component

  def on_mount(:default, _params, _session, socket) do
    locale = get_locale_from_socket(socket)
    Gettext.put_locale(HomesiteWeb.Gettext, locale)
    {:cont, socket}
  end

  defp get_locale_from_socket(socket) do
    case socket.assigns[:current_scope] do
      %{user: %{preferred_language: lang}} when is_binary(lang) and lang in ["en", "fi"] ->
        lang

      _ ->
        "en"
    end
  end
end
