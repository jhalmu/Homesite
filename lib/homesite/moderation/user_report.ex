defmodule Homesite.Moderation.UserReport do
  @moduledoc """
  Schema for user reports.

  Users can report other users for admin review.
  Reports go through a workflow: pending -> reviewing -> resolved/dismissed.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @status_values ~w(pending reviewing resolved dismissed)

  @valid_content_types ~w(post chat_message)

  schema "user_reports" do
    field :reason, :string
    field :status, :string, default: "pending"
    field :resolved_at, :utc_datetime
    field :resolution_notes, :string
    field :metadata, :map, default: %{}
    field :content_type, :string
    field :content_id, :integer

    belongs_to :reporter, Homesite.Accounts.User
    belongs_to :reported_user, Homesite.Accounts.User
    belongs_to :resolved_by, Homesite.Accounts.User, foreign_key: :resolved_by_user_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(report, attrs) do
    report
    |> cast(attrs, [
      :reporter_id,
      :reported_user_id,
      :reason,
      :status,
      :metadata,
      :content_type,
      :content_id
    ])
    |> validate_required([:reporter_id, :reported_user_id, :reason])
    |> validate_length(:reason, min: 10, max: 5000)
    |> validate_inclusion(:status, @status_values)
    |> validate_not_self_report()
    |> validate_content_reference()
    |> foreign_key_constraint(:reporter_id)
    |> foreign_key_constraint(:reported_user_id)
  end

  @doc """
  Changeset for resolving or dismissing a report.
  """
  def resolution_changeset(report, attrs) do
    report
    |> cast(attrs, [:status, :resolved_at, :resolved_by_user_id, :resolution_notes])
    |> validate_required([:status, :resolved_at, :resolved_by_user_id])
    |> validate_inclusion(:status, ["resolved", "dismissed"])
    |> validate_length(:resolution_notes, max: 5000)
  end

  defp validate_not_self_report(changeset) do
    reporter_id = get_field(changeset, :reporter_id)
    reported_user_id = get_field(changeset, :reported_user_id)

    if reporter_id && reported_user_id && reporter_id == reported_user_id do
      add_error(changeset, :reported_user_id, "cannot report yourself")
    else
      changeset
    end
  end

  defp validate_content_reference(changeset) do
    content_type = get_field(changeset, :content_type)
    content_id = get_field(changeset, :content_id)

    cond do
      is_nil(content_type) and is_nil(content_id) ->
        changeset

      is_nil(content_type) or is_nil(content_id) ->
        add_error(
          changeset,
          :content_type,
          "both content_type and content_id must be provided together"
        )

      content_type not in @valid_content_types ->
        add_error(
          changeset,
          :content_type,
          "must be one of: #{Enum.join(@valid_content_types, ", ")}"
        )

      true ->
        changeset
    end
  end

  def status_values, do: @status_values
  def valid_content_types, do: @valid_content_types
end
