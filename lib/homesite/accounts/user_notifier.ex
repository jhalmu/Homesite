defmodule Homesite.Accounts.UserNotifier do
  @moduledoc """
  Email notifications for user authentication and account management.

  Supports multilingual emails based on user's preferred_language setting.
  Registration emails are sent in both English and Finnish for clarity.
  """
  import Swoosh.Email

  alias Homesite.Accounts.User
  alias Homesite.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    from_email =
      System.get_env("SMTP_FROM") || System.get_env("SMTP_USERNAME") || "noreply@orangedinos.de"

    email =
      new()
      |> to(recipient)
      |> from({"Orangedinos", from_email})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  # Translation helper
  defp t(msgid), do: Gettext.gettext(HomesiteWeb.Gettext, msgid)
  defp t(msgid, bindings), do: Gettext.gettext(HomesiteWeb.Gettext, msgid, bindings)

  # Runs a function with the user's preferred locale
  defp with_locale(user, fun) do
    locale = user.preferred_language || "en"
    Gettext.with_locale(HomesiteWeb.Gettext, locale, fun)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    with_locale(user, fn ->
      deliver(user.email, t("Update email instructions"), """

      ==============================

      #{t("Hi %{email},", email: user.email)}

      #{t("You can change your email by visiting the URL below:")}

      #{url}

      #{t("If you didn't request this change, please ignore this.")}

      ==============================
      """)
    end)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    with_locale(user, fn ->
      deliver(user.email, t("Log in instructions"), """

      ==============================

      #{t("Hi %{email},", email: user.email)}

      #{t("You can log into your account by visiting the URL below:")}

      #{url}

      #{t("If you didn't request this email, please ignore this.")}

      ==============================
      """)
    end)
  end

  @doc """
  Deliver notification to admins when a new user registers.
  """
  def deliver_new_user_notification(admin_email, new_user) do
    deliver(admin_email, "New user registered", """

    ==============================

    A new user has registered on Orangedinos:

    Email: #{new_user.email}
    Registered: #{Calendar.strftime(DateTime.utc_now(), "%Y-%m-%d %H:%M UTC")}

    ==============================
    """)
  end

  # Registration confirmation is sent in both languages for new users
  defp deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirm your account / Vahvista tilisi", """

    ==============================
    ENGLISH / ENGLANNIKSI
    ==============================

    Hi #{user.email},

    Welcome to Orangedinos! You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    SUOMEKSI / IN FINNISH
    ==============================

    Hei #{user.email},

    Tervetuloa Orangedinos-palveluun! Voit vahvistaa tilisi alla olevasta linkistä:

    #{url}

    Jos et luonut tiliä, voit jättää tämän viestin huomiotta.

    ==============================
    """)
  end
end
