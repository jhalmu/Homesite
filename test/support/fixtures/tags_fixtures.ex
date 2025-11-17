defmodule Homesite.TagsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Homesite.Tags` context.
  """

  @doc """
  Generate a unique tag slug.
  """
  def unique_tag_slug, do: "some slug#{System.unique_integer([:positive])}"

  @doc """
  Generate a tag.
  """
  def tag_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name_en: "some name_en",
        name_fi: "some name_fi",
        slug: unique_tag_slug()
      })

    {:ok, tag} = Homesite.Tags.create_tag(scope, attrs)
    tag
  end

  @doc """
  Generate a tagging.
  """
  def tagging_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        taggable_id: 42,
        taggable_type: "some taggable_type"
      })

    {:ok, tagging} = Homesite.Tags.create_tagging(scope, attrs)
    tagging
  end
end
