defmodule HomesiteWeb.AdminLive.Moderation.Settings do
  @moduledoc """
  LiveView for moderation settings management.

  Allows admins to configure:
  - Alert thresholds for violation tracking
  - Admin action multipliers
  - Default durations
  - Reason presets
  """
  use HomesiteWeb, :live_view

  alias Homesite.Moderation

  @impl true
  def mount(_params, _session, socket) do
    settings = Moderation.list_settings()
    reason_presets = load_all_presets()

    {:ok,
     socket
     |> assign(:page_title, gettext("Moderation Settings"))
     |> assign(:settings, settings)
     |> assign(:reason_presets, reason_presets)
     |> assign(:editing_setting, nil)
     |> assign(:editing_preset, nil)
     |> assign(:active_preset_category, "report")
     |> assign(:show_new_preset_form, false)}
  end

  defp load_all_presets do
    %{
      "report" => Moderation.list_reason_presets("report"),
      "mute" => Moderation.list_reason_presets("mute"),
      "suspend" => Moderation.list_reason_presets("suspend"),
      "ban" => Moderation.list_reason_presets("ban")
    }
  end

  @impl true
  def handle_event("edit_setting", %{"key" => key}, socket) do
    setting = Enum.find(socket.assigns.settings, &(&1.key == key))
    {:noreply, assign(socket, :editing_setting, setting)}
  end

  @impl true
  def handle_event("cancel_edit_setting", _params, socket) do
    {:noreply, assign(socket, :editing_setting, nil)}
  end

  @impl true
  def handle_event("save_setting", %{"key" => key, "value" => value_json}, socket) do
    case Jason.decode(value_json) do
      {:ok, value} ->
        case Moderation.update_setting(key, value, socket.assigns.current_scope) do
          {:ok, _setting} ->
            {:noreply,
             socket
             |> put_flash(:info, gettext("Setting updated"))
             |> assign(:settings, Moderation.list_settings())
             |> assign(:editing_setting, nil)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, gettext("Failed to update setting"))}
        end

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Invalid JSON format"))}
    end
  end

  @impl true
  def handle_event("select_preset_category", %{"category" => category}, socket) do
    {:noreply, assign(socket, :active_preset_category, category)}
  end

  @impl true
  def handle_event("show_new_preset", _params, socket) do
    {:noreply, assign(socket, :show_new_preset_form, true)}
  end

  @impl true
  def handle_event("cancel_new_preset", _params, socket) do
    {:noreply, assign(socket, :show_new_preset_form, false)}
  end

  @impl true
  def handle_event("create_preset", params, socket) do
    attrs = %{
      category: socket.assigns.active_preset_category,
      label_en: params["label_en"],
      label_fi: params["label_fi"],
      text_en: params["text_en"],
      text_fi: params["text_fi"],
      display_order: String.to_integer(params["display_order"] || "0"),
      is_active: params["is_active"] == "true"
    }

    case Moderation.create_reason_preset(socket.assigns.current_scope, attrs) do
      {:ok, _preset} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Preset created"))
         |> assign(:reason_presets, load_all_presets())
         |> assign(:show_new_preset_form, false)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to create preset"))}
    end
  end

  @impl true
  def handle_event("toggle_preset", %{"id" => id}, socket) do
    preset = Moderation.get_reason_preset!(id)

    case Moderation.update_reason_preset(socket.assigns.current_scope, preset, %{
           is_active: !preset.is_active
         }) do
      {:ok, _preset} ->
        {:noreply,
         socket
         |> assign(:reason_presets, load_all_presets())}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to update preset"))}
    end
  end

  @impl true
  def handle_event("delete_preset", %{"id" => id}, socket) do
    preset = Moderation.get_reason_preset!(id)

    case Moderation.delete_reason_preset(socket.assigns.current_scope, preset) do
      {:ok, _preset} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Preset deleted"))
         |> assign(:reason_presets, load_all_presets())}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to delete preset"))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Moderation Settings")}
        <:subtitle>
          {gettext("Configure moderation parameters and reason presets")}
        </:subtitle>
      </.header>

      <div class="mt-6 max-w-4xl">
        <%!-- System Settings --%>
        <div class="card bg-base-100 mb-6 shadow">
          <div class="card-body">
            <h2 class="card-title">{gettext("System Settings")}</h2>

            <div class="overflow-x-auto">
              <table class="table">
                <thead>
                  <tr>
                    <th>{gettext("Setting")}</th>
                    <th>{gettext("Value")}</th>
                    <th>{gettext("Description")}</th>
                    <th>{gettext("Actions")}</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for setting <- @settings do %>
                    <tr>
                      <td class="font-mono text-sm">{setting.key}</td>
                      <td>
                        <%= if @editing_setting && @editing_setting.key == setting.key do %>
                          <form phx-submit="save_setting" class="flex gap-2">
                            <input type="hidden" name="key" value={setting.key} />
                            <textarea
                              name="value"
                              class="textarea textarea-bordered textarea-sm w-48"
                              rows="3"
                            >{Jason.encode!(setting.value, pretty: true)}</textarea>
                            <div class="flex flex-col gap-1">
                              <button type="submit" class="btn btn-primary btn-xs">
                                {gettext("Save")}
                              </button>
                              <button
                                type="button"
                                phx-click="cancel_edit_setting"
                                class="btn btn-ghost btn-xs"
                              >
                                {gettext("Cancel")}
                              </button>
                            </div>
                          </form>
                        <% else %>
                          <pre class="text-xs">{Jason.encode!(setting.value, pretty: true)}</pre>
                        <% end %>
                      </td>
                      <td class="max-w-xs text-sm">{setting.description}</td>
                      <td>
                        <%= if is_nil(@editing_setting) do %>
                          <button
                            phx-click="edit_setting"
                            phx-value-key={setting.key}
                            class="btn btn-ghost btn-sm"
                          >
                            {gettext("Edit")}
                          </button>
                        <% end %>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <%!-- Reason Presets --%>
        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <div class="flex items-center justify-between">
              <h2 class="card-title">{gettext("Reason Presets")}</h2>
              <button phx-click="show_new_preset" class="btn btn-primary btn-sm">
                <.icon name="hero-plus" class="h-4 w-4" />
                {gettext("Add Preset")}
              </button>
            </div>

            <%!-- Category tabs --%>
            <div role="tablist" class="tabs tabs-boxed mb-4">
              <button
                role="tab"
                class={["tab", @active_preset_category == "report" && "tab-active"]}
                phx-click="select_preset_category"
                phx-value-category="report"
              >
                {gettext("Reports")}
              </button>
              <button
                role="tab"
                class={["tab", @active_preset_category == "mute" && "tab-active"]}
                phx-click="select_preset_category"
                phx-value-category="mute"
              >
                {gettext("Mutes")}
              </button>
              <button
                role="tab"
                class={["tab", @active_preset_category == "suspend" && "tab-active"]}
                phx-click="select_preset_category"
                phx-value-category="suspend"
              >
                {gettext("Suspensions")}
              </button>
              <button
                role="tab"
                class={["tab", @active_preset_category == "ban" && "tab-active"]}
                phx-click="select_preset_category"
                phx-value-category="ban"
              >
                {gettext("Bans")}
              </button>
            </div>

            <%!-- New preset form --%>
            <%= if @show_new_preset_form do %>
              <div class="card bg-base-200 mb-4">
                <div class="card-body">
                  <h3 class="font-semibold">{gettext("New Preset")}</h3>
                  <form phx-submit="create_preset" class="space-y-4">
                    <div class="grid grid-cols-2 gap-4">
                      <div class="form-control">
                        <label class="label">
                          <span class="label-text">{gettext("Label (English)")}</span>
                        </label>
                        <input
                          type="text"
                          name="label_en"
                          class="input input-bordered"
                          required
                        />
                      </div>
                      <div class="form-control">
                        <label class="label">
                          <span class="label-text">{gettext("Label (Finnish)")}</span>
                        </label>
                        <input
                          type="text"
                          name="label_fi"
                          class="input input-bordered"
                          required
                        />
                      </div>
                    </div>
                    <div class="grid grid-cols-2 gap-4">
                      <div class="form-control">
                        <label class="label">
                          <span class="label-text">{gettext("Text (English)")}</span>
                        </label>
                        <textarea
                          name="text_en"
                          class="textarea textarea-bordered"
                          rows="2"
                          required
                        ></textarea>
                      </div>
                      <div class="form-control">
                        <label class="label">
                          <span class="label-text">{gettext("Text (Finnish)")}</span>
                        </label>
                        <textarea
                          name="text_fi"
                          class="textarea textarea-bordered"
                          rows="2"
                          required
                        ></textarea>
                      </div>
                    </div>
                    <div class="grid grid-cols-2 gap-4">
                      <div class="form-control">
                        <label class="label">
                          <span class="label-text">{gettext("Display Order")}</span>
                        </label>
                        <input
                          type="number"
                          name="display_order"
                          class="input input-bordered"
                          value="0"
                        />
                      </div>
                      <div class="form-control">
                        <label class="label cursor-pointer">
                          <span class="label-text">{gettext("Active")}</span>
                          <input
                            type="checkbox"
                            name="is_active"
                            value="true"
                            checked
                            class="checkbox"
                          />
                        </label>
                      </div>
                    </div>
                    <div class="flex gap-2">
                      <button type="submit" class="btn btn-primary btn-sm">
                        {gettext("Create")}
                      </button>
                      <button
                        type="button"
                        phx-click="cancel_new_preset"
                        class="btn btn-ghost btn-sm"
                      >
                        {gettext("Cancel")}
                      </button>
                    </div>
                  </form>
                </div>
              </div>
            <% end %>

            <%!-- Presets list --%>
            <div class="overflow-x-auto">
              <table class="table-sm table">
                <thead>
                  <tr>
                    <th>{gettext("Order")}</th>
                    <th>{gettext("Label (EN)")}</th>
                    <th>{gettext("Label (FI)")}</th>
                    <th>{gettext("Active")}</th>
                    <th>{gettext("Actions")}</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for preset <- @reason_presets[@active_preset_category] || [] do %>
                    <tr class={!preset.is_active && "opacity-50"}>
                      <td>{preset.display_order}</td>
                      <td>{preset.label_en}</td>
                      <td>{preset.label_fi}</td>
                      <td>
                        <input
                          type="checkbox"
                          class="toggle toggle-sm"
                          checked={preset.is_active}
                          phx-click="toggle_preset"
                          phx-value-id={preset.id}
                        />
                      </td>
                      <td>
                        <button
                          phx-click="delete_preset"
                          phx-value-id={preset.id}
                          data-confirm={gettext("Are you sure you want to delete this preset?")}
                          class="btn btn-ghost btn-xs text-error"
                        >
                          <.icon name="hero-trash" class="h-4 w-4" />
                        </button>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
