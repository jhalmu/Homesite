defmodule HomesiteWeb.FaqLive.Form do
  use HomesiteWeb, :live_view

  import HomesiteWeb.Gettext

  alias Homesite.Faqs
  alias Homesite.Faqs.Faq

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>{gettext("Use this form to manage FAQ entries in the database.")}</:subtitle>
      </.header>

      <.form for={@form} id="faq-form" phx-change="validate" phx-submit="save">
        <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
          <.input
            field={@form[:category]}
            type="select"
            label={gettext("Category")}
            options={[
              {gettext("User FAQ"), "user"},
              {gettext("Admin FAQ"), "admin"}
            ]}
            required
          >
            <:help>
              {gettext(
                "User FAQs are visible to everyone. Admin FAQs are only visible to administrators."
              )}
            </:help>
          </.input>

          <.input
            field={@form[:display_order]}
            type="number"
            label={gettext("Display Order")}
            min="0"
          >
            <:help>
              {gettext("Lower numbers appear first. FAQs with same order are sorted by ID.")}
            </:help>
          </.input>
        </div>

        <div class="divider">{gettext("English")}</div>

        <.input field={@form[:question_en]} type="text" label={gettext("Question (English)")} required>
          <:help>
            {gettext("The question in English. Will be shown to users with English locale.")}
          </:help>
        </.input>

        <.input
          field={@form[:answer_en]}
          type="textarea"
          label={gettext("Answer (English)")}
          rows="6"
          required
        >
          <:help>
            {gettext("The answer in English. Supports basic HTML for formatting.")}
          </:help>
        </.input>

        <div class="divider">{gettext("Finnish")}</div>

        <.input field={@form[:question_fi]} type="text" label={gettext("Question (Finnish)")} required>
          <:help>
            {gettext("The question in Finnish. Will be shown to users with Finnish locale.")}
          </:help>
        </.input>

        <.input
          field={@form[:answer_fi]}
          type="textarea"
          label={gettext("Answer (Finnish)")}
          rows="6"
          required
        >
          <:help>
            {gettext("The answer in Finnish. Supports basic HTML for formatting.")}
          </:help>
        </.input>

        <.input field={@form[:is_active]} type="checkbox" label={gettext("Active")}>
          <:help>
            {gettext("Inactive FAQs are hidden from users but remain in the database.")}
          </:help>
        </.input>

        <div class="flex gap-2">
          <.button variant="primary" phx-disable-with={gettext("Saving...")}>
            {gettext("Save FAQ")}
          </.button>
          <.link navigate={~p"/faqs"} class="btn">
            {gettext("Cancel")}
          </.link>
        </div>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    faq = %Faq{}
    changeset = Faqs.change_faq(socket.assigns.current_scope, faq)

    socket
    |> assign(:page_title, gettext("New FAQ"))
    |> assign(:faq, faq)
    |> assign(:form, to_form(changeset))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    faq = Faqs.get_faq_for_management!(socket.assigns.current_scope, String.to_integer(id))
    changeset = Faqs.change_faq(socket.assigns.current_scope, faq)

    socket
    |> assign(:page_title, gettext("Edit FAQ"))
    |> assign(:faq, faq)
    |> assign(:form, to_form(changeset))
  end

  @impl true
  def handle_event("validate", %{"faq" => faq_params}, socket) do
    changeset =
      Faqs.change_faq(socket.assigns.current_scope, socket.assigns.faq, faq_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"faq" => faq_params}, socket) do
    save_faq(socket, socket.assigns.live_action, faq_params)
  end

  defp save_faq(socket, :new, faq_params) do
    case Faqs.create_faq(socket.assigns.current_scope, faq_params) do
      {:ok, _faq} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("FAQ created successfully."))
         |> push_navigate(to: ~p"/faqs")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_faq(socket, :edit, faq_params) do
    case Faqs.update_faq(socket.assigns.current_scope, socket.assigns.faq, faq_params) do
      {:ok, _faq} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("FAQ updated successfully."))
         |> push_navigate(to: ~p"/faqs")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
