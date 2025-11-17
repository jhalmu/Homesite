defmodule HomesiteWeb.PageController do
  use HomesiteWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
