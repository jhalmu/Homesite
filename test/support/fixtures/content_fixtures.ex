defmodule Homesite.ContentFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Homesite.Content` context.
  """

  @doc """
  Generate a unique blog_post slug.
  """
  def unique_blog_post_slug, do: "some slug#{System.unique_integer([:positive])}"

  @doc """
  Generate a blog_post.
  """
  def blog_post_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        author_id: 42,
        author_type: "some author_type",
        content_en: "some content_en",
        content_fi: "some content_fi",
        curator_added: true,
        metadata: %{},
        published_at: ~U[2025-11-16 15:19:00Z],
        slug: unique_blog_post_slug(),
        status: "some status",
        title_en: "some title_en",
        title_fi: "some title_fi"
      })

    {:ok, blog_post} = Homesite.Content.create_blog_post(scope, attrs)
    blog_post
  end
end
