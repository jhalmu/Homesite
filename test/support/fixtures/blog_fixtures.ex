defmodule Kotisivut.BlogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Kotisivut.Blog` context.
  """

  @doc """
  Generate a post.
  """
  def post_fixture(attrs \\ %{}) do
    {:ok, post} =
      attrs
      |> Enum.into(%{
        user_id: 1,
        status: "some status",
        body: "some body",
        title: "some title"
      })
      |> Kotisivut.Blog.create_post()

    post
  end
end
