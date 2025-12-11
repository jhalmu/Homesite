defmodule Homesite.Repo.Migrations.CreateModerationReasonPresets do
  use Ecto.Migration

  def change do
    create table(:moderation_reason_presets) do
      add :category, :string, null: false
      add :label_en, :string, null: false
      add :label_fi, :string, null: false
      add :text_en, :text, null: false
      add :text_fi, :text, null: false
      add :display_order, :integer, default: 0
      add :is_active, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    create index(:moderation_reason_presets, [:category, :is_active, :display_order])

    # Seed default presets
    flush()

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    execute(
      fn ->
        repo().insert_all("moderation_reason_presets", [
          # Report presets
          %{
            category: "report",
            label_en: "Harassment",
            label_fi: "Häirintä",
            text_en: "This user is engaging in harassment or bullying behavior.",
            text_fi: "Tämä käyttäjä käyttäytyy häiritsevästi tai kiusaa.",
            display_order: 1,
            is_active: true,
            inserted_at: now,
            updated_at: now
          },
          %{
            category: "report",
            label_en: "Spam",
            label_fi: "Roskaposti",
            text_en: "This user is posting spam or unwanted promotional content.",
            text_fi: "Tämä käyttäjä lähettää roskapostia tai ei-toivottua mainossisältöä.",
            display_order: 2,
            is_active: true,
            inserted_at: now,
            updated_at: now
          },
          %{
            category: "report",
            label_en: "Inappropriate Content",
            label_fi: "Sopimaton sisältö",
            text_en: "This user is sharing inappropriate or offensive content.",
            text_fi: "Tämä käyttäjä jakaa sopimatonta tai loukkaavaa sisältöä.",
            display_order: 3,
            is_active: true,
            inserted_at: now,
            updated_at: now
          },
          %{
            category: "report",
            label_en: "Impersonation",
            label_fi: "Tekeytyminen",
            text_en: "This user is impersonating another person.",
            text_fi: "Tämä käyttäjä esiintyy toisena henkilönä.",
            display_order: 4,
            is_active: true,
            inserted_at: now,
            updated_at: now
          },
          # Mute presets
          %{
            category: "mute",
            label_en: "Disruptive Behavior",
            label_fi: "Häiritsevä käytös",
            text_en: "Temporarily muted due to disruptive behavior in chat.",
            text_fi: "Väliaikaisesti hiljennetty häiritsevän käytöksen vuoksi chatissa.",
            display_order: 1,
            is_active: true,
            inserted_at: now,
            updated_at: now
          },
          %{
            category: "mute",
            label_en: "Excessive Messaging",
            label_fi: "Liiallinen viestintä",
            text_en: "Temporarily muted for sending too many messages.",
            text_fi: "Väliaikaisesti hiljennetty liian useiden viestien lähettämisestä.",
            display_order: 2,
            is_active: true,
            inserted_at: now,
            updated_at: now
          },
          %{
            category: "mute",
            label_en: "Off-topic Discussion",
            label_fi: "Aiheen vierestä",
            text_en: "Temporarily muted for off-topic or derailing discussions.",
            text_fi: "Väliaikaisesti hiljennetty aiheen vierestä keskustelusta.",
            display_order: 3,
            is_active: true,
            inserted_at: now,
            updated_at: now
          },
          # Suspend presets
          %{
            category: "suspend",
            label_en: "Repeated Violations",
            label_fi: "Toistuvat rikkomukset",
            text_en: "Account suspended due to repeated policy violations.",
            text_fi: "Tili jäädytetty toistuvien sääntörikkomusten vuoksi.",
            display_order: 1,
            is_active: true,
            inserted_at: now,
            updated_at: now
          },
          %{
            category: "suspend",
            label_en: "Harassment",
            label_fi: "Häirintä",
            text_en: "Account suspended for harassment of other users.",
            text_fi: "Tili jäädytetty muiden käyttäjien häirinnästä.",
            display_order: 2,
            is_active: true,
            inserted_at: now,
            updated_at: now
          },
          %{
            category: "suspend",
            label_en: "Cooling Off Period",
            label_fi: "Rauhoittumisaika",
            text_en: "Account suspended to allow for a cooling off period.",
            text_fi: "Tili jäädytetty rauhoittumisajan ajaksi.",
            display_order: 3,
            is_active: true,
            inserted_at: now,
            updated_at: now
          },
          # Ban presets
          %{
            category: "ban",
            label_en: "Severe Harassment",
            label_fi: "Vakava häirintä",
            text_en: "Permanently banned for severe harassment.",
            text_fi: "Pysyvästi estetty vakavasta häirinnästä.",
            display_order: 1,
            is_active: true,
            inserted_at: now,
            updated_at: now
          },
          %{
            category: "ban",
            label_en: "Illegal Activity",
            label_fi: "Laiton toiminta",
            text_en: "Permanently banned for illegal activity or content.",
            text_fi: "Pysyvästi estetty laittomasta toiminnasta tai sisällöstä.",
            display_order: 2,
            is_active: true,
            inserted_at: now,
            updated_at: now
          },
          %{
            category: "ban",
            label_en: "Multiple Account Abuse",
            label_fi: "Useiden tilien väärinkäyttö",
            text_en: "Permanently banned for creating multiple accounts to evade restrictions.",
            text_fi: "Pysyvästi estetty useiden tilien luomisesta rajoitusten kiertämiseksi.",
            display_order: 3,
            is_active: true,
            inserted_at: now,
            updated_at: now
          }
        ])
      end,
      fn -> :ok end
    )
  end
end
