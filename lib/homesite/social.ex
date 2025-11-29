defmodule Homesite.Social do
  @moduledoc """
  The Social context for share tracking and analytics.
  """

  import Ecto.Query, warn: false
  alias Homesite.Repo
  alias Homesite.Social.ShareLog

  @doc """
  Creates a share log entry.

  ## Examples

      iex> log_share(%{platform: "twitter", shared_url: "...", post_id: 1})
      {:ok, %ShareLog{}}

  """
  def log_share(attrs \\ %{}) do
    %ShareLog{}
    |> ShareLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns share statistics for a post.

  ## Examples

      iex> get_post_share_stats(123)
      %{total: 42, by_platform: %{"twitter" => 15, "facebook" => 12, ...}}

  """
  def get_post_share_stats(post_id) do
    shares =
      from(s in ShareLog,
        where: s.post_id == ^post_id,
        select: {s.platform, count(s.id)},
        group_by: s.platform
      )
      |> Repo.all()
      |> Map.new()

    total = Enum.reduce(shares, 0, fn {_platform, count}, acc -> acc + count end)

    %{
      total: total,
      by_platform: shares
    }
  end

  @doc """
  Returns share statistics for all posts.

  Returns list of posts with their share counts.
  """
  def get_all_share_stats do
    from(s in ShareLog,
      join: p in assoc(s, :post),
      group_by: [s.post_id, p.title],
      select: %{
        post_id: s.post_id,
        post_title: p.title,
        share_count: count(s.id)
      },
      order_by: [desc: count(s.id)]
    )
    |> Repo.all()
  end

  @doc """
  Returns recent shares.

  ## Examples

      iex> list_recent_shares(10)
      [%ShareLog{}, ...]

  """
  def list_recent_shares(limit \\ 20) do
    from(s in ShareLog,
      order_by: [desc: s.inserted_at],
      limit: ^limit,
      preload: [:post, :user]
    )
    |> Repo.all()
  end
end
