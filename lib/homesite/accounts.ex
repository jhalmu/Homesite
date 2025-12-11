defmodule Homesite.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Homesite.Repo

  alias Homesite.Accounts.{AuthLog, Invitation, User, UserNotifier, UserToken}

  # Account lockout settings
  @lockout_threshold 5
  @lockout_window_minutes 15
  @suspicious_threshold 10

  ## Database getters

  @doc """
  Returns the list of all users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Returns the list of all admin users.

  ## Examples

      iex> list_admins()
      [%User{role: "admin"}, ...]

  """
  def list_admins do
    from(u in User, where: u.role == "admin")
    |> Repo.all()
  end

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user with an invitation code.

  ## Examples

      iex> register_user(%{field: value, invitation_code: "ABC123XY"})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    invitation_code = Map.get(attrs, "invitation_code") || Map.get(attrs, :invitation_code)

    # Quick validation first (before transaction)
    case validate_invitation_for_registration(invitation_code) do
      :ok ->
        # CRITICAL: Wrap in transaction to ensure atomicity
        Repo.transaction(fn ->
          # Lock invitation row to prevent race conditions
          invitation =
            from(i in Invitation, where: i.code == ^invitation_code, lock: "FOR UPDATE")
            |> Repo.one()

          # Re-validate inside transaction (code could have been deleted or exhausted)
          cond do
            is_nil(invitation) ->
              Repo.rollback(:invitation_deleted)

            not Invitation.valid?(invitation) ->
              Repo.rollback(:invitation_invalid)

            true ->
              # Create user with invitation tracking
              # Apply password changeset only if password is provided (supports passwordless registration)
              changeset =
                %User{}
                |> User.email_changeset(attrs)
                |> maybe_apply_password_changeset(attrs)
                |> Ecto.Changeset.cast(%{invitation_code_used: invitation_code}, [
                  :invitation_code_used
                ])

              with {:ok, user} <- Repo.insert(changeset),
                   {:ok, _invitation} <- increment_invitation_usage(invitation) do
                user
              else
                {:error, changeset} -> Repo.rollback(changeset)
              end
          end
        end)
        |> case do
          {:ok, user} ->
            {:ok, user}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:error, changeset}

          {:error, reason} when reason in [:invitation_deleted, :invitation_invalid] ->
            {:error,
             %User{}
             |> User.email_changeset(attrs)
             |> Ecto.Changeset.add_error(:invitation_code, invitation_error_message(:not_found))
             |> Map.put(:action, :insert)}
        end

      {:error, reason} ->
        {:error,
         %User{}
         |> User.email_changeset(attrs)
         |> Ecto.Changeset.add_error(:invitation_code, invitation_error_message(reason))
         |> Map.put(:action, :insert)}
    end
  end

  # Helper function for atomically incrementing invitation usage
  defp increment_invitation_usage(invitation) do
    invitation
    |> Ecto.Changeset.change(current_uses: invitation.current_uses + 1)
    |> Repo.update()
  end

  # Helper function to conditionally apply password changeset
  # Supports both password-based and passwordless registration
  defp maybe_apply_password_changeset(changeset, attrs) do
    password = Map.get(attrs, "password") || Map.get(attrs, :password)

    if password && password != "" do
      User.password_changeset(changeset, attrs)
    else
      changeset
    end
  end

  @doc """
  Registers an admin user without requiring an invitation code.

  This is used by the seed_admin mix task and should NOT be used
  for regular user registration.

  ## Examples

      iex> register_admin(%{email: "admin@test.com", password: "pass123", role: "admin"})
      {:ok, %User{}}

  """
  def register_admin(attrs) do
    %User{}
    |> User.email_changeset(attrs)
    |> User.password_changeset(attrs)
    |> Ecto.Changeset.cast(attrs, [:role, :admin_flowers, :display_name])
    |> Repo.insert()
  end

  defp validate_invitation_for_registration(nil), do: {:error, :required}
  defp validate_invitation_for_registration(""), do: {:error, :required}
  defp validate_invitation_for_registration(code), do: validate_invitation(code)

  defp invitation_error_message(:required), do: "is required"
  defp invitation_error_message(:not_found), do: "is invalid"
  defp invitation_error_message(:expired), do: "has expired"
  defp invitation_error_message(:exhausted), do: "has been used too many times"
  defp invitation_error_message(_), do: "is invalid"

  ## Settings

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `Homesite.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `Homesite.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user profile.

  ## Examples

      iex> change_user_profile(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_profile(user, attrs \\ %{}) do
    User.profile_changeset(user, attrs)
  end

  @doc """
  Updates the user profile.

  If the user uploads a new avatar, the old avatar file is deleted.

  ## Examples

      iex> update_user_profile(user, %{display_name: "New Name"})
      {:ok, %User{}}

      iex> update_user_profile(user, %{website_url: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_profile(user, attrs) do
    # Delete old avatar file if a new one is being uploaded
    if Map.has_key?(attrs, "avatar") && attrs["avatar"] != user.avatar && user.avatar do
      delete_avatar_file(user.avatar)
    end

    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets the avatar URL for a user.

  Returns the uploaded avatar path if available, otherwise generates
  an SVG avatar with user initials.

  ## Examples

      iex> get_avatar_url(%User{avatar: "/uploads/avatars/123.jpg"})
      "/uploads/avatars/123.jpg"

      iex> get_avatar_url(%User{avatar: nil, id: 1, display_name: "John Doe"})
      "data:image/svg+xml;charset=utf-8,..."

  """
  def get_avatar_url(%User{avatar: avatar}) when is_binary(avatar) and avatar != "" do
    avatar
  end

  def get_avatar_url(user) do
    Homesite.Accounts.AvatarGenerator.generate_avatar(user)
  end

  @doc """
  Gets a user by username.

  ## Examples

      iex> get_user_by_username("johndoe")
      %User{}

      iex> get_user_by_username("nonexistent")
      nil

  """
  def get_user_by_username(username) when is_binary(username) do
    # Convert to lowercase for case-insensitive lookup (citext handles this at DB level)
    Repo.get_by(User, username: String.downcase(username))
  end

  @doc """
  Gets a user by identifier (either numeric ID or @username).

  Supports two formats:
  - Numeric ID: "123" or 123
  - Username with @ prefix: "@johndoe"

  ## Examples

      iex> get_user_by_identifier("123")
      %User{id: 123}

      iex> get_user_by_identifier("@johndoe")
      %User{username: "johndoe"}

      iex> get_user_by_identifier("@nonexistent")
      nil

  """
  def get_user_by_identifier("@" <> username) do
    get_user_by_username(username)
  end

  def get_user_by_identifier(id) when is_binary(id) do
    case Integer.parse(id) do
      {int_id, ""} -> Repo.get(User, int_id)
      _ -> nil
    end
  end

  def get_user_by_identifier(id) when is_integer(id) do
    Repo.get(User, id)
  end

  def get_user_by_identifier(_), do: nil

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the username.

  ## Examples

      iex> change_user_username(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_username(user, attrs \\ %{}) do
    User.username_changeset(user, attrs)
  end

  @doc """
  Updates the user's username.

  ## Examples

      iex> update_user_username(user, %{username: "johndoe"})
      {:ok, %User{}}

      iex> update_user_username(user, %{username: "a"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_username(user, attrs, opts \\ []) do
    old_username = user.username
    changeset = User.username_changeset(user, attrs)

    with {:ok, updated_user} <- Repo.update(changeset),
         new_username when new_username != old_username <- updated_user.username do
      # Log username change
      log_username_change(updated_user, old_username, new_username, opts)
      {:ok, updated_user}
    else
      {:error, _} = error -> error
      _ -> {:ok, changeset |> Ecto.Changeset.apply_changes()}
    end
  end

  defp log_username_change(user, old_username, new_username, opts) do
    attrs = %{
      user_id: user.id,
      old_username: old_username,
      new_username: new_username,
      changed_at: DateTime.utc_now(:second),
      ip_address: Keyword.get(opts, :ip_address),
      user_agent: Keyword.get(opts, :user_agent)
    }

    %Homesite.Accounts.UsernameChange{}
    |> Homesite.Accounts.UsernameChange.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Lists username change history for a user.

  Returns changes ordered by most recent first.

  ## Examples

      iex> list_username_changes(user_id)
      [%UsernameChange{}, ...]

  """
  def list_username_changes(user_id) do
    Homesite.Accounts.UsernameChange
    |> where([c], c.user_id == ^user_id)
    |> order_by([c], desc: c.changed_at)
    |> Repo.all()
  end

  @doc """
  Deletes an avatar file from disk.

  ## Examples

      iex> delete_avatar_file("/uploads/avatars/123.jpg")
      :ok

  """
  def delete_avatar_file(avatar_path) when is_binary(avatar_path) do
    full_path = Path.join(["priv", "static", avatar_path])

    if File.exists?(full_path) do
      File.rm!(full_path)
    end

    :ok
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the user with the given magic link token.
  """
  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Logs the user in by magic link.

  There are three cases to consider:

  1. The user has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The user has not confirmed their email and no password is set.
     In this case, the user gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The user has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      # Prevent session fixation attacks by disallowing magic links for unconfirmed users with password
      {%User{confirmed_at: nil, hashed_password: hash}, _token} when not is_nil(hash) ->
        raise """
        magic link log in is not allowed for unconfirmed users with a password set!

        This cannot happen with the default implementation, which indicates that you
        might have adapted the code to a different use case. Please make sure to read the
        "Mixing magic link and password registration" section of `mix help phx.gen.auth`.
        """

      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, {user, []}}

      nil ->
        {:error, :not_found}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Delivers the magic link login instructions to the given user.
  """
  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Admin User Management

  @doc """
  Returns a paginated list of users with optional search.

  ## Options

    * `:page` - Page number (default: 1)
    * `:per_page` - Number of users per page (default: 20)
    * `:search` - Search query for email filtering

  ## Examples

      iex> list_users_paginated(page: 1, per_page: 20)
      [%User{}, ...]

      iex> list_users_paginated(page: 1, per_page: 20, search: "admin")
      [%User{email: "admin@example.com"}, ...]

  """
  def list_users_paginated(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 20)
    search = Keyword.get(opts, :search, nil)

    offset = (page - 1) * per_page

    query =
      from u in User,
        order_by: [desc: u.inserted_at],
        limit: ^per_page,
        offset: ^offset

    query =
      if search && search != "" do
        search_pattern = "%#{search}%"
        from u in query, where: ilike(u.email, ^search_pattern)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Counts total users, optionally filtered by search query.

  ## Examples

      iex> count_users()
      42

      iex> count_users(search: "admin")
      3

  """
  def count_users(opts \\ []) do
    search = Keyword.get(opts, :search, nil)

    query = from(u in User, select: count(u.id))

    query =
      if search && search != "" do
        search_pattern = "%#{search}%"
        from u in query, where: ilike(u.email, ^search_pattern)
      else
        query
      end

    Repo.one(query)
  end

  @doc """
  Updates a user's admin settings (role and flower permissions).

  Only admins should be able to call this function.

  ## Examples

      iex> update_user_admin_settings(user, %{role: "admin", admin_flowers: 5})
      {:ok, %User{}}

      iex> update_user_admin_settings(user, %{admin_flowers: 10})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_admin_settings(user, attrs) do
    changeset =
      user
      |> Ecto.Changeset.cast(attrs, [:role, :admin_flowers])
      |> Ecto.Changeset.validate_required([:role])
      |> Ecto.Changeset.validate_inclusion(:role, ["user", "admin"])
      |> Ecto.Changeset.validate_inclusion(:admin_flowers, 0..5)

    Repo.update(changeset)
  end

  @doc """
  Gets user statistics including post count and tag count.

  Returns a map with user and their statistics.

  ## Examples

      iex> get_user_with_stats(user_id)
      %{user: %User{}, post_count: 5, tag_count: 3}

  """
  def get_user_with_stats(user_id) do
    user = get_user!(user_id)

    post_count =
      Repo.one(
        from p in Homesite.Content.Post,
          where: p.user_id == ^user_id,
          select: count(p.id)
      )

    tag_count =
      Repo.one(
        from t in Homesite.Content.Tag,
          where: t.user_id == ^user_id,
          select: count(t.id)
      )

    %{
      user: user,
      post_count: post_count,
      tag_count: tag_count
    }
  end

  ## Invitations

  @doc """
  Creates an invitation code.

  ## Examples

      iex> create_invitation(%User{id: 1}, %{max_uses: 5, expires_at: ~U[2025-12-31 23:59:59Z]})
      {:ok, %Invitation{}}

      iex> create_invitation(%User{id: 1}, %{})
      {:ok, %Invitation{}}

  """
  def create_invitation(%User{} = creator, attrs \\ %{}) do
    # Normalize to string keys to avoid mixed key errors
    attrs =
      attrs
      |> Enum.into(%{}, fn
        {k, v} when is_atom(k) -> {Atom.to_string(k), v}
        {k, v} -> {k, v}
      end)
      |> Map.put_new("code", Invitation.generate_code())
      |> Map.put("created_by_user_id", creator.id)

    %Invitation{}
    |> Invitation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets an invitation by code.

  Returns `nil` if the invitation does not exist.

  ## Examples

      iex> get_invitation_by_code("ABC123XY")
      %Invitation{}

      iex> get_invitation_by_code("INVALID")
      nil

  """
  def get_invitation_by_code(code) when is_binary(code) do
    Repo.get_by(Invitation, code: code)
    |> Repo.preload(:created_by)
  end

  @doc """
  Gets a single invitation.

  Raises `Ecto.NoResultsError` if the Invitation does not exist.

  ## Examples

      iex> get_invitation!(123)
      %Invitation{}

      iex> get_invitation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_invitation!(id) do
    Repo.get!(Invitation, id)
    |> Repo.preload(:created_by)
  end

  @doc """
  Validates an invitation code and returns `:ok` or `{:error, reason}`.

  ## Examples

      iex> validate_invitation("ABC123XY")
      :ok

      iex> validate_invitation("INVALID")
      {:error, :not_found}

      iex> validate_invitation("EXPIRED")
      {:error, :expired}

      iex> validate_invitation("EXHAUSTED")
      {:error, :exhausted}

  """
  def validate_invitation(code) when is_binary(code) do
    case get_invitation_by_code(code) do
      nil ->
        {:error, :not_found}

      invitation ->
        cond do
          not Invitation.not_expired?(invitation) ->
            {:error, :expired}

          not Invitation.not_exhausted?(invitation) ->
            {:error, :exhausted}

          true ->
            :ok
        end
    end
  end

  @doc """
  Uses an invitation (increments current_uses).

  Returns `{:ok, invitation}` if successful, `{:error, reason}` otherwise.

  ## Examples

      iex> use_invitation("ABC123XY")
      {:ok, %Invitation{current_uses: 1}}

  """
  def use_invitation(code) when is_binary(code) do
    case get_invitation_by_code(code) do
      nil ->
        {:error, :not_found}

      invitation ->
        if Invitation.valid?(invitation) do
          invitation
          |> Ecto.Changeset.change(current_uses: invitation.current_uses + 1)
          |> Repo.update()
        else
          {:error, :invalid}
        end
    end
  end

  @doc """
  Lists all invitations created by a user.

  ## Examples

      iex> list_invitations(%User{id: 1})
      [%Invitation{}, ...]

  """
  def list_invitations(%User{} = user) do
    from(i in Invitation,
      where: i.created_by_user_id == ^user.id,
      order_by: [desc: i.inserted_at],
      preload: [:created_by]
    )
    |> Repo.all()
  end

  @doc """
  Lists all invitations (admin only).

  ## Examples

      iex> list_all_invitations()
      [%Invitation{}, ...]

  """
  def list_all_invitations do
    from(i in Invitation,
      order_by: [desc: i.inserted_at],
      preload: [:created_by]
    )
    |> Repo.all()
  end

  @doc """
  Deletes an invitation.

  ## Examples

      iex> delete_invitation(invitation)
      {:ok, %Invitation{}}

      iex> delete_invitation(invitation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_invitation(%Invitation{} = invitation) do
    Repo.delete(invitation)
  end

  ## Analytics

  @doc """
  Returns comprehensive user statistics for the analytics dashboard.

  Returns a map with:
  - `total_users`: Total registered users
  - `new_users_7d`: New signups in last 7 days
  - `new_users_30d`: New signups in last 30 days
  - `admin_count`: Number of admin users
  - `user_growth`: List of daily signup counts for last 30 days

  ## Examples

      iex> get_user_stats()
      %{
        total_users: 150,
        new_users_7d: 12,
        new_users_30d: 45,
        admin_count: 3,
        user_growth: [...]
      }

  """
  def get_user_stats do
    now = DateTime.utc_now(:second)
    seven_days_ago = DateTime.add(now, -7, :day)
    thirty_days_ago = DateTime.add(now, -30, :day)

    total_users = Repo.aggregate(User, :count, :id)

    new_users_7d =
      from(u in User, where: u.inserted_at >= ^seven_days_ago)
      |> Repo.aggregate(:count, :id)

    new_users_30d =
      from(u in User, where: u.inserted_at >= ^thirty_days_ago)
      |> Repo.aggregate(:count, :id)

    admin_count =
      from(u in User, where: u.role == "admin")
      |> Repo.aggregate(:count, :id)

    # User growth - daily signups for last 30 days
    user_growth =
      from(u in User,
        where: u.inserted_at >= ^thirty_days_ago,
        group_by: fragment("DATE(?)", u.inserted_at),
        select: %{
          date: fragment("DATE(?)", u.inserted_at),
          count: count(u.id)
        },
        order_by: fragment("DATE(?) ASC", u.inserted_at)
      )
      |> Repo.all()

    %{
      total_users: total_users,
      new_users_7d: new_users_7d,
      new_users_30d: new_users_30d,
      admin_count: admin_count,
      user_growth: user_growth
    }
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {user, tokens_to_expire}}
      end
    end)
  end

  ## Authentication Logging & Security

  @doc """
  Logs an authentication event.

  ## Parameters
  - `event_type` - Type of event (see AuthLog.event_types/0)
  - `email` - Email address involved
  - `opts` - Optional parameters:
    - `:success` - Whether the event was successful (default: false)
    - `:user` - User struct if known
    - `:ip_address` - Client IP address
    - `:user_agent` - Client user agent
    - `:failure_reason` - Reason for failure if applicable
    - `:metadata` - Additional metadata map

  ## Examples

      iex> log_auth_event("login_success", "user@example.com", success: true, user: user)
      {:ok, %AuthLog{}}

      iex> log_auth_event("login_failure", "user@example.com", failure_reason: "invalid_password")
      {:ok, %AuthLog{}}

  """
  def log_auth_event(event_type, email, opts \\ []) do
    attrs = %{
      event_type: event_type,
      email: email,
      success: Keyword.get(opts, :success, false),
      user_id: get_in(opts, [:user, Access.key(:id)]),
      ip_address: Keyword.get(opts, :ip_address),
      user_agent: Keyword.get(opts, :user_agent),
      failure_reason: Keyword.get(opts, :failure_reason),
      metadata: Keyword.get(opts, :metadata, %{})
    }

    %AuthLog{}
    |> AuthLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Checks if an account is locked out due to too many failed login attempts.

  Returns `true` if the account should be locked out.

  ## Examples

      iex> account_locked_out?("user@example.com")
      false

      iex> account_locked_out?("attacker@example.com")
      true

  """
  def account_locked_out?(email) when is_binary(email) do
    window_start = DateTime.add(DateTime.utc_now(), -@lockout_window_minutes, :minute)

    count =
      from(l in AuthLog,
        where: l.email == ^email,
        where: l.success == false,
        where: l.event_type in ["login_failure", "magic_link_failure"],
        where: l.inserted_at >= ^window_start,
        select: count(l.id)
      )
      |> Repo.one()

    count >= @lockout_threshold
  end

  @doc """
  Returns the number of minutes remaining in the lockout period.

  Returns `0` if not locked out.

  ## Examples

      iex> lockout_remaining_minutes("user@example.com")
      0

      iex> lockout_remaining_minutes("locked@example.com")
      12

  """
  def lockout_remaining_minutes(email) when is_binary(email) do
    window_start = DateTime.add(DateTime.utc_now(), -@lockout_window_minutes, :minute)

    oldest_failure =
      from(l in AuthLog,
        where: l.email == ^email,
        where: l.success == false,
        where: l.event_type in ["login_failure", "magic_link_failure"],
        where: l.inserted_at >= ^window_start,
        order_by: [asc: l.inserted_at],
        limit: 1,
        select: l.inserted_at
      )
      |> Repo.one()

    case oldest_failure do
      nil ->
        0

      timestamp ->
        # Convert NaiveDateTime to DateTime (inserted_at is naive)
        {:ok, datetime} = DateTime.from_naive(timestamp, "Etc/UTC")
        lockout_ends = DateTime.add(datetime, @lockout_window_minutes, :minute)
        diff = DateTime.diff(lockout_ends, DateTime.utc_now(), :minute)
        max(0, diff)
    end
  end

  @doc """
  Detects suspicious activity patterns for an email or IP.

  Returns a map with detection results:
  - `:suspicious` - boolean indicating if activity is suspicious
  - `:reason` - reason for suspicion if applicable
  - `:details` - additional details

  ## Examples

      iex> detect_suspicious_activity("user@example.com", ip_address: "1.2.3.4")
      %{suspicious: false, reason: nil, details: %{}}

  """
  def detect_suspicious_activity(email, opts \\ []) do
    ip_address = Keyword.get(opts, :ip_address)
    window_start = DateTime.add(DateTime.utc_now(), -60, :minute)

    # Check for rapid failures from same email
    email_failures =
      from(l in AuthLog,
        where: l.email == ^email,
        where: l.success == false,
        where: l.inserted_at >= ^window_start,
        select: count(l.id)
      )
      |> Repo.one()

    # Check for failures from same IP across different emails
    ip_failures =
      if ip_address do
        from(l in AuthLog,
          where: l.ip_address == ^ip_address,
          where: l.success == false,
          where: l.inserted_at >= ^window_start,
          select: count(l.id)
        )
        |> Repo.one()
      else
        0
      end

    # Check for multiple emails from same IP (credential stuffing indicator)
    unique_emails_from_ip =
      if ip_address do
        from(l in AuthLog,
          where: l.ip_address == ^ip_address,
          where: l.inserted_at >= ^window_start,
          select: count(l.email, :distinct)
        )
        |> Repo.one()
      else
        0
      end

    cond do
      email_failures >= @suspicious_threshold ->
        %{
          suspicious: true,
          reason: "high_failure_rate",
          details: %{failures: email_failures, window_minutes: 60}
        }

      ip_failures >= @suspicious_threshold * 2 ->
        %{
          suspicious: true,
          reason: "ip_abuse",
          details: %{ip_failures: ip_failures, window_minutes: 60}
        }

      unique_emails_from_ip >= 5 ->
        %{
          suspicious: true,
          reason: "credential_stuffing",
          details: %{unique_emails: unique_emails_from_ip, window_minutes: 60}
        }

      true ->
        %{suspicious: false, reason: nil, details: %{}}
    end
  end

  @doc """
  Logs suspicious activity and optionally notifies admins.

  ## Examples

      iex> log_suspicious_activity("attacker@example.com", "credential_stuffing", %{ip: "1.2.3.4"})
      {:ok, %AuthLog{}}

  """
  def log_suspicious_activity(email, reason, details \\ %{}, opts \\ []) do
    log_auth_event("suspicious_activity", email,
      success: false,
      failure_reason: reason,
      metadata: details,
      ip_address: Keyword.get(opts, :ip_address),
      user_agent: Keyword.get(opts, :user_agent)
    )

    # Notify all admins about suspicious activity
    notify_admins_suspicious_activity(email, reason, details)
  end

  # Notifies all admin users about suspicious activity
  defp notify_admins_suspicious_activity(email, reason, details) do
    alias Homesite.Notifications

    for admin <- list_admins() do
      Notifications.create_notification(
        admin.id,
        "suspicious_activity",
        nil,
        %{
          "email" => email,
          "reason" => reason,
          "details" => details
        }
      )
    end

    :ok
  end

  @doc """
  Returns recent auth logs for an email (for admin review).

  ## Examples

      iex> get_auth_logs_for_email("user@example.com", limit: 20)
      [%AuthLog{}, ...]

  """
  def get_auth_logs_for_email(email, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    from(l in AuthLog,
      where: l.email == ^email,
      order_by: [desc: l.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Returns recent auth logs for an IP address (for admin review).

  ## Examples

      iex> get_auth_logs_for_ip("192.168.1.1", limit: 20)
      [%AuthLog{}, ...]

  """
  def get_auth_logs_for_ip(ip_address, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    from(l in AuthLog,
      where: l.ip_address == ^ip_address,
      order_by: [desc: l.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Returns auth statistics for the analytics dashboard.

  ## Examples

      iex> get_auth_stats()
      %{
        total_logins_24h: 150,
        failed_logins_24h: 12,
        locked_accounts: 2,
        suspicious_ips: ["1.2.3.4"]
      }

  """
  def get_auth_stats do
    now = DateTime.utc_now()
    day_ago = DateTime.add(now, -24, :hour)
    window_start = DateTime.add(now, -@lockout_window_minutes, :minute)

    total_logins =
      from(l in AuthLog,
        where: l.event_type in ["login_success", "magic_link_success"],
        where: l.inserted_at >= ^day_ago,
        select: count(l.id)
      )
      |> Repo.one()

    failed_logins =
      from(l in AuthLog,
        where: l.event_type in ["login_failure", "magic_link_failure"],
        where: l.inserted_at >= ^day_ago,
        select: count(l.id)
      )
      |> Repo.one()

    # Find currently locked out emails
    locked_emails =
      from(l in AuthLog,
        where: l.success == false,
        where: l.event_type in ["login_failure", "magic_link_failure"],
        where: l.inserted_at >= ^window_start,
        group_by: l.email,
        having: count(l.id) >= ^@lockout_threshold,
        select: l.email
      )
      |> Repo.all()

    # Find suspicious IPs (many failures)
    suspicious_ips =
      from(l in AuthLog,
        where: l.success == false,
        where: l.inserted_at >= ^day_ago,
        where: not is_nil(l.ip_address),
        group_by: l.ip_address,
        having: count(l.id) >= ^@suspicious_threshold,
        select: l.ip_address
      )
      |> Repo.all()

    %{
      total_logins_24h: total_logins,
      failed_logins_24h: failed_logins,
      locked_accounts: length(locked_emails),
      locked_emails: locked_emails,
      suspicious_ips: suspicious_ips
    }
  end

  ## Notification Preferences

  @doc """
  Gets a user by ID for profile viewing.
  """
  def get_user_profile(user_id) when is_integer(user_id) do
    Repo.get(User, user_id)
  end

  @doc """
  Gets notification preferences for the current user.
  Returns the stored preferences or defaults if nil.
  """
  def get_notification_preferences(%Homesite.Accounts.Scope{} = scope) do
    scope.user.notification_preferences ||
      %{"new_follower" => true, "show_toast" => true}
  end

  @doc """
  Updates notification preferences for the current user.
  """
  def update_notification_preferences(%Homesite.Accounts.Scope{} = scope, preferences)
      when is_map(preferences) do
    scope.user
    |> User.notification_preferences_changeset(preferences)
    |> Repo.update()
  end

  @doc """
  Checks if a user wants notifications of a specific type.
  """
  def notification_enabled?(%User{} = user, type) when is_binary(type) do
    prefs = user.notification_preferences || %{}
    Map.get(prefs, type, true)
  end
end
