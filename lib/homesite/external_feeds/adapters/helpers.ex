defmodule Homesite.ExternalFeeds.Adapters.Helpers do
  @moduledoc """
  Shared helper functions for feed adapters.

  This module extracts common functionality used across all feed adapters
  to reduce code duplication and maintain consistency.
  """

  require Logger

  @doc """
  Truncates text to a maximum length, adding ellipsis if needed.

  ## Examples

      iex> Helpers.truncate_text("Hello world", 5)
      "Hello..."

      iex> Helpers.truncate_text("Hi", 10)
      "Hi"

      iex> Helpers.truncate_text(nil, 10)
      "Untitled"
  """
  def truncate_text(text, max_length) when is_binary(text) do
    if String.length(text) > max_length do
      String.slice(text, 0, max_length) <> "..."
    else
      text
    end
  end

  def truncate_text(_, _), do: "Untitled"

  @doc """
  Parses an ISO8601 datetime string.

  Returns the parsed DateTime or current UTC time if parsing fails.

  ## Examples

      iex> Helpers.parse_iso8601_date("2024-01-15T10:30:00Z")
      ~U[2024-01-15 10:30:00Z]

      iex> Helpers.parse_iso8601_date("invalid")
      # Returns current DateTime

      iex> Helpers.parse_iso8601_date(nil)
      # Returns current DateTime
  """
  def parse_iso8601_date(date_string) when is_binary(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _offset} -> datetime
      _ -> DateTime.utc_now()
    end
  end

  def parse_iso8601_date(_), do: DateTime.utc_now()

  @doc """
  Generates a random ID using SHA256 hash.

  ## Examples

      iex> id = Helpers.generate_random_id()
      iex> String.length(id)
      64
  """
  def generate_random_id do
    :crypto.hash(:sha256, :rand.bytes(16))
    |> Base.encode16(case: :lower)
  end

  @doc """
  Generates a deterministic ID from a string using SHA256 hash.

  ## Examples

      iex> Helpers.generate_id_from_string("hello")
      "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
  """
  def generate_id_from_string(string) when is_binary(string) and string != "" do
    :crypto.hash(:sha256, string)
    |> Base.encode16(case: :lower)
  end

  def generate_id_from_string(_), do: generate_random_id()

  @doc """
  Fetches JSON data from a URL with retries.

  ## Options

    * `:headers` - Additional headers (merged with defaults)
    * `:max_retries` - Maximum retry attempts (default: 2)
    * `:retry_delay` - Delay between retries in milliseconds (default: 1000)

  ## Examples

      iex> Helpers.fetch_json("https://api.example.com/data")
      {:ok, %{"key" => "value"}}

      iex> Helpers.fetch_json("https://invalid.url")
      {:error, "HTTP 404"}
  """
  def fetch_json(url, opts \\ []) do
    headers =
      Keyword.get(opts, :headers, [])
      |> Kernel.++([
        {"user-agent", "HomesiteBot/1.0"},
        {"accept", "application/json"}
      ])

    max_retries = Keyword.get(opts, :max_retries, 2)
    retry_delay = Keyword.get(opts, :retry_delay, 1000)

    case Req.get(url,
           headers: headers,
           max_retries: max_retries,
           retry_delay: retry_delay
         ) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: 404}} ->
        {:error, "Resource not found"}

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, exception} ->
        {:error, Exception.message(exception)}
    end
  end

  @doc """
  Safely extracts a value from a map with a default fallback.

  Handles nested maps using a list of keys.

  ## Examples

      iex> Helpers.safe_get(%{"a" => %{"b" => "value"}}, ["a", "b"], "default")
      "value"

      iex> Helpers.safe_get(%{}, ["missing"], "default")
      "default"
  """
  def safe_get(map, keys, default \\ nil)

  def safe_get(map, [key], default) when is_map(map) do
    Map.get(map, key) || Map.get(map, to_string(key), default)
  end

  def safe_get(map, [key | rest], default) when is_map(map) do
    case Map.get(map, key) || Map.get(map, to_string(key)) do
      nil -> default
      nested_map when is_map(nested_map) -> safe_get(nested_map, rest, default)
      _ -> default
    end
  end

  def safe_get(_, _, default), do: default

  @doc """
  Cleans HTML tags from text, leaving plain text.

  ## Examples

      iex> Helpers.strip_html("<p>Hello <b>world</b></p>")
      "Hello world"
  """
  def strip_html(nil), do: ""

  def strip_html(html) when is_binary(html) do
    html
    |> String.replace(~r/<[^>]+>/, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  @doc """
  Logs an error with context about the adapter and operation.
  """
  def log_adapter_error(adapter_name, operation, error, context \\ %{}) do
    Logger.error(
      "[#{adapter_name}] #{operation} failed: #{inspect(error)}",
      context: context
    )
  end
end
