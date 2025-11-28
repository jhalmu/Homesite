defmodule Homesite.FaqsTest do
  use Homesite.DataCase

  alias Homesite.Faqs

  describe "faqs" do
    alias Homesite.Faqs.Faq

    import Homesite.AccountsFixtures, only: [user_scope_fixture: 0]
    import Homesite.FaqsFixtures

    @invalid_attrs %{
      category: nil,
      question_en: nil,
      question_fi: nil,
      answer_en: nil,
      answer_fi: nil
    }

    test "list_user_faqs/1 returns all active user FAQs" do
      admin_scope = admin_scope_fixture()
      user_faq1 = user_faq_fixture(admin_scope, %{display_order: 1})
      user_faq2 = user_faq_fixture(admin_scope, %{display_order: 2})
      _admin_faq = admin_faq_fixture(admin_scope)
      _inactive_faq = user_faq_fixture(admin_scope, %{is_active: false})

      faqs = Faqs.list_user_faqs("en")
      assert length(faqs) == 2
      assert Enum.map(faqs, & &1.id) == [user_faq1.id, user_faq2.id]
    end

    test "list_user_faqs/1 returns localized content" do
      admin_scope = admin_scope_fixture()
      user_faq_fixture(admin_scope)

      [faq_en] = Faqs.list_user_faqs("en")
      assert faq_en.question == "Test question in English?"
      assert faq_en.answer =~ "answer in English"

      [faq_fi] = Faqs.list_user_faqs("fi")
      assert faq_fi.question == "Testikysymys suomeksi?"
      assert faq_fi.answer =~ "vastaus suomeksi"
    end

    test "list_admin_faqs/2 returns all active admin FAQs" do
      admin_scope = admin_scope_fixture()
      admin_faq1 = admin_faq_fixture(admin_scope, %{display_order: 1})
      admin_faq2 = admin_faq_fixture(admin_scope, %{display_order: 2})
      _user_faq = user_faq_fixture(admin_scope)

      faqs = Faqs.list_admin_faqs(admin_scope, "en")
      assert length(faqs) == 2
      assert Enum.map(faqs, & &1.id) == [admin_faq1.id, admin_faq2.id]
    end

    test "list_admin_faqs/2 requires admin scope" do
      user_scope = user_scope_fixture()

      assert_raise MatchError, fn ->
        Faqs.list_admin_faqs(user_scope, "en")
      end
    end

    test "list_all_faqs_for_management/1 returns all FAQs" do
      admin_scope = admin_scope_fixture()
      user_faq = user_faq_fixture(admin_scope)
      admin_faq = admin_faq_fixture(admin_scope)

      faqs = Faqs.list_all_faqs_for_management(admin_scope)
      assert length(faqs) == 2
      faq_ids = Enum.map(faqs, & &1.id) |> Enum.sort()
      assert faq_ids == Enum.sort([user_faq.id, admin_faq.id])
    end

    test "list_all_faqs_for_management/1 requires admin scope" do
      user_scope = user_scope_fixture()

      assert_raise MatchError, fn ->
        Faqs.list_all_faqs_for_management(user_scope)
      end
    end

    test "get_user_faq_by_slug!/2 returns the FAQ with given slug" do
      admin_scope = admin_scope_fixture()
      faq = user_faq_fixture(admin_scope)

      found_faq = Faqs.get_user_faq_by_slug!(faq.slug, "en")
      assert found_faq.id == faq.id
      assert found_faq.question == "Test question in English?"
    end

    test "get_user_faq_by_slug!/2 raises when FAQ not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Faqs.get_user_faq_by_slug!("nonexistent-slug", "en")
      end
    end

    test "get_admin_faq_by_slug!/3 returns admin FAQ" do
      admin_scope = admin_scope_fixture()
      faq = admin_faq_fixture(admin_scope)

      found_faq = Faqs.get_admin_faq_by_slug!(admin_scope, faq.slug, "en")
      assert found_faq.id == faq.id
    end

    test "get_admin_faq_by_slug!/3 requires admin scope" do
      user_scope = user_scope_fixture()
      admin_scope = admin_scope_fixture()
      faq = admin_faq_fixture(admin_scope)

      assert_raise MatchError, fn ->
        Faqs.get_admin_faq_by_slug!(user_scope, faq.slug, "en")
      end
    end

    test "create_faq/2 with valid data creates a FAQ" do
      admin_scope = admin_scope_fixture()

      valid_attrs = %{
        category: "user",
        question_en: "How do I do this?",
        question_fi: "Miten teen taman?",
        answer_en: "You can do it like this with detailed instructions.",
        answer_fi: "Voit tehda sen nain yksityiskohtaisilla ohjeilla.",
        display_order: 10
      }

      assert {:ok, %Faq{} = faq} = Faqs.create_faq(admin_scope, valid_attrs)
      assert faq.category == "user"
      assert faq.question_en == "How do I do this?"
      assert faq.question_fi == "Miten teen taman?"
      assert faq.answer_en =~ "detailed instructions"
      assert faq.display_order == 10
      assert faq.is_active == true
      assert faq.slug =~ "how-do-i-do-this"
      assert faq.created_by_id == admin_scope.user.id
    end

    test "create_faq/2 with invalid data returns error changeset" do
      admin_scope = admin_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Faqs.create_faq(admin_scope, @invalid_attrs)
    end

    test "create_faq/2 requires admin scope" do
      user_scope = user_scope_fixture()

      valid_attrs = %{
        category: "user",
        question_en: "Test?",
        question_fi: "Testi?",
        answer_en: "Test answer here",
        answer_fi: "Testi vastaus t��ll�"
      }

      assert_raise MatchError, fn ->
        Faqs.create_faq(user_scope, valid_attrs)
      end
    end

    test "update_faq/3 with valid data updates the FAQ" do
      admin_scope = admin_scope_fixture()
      faq = user_faq_fixture(admin_scope)

      update_attrs = %{
        question_en: "Updated question?",
        answer_en: "Updated answer with enough text."
      }

      assert {:ok, %Faq{} = updated_faq} = Faqs.update_faq(admin_scope, faq, update_attrs)
      assert updated_faq.question_en == "Updated question?"
      assert updated_faq.answer_en == "Updated answer with enough text."
      assert updated_faq.updated_by_id == admin_scope.user.id
    end

    test "update_faq/3 with invalid data returns error changeset" do
      admin_scope = admin_scope_fixture()
      faq = user_faq_fixture(admin_scope)

      assert {:error, %Ecto.Changeset{}} =
               Faqs.update_faq(admin_scope, faq, %{question_en: nil})
    end

    test "update_faq/3 requires admin scope" do
      admin_scope = admin_scope_fixture()
      user_scope = user_scope_fixture()
      faq = user_faq_fixture(admin_scope)

      assert_raise MatchError, fn ->
        Faqs.update_faq(user_scope, faq, %{question_en: "Updated?"})
      end
    end

    test "delete_faq/2 deletes the FAQ" do
      admin_scope = admin_scope_fixture()
      faq = user_faq_fixture(admin_scope)

      assert {:ok, %Faq{}} = Faqs.delete_faq(admin_scope, faq)

      assert_raise Ecto.NoResultsError, fn ->
        Faqs.get_faq_for_management!(admin_scope, faq.id)
      end
    end

    test "delete_faq/2 requires admin scope" do
      admin_scope = admin_scope_fixture()
      user_scope = user_scope_fixture()
      faq = user_faq_fixture(admin_scope)

      assert_raise MatchError, fn ->
        Faqs.delete_faq(user_scope, faq)
      end
    end

    test "change_faq/3 returns a FAQ changeset" do
      admin_scope = admin_scope_fixture()
      faq = user_faq_fixture(admin_scope)
      assert %Ecto.Changeset{} = Faqs.change_faq(admin_scope, faq)
    end

    test "add_localized_content/2 merges correct locale fields" do
      admin_scope = admin_scope_fixture()
      faq = user_faq_fixture(admin_scope)

      faq_en = Faqs.add_localized_content(faq, "en")
      assert faq_en.question == faq.question_en
      assert faq_en.answer == faq.answer_en

      faq_fi = Faqs.add_localized_content(faq, "fi")
      assert faq_fi.question == faq.question_fi
      assert faq_fi.answer == faq.answer_fi
    end
  end
end
