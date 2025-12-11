defmodule Homesite.Moderation.ReasonPreset do
  @moduledoc """
  Schema for moderation reason presets.

  Pre-defined reasons for reporting, muting, suspending, and banning users.
  Supports bilingual content (English and Finnish).
  """
  use Ecto.Schema
  import Ecto.Changeset

  @valid_categories ~w(report mute suspend ban)

  schema "moderation_reason_presets" do
    field :category, :string
    field :label_en, :string
    field :label_fi, :string
    field :text_en, :string
    field :text_fi, :string
    field :display_order, :integer, default: 0
    field :is_active, :boolean, default: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(preset, attrs) do
    preset
    |> cast(attrs, [
      :category,
      :label_en,
      :label_fi,
      :text_en,
      :text_fi,
      :display_order,
      :is_active
    ])
    |> validate_required([:category, :label_en, :label_fi, :text_en, :text_fi])
    |> validate_inclusion(:category, @valid_categories)
    |> validate_length(:label_en, max: 100)
    |> validate_length(:label_fi, max: 100)
    |> validate_length(:text_en, max: 5000)
    |> validate_length(:text_fi, max: 5000)
  end

  @doc """
  Returns the label in the specified locale.
  """
  def label(%__MODULE__{} = preset, locale) when locale in ["en", "fi"] do
    case locale do
      "en" -> preset.label_en
      "fi" -> preset.label_fi
    end
  end

  def label(%__MODULE__{} = preset, _locale), do: preset.label_en

  @doc """
  Returns the full text in the specified locale.
  """
  def text(%__MODULE__{} = preset, locale) when locale in ["en", "fi"] do
    case locale do
      "en" -> preset.text_en
      "fi" -> preset.text_fi
    end
  end

  def text(%__MODULE__{} = preset, _locale), do: preset.text_en

  def valid_categories, do: @valid_categories
end
