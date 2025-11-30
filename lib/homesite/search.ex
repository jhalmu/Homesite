defmodule Homesite.Search do
  @moduledoc """
  Unified search module that searches across all content types.

  Provides a single search interface that queries Posts, Tags, and FAQs
  in parallel and returns categorized results.

  Includes telemetry events and analytics tracking.
  """

  alias Homesite.Analytics
  alias Homesite.Content
  alias Homesite.Faqs

  @doc """
  Search across all content types (Posts, Tags, FAQs).

  Executes searches in parallel using Task.async for performance.
  Returns results grouped by content type with relevance scoring.

  ## Options

    * `:limit` - Maximum results per category (default: 10)
    * `:locale` - Locale for FAQ results (default: "en")

  ## Returns

  A map with:
  - `:posts` - List of matching posts
  - `:tags` - List of matching tags
  - `:faqs` - List of matching FAQs
  - `:total_count` - Total number of results across all categories

  ## Examples

      iex> search_all("elixir")
      %{
        posts: [%Post{}, ...],
        tags: [%Tag{}, ...],
        faqs: [%Faq{}, ...],
        total_count: 15
      }

      iex> search_all("phoenix", limit: 5, locale: "fi")
      %{posts: [...], tags: [...], faqs: [...], total_count: 8}

  """
  def search_all(query, opts \\ []) when is_binary(query) do
    start_time = System.monotonic_time(:millisecond)

    results =
      case String.trim(query) do
        "" ->
          empty_results()

        trimmed_query ->
          limit = Keyword.get(opts, :limit, 10)
          locale = Keyword.get(opts, :locale, "en")

          # Execute searches in parallel
          post_task = Task.async(fn -> Content.search_posts(trimmed_query, limit: limit) end)
          tag_task = Task.async(fn -> Content.search_tags(trimmed_query, limit: limit) end)

          faq_task =
            Task.async(fn -> Faqs.search_faqs(trimmed_query, limit: limit, locale: locale) end)

          # Await all results
          posts = Task.await(post_task)
          tags = Task.await(tag_task)
          faqs = Task.await(faq_task)

          %{
            posts: posts,
            tags: tags,
            faqs: faqs,
            total_count: length(posts) + length(tags) + length(faqs)
          }
      end

    # Calculate duration and emit telemetry
    duration_ms = System.monotonic_time(:millisecond) - start_time

    :telemetry.execute(
      [:homesite, :search, :execute],
      %{duration_ms: duration_ms, result_count: results.total_count},
      %{query: query}
    )

    # Record analytics (async, don't block response)
    # Skip in test environment to avoid database connection issues
    if String.trim(query) != "" and Mix.env() != :test do
      Task.start(fn ->
        Analytics.record_search(query, results, duration_ms,
          user_id: Keyword.get(opts, :user_id),
          ip_address: Keyword.get(opts, :ip_address),
          user_agent: Keyword.get(opts, :user_agent)
        )
      end)
    end

    results
  end

  @doc """
  Search only posts.

  Convenience wrapper around Content.search_posts/2.

  ## Examples

      iex> search_posts("elixir", limit: 20)
      [%Post{}, ...]

  """
  def search_posts(query, opts \\ []) do
    Content.search_posts(query, opts)
  end

  @doc """
  Search only tags.

  Convenience wrapper around Content.search_tags/2.

  ## Examples

      iex> search_tags("phoenix", limit: 10)
      [%Tag{}, ...]

  """
  def search_tags(query, opts \\ []) do
    Content.search_tags(query, opts)
  end

  @doc """
  Search only FAQs.

  Convenience wrapper around Faqs.search_faqs/2.

  ## Examples

      iex> search_faqs("how to", limit: 15, locale: "fi")
      [%Faq{}, ...]

  """
  def search_faqs(query, opts \\ []) do
    Faqs.search_faqs(query, opts)
  end

  # Private helpers

  defp empty_results do
    %{
      posts: [],
      tags: [],
      faqs: [],
      total_count: 0
    }
  end
end
