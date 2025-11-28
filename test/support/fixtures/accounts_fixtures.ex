defmodule Homesite.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Homesite.Accounts` context.
  """

  import Ecto.Query

  alias Homesite.Accounts
  alias Homesite.Accounts.Scope

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    # Merge attrs into defaults, ensuring invitation_code is always present
    # Convert attrs to map in case it's a keyword list
    attrs = Enum.into(attrs, %{})

    defaults = %{
      email: unique_user_email(),
      password: valid_user_password()
    }

    defaults
    |> Map.merge(attrs)
    |> Map.put_new(:invitation_code, "TEST-INVITE")
  end

  def unconfirmed_user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Accounts.register_user()

    user
  end

  @doc """
  Creates an unconfirmed user WITHOUT a password (for magic-link only flow).
  This bypasses the invitation requirement by directly inserting into DB.
  """
  def unconfirmed_user_fixture_no_password(attrs \\ %{}) do
    attrs = Enum.into(attrs, %{email: unique_user_email()})

    %Homesite.Accounts.User{}
    |> Ecto.Changeset.change(attrs)
    |> Homesite.Repo.insert!()
  end

  def user_fixture(attrs \\ %{}) do
    user = unconfirmed_user_fixture(attrs)

    # Manually confirm the user (simpler than magic link for password-based users)
    # Use :second precision to match database schema
    user
    |> Ecto.Changeset.change(%{confirmed_at: DateTime.utc_now(:second)})
    |> Homesite.Repo.update!()
  end

  def user_scope_fixture do
    user = user_fixture()
    user_scope_fixture(user)
  end

  def user_scope_fixture(user) do
    Scope.for_user(user)
  end

  def set_password(user) do
    {:ok, {user, _expired_tokens}} =
      Accounts.update_user_password(user, %{password: valid_user_password()})

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def override_token_authenticated_at(token, authenticated_at) when is_binary(token) do
    Homesite.Repo.update_all(
      from(t in Accounts.UserToken,
        where: t.token == ^token
      ),
      set: [authenticated_at: authenticated_at]
    )
  end

  def generate_user_magic_link_token(user) do
    {encoded_token, user_token} = Accounts.UserToken.build_email_token(user, "login")
    Homesite.Repo.insert!(user_token)
    {encoded_token, user_token.token}
  end

  def offset_user_token(token, amount_to_add, unit) do
    dt = DateTime.add(DateTime.utc_now(:second), amount_to_add, unit)

    Homesite.Repo.update_all(
      from(ut in Accounts.UserToken, where: ut.token == ^token),
      set: [inserted_at: dt, authenticated_at: dt]
    )
  end
end
