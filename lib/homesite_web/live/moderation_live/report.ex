defmodule HomesiteWeb.ModerationLive.Report do
  @moduledoc """
  LiveView for reporting a user.

  Users can submit reports about other users for admin review.
  Supports content context (e.g., reporting from a chat message or post)
  and reason presets for common report types.
  """
  use HomesiteWeb, :live_view

  alias Homesite.Accounts
  alias Homesite.Moderation
  alias Homesite.Moderation.ReasonPreset

  @impl true
  def mount(%{"user_id" => user_id} = params, _session, socket) do
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
        reason_presets = Moderation.list_reason_presets("report")

        # Extract content context from params
        content_context = %{
          source: params["source"],
          content_type: params["content_type"],
          content_id: parse_content_id(params["content_id"])
        }

        # Determine locale for preset labels
        locale = socket.assigns[:locale] || "en"

        {:ok,
         socket
         |> assign(:page_title, gettext("Report User"))
         |> assign(:reported_user, reported_user)
         |> assign(:reason_presets, reason_presets)
         |> assign(:content_context, content_context)
         |> assign(:selected_preset_id, nil)
         |> assign(:custom_reason, "")
         |> assign(:locale, locale)
         |> assign(:form, to_form(%{"reason" => "", "preset_id" => ""}))}
      rescue
        Ecto.NoResultsError ->
          {:ok,
           socket
           |> put_flash(:error, gettext("User not found"))
           |> redirect(to: ~p"/dashboard")}
      end
    end
  end

  defp parse_content_id(nil), do: nil
  defp parse_content_id(id) when is_binary(id), do: String.to_integer(id)
  defp parse_content_id(id) when is_integer(id), do: id

  @impl true
  def handle_event("validate", params, socket) do
    reason = params["reason"] || ""
    preset_id = params["preset_id"] || ""

    {:noreply,
     socket
     |> assign(:custom_reason, reason)
     |> assign(:form, to_form(%{"reason" => reason, "preset_id" => preset_id}))}
  end

  @impl true
  def handle_event("select_preset", %{"preset_id" => ""}, socket) do
    {:noreply,
     socket
     |> assign(:selected_preset_id, nil)
     |> assign(:custom_reason, "")
     |> assign(:form, to_form(%{"reason" => "", "preset_id" => ""}))}
  end

  @impl true
  def handle_event("select_preset", %{"preset_id" => "custom"}, socket) do
    {:noreply,
     socket
     |> assign(:selected_preset_id, "custom")
     |> assign(
       :form,
       to_form(%{"reason" => socket.assigns.custom_reason, "preset_id" => "custom"})
     )}
  end

  @impl true
  def handle_event("select_preset", %{"preset_id" => preset_id}, socket) do
    preset = Moderation.get_reason_preset!(preset_id)
    preset_text = ReasonPreset.text(preset, socket.assigns.locale)

    {:noreply,
     socket
     |> assign(:selected_preset_id, preset_id)
     |> assign(:custom_reason, preset_text)
     |> assign(:form, to_form(%{"reason" => preset_text, "preset_id" => preset_id}))}
  end

  @impl true
  def handle_event("submit", %{"reason" => reason}, socket) do
    scope = socket.assigns.current_scope
    reported_user = socket.assigns.reported_user
    content_context = socket.assigns.content_context

    # Build metadata including content context
    metadata =
      %{
        reported_from: content_context.source || "web",
        reporter_ip: to_string(:inet.ntoa(socket.assigns[:peer_ip] || {0, 0, 0, 0}))
      }
      |> maybe_add_content_context(content_context)
      |> maybe_add_reason_category(socket.assigns)

    # Use the new tracking function
    case Moderation.create_report_with_tracking(scope, reported_user.id, reason, metadata) do
      {:ok, _report} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Report submitted successfully. Our team will review it."))
         |> redirect(to: redirect_path(content_context))}

      {:error, :rate_limited} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           gettext("You have submitted too many reports. Please try again later.")
         )
         |> assign(
           :form,
           to_form(%{"reason" => reason, "preset_id" => socket.assigns.selected_preset_id || ""})
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = format_errors(changeset)

        {:noreply,
         socket
         |> put_flash(:error, errors)
         |> assign(
           :form,
           to_form(%{"reason" => reason, "preset_id" => socket.assigns.selected_preset_id || ""})
         )}
    end
  end

  defp maybe_add_content_context(metadata, %{content_type: nil}), do: metadata

  defp maybe_add_content_context(metadata, %{content_type: type, content_id: id}) do
    Map.merge(metadata, %{content_type: type, content_id: id})
  end

  defp maybe_add_reason_category(metadata, %{selected_preset_id: nil}), do: metadata

  defp maybe_add_reason_category(metadata, %{selected_preset_id: "custom"}),
    do: Map.put(metadata, :reason_category, "custom")

  defp maybe_add_reason_category(metadata, %{
         selected_preset_id: preset_id,
         reason_presets: presets
       }) do
    preset = Enum.find(presets, &(&1.id == String.to_integer(preset_id)))
    if preset, do: Map.put(metadata, :reason_category, preset.label_en), else: metadata
  end

  defp redirect_path(%{source: "chat"}), do: ~p"/chat"
  defp redirect_path(_), do: ~p"/dashboard"

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

      <div class="mt-[var(--space-md)] max-w-2xl">
        <%!-- Content context alert --%>
        <%= if @content_context.source == "chat" do %>
          <div class="alert alert-info mb-[var(--space-md)]">
            <.icon name="hero-chat-bubble-left-right" class="h-5 w-5" />
            <span>{gettext("Reporting based on a chat message")}</span>
          </div>
        <% end %>

        <div class="alert alert-warning mb-[var(--space-md)]">
          <.icon name="hero-exclamation-triangle" class="h-5 w-5" />
          <span>
            {gettext(
              "Please provide a detailed description of why you are reporting this user. False reports may result in action against your account."
            )}
          </span>
        </div>

        <div class="card bg-base-200 mb-[var(--space-md)]">
          <div class="card-body">
            <h3 class="card-title text-[var(--text-sm)]">{gettext("User being reported")}</h3>
            <div class="flex items-center gap-[var(--space-xs)]">
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
          <%!-- Reason preset dropdown --%>
          <div class="form-control mb-[var(--space-sm)]">
            <label class="label">
              <span class="label-text font-medium">{gettext("Select a reason")}</span>
            </label>
            <select
              name="preset_id"
              class="select select-bordered w-full"
              phx-change="select_preset"
            >
              <option value="">{gettext("Choose a reason...")}</option>
              <%= for preset <- @reason_presets do %>
                <option value={preset.id} selected={@selected_preset_id == to_string(preset.id)}>
                  {Homesite.Moderation.ReasonPreset.label(preset, @locale)}
                </option>
              <% end %>
              <option value="custom" selected={@selected_preset_id == "custom"}>
                {gettext("Other (custom reason)")}
              </option>
            </select>
          </div>

          <%!-- Reason textarea --%>
          <div class="form-control">
            <label class="label">
              <span class="label-text font-medium">{gettext("Reason details")}</span>
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

          <div class="mt-[var(--space-md)] flex gap-[var(--space-sm)]">
            <button type="submit" class="btn btn-primary">
              <.icon name="hero-flag" class="h-4 w-4" />
              {gettext("Submit Report")}
            </button>
            <.link navigate={redirect_path(@content_context)} class="btn btn-ghost">
              {gettext("Cancel")}
            </.link>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end
end
