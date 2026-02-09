defmodule HomesiteWeb.Helpers.DateHelpers do
  @moduledoc """
  Locale-aware date formatting helpers.

  Provides functions to format dates according to the user's locale preference.
  Supports Finnish (fi) and English (en) locales.
  """

  # Finnish month names
  @finnish_months %{
    1 => "tammikuuta",
    2 => "helmikuuta",
    3 => "maaliskuuta",
    4 => "huhtikuuta",
    5 => "toukokuuta",
    6 => "kesäkuuta",
    7 => "heinäkuuta",
    8 => "elokuuta",
    9 => "syyskuuta",
    10 => "lokakuuta",
    11 => "marraskuuta",
    12 => "joulukuuta"
  }

  @finnish_months_short %{
    1 => "tammi",
    2 => "helmi",
    3 => "maalis",
    4 => "huhti",
    5 => "touko",
    6 => "kesä",
    7 => "heinä",
    8 => "elo",
    9 => "syys",
    10 => "loka",
    11 => "marras",
    12 => "joulu"
  }

  @doc """
  Formats a date in a human-readable format based on locale.

  ## Examples

      iex> format_date(~D[2025-12-07], "en")
      "December 7, 2025"

      iex> format_date(~D[2025-12-07], "fi")
      "7. joulukuuta 2025"

  """
  def format_date(date, locale \\ nil)
  def format_date(nil, _locale), do: ""

  def format_date(date, locale) do
    locale = locale || get_current_locale()

    case locale do
      "fi" -> format_date_fi(date)
      _ -> format_date_en(date)
    end
  end

  @doc """
  Formats a date with month and year only.

  ## Examples

      iex> format_month_year(~D[2025-12-07], "en")
      "December 2025"

      iex> format_month_year(~D[2025-12-07], "fi")
      "Joulukuu 2025"

  """
  def format_month_year(date, locale \\ nil)
  def format_month_year(nil, _locale), do: ""

  def format_month_year(date, locale) do
    locale = locale || get_current_locale()

    case locale do
      "fi" -> format_month_year_fi(date)
      _ -> format_month_year_en(date)
    end
  end

  @doc """
  Formats a datetime with time included.

  ## Examples

      iex> format_datetime(~U[2025-12-07 14:30:00Z], "en")
      "December 7, 2025 at 14:30"

      iex> format_datetime(~U[2025-12-07 14:30:00Z], "fi")
      "7. joulukuuta 2025 klo 14:30"

  """
  def format_datetime(datetime, locale \\ nil)
  def format_datetime(nil, _locale), do: ""

  def format_datetime(datetime, locale) do
    locale = locale || get_current_locale()

    case locale do
      "fi" -> format_datetime_fi(datetime)
      _ -> format_datetime_en(datetime)
    end
  end

  @doc """
  Formats a short date (e.g., for compact displays).

  ## Examples

      iex> format_date_short(~D[2025-12-07], "en")
      "Dec 7, 2025"

      iex> format_date_short(~D[2025-12-07], "fi")
      "7.12.2025"

  """
  def format_date_short(date, locale \\ nil)
  def format_date_short(nil, _locale), do: ""

  def format_date_short(date, locale) do
    locale = locale || get_current_locale()

    case locale do
      "fi" -> format_date_short_fi(date)
      _ -> format_date_short_en(date)
    end
  end

  @doc """
  Formats a datetime as a relative time string (e.g., "2 hours ago", "just now").
  Locale-aware.

  ## Examples

      iex> format_relative_time(DateTime.utc_now())
      "just now"

      iex> format_relative_time(DateTime.add(DateTime.utc_now(), -3600, :second))
      "1 hour ago"

  """
  def format_relative_time(datetime, locale \\ nil)
  def format_relative_time(nil, _locale), do: ""

  def format_relative_time(datetime, locale) do
    locale = locale || get_current_locale()
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(now, datetime, :second)

    cond do
      diff_seconds < 60 ->
        if locale == "fi", do: "juuri nyt", else: "just now"

      diff_seconds < 3600 ->
        format_relative_minutes(div(diff_seconds, 60), locale)

      diff_seconds < 86_400 ->
        format_relative_hours(div(diff_seconds, 3600), locale)

      diff_seconds < 604_800 ->
        format_relative_days(div(diff_seconds, 86_400), locale)

      true ->
        # Fall back to regular date format for older dates
        format_date_short(datetime, locale)
    end
  end

  # Private helpers

  defp format_relative_minutes(minutes, "fi"),
    do: "#{minutes} #{if minutes == 1, do: "minuutti", else: "minuuttia"} sitten"

  defp format_relative_minutes(minutes, _locale),
    do: "#{minutes} #{if minutes == 1, do: "minute", else: "minutes"} ago"

  defp format_relative_hours(hours, "fi"),
    do: "#{hours} #{if hours == 1, do: "tunti", else: "tuntia"} sitten"

  defp format_relative_hours(hours, _locale),
    do: "#{hours} #{if hours == 1, do: "hour", else: "hours"} ago"

  defp format_relative_days(days, "fi"),
    do: "#{days} #{if days == 1, do: "päivä", else: "päivää"} sitten"

  defp format_relative_days(days, _locale),
    do: "#{days} #{if days == 1, do: "day", else: "days"} ago"

  defp format_date_en(date) do
    Calendar.strftime(date, "%B %d, %Y")
  end

  defp format_date_fi(date) do
    day = get_day(date)
    month = @finnish_months[get_month(date)]
    year = get_year(date)
    "#{day}. #{month} #{year}"
  end

  defp format_month_year_en(date) do
    Calendar.strftime(date, "%B %Y")
  end

  defp format_month_year_fi(date) do
    month = @finnish_months_short[get_month(date)] |> String.capitalize()
    year = get_year(date)
    "#{month}kuu #{year}"
  end

  defp format_datetime_en(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y at %H:%M")
  end

  defp format_datetime_fi(datetime) do
    day = get_day(datetime)
    month = @finnish_months[get_month(datetime)]
    year = get_year(datetime)
    time = Calendar.strftime(datetime, "%H:%M")
    "#{day}. #{month} #{year} klo #{time}"
  end

  defp format_date_short_en(date) do
    Calendar.strftime(date, "%b %d, %Y")
  end

  defp format_date_short_fi(date) do
    day = get_day(date)
    month = get_month(date)
    year = get_year(date)
    "#{day}.#{month}.#{year}"
  end

  defp get_day(%{day: day}), do: day
  defp get_month(%{month: month}), do: month
  defp get_year(%{year: year}), do: year

  defp get_current_locale do
    Gettext.get_locale(HomesiteWeb.Gettext)
  end
end
