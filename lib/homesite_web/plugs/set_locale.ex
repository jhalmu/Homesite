defmodule HomesiteWeb.Plugs.SetLocale do
  @moduledoc """
  Plug to detect and set the user's locale preference.

  Locale is determined in this priority order:
  1. Authenticated user's preferred_language setting
  2. Locale cookie (for non-authenticated users)
  3. Browser's Accept-Language header
  4. Default locale ("fi")
  """
  import Plug.Conn

  @supported_locales Gettext.known_locales(HomesiteWeb.Gettext)

  def init(opts), do: opts

  def call(conn, _opts) do
    # Fetch cookies so conn.cookies is populated
    conn = fetch_cookies(conn)

    locale =
      conn
      |> get_locale_from_user()
      |> Kernel.||(get_locale_from_cookie(conn))
      |> Kernel.||(get_locale_from_header(conn))
      |> Kernel.||(Gettext.get_locale(HomesiteWeb.Gettext))
      |> validate_locale()

    Gettext.put_locale(HomesiteWeb.Gettext, locale)

    # Store locale in session for LiveView to access
    put_session(conn, :locale, locale)
  end

  # Get locale from authenticated user's preference
  defp get_locale_from_user(conn) do
    case conn.assigns[:current_scope] do
      %{user: %{preferred_language: lang}} when is_binary(lang) -> lang
      _ -> nil
    end
  end

  # Get locale from cookie
  defp get_locale_from_cookie(conn) do
    case conn.cookies["locale"] do
      locale when is_binary(locale) and locale in @supported_locales -> locale
      _ -> nil
    end
  end

  # Get locale from Accept-Language header
  defp get_locale_from_header(conn) do
    conn
    |> get_req_header("accept-language")
    |> List.first()
    |> parse_accept_language()
  end

  # Parse Accept-Language header (e.g., "en-US,en;q=0.9,fi;q=0.8")
  defp parse_accept_language(nil), do: nil

  defp parse_accept_language(header) do
    header
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(fn lang ->
      lang
      |> String.split(";")
      |> List.first()
      |> String.split("-")
      |> List.first()
      |> String.downcase()
    end)
    |> Enum.find(&(&1 in @supported_locales))
  end

  # Validate locale is supported, fallback to configured default
  defp validate_locale(locale) when locale in @supported_locales, do: locale
  defp validate_locale(_), do: default_locale()

  defp default_locale do
    Application.get_env(:homesite, HomesiteWeb.Gettext)[:default_locale] || "fi"
  end
end
