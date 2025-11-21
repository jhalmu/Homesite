defmodule Homesite.ContentFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Homesite.Content` context.
  """

  @doc """
  Generate a unique tag name.
  """
  def unique_tag_name, do: "tag name #{System.unique_integer([:positive])}"

  @doc """
  Generate a tag.
  """
  def tag_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        is_public: true,
        name: unique_tag_name(),
        slug: "will-be-generated"
      })

    {:ok, tag} = Homesite.Content.create_tag(scope, attrs)
    tag
  end

  @doc """
  Generate a unique post title.
  """
  def unique_post_title, do: "post title #{System.unique_integer([:positive])}"

  @doc """
  Generate a post.
  """
  def post_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        body: "some body content that is long enough",
        published_at: ~U[2025-11-20 11:44:00Z],
        slug: "will-be-generated",
        title: unique_post_title()
      })

    {:ok, post} = Homesite.Content.create_post(scope, attrs)
    post
  end
end
