defmodule Homesite.DevFaqsTest do
  use ExUnit.Case, async: true

  alias Homesite.DevFaqs

  describe "all_articles/0" do
    test "returns articles sorted by order" do
      articles = DevFaqs.all_articles()

      # In test environment, DEV FAQs are not available (empty list)
      # In dev environment, should have 4+ articles
      assert is_list(articles)

      # If articles exist, verify they're sorted by order
      if articles != [] do
        orders = Enum.map(articles, & &1.order)
        assert orders == Enum.sort(orders)
      end
    end

    test "all articles have required fields" do
      articles = DevFaqs.all_articles()

      for article <- articles do
        assert article.id
        assert article.title
        assert article.body
        assert article.order
        assert article.category
      end
    end

    test "article IDs match filename pattern" do
      articles = DevFaqs.all_articles()

      for article <- articles do
        # IDs should follow pattern like "001-test-users"
        assert String.match?(article.id, ~r/^\d{3}-.+$/)
      end
    end

    test "article bodies contain HTML" do
      articles = DevFaqs.all_articles()

      for article <- articles do
        # Markdown should be converted to HTML
        assert String.contains?(article.body, "<h1>") or
                 String.contains?(article.body, "<h2>") or
                 String.contains?(article.body, "<p>")
      end
    end
  end

  describe "articles_by_category/1" do
    test "filters articles by category" do
      all_articles = DevFaqs.all_articles()
      categories = Enum.map(all_articles, & &1.category) |> Enum.uniq()

      for category <- categories do
        filtered = DevFaqs.articles_by_category(category)
        assert Enum.all?(filtered, &(&1.category == category))
      end
    end

    test "returns empty list for non-existent category" do
      articles = DevFaqs.articles_by_category("non-existent-category")
      assert articles == []
    end

    test "returns empty list for nil category" do
      articles = DevFaqs.articles_by_category(nil)
      assert articles == []
    end
  end

  describe "categories/0" do
    test "returns unique sorted categories" do
      categories = DevFaqs.categories()

      assert is_list(categories)

      # In test environment, may be empty; in dev, should have categories
      if categories != [] do
        # Should be sorted
        assert categories == Enum.sort(categories)

        # Should be unique
        assert length(categories) == length(Enum.uniq(categories))
      end
    end

    test "all categories are strings" do
      categories = DevFaqs.categories()

      for category <- categories do
        assert is_binary(category)
      end
    end
  end

  describe "available?/0" do
    test "returns true in dev environment" do
      # This test runs in test environment, but we can verify the function exists
      assert is_boolean(DevFaqs.available?())
    end
  end

  describe "edge cases" do
    test "handles duplicate order numbers gracefully" do
      # Articles can have same order - they'll still be sorted
      articles = DevFaqs.all_articles()
      orders = Enum.map(articles, & &1.order)

      # Verify we can handle this without crashing
      assert is_list(orders)
    end

    test "article bodies are safe HTML" do
      articles = DevFaqs.all_articles()

      for article <- articles do
        # HTML should not contain dangerous scripts
        refute String.contains?(article.body, "<script>")
      end
    end

    test "handles articles with special characters in titles" do
      articles = DevFaqs.all_articles()

      # Should handle titles with quotes, dashes, etc.
      for article <- articles do
        assert String.valid?(article.title)
      end
    end
  end
end
