defmodule HomesiteWeb.FaqLive.Index do
  use HomesiteWeb, :live_view

  alias Homesite.Accounts.Scope
  alias Homesite.Faqs
  alias HomesiteWeb.Components.TableOfContents
  alias HomesiteWeb.SEO.JsonLD

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="technical-main">
        <.header>
          {if @category == "admin", do: gettext("Admin FAQs"), else: gettext("User FAQs")}
          <:subtitle>
            {if @category == "admin",
              do: gettext("Frequently asked questions for administrators"),
              else: gettext("Frequently asked questions")}
          </:subtitle>
          <:actions>
            <%= if @is_admin do %>
              <.link navigate={~p"/faqs?category=user"} class="btn">
                {gettext("User FAQs")}
              </.link>
              <.link navigate={~p"/faqs?category=admin"} class="btn">
                {gettext("Admin FAQs")}
              </.link>
              <.button variant="primary" navigate={~p"/faqs/new"}>
                <.icon name="hero-plus" /> {gettext("New FAQ")}
              </.button>
            <% end %>
          </:actions>
        </.header>

        <div class="gap-[var(--space-lg)] mt-[var(--space-lg)] flex">
          <div class="space-y-[var(--space-sm)] flex-1">
            <%= if Enum.empty?(@faqs) do %>
              <div class="card bg-base-200">
                <div class="card-body text-center">
                  <p class="text-base-content/60">{gettext("No FAQs available yet.")}</p>
                  <%= if @is_admin do %>
                    <p class="text-base-content/40 text-[var(--text-sm)]">
                      {gettext("Click 'New FAQ' to create your first FAQ entry.")}
                    </p>
                  <% end %>
                </div>
              </div>
            <% else %>
              <%= for faq <- @faqs do %>
                <div class="card bg-base-200 scroll-mt-24 shadow-md" id={"faq-#{faq.id}"}>
                  <div class="card-body">
                    <h2 class="card-title">
                      <.icon name="hero-question-mark-circle" class="h-6 w-6" />
                      {faq.question}
                    </h2>
                    <div class="prose prose-sm max-w-none">
                      {raw(TableOfContents.add_heading_ids(faq.answer))}
                    </div>
                    <%= if @is_admin do %>
                      <div class="card-actions mt-[var(--space-sm)] justify-end">
                        <.link navigate={~p"/faqs/#{faq}/edit"} class="btn btn-sm">
                          <.icon name="hero-pencil" class="h-4 w-4" />
                          {gettext("Edit")}
                        </.link>
                        <button
                          class="btn btn-sm btn-ghost"
                          phx-click="delete"
                          phx-value-id={faq.id}
                          data-confirm={gettext("Are you sure you want to delete this FAQ?")}
                        >
                          <.icon name="hero-trash" class="h-4 w-4" />
                          {gettext("Delete")}
                        </button>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
          
    <!-- Sidebar with TOC -->
          <%= if !Enum.empty?(@faqs) && @headings != [] do %>
            <aside class="hidden lg:block lg:w-64">
              <TableOfContents.table_of_contents
                headings={@headings}
                title={gettext("On This Page")}
                sticky={true}
                show_mobile={false}
              />
            </aside>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    locale = Gettext.get_locale(HomesiteWeb.Gettext)

    is_admin =
      socket.assigns[:current_scope] &&
        Scope.admin?(socket.assigns.current_scope)

    {:ok, assign(socket, locale: locale, is_admin: is_admin)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    category = Map.get(params, "category", "user")
    faqs = load_faqs(socket, category)

    # Extract headings from all FAQs for TOC
    headings = extract_all_headings(faqs)

    # Generate JSON-LD for user FAQs (public)
    json_ld =
      if category == "user" && !Enum.empty?(faqs) do
        JsonLD.faq_page(faqs) |> Jason.encode!()
      else
        nil
      end

    {:noreply,
     assign(socket,
       category: category,
       faqs: faqs,
       headings: headings,
       page_title: page_title(category),
       json_ld: json_ld
     )}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    # Only admins can delete
    if socket.assigns.is_admin do
      faq = Faqs.get_faq_for_management!(socket.assigns.current_scope, String.to_integer(id))
      {:ok, _} = Faqs.delete_faq(socket.assigns.current_scope, faq)

      faqs = load_faqs(socket, socket.assigns.category)

      {:noreply,
       socket
       |> assign(:faqs, faqs)
       |> put_flash(:info, gettext("FAQ deleted successfully."))}
    else
      {:noreply, put_flash(socket, :error, gettext("Unauthorized"))}
    end
  end

  defp load_faqs(socket, category) do
    if socket.assigns.is_admin do
      case category do
        "admin" -> Faqs.list_admin_faqs(socket.assigns.current_scope, socket.assigns.locale)
        "user" -> Faqs.list_user_faqs(socket.assigns.locale)
        _ -> []
      end
    else
      if category == "user" do
        Faqs.list_user_faqs(socket.assigns.locale)
      else
        []
      end
    end
  end

  defp page_title("admin"), do: gettext("Admin FAQs")
  defp page_title(_), do: gettext("FAQs")

  # Build TOC from FAQ question titles (not from answer content)
  defp extract_all_headings(faqs) do
    Enum.map(faqs, fn faq ->
      %{
        level: 2,
        text: faq.question,
        id: "faq-#{faq.id}",
        children: []
      }
    end)
  end
end
