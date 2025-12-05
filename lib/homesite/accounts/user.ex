defmodule Homesite.Accounts.User do
  @moduledoc """
  User schema with authentication and content ownership.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @reserved_usernames ~w[
    admin api app auth blog dashboard dev docs feed feeds help
    home login logout new posts public register rss search settings
    signup staff static support system tags test user users www
  ]

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :utc_datetime
    field :authenticated_at, :utc_datetime, virtual: true

    # Profile fields
    field :display_name, :string
    field :avatar, :string
    field :bio, :string
    field :website_url, :string
    field :bluesky_handle, :string
    field :mastodon_handle, :string

    # Admin fields
    field :role, :string, default: "user"
    field :admin_flowers, :integer, default: 0

    # Localization
    field :preferred_language, :string, default: "en"

    # Username for URL routing (optional)
    field :username, :string

    # Invitation tracking (audit trail)
    field :invitation_code_used, :string

    # Feedback system fields
    field :rank, :integer, default: 1
    field :rank_updated_at, :utc_datetime
    field :last_feedback_prompt_at, :utc_datetime
    field :feedback_prompt_preference, :string, default: "normal"
    field :positive_feedback_count, :integer, default: 0
    field :negative_feedback_count, :integer, default: 0

    has_many :posts, Homesite.Content.Post
    has_many :tags, Homesite.Content.Tag
    has_many :feed_sources, Homesite.ExternalFeeds.FeedSource
    has_many :feedback_responses, Homesite.Feedback.FeedbackResponse

    timestamps(type: :utc_datetime)
  end

  @doc """
  Returns true if the user is an admin.
  """
  def admin?(%__MODULE__{role: "admin"}), do: true
  def admin?(_user), do: false

  @doc """
  Returns the number of flower permissions (1-5) for admin users, 0 for regular users.
  """
  def flower_count(%__MODULE__{role: "admin", admin_flowers: count}), do: count
  def flower_count(_user), do: 0

  @doc """
  Returns true if the user has opted out of feedback prompts.
  """
  def feedback_opted_out?(%__MODULE__{feedback_prompt_preference: "opted_out"}), do: true
  def feedback_opted_out?(_user), do: false

  @doc """
  Returns the user's rank (1-10 scale).

  For admins, maps admin_flowers (1-5) to rank (2, 4, 6, 8, 10) by multiplying by 2.
  For regular users, returns the calculated rank field (default 1).
  """
  def get_rank(%__MODULE__{role: "admin", admin_flowers: flowers}) when is_integer(flowers) do
    flowers * 2
  end

  def get_rank(%__MODULE__{rank: rank}) when is_integer(rank), do: rank
  def get_rank(_user), do: 1

  @doc """
  A user changeset for registering or changing the email.

  It requires the email to change otherwise an error is added.

  ## Options

    * `:validate_unique` - Set to false if you don't want to validate the
      uniqueness of the email, useful when displaying live validations.
      Defaults to `true`.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :preferred_language])
    |> validate_email(opts)
    |> validate_inclusion(:preferred_language, ["en", "fi"])
  end

  defp validate_email(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: "must have the @ sign and no spaces"
      )
      |> validate_length(:email, max: 160)

    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:email, Homesite.Repo)
      |> unique_constraint(:email)
      |> validate_email_changed()
    else
      changeset
    end
  end

  defp validate_email_changed(changeset) do
    if get_field(changeset, :email) && get_change(changeset, :email) == nil do
      add_error(changeset, :email, "did not change")
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the password.

  It is important to validate the length of the password, as long passwords may
  be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Argon2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  A user changeset for updating profile information.

  Validates display name, bio, URLs, and social media handles.
  """
  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :display_name,
      :avatar,
      :bio,
      :website_url,
      :bluesky_handle,
      :mastodon_handle,
      :preferred_language,
      :username
    ])
    |> validate_length(:display_name, max: 100)
    |> validate_length(:bio, max: 500)
    |> validate_url(:website_url)
    |> validate_social_handle(:bluesky_handle)
    |> validate_social_handle(:mastodon_handle)
    |> validate_inclusion(:preferred_language, ["en", "fi"])
    |> validate_username()
  end

  @doc """
  A user changeset for updating username.

  Validates username format, uniqueness, and reserved names.
  """
  def username_changeset(user, attrs) do
    user
    |> cast(attrs, [:username])
    |> validate_username()
  end

  defp validate_username(changeset) do
    changeset
    |> validate_length(:username, min: 3, max: 30)
    |> validate_format(:username, ~r/^[a-z][a-z0-9_]{2,29}$/,
      message: "must start with letter, lowercase alphanumeric/underscore only"
    )
    |> validate_not_reserved(:username)
    |> unsafe_validate_unique(:username, Homesite.Repo)
    |> unique_constraint(:username)
  end

  defp validate_not_reserved(changeset, field) do
    username = get_change(changeset, field)

    if username && username in @reserved_usernames do
      add_error(changeset, field, "is reserved and cannot be used")
    else
      changeset
    end
  end

  defp validate_url(changeset, field) do
    case get_change(changeset, field) do
      nil ->
        changeset

      "" ->
        changeset

      url ->
        if String.match?(url, ~r/^https?:\/\/.+\..+/i) do
          changeset
        else
          add_error(changeset, field, "must be a valid URL starting with http:// or https://")
        end
    end
  end

  defp validate_social_handle(changeset, field) do
    changeset
    |> validate_length(field, max: 255)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Argon2.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Homesite.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Argon2.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Argon2.no_user_verify()
    false
  end
end
