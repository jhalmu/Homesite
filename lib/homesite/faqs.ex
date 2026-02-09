defmodule Homesite.Faqs do
  @moduledoc """
  The FAQs context for managing FAQ entries.
  """

  import Ecto.Query, warn: false
  alias Homesite.Repo

  alias Homesite.Accounts.Scope
  alias Homesite.Faqs.Faq

  ## Public functions (no scope required)

  @doc """
  Returns the list of active user FAQs with localized content.

  ## Examples

      iex> list_user_faqs("en")
      [%Faq{question: "How to...", answer: "You can..."}]

  """
  def list_user_faqs(locale \\ "en") do
    from(f in Faq,
      where: f.category == "user" and f.is_active == true,
      order_by: [asc: f.display_order, asc: f.id]
    )
    |> Repo.all()
    |> Enum.map(&add_localized_content(&1, locale))
  end

  @doc """
  Gets a single user FAQ by slug with localized content.

  Raises `Ecto.NoResultsError` if the FAQ does not exist.

  ## Examples

      iex> get_user_faq_by_slug!("how-to-post", "en")
      %Faq{question: "How to...", answer: "You can..."}

  """
  def get_user_faq_by_slug!(slug, locale \\ "en") do
    Repo.get_by!(Faq, slug: slug, category: "user", is_active: true)
    |> add_localized_content(locale)
  end

  ## Admin functions (scope required)

  @doc """
  Returns the list of active admin FAQs with localized content.

  Requires admin scope.

  ## Examples

      iex> list_admin_faqs(scope, "en")
      [%Faq{}]

  """
  def list_admin_faqs(%Scope{} = scope, locale \\ "en") do
    true = Scope.admin?(scope)

    from(f in Faq,
      where: f.category == "admin" and f.is_active == true,
      order_by: [asc: f.display_order, asc: f.id]
    )
    |> Repo.all()
    |> Enum.map(&add_localized_content(&1, locale))
  end

  @doc """
  Gets a single admin FAQ by slug with localized content.

  Requires admin scope.
  Raises `Ecto.NoResultsError` if the FAQ does not exist.

  ## Examples

      iex> get_admin_faq_by_slug!(scope, "admin-panel", "en")
      %Faq{}

  """
  def get_admin_faq_by_slug!(%Scope{} = scope, slug, locale \\ "en") do
    true = Scope.admin?(scope)

    Repo.get_by!(Faq, slug: slug, category: "admin", is_active: true)
    |> add_localized_content(locale)
  end

  @doc """
  Returns all FAQs for management (CRUD operations).

  Requires admin scope.

  ## Examples

      iex> list_all_faqs_for_management(scope)
      [%Faq{}, ...]

  """
  def list_all_faqs_for_management(%Scope{} = scope) do
    true = Scope.admin?(scope)

    from(f in Faq,
      order_by: [asc: f.category, asc: f.display_order, asc: f.id],
      preload: [:created_by, :updated_by]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single FAQ for management.

  Requires admin scope.
  Raises `Ecto.NoResultsError` if the FAQ does not exist.

  ## Examples

      iex> get_faq_for_management!(scope, 123)
      %Faq{}

  """
  def get_faq_for_management!(%Scope{} = scope, id) do
    true = Scope.admin?(scope)

    Repo.get!(Faq, id)
    |> Repo.preload([:created_by, :updated_by])
  end

  @doc """
  Creates a FAQ.

  Requires admin scope.

  ## Examples

      iex> create_faq(scope, %{category: "user", question_en: "...", ...})
      {:ok, %Faq{}}

      iex> create_faq(scope, %{category: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  def create_faq(%Scope{} = scope, attrs \\ %{}) do
    true = Scope.admin?(scope)

    %Faq{}
    |> Faq.changeset(attrs, scope)
    |> Repo.insert()
  end

  @doc """
  Updates a FAQ.

  Requires admin scope.

  ## Examples

      iex> update_faq(scope, faq, %{question_en: "Updated question"})
      {:ok, %Faq{}}

      iex> update_faq(scope, faq, %{category: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  def update_faq(%Scope{} = scope, %Faq{} = faq, attrs) do
    true = Scope.admin?(scope)

    faq
    |> Faq.changeset(attrs, scope)
    |> Repo.update()
  end

  @doc """
  Deletes a FAQ.

  Requires admin scope.

  ## Examples

      iex> delete_faq(scope, faq)
      {:ok, %Faq{}}

      iex> delete_faq(scope, faq)
      {:error, %Ecto.Changeset{}}

  """
  def delete_faq(%Scope{} = scope, %Faq{} = faq) do
    true = Scope.admin?(scope)
    Repo.delete(faq)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking FAQ changes.

  ## Examples

      iex> change_faq(scope, faq)
      %Ecto.Changeset{data: %Faq{}}

  """
  def change_faq(%Scope{} = scope, %Faq{} = faq, attrs \\ %{}) do
    Faq.changeset(faq, attrs, scope)
  end

  @doc """
  Search FAQs by question and answer content using PostgreSQL full-text search.

  Searches both English and Finnish content. Returns active FAQs that match
  the query with trigram similarity or ILIKE matching.

  ## Options

    * `:limit` - Maximum number of results (default: 20)
    * `:locale` - Locale for localized content (default: "en")
    * `:category` - Filter by category ("user" or "admin", optional)

  ## Examples

      iex> search_faqs("how to post")
      [%Faq{question: "How to create a post?", ...}]

      iex> search_faqs("admin", category: "admin", limit: 10)
      [%Faq{}, ...]

  """
  def search_faqs(query, opts \\ []) when is_binary(query) do
    case String.trim(query) do
      "" ->
        []

      trimmed_query ->
        locale = Keyword.get(opts, :locale, "en")

        trimmed_query
        |> build_faq_search_query(max(Keyword.get(opts, :limit, 20), 0))
        |> maybe_filter_by_category(Keyword.get(opts, :category))
        |> Repo.all()
        |> Enum.map(&add_localized_content(&1, locale))
    end
  end

  defp build_faq_search_query(trimmed_query, limit) do
    from(f in Faq,
      where: f.is_active == true,
      where:
        fragment("similarity(?, ?) > 0.1", f.question_en, ^trimmed_query) or
          fragment("similarity(?, ?) > 0.1", f.answer_en, ^trimmed_query) or
          fragment("similarity(?, ?) > 0.1", f.question_fi, ^trimmed_query) or
          fragment("similarity(?, ?) > 0.1", f.answer_fi, ^trimmed_query) or
          fragment("? ILIKE ?", f.question_en, ^"%#{trimmed_query}%") or
          fragment("? ILIKE ?", f.answer_en, ^"%#{trimmed_query}%") or
          fragment("? ILIKE ?", f.question_fi, ^"%#{trimmed_query}%") or
          fragment("? ILIKE ?", f.answer_fi, ^"%#{trimmed_query}%"),
      order_by: [
        desc:
          fragment(
            "greatest(similarity(?, ?), similarity(?, ?), similarity(?, ?), similarity(?, ?))",
            f.question_en,
            ^trimmed_query,
            f.answer_en,
            ^trimmed_query,
            f.question_fi,
            ^trimmed_query,
            f.answer_fi,
            ^trimmed_query
          )
      ],
      limit: ^limit
    )
  end

  defp maybe_filter_by_category(query, nil), do: query

  defp maybe_filter_by_category(query, category),
    do: from(f in query, where: f.category == ^category)

  ## Helpers

  @doc """
  Adds localized content to a FAQ struct.

  Merges locale-specific fields into virtual :question and :answer fields.

  ## Examples

      iex> add_localized_content(faq, "en")
      %Faq{question: "English question", answer: "English answer"}

      iex> add_localized_content(faq, "fi")
      %Faq{question: "Finnish question", answer: "Finnish answer"}

  """
  def add_localized_content(%Faq{} = faq, locale) do
    {question, answer} =
      case locale do
        "fi" -> {faq.question_fi, faq.answer_fi}
        _ -> {faq.question_en, faq.answer_en}
      end

    Map.merge(faq, %{
      question: question,
      answer: answer
    })
  end
end
