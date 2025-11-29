defmodule Homesite.Analytics.ActivityLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "activity_logs" do
    field :action, :string
    field :resource_type, :string
    field :resource_id, :integer
    field :changes, :map, default: %{}
    field :ip_address, :string
    field :user_agent, :string
    field :metadata, :map, default: %{}

    belongs_to :user, Homesite.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(activity_log, attrs) do
    activity_log
    |> cast(attrs, [
      :user_id,
      :action,
      :resource_type,
      :resource_id,
      :changes,
      :ip_address,
      :user_agent,
      :metadata
    ])
    |> validate_required([:user_id, :action, :resource_type])
    |> validate_length(:action, min: 1, max: 255)
    |> validate_length(:resource_type, min: 1, max: 255)
  end
end
