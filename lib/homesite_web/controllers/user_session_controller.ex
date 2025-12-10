defmodule HomesiteWeb.UserSessionController do
  use HomesiteWeb, :controller

  alias Homesite.Accounts
  alias HomesiteWeb.UserAuth

  def create(conn, %{"_action" => "confirmed"} = params) do
    create(conn, params, "User confirmed successfully.")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  # magic link login
  defp create(conn, %{"user" => %{"token" => token} = user_params}, info) do
    case Accounts.login_user_by_magic_link(token) do
      {:ok, {user, tokens_to_disconnect}} ->
        # Log successful magic link login
        log_auth_event(conn, "magic_link_success", user.email, success: true, user: user)

        UserAuth.disconnect_sessions(tokens_to_disconnect)

        conn
        |> put_flash(:info, info)
        |> UserAuth.log_in_user(user, user_params)

      _ ->
        # Log failed magic link attempt (we don't know the email here)
        log_auth_event(conn, "magic_link_failure", "unknown", failure_reason: "invalid_or_expired_token")

        conn
        |> put_flash(:error, "The link is invalid or it has expired.")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  # email + password login
  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params
    ip_address = get_client_ip(conn)

    # Check for account lockout first
    if Accounts.account_locked_out?(email) do
      minutes = Accounts.lockout_remaining_minutes(email)

      log_auth_event(conn, "login_failure", email,
        failure_reason: "account_locked",
        metadata: %{lockout_remaining_minutes: minutes}
      )

      conn
      |> put_flash(:error, "Account temporarily locked. Try again in #{minutes} minutes.")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log-in")
    else
      if user = Accounts.get_user_by_email_and_password(email, password) do
        # Log successful login
        log_auth_event(conn, "login_success", email, success: true, user: user)

        conn
        |> put_flash(:info, info)
        |> UserAuth.log_in_user(user, user_params)
      else
        # Log failed login attempt
        log_auth_event(conn, "login_failure", email, failure_reason: "invalid_credentials")

        # Check for suspicious activity after logging
        check_and_log_suspicious_activity(email, ip_address)

        # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
        conn
        |> put_flash(:error, "Invalid email or password")
        |> put_flash(:email, String.slice(email, 0, 160))
        |> redirect(to: ~p"/users/log-in")
      end
    end
  end

  def update_password(conn, %{"user" => user_params} = params) do
    user = conn.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)
    {:ok, {_user, expired_tokens}} = Accounts.update_user_password(user, user_params)

    # Log password change
    log_auth_event(conn, "password_change", user.email, success: true, user: user)

    # disconnect all existing LiveViews with old sessions
    UserAuth.disconnect_sessions(expired_tokens)

    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end

  # Private helpers

  defp log_auth_event(conn, event_type, email, opts) do
    opts =
      opts
      |> Keyword.put_new(:ip_address, get_client_ip(conn))
      |> Keyword.put_new(:user_agent, get_user_agent(conn))

    Accounts.log_auth_event(event_type, email, opts)
  end

  defp get_client_ip(conn) do
    # Check for forwarded IP first (behind proxy/load balancer)
    forwarded_for =
      conn
      |> get_req_header("x-forwarded-for")
      |> List.first()

    case forwarded_for do
      nil ->
        conn.remote_ip |> :inet.ntoa() |> to_string()

      ip_list ->
        # Take the first IP (original client)
        ip_list |> String.split(",") |> List.first() |> String.trim()
    end
  end

  defp get_user_agent(conn) do
    conn
    |> get_req_header("user-agent")
    |> List.first()
    |> case do
      nil -> nil
      ua -> String.slice(ua, 0, 500)
    end
  end

  defp check_and_log_suspicious_activity(email, ip_address) do
    case Accounts.detect_suspicious_activity(email, ip_address: ip_address) do
      %{suspicious: true, reason: reason, details: details} ->
        Accounts.log_suspicious_activity(email, reason, details, ip_address: ip_address)

      _ ->
        :ok
    end
  end
end
