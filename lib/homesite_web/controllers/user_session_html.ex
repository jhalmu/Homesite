defmodule HomesiteWeb.UserSessionHTML do
  use HomesiteWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:homesite, Homesite.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
