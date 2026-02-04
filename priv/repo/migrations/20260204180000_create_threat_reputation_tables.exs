defmodule Homesite.Repo.Migrations.CreateThreatReputationTables do
  use Ecto.Migration

  def change do
    # IP reputation tracking
    create table(:ip_reputations) do
      add :ip_address, :string, null: false
      add :score, :integer, default: 0, null: false
      add :failed_login_count, :integer, default: 0
      add :suspicious_activity_count, :integer, default: 0
      add :request_volume_score, :integer, default: 0
      add :historical_violation_count, :integer, default: 0
      add :watchlist_boost, :integer, default: 0
      add :blocked, :boolean, default: false, null: false
      add :blocked_at, :utc_datetime
      add :block_expires_at, :utc_datetime
      add :block_count, :integer, default: 0
      add :country_code, :string, size: 2
      add :last_seen_at, :utc_datetime
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:ip_reputations, [:ip_address])
    create index(:ip_reputations, [:score])
    create index(:ip_reputations, [:blocked])
    create index(:ip_reputations, [:country_code])
    create index(:ip_reputations, [:block_expires_at])

    # Country-level reputation aggregation
    create table(:country_reputations) do
      add :country_code, :string, size: 2, null: false
      add :score, :integer, default: 0, null: false
      add :total_ips, :integer, default: 0
      add :blocked_ips, :integer, default: 0
      add :threat_events_count, :integer, default: 0
      add :watchlist_boost, :integer, default: 0
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:country_reputations, [:country_code])
    create index(:country_reputations, [:score])

    # Threat event log
    create table(:threat_events) do
      add :ip_address, :string, null: false
      add :event_type, :string, null: false
      add :severity, :string, default: "low"
      add :score_impact, :integer, default: 0
      add :details, :map, default: %{}
      add :country_code, :string, size: 2
      add :user_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:threat_events, [:ip_address])
    create index(:threat_events, [:event_type])
    create index(:threat_events, [:severity])
    create index(:threat_events, [:inserted_at])
    create index(:threat_events, [:country_code])
    create index(:threat_events, [:user_id])

    # IP watchlist (admin-managed)
    create table(:ip_watchlist) do
      add :ip_address, :string, null: false
      add :boost_score, :integer, default: 15, null: false
      add :reason, :string
      add :notes, :text
      add :expires_at, :utc_datetime
      add :added_by_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:ip_watchlist, [:ip_address])
    create index(:ip_watchlist, [:expires_at])

    # Country watchlist (admin-managed)
    create table(:country_watchlist) do
      add :country_code, :string, size: 2, null: false
      add :boost_score, :integer, default: 15, null: false
      add :reason, :string
      add :notes, :text
      add :expires_at, :utc_datetime
      add :added_by_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:country_watchlist, [:country_code])
    create index(:country_watchlist, [:expires_at])
  end
end
