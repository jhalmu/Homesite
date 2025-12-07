defmodule Homesite.Media.Collaborator do
  @moduledoc """
  Collaborator schema for tracking team members who worked on projects.

  Collaborators can have:
  - Name (required)
  - Contact information (optional): URL, email, or none
  - Display order for controlling presentation order
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "collaborators" do
    field :name, :string
    field :contact, :string
    field :contact_type, :string  # "url", "email", "none"
    field :display_order, :integer, default: 0

    belongs_to :project, Homesite.Media.Project
    belongs_to :user, Homesite.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(collaborator, attrs, user_scope) do
    collaborator
    |> cast(attrs, [:name, :contact, :contact_type, :display_order, :project_id])
    |> validate_required([:name, :project_id])
    |> validate_length(:name, min: 1, max: 200)
    |> validate_length(:contact, max: 500)
    |> validate_contact()
    |> validate_number(:display_order, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:user_id)
    |> put_change(:user_id, user_scope.user.id)
  end

  defp validate_contact(changeset) do
    contact = get_field(changeset, :contact)
    contact_type = get_field(changeset, :contact_type)

    case {contact, contact_type} do
      {nil, _} ->
        put_change(changeset, :contact_type, "none")

      {"", _} ->
        put_change(changeset, :contact_type, "none")

      {contact_value, "url"} ->
        validate_url_format(changeset, contact_value)

      {contact_value, "email"} ->
        validate_email_format(changeset, contact_value)

      {_, "none"} ->
        changeset

      {_contact_value, nil} ->
        # Infer contact type if not provided
        infer_contact_type(changeset, contact)

      _ ->
        add_error(changeset, :contact_type, "must be 'url', 'email', or 'none'")
    end
  end

  defp validate_url_format(changeset, url) do
    uri = URI.parse(url)

    if uri.scheme in ["http", "https"] && uri.host do
      changeset
    else
      add_error(changeset, :contact, "must be a valid URL with http:// or https://")
    end
  end

  defp validate_email_format(changeset, email) do
    if email =~ ~r/^[^\s]+@[^\s]+\.[^\s]+$/ do
      changeset
    else
      add_error(changeset, :contact, "must be a valid email address")
    end
  end

  defp infer_contact_type(changeset, contact) do
    cond do
      String.starts_with?(contact, "http://") || String.starts_with?(contact, "https://") ->
        changeset
        |> put_change(:contact_type, "url")
        |> validate_url_format(contact)

      contact =~ ~r/^[^\s]+@[^\s]+\.[^\s]+$/ ->
        changeset
        |> put_change(:contact_type, "email")

      true ->
        add_error(changeset, :contact_type, "could not infer contact type, please specify")
    end
  end
end
