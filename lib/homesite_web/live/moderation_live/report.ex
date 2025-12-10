defmodule HomesiteWeb.ModerationLive.Report do
  @moduledoc """
  LiveView for reporting a user.

  Users can submit reports about other users for admin review.
  """
  use HomesiteWeb, :live_view

  alias Homesite.Accounts
  alias Homesite.Moderation

  @impl true
  def mount(%{"user_id" => user_id}, _session, socket) do
    user_id = String.to_integer(user_id)
    current_user = socket.assigns.current_scope.user

    # Can't report yourself
    if user_id == current_user.id do
      {:ok,
       socket
       |> put_flash(:error, gettext("You cannot report yourself"))
       |> redirect(to: ~p"/dashboard")}
    else
      try do
        reported_user = Accounts.get_user!(user_id)

        {:ok,
         socket
         |> assign(:page_title, gettext("Report User"))
         |> assign(:reported_user, reported_user)
         |> assign(:form, to_form(%{"reason" => ""}))}
      rescue
        Ecto.NoResultsError ->
          {:ok,
           socket
           |> put_flash(:error, gettext("User not found"))
           |> redirect(to: ~p"/dashboard")}
      end
    end
  end

  @impl true
  def handle_event("validate", %{"reason" => reason}, socket) do
    {:noreply, assign(socket, :form, to_form(%{"reason" => reason}))}
  end

  @impl true
  def handle_event("submit", %{"reason" => reason}, socket) do
    scope = socket.assigns.current_scope
    reported_user = socket.assigns.reported_user

    # Add metadata about where the report came from
    metadata = %{
      reported_from: "web",
      reporter_ip: to_string(:inet.ntoa(socket.assigns[:peer_ip] || {0, 0, 0, 0}))
    }

    case Moderation.create_report(scope, reported_user.id, reason, metadata) do
      {:ok, _report} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Report submitted successfully. Our team will review it."))
         |> redirect(to: ~p"/dashboard")}

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = format_errors(changeset)

        {:noreply,
         socket
         |> put_flash(:error, errors)
         |> assign(:form, to_form(%{"reason" => reason}))}
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Report User")}
        <:subtitle>
          {gettext("Report %{user} for violating community guidelines",
            user: @reported_user.display_name || @reported_user.email
          )}
        </:subtitle>
      </.header>

      <div class="mt-6 max-w-2xl">
        <div class="alert alert-warning mb-6">
          <.icon name="hero-exclamation-triangle" class="h-5 w-5" />
          <span>
            {gettext(
              "Please provide a detailed description of why you are reporting this user. False reports may result in action against your account."
            )}
          </span>
        </div>

        <div class="card bg-base-200 mb-6">
          <div class="card-body">
            <h3 class="card-title text-sm">{gettext("User being reported")}</h3>
            <div class="flex items-center gap-3">
              <div class="avatar placeholder">
                <div class="bg-neutral text-neutral-content w-12 rounded-full">
                  <span>
                    {String.first(@reported_user.email) |> String.upcase()}
                  </span>
                </div>
              </div>
              <div>
                <div class="font-bold">
                  {@reported_user.display_name || @reported_user.email}
                </div>
                <%= if @reported_user.display_name do %>
                  <div class="text-sm opacity-50">{@reported_user.email}</div>
                <% end %>
              </div>
            </div>
          </div>
        </div>

        <.form for={@form} phx-change="validate" phx-submit="submit" id="report-form">
          <div class="form-control">
            <label class="label">
              <span class="label-text font-medium">{gettext("Reason for reporting")}</span>
            </label>
            <textarea
              name="reason"
              class="textarea textarea-bordered h-32"
              placeholder={
                gettext(
                  "Please describe in detail why you are reporting this user. Include specific examples if possible..."
                )
              }
              required
              minlength="10"
              maxlength="5000"
            >{@form[:reason].value}</textarea>
            <label class="label">
              <span class="label-text-alt text-base-content/60">
                {gettext("Minimum 10 characters required")}
              </span>
              <span class="label-text-alt">
                {String.length(@form[:reason].value || "")}/5000
              </span>
            </label>
          </div>

          <div class="mt-6 flex gap-4">
            <button type="submit" class="btn btn-primary">
              <.icon name="hero-flag" class="h-4 w-4" />
              {gettext("Submit Report")}
            </button>
            <.link navigate={~p"/dashboard"} class="btn btn-ghost">
              {gettext("Cancel")}
            </.link>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end
end
