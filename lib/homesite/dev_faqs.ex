defmodule Homesite.DevFaqs do
  @moduledoc """
  Context for DEV FAQs - markdown-based documentation for developers.
  Only available in development environment.
  """

  alias Homesite.DevFaqs.Article

  use NimblePublisher,
    build: Article,
    from: Application.app_dir(:homesite, "priv/dev_faqs/**/*.md"),
    as: :articles,
    parser: Homesite.DevFaqs.Parser

  # The @articles variable is first defined by NimblePublisher.
  # Let's further modify it by sorting by order.
  @articles Enum.sort_by(@articles, & &1.order)

  @doc """
  Returns all DEV FAQ articles, sorted by order.
  Only works in development environment.
  """
  def all_articles do
    if Mix.env() == :dev do
      @articles
    else
      []
    end
  end

  @doc """
  Returns DEV FAQ articles filtered by category.
  """
  def articles_by_category(category) do
    all_articles()
    |> Enum.filter(&(&1.category == category))
  end

  @doc """
  Returns all unique categories.
  """
  def categories do
    all_articles()
    |> Enum.map(& &1.category)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Checks if DEV FAQs are available (development environment).
  """
  def available? do
    Mix.env() == :dev
  end
end
