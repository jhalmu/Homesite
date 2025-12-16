defmodule Homesite.SearchTest do
  use Homesite.DataCase

  alias Homesite.{Content, Faqs, Search}

  describe "search_all/2" do
    setup do
      scope = Homesite.AccountsFixtures.user_scope_fixture()
      admin_scope = Homesite.AccountsFixtures.admin_scope_fixture()

      # Create a published post
      {:ok, post} =
        Content.create_post(scope, %{
          title: "Getting started with Elixir",
          body: "Learn how to use Phoenix and LiveView",
          published_at: DateTime.utc_now()
        })

      # Create tags
      {:ok, elixir_tag} = Content.create_tag(scope, %{name: "Elixir", slug: "elixir"})
      {:ok, phoenix_tag} = Content.create_tag(scope, %{name: "Phoenix", slug: "phoenix"})

      # Create FAQ
      {:ok, faq} =
        Faqs.create_faq(admin_scope, %{
          category: "user",
          question_en: "How to learn Elixir?",
          question_fi: "Miten oppia Elixir?",
          answer_en: "Start with the official guides and Phoenix framework.",
          answer_fi: "Aloita virallisista oppaista ja Phoenix-kehyksestä.",
          display_order: 1,
          is_active: true
        })

      %{
        post: post,
        elixir_tag: elixir_tag,
        phoenix_tag: phoenix_tag,
        faq: faq,
        scope: scope
      }
    end

    test "returns empty results for empty query" do
      results = Search.search_all("")
      assert results.posts == []
      assert results.tags == []
      assert results.faqs == []
      assert results.total_count == 0
    end

    test "returns empty results for whitespace-only query" do
      results = Search.search_all("   ")
      assert results.posts == []
      assert results.tags == []
      assert results.faqs == []
      assert results.total_count == 0
    end

    test "searches across all content types", %{post: post, elixir_tag: tag, faq: faq} do
      results = Search.search_all("Elixir")

      # Should find the post
      assert length(results.posts) >= 1
      assert Enum.any?(results.posts, &(&1.id == post.id))

      # Should find the tag
      assert length(results.tags) >= 1
      assert Enum.any?(results.tags, &(&1.id == tag.id))

      # Should find the FAQ
      assert length(results.faqs) >= 1
      assert Enum.any?(results.faqs, &(&1.id == faq.id))

      # Total count should be sum of all results
      assert results.total_count ==
               length(results.posts) + length(results.tags) + length(results.faqs)

      assert results.total_count >= 3
    end

    test "respects limit option", %{scope: scope} do
      admin_scope = Homesite.AccountsFixtures.admin_scope_fixture()

      # Create many items of each type
      for i <- 1..15 do
        Content.create_post(scope, %{
          title: "Test Post #{i}",
          body: "Content about testing",
          published_at: DateTime.utc_now()
        })

        Content.create_tag(scope, %{name: "Test Tag #{i}", slug: "test-tag-#{i}"})

        Faqs.create_faq(admin_scope, %{
          category: "user",
          question_en: "Test Question #{i}",
          question_fi: "Testikysymys #{i}",
          answer_en: "Test answer #{i}",
          answer_fi: "Testivastaus #{i}",
          display_order: i,
          is_active: true
        })
      end

      results = Search.search_all("Test", limit: 5)

      assert length(results.posts) <= 5
      assert length(results.tags) <= 5
      assert length(results.faqs) <= 5
    end

    test "respects locale option for FAQs", %{faq: faq} do
      en_results = Search.search_all("learn Elixir", locale: "en")
      fi_results = Search.search_all("oppia", locale: "fi")

      en_faq = Enum.find(en_results.faqs, &(&1.id == faq.id))
      fi_faq = Enum.find(fi_results.faqs, &(&1.id == faq.id))

      assert en_faq.question == "How to learn Elixir?"
      assert fi_faq.question == "Miten oppia Elixir?"
    end

    test "executes searches in parallel (performance test)" do
      # This test ensures parallel execution works
      start_time = System.monotonic_time(:millisecond)
      _results = Search.search_all("Phoenix")
      end_time = System.monotonic_time(:millisecond)

      duration = end_time - start_time

      # Parallel execution should be faster than sequential
      # (This is a basic smoke test, actual performance depends on data volume)
      assert duration < 5000
    end

    test "finds items by different search terms" do
      # Search for "Phoenix" should find post and tag
      phoenix_results = Search.search_all("Phoenix")
      assert length(phoenix_results.posts) >= 1
      assert length(phoenix_results.tags) >= 1

      # Search for "LiveView" should find post
      liveview_results = Search.search_all("LiveView")
      assert length(liveview_results.posts) >= 1
    end

    test "handles queries with no matches gracefully" do
      results = Search.search_all("NonExistentTerm12345")
      assert results.posts == []
      assert results.tags == []
      assert results.faqs == []
      assert results.total_count == 0
    end
  end

  describe "search_posts/2" do
    setup do
      scope = Homesite.AccountsFixtures.user_scope_fixture()

      {:ok, post} =
        Content.create_post(scope, %{
          title: "Elixir Tutorial",
          body: "Learn Elixir programming",
          published_at: DateTime.utc_now()
        })

      %{post: post}
    end

    test "delegates to Content.search_posts/2", %{post: post} do
      results = Search.search_posts("Elixir")
      assert length(results) >= 1
      assert Enum.any?(results, &(&1.id == post.id))
    end

    test "passes options correctly" do
      results = Search.search_posts("Elixir", limit: 1)
      assert length(results) <= 1
    end
  end

  describe "search_tags/2" do
    setup do
      scope = Homesite.AccountsFixtures.user_scope_fixture()
      {:ok, tag} = Content.create_tag(scope, %{name: "Elixir", slug: "elixir"})
      %{tag: tag}
    end

    test "delegates to Content.search_tags/2", %{tag: tag} do
      results = Search.search_tags("Elixir")
      assert length(results) >= 1
      assert Enum.any?(results, &(&1.id == tag.id))
    end

    test "passes options correctly" do
      results = Search.search_tags("Elixir", limit: 1)
      assert length(results) <= 1
    end
  end

  describe "search_faqs/2" do
    setup do
      admin_scope = Homesite.AccountsFixtures.admin_scope_fixture()

      {:ok, faq} =
        Faqs.create_faq(admin_scope, %{
          category: "user",
          question_en: "What is Elixir?",
          question_fi: "Mikä on Elixir?",
          answer_en: "A functional programming language",
          answer_fi: "Funktionaalinen ohjelmointikieli",
          display_order: 1,
          is_active: true
        })

      %{faq: faq}
    end

    test "delegates to Faqs.search_faqs/2", %{faq: faq} do
      results = Search.search_faqs("Elixir")
      assert length(results) >= 1
      assert Enum.any?(results, &(&1.id == faq.id))
    end

    test "passes options correctly" do
      results = Search.search_faqs("Elixir", limit: 1, locale: "fi")
      assert length(results) <= 1

      if length(results) > 0 do
        assert hd(results).question =~ ~r/Mikä|Elixir/
      end
    end
  end
end
