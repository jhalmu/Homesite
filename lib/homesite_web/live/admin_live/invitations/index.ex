defmodule HomesiteWeb.AdminLive.Invitations.Index do
  @moduledoc """
  LiveView for managing invitation codes (admin only).
  """
  use HomesiteWeb, :live_view

  import HomesiteWeb.Helpers.DateHelpers

  alias Homesite.Accounts
  alias Homesite.Accounts.Invitation

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    # Verify admin access
    if Accounts.Scope.admin?(scope) do
      invitations = Accounts.list_all_invitations()

      socket =
        socket
        |> assign(:page_title, "Manage Invitations")
        |> assign(:invitations, invitations)
        |> assign(:form, nil)

      {:ok, socket}
    else
      socket =
        socket
        |> put_flash(:error, "You must be an admin to access this page.")
        |> redirect(to: ~p"/dashboard")

      {:ok, socket}
    end
  end

  @impl true
  def handle_event("new", _params, socket) do
    changeset = Invitation.changeset(%Invitation{}, %{})

    socket =
      socket
      |> assign(:form, to_form(changeset))
      |> assign(:invitation, nil)
      |> assign(:default_expires_at, default_expires_at())

    {:noreply, socket}
  end

  @impl true
  def handle_event("create", %{"invitation" => invitation_params}, socket) do
    scope = socket.assigns.current_scope

    # Generate code if not provided
    attrs =
      invitation_params
      |> Map.put_new("code", Invitation.generate_code())
      |> maybe_parse_expires_at()

    case Accounts.create_invitation(scope.user, attrs) do
      {:ok, _invitation} ->
        invitations = Accounts.list_all_invitations()

        socket =
          socket
          |> put_flash(:info, "Invitation created successfully")
          |> assign(:form, nil)
          |> assign(:invitations, invitations)

        {:noreply, socket}

      {:error, changeset} ->
        socket = assign(socket, :form, to_form(changeset))
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    {:noreply, assign(socket, :form, nil)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    invitation = Accounts.get_invitation!(id)

    case Accounts.delete_invitation(invitation) do
      {:ok, _invitation} ->
        invitations = Accounts.list_all_invitations()

        socket =
          socket
          |> put_flash(:info, "Invitation deleted successfully")
          |> assign(:invitations, invitations)

        {:noreply, socket}

      {:error, _changeset} ->
        socket = put_flash(socket, :error, "Failed to delete invitation")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("copy", %{"code" => _code}, socket) do
    # This is handled by JavaScript on the client side
    # Just return success flash
    socket = put_flash(socket, :info, "Code copied to clipboard!")
    {:noreply, socket}
  end

  defp maybe_parse_expires_at(attrs) do
    case Map.get(attrs, "expires_at") do
      nil ->
        attrs

      "" ->
        Map.put(attrs, "expires_at", nil)

      datetime_string ->
        case DateTime.from_iso8601(datetime_string <> ":00Z") do
          {:ok, datetime, _offset} ->
            Map.put(attrs, "expires_at", datetime)

          _ ->
            attrs
        end
    end
  end

  defp default_expires_at do
    DateTime.utc_now()
    |> DateTime.add(1, :day)
    |> DateTime.truncate(:second)
    |> Calendar.strftime("%Y-%m-%dT%H:%M")
  end
end
