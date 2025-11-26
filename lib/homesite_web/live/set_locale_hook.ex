defmodule HomesiteWeb.SetLocaleHook do
  @moduledoc """
  LiveView hook to set locale based on user preference.

  This ensures locale is set correctly for LiveView WebSocket connections,
  not just the initial HTTP request.

  Locale priority:
  1. Authenticated user's preferred_language
  2. Session locale (set by SetLocale plug from cookie/header)
  3. Default to "fi"
  """

  @supported_locales Gettext.known_locales(HomesiteWeb.Gettext)

  def on_mount(:default, _params, session, socket) do
    locale = get_locale(socket, session)
    Gettext.put_locale(HomesiteWeb.Gettext, locale)
    {:cont, socket}
  end

  defp get_locale(socket, session) do
    socket
    |> get_locale_from_user()
    |> Kernel.||(get_locale_from_session(session))
    |> Kernel.||(Gettext.get_locale(HomesiteWeb.Gettext))
    |> validate_locale()
  end

  defp get_locale_from_user(socket) do
    case socket.assigns[:current_scope] do
      %{user: %{preferred_language: lang}} when is_binary(lang) and lang in @supported_locales ->
        lang

      _ ->
        nil
    end
  end

  defp get_locale_from_session(session) do
    case session["locale"] do
      locale when is_binary(locale) and locale in @supported_locales -> locale
      _ -> nil
    end
  end

  defp validate_locale(locale) when locale in @supported_locales, do: locale
  defp validate_locale(_), do: "fi"
end
