defmodule Homesite.FaqSearchTest do
  use Homesite.DataCase

  alias Homesite.Faqs

  describe "search_faqs/2" do
    setup do
      # Create test FAQs
      {:ok, user_faq1} =
        Faqs.create_faq(admin_scope(), %{
          category: "user",
          question_en: "How to create a post?",
          question_fi: "Miten luodaan julkaisu?",
          answer_en: "Click the New Post button and fill out the form.",
          answer_fi: "Klikkaa Uusi julkaisu -painiketta ja täytä lomake.",
          display_order: 1,
          is_active: true
        })

      {:ok, user_faq2} =
        Faqs.create_faq(admin_scope(), %{
          category: "user",
          question_en: "How to tag posts?",
          question_fi: "Miten lisätään tagit julkaisuun?",
          answer_en: "Use the tag selector when creating or editing a post.",
          answer_fi: "Käytä tagin valitsinta luodessasi tai muokatessasi julkaisua.",
          display_order: 2,
          is_active: true
        })

      {:ok, admin_faq} =
        Faqs.create_faq(admin_scope(), %{
          category: "admin",
          question_en: "How to manage users?",
          question_fi: "Miten hallitaan käyttäjiä?",
          answer_en: "Go to the Admin Dashboard and select User Management.",
          answer_fi: "Siirry hallintapaneeliin ja valitse käyttäjien hallinta.",
          display_order: 1,
          is_active: true
        })

      {:ok, inactive_faq} =
        Faqs.create_faq(admin_scope(), %{
          category: "user",
          question_en: "Inactive question",
          question_fi: "Inaktiivinen kysymys",
          answer_en: "This should not appear",
          answer_fi: "Tämä ei pitäisi näkyä",
          display_order: 99,
          is_active: false
        })

      %{
        user_faq1: user_faq1,
        user_faq2: user_faq2,
        admin_faq: admin_faq,
        inactive_faq: inactive_faq
      }
    end

    test "returns empty list for empty query" do
      assert Faqs.search_faqs("") == []
    end

    test "returns empty list for whitespace-only query" do
      assert Faqs.search_faqs("   ") == []
    end

    test "finds FAQ by exact question match (English)", %{user_faq1: faq} do
      results = Faqs.search_faqs("How to create a post")
      assert length(results) >= 1
      result = Enum.find(results, &(&1.id == faq.id))
      assert result
      assert result.question == "How to create a post?"
    end

    test "finds FAQ by partial question match", %{user_faq1: faq} do
      results = Faqs.search_faqs("create post")
      assert length(results) >= 1
      assert Enum.any?(results, &(&1.id == faq.id))
    end

    test "finds FAQ by answer content (English)", %{user_faq1: faq} do
      results = Faqs.search_faqs("New Post button")
      assert length(results) >= 1
      assert Enum.any?(results, &(&1.id == faq.id))
    end

    test "finds FAQ by Finnish question", %{user_faq1: faq} do
      results = Faqs.search_faqs("Miten luodaan", locale: "fi")
      assert length(results) >= 1
      result = Enum.find(results, &(&1.id == faq.id))
      assert result
      assert result.question == "Miten luodaan julkaisu?"
    end

    test "finds FAQ by Finnish answer", %{user_faq1: faq} do
      results = Faqs.search_faqs("täytä lomake", locale: "fi")
      assert length(results) >= 1
      assert Enum.any?(results, &(&1.id == faq.id))
    end

    test "returns localized content based on locale option", %{user_faq1: faq} do
      en_results = Faqs.search_faqs("create", locale: "en")
      fi_results = Faqs.search_faqs("luodaan", locale: "fi")

      en_result = Enum.find(en_results, &(&1.id == faq.id))
      fi_result = Enum.find(fi_results, &(&1.id == faq.id))

      assert en_result.question == "How to create a post?"
      assert fi_result.question == "Miten luodaan julkaisu?"
    end

    test "respects category filter", %{user_faq1: user_faq, admin_faq: admin_faq} do
      user_results = Faqs.search_faqs("How to", category: "user")
      admin_results = Faqs.search_faqs("How to", category: "admin")

      assert Enum.any?(user_results, &(&1.id == user_faq.id))
      refute Enum.any?(user_results, &(&1.id == admin_faq.id))

      assert Enum.any?(admin_results, &(&1.id == admin_faq.id))
      refute Enum.any?(admin_results, &(&1.id == user_faq.id))
    end

    test "does not return inactive FAQs", %{inactive_faq: inactive} do
      results = Faqs.search_faqs("Inactive")
      refute Enum.any?(results, &(&1.id == inactive.id))
    end

    test "respects limit option" do
      # Create many FAQs
      for i <- 1..15 do
        Faqs.create_faq(admin_scope(), %{
          category: "user",
          question_en: "Question #{i} about posts",
          question_fi: "Kysymys #{i} julkaisuista",
          answer_en: "Answer #{i} with enough content here",
          answer_fi: "Vastaus #{i} riittävällä sisällöllä",
          display_order: i,
          is_active: true
        })
      end

      results = Faqs.search_faqs("Question", limit: 5)
      assert length(results) == 5
    end

    test "handles negative limit gracefully" do
      results = Faqs.search_faqs("How to", limit: -1)
      assert results == []
    end

    test "handles fuzzy matching with typos" do
      results = Faqs.search_faqs("crate post")
      # Should still find "create post" with typo
      assert length(results) >= 1
    end

    test "case-insensitive search" do
      results = Faqs.search_faqs("HOW TO CREATE")
      assert length(results) >= 1
    end

    test "orders results by relevance" do
      # FAQ with exact match in question should rank higher
      results = Faqs.search_faqs("create post")
      assert length(results) >= 1
      # First result should have "create" and "post" in question
      first_result = hd(results)
      assert first_result.question =~ ~r/create|post/i
    end
  end

  # Helper function to create admin scope
  defp admin_scope do
    Homesite.AccountsFixtures.admin_scope_fixture()
  end
end
