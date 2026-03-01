defmodule HomesiteWeb.UserLive.Reading do
  @moduledoc false
  use HomesiteWeb, :live_view

  import HomesiteWeb.Helpers.DateHelpers

  alias Homesite.Accounts
  alias Homesite.ExternalFeeds

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={assigns[:current_scope]}>
      <div class="w-[min(95vw,800px)] mx-auto">
        <div class="my-[var(--space-lg)]">
          <.link
            navigate={
              if @user.username,
                do: ~p"/users/@#{@user.username}",
                else: ~p"/users/#{@user.id}"
            }
            class="text-base-content/60 mb-[var(--space-sm)] gap-[var(--space-inline)] text-[var(--text-sm)] inline-flex items-center transition-colors hover:text-primary"
          >
            <.icon name="hero-arrow-left" class="h-4 w-4" />
            {gettext("Back to profile")}
          </.link>

          <div class="gap-[var(--space-sm)] flex items-center">
            <span class="text-[clamp(2rem,5vw,2.25rem)]">{@feed_source.icon}</span>
            <div>
              <h1 class="text-[var(--font-size-fluid-lg)] font-bold">{@feed_source.name}</h1>
              <p class="text-base-content/60 text-[var(--text-sm)]">
                {gettext("Reading list by %{name}",
                  name: @user.display_name || @user.username || gettext("User")
                )}
              </p>
            </div>
          </div>
        </div>

        <%= if @feed_items == [] do %>
          <div class="py-[var(--space-lg)] text-center opacity-60">
            <.icon name="hero-rss" class="mb-[var(--space-md)] mx-auto h-12 w-12 opacity-50" />
            <p class="text-[var(--text-lg)]">{gettext("No items yet")}</p>
          </div>
        <% else %>
          <div class="divide-base-300 divide-y">
            <article
              :for={item <- @feed_items}
              class="gap-[var(--space-sm)] py-[var(--space-sm)] flex items-start"
            >
              <div class="min-w-0 flex-1">
                <a
                  href={item.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="group"
                >
                  <h3 class="text-base font-semibold transition-colors group-hover:text-primary">
                    {item.title}
                  </h3>
                </a>

                <div class="text-base-content/60 mt-[var(--space-inline)] gap-[var(--space-xs)] text-[var(--text-xs)] flex items-center">
                  <time datetime={to_string(item.published_at)}>
                    {format_date(item.published_at)}
                  </time>
                  <span :if={item.author_name}>·</span>
                  <span :if={item.author_name}>{item.author_name}</span>
                </div>

                <p
                  :if={item.content}
                  class="text-base-content/70 line-clamp-2 mt-[var(--space-inline)] text-[var(--text-sm)]"
                >
                  {HtmlSanitizeEx.strip_tags(item.content) |> String.slice(0..200)}
                </p>
              </div>

              <a
                href={item.url}
                target="_blank"
                rel="noopener noreferrer"
                class="btn btn-primary btn-sm shrink-0"
              >
                {gettext("Read")} <.icon name="hero-arrow-top-right-on-square" class="h-3 w-3" />
              </a>
            </article>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"user_identifier" => user_identifier, "id" => feed_source_id}, _session, socket) do
    case Accounts.get_user_by_identifier(user_identifier) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, gettext("User not found"))
         |> redirect(to: ~p"/")}

      user ->
        case ExternalFeeds.get_public_feed_source(user.id, feed_source_id) do
          nil ->
            {:ok,
             socket
             |> put_flash(:error, gettext("Feed not found"))
             |> redirect(to: ~p"/")}

          feed_source ->
            feed_items =
              ExternalFeeds.list_public_feed_items_for_source(user.id, feed_source_id)

            {:ok,
             socket
             |> assign(:page_title, feed_source.name)
             |> assign(:user, user)
             |> assign(:feed_source, feed_source)
             |> assign(:feed_items, feed_items)}
        end
    end
  end
end
