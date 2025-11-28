defmodule Homesite.Faqs.Faq do
  @moduledoc """
  FAQ schema with bilingual content (English/Finnish).
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Homesite.Accounts.{Scope, User}

  schema "faqs" do
    field :category, :string
    field :question_en, :string
    field :question_fi, :string
    field :answer_en, :string
    field :answer_fi, :string
    field :display_order, :integer, default: 0
    field :is_active, :boolean, default: true
    field :slug, :string
    field :metadata, :map, default: %{}

    # Virtual fields for localized content
    field :question, :string, virtual: true
    field :answer, :string, virtual: true

    belongs_to :created_by, User, foreign_key: :created_by_id
    belongs_to :updated_by, User, foreign_key: :updated_by_id

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating or updating a FAQ.
  """
  def changeset(faq, attrs, %Scope{} = scope) do
    faq
    |> cast(attrs, [
      :category,
      :question_en,
      :question_fi,
      :answer_en,
      :answer_fi,
      :display_order,
      :is_active,
      :slug,
      :metadata
    ])
    |> validate_required([:category, :question_en, :question_fi, :answer_en, :answer_fi])
    |> validate_inclusion(:category, ["admin", "user"])
    |> validate_length(:question_en, min: 3, max: 500)
    |> validate_length(:question_fi, min: 3, max: 500)
    |> validate_length(:answer_en, min: 10)
    |> validate_length(:answer_fi, min: 10)
    |> validate_number(:display_order, greater_than_or_equal_to: 0)
    |> generate_slug()
    |> validate_required([:slug])
    |> unique_constraint(:slug)
    |> track_user(scope, faq)
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :slug) do
      nil ->
        # Auto-generate from question_en if slug not provided
        case get_change(changeset, :question_en) do
          nil ->
            changeset

          question ->
            base_slug =
              question
              |> String.downcase()
              |> String.replace(~r/[^a-z0-9-]+/, "-")
              |> String.trim("-")
              |> String.slice(0, 50)

            # Add timestamp and random for uniqueness
            random = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
            slug = "#{base_slug}-#{:os.system_time(:millisecond)}-#{random}"
            put_change(changeset, :slug, slug)
        end

      _provided_slug ->
        # User provided slug, validate it
        changeset
        |> validate_format(:slug, ~r/^[a-z0-9-]+$/)
        |> validate_length(:slug, min: 3, max: 100)
    end
  end

  defp track_user(changeset, scope, %__MODULE__{id: nil}) do
    # New record - set created_by
    put_change(changeset, :created_by_id, scope.user.id)
  end

  defp track_user(changeset, scope, _existing) do
    # Existing record - set updated_by
    put_change(changeset, :updated_by_id, scope.user.id)
  end
end
