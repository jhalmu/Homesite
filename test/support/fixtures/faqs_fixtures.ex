defmodule Homesite.FaqsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Homesite.Faqs` context.
  """

  alias Homesite.Faqs

  @doc """
  Generate a FAQ with default attributes.
  """
  def faq_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        category: "user",
        question_en: "Test question in English?",
        question_fi: "Testikysymys suomeksi?",
        answer_en: "This is the answer in English. It needs to be at least 10 characters long.",
        answer_fi: "Tama on vastaus suomeksi. Sen taytyy olla vahintaan 10 merkkia pitkaa.",
        display_order: 0,
        is_active: true
      })

    {:ok, faq} = Faqs.create_faq(scope, attrs)
    faq
  end

  @doc """
  Generate an admin FAQ.
  """
  def admin_faq_fixture(scope, attrs \\ %{}) do
    faq_fixture(scope, Map.put(attrs, :category, "admin"))
  end

  @doc """
  Generate a user FAQ.
  """
  def user_faq_fixture(scope, attrs \\ %{}) do
    faq_fixture(scope, Map.put(attrs, :category, "user"))
  end
end
