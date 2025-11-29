defmodule Homesite.Analytics.SearchQuery do
  use Ecto.Schema
  import Ecto.Changeset

  schema "search_queries" do
    field :query, :string
    field :result_count, :integer, default: 0
    field :posts_count, :integer, default: 0
    field :tags_count, :integer, default: 0
    field :faqs_count, :integer, default: 0
    field :duration_ms, :integer
    field :ip_address, :string
    field :user_agent, :string

    belongs_to :user, Homesite.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(search_query, attrs) do
    search_query
    |> cast(attrs, [
      :query,
      :result_count,
      :posts_count,
      :tags_count,
      :faqs_count,
      :duration_ms,
      :user_id,
      :ip_address,
      :user_agent
    ])
    |> validate_required([:query, :result_count])
    |> validate_length(:query, min: 1, max: 255)
    |> validate_number(:result_count, greater_than_or_equal_to: 0)
    |> validate_number(:posts_count, greater_than_or_equal_to: 0)
    |> validate_number(:tags_count, greater_than_or_equal_to: 0)
    |> validate_number(:faqs_count, greater_than_or_equal_to: 0)
  end
end
