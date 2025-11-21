defmodule Homesite.ContentFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Homesite.Content` context.
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
        is_public: true,
        name: "some name",
        slug: unique_tag_slug()
      })

    {:ok, tag} = Homesite.Content.create_tag(scope, attrs)
    tag
  end

  @doc """
  Generate a unique post slug.
  """
  def unique_post_slug, do: "some slug#{System.unique_integer([:positive])}"

  @doc """
  Generate a post.
  """
  def post_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        body: "some body",
        published_at: ~U[2025-11-20 11:44:00Z],
        slug: unique_post_slug(),
        title: "some title"
      })

    {:ok, post} = Homesite.Content.create_post(scope, attrs)
    post
  end
end
