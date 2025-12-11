defmodule HomesiteWeb.UserLive.Followers do
  @moduledoc """
  LiveView for displaying followers and following lists.
  Supports tabbed navigation between followers and following views.
  """
  use HomesiteWeb, :live_view

  import HomesiteWeb.Helpers.DateHelpers

  alias Homesite.Accounts
  alias Homesite.Follows

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={assigns[:current_scope]}>
      <div class="w-[min(95vw,600px)] my-[var(--space-lg)] mx-auto">
        <%!-- Back to profile --%>
        <div class="mb-[var(--space-md)]">
          <.link
            navigate={
              if @user.username, do: ~p"/users/@#{@user.username}", else: ~p"/users/#{@user.id}"
            }
            class="link link-hover gap-[var(--space-inline)] text-[var(--text-sm)] flex items-center"
          >
            <.icon name="hero-arrow-left" class="h-4 w-4" />
            {gettext("Back to profile")}
          </.link>
        </div>

        <%!-- Profile header --%>
        <div class="mb-[var(--space-lg)] gap-[var(--space-sm)] flex items-center">
          <.avatar user={@user} class="h-12 w-12" />
          <div>
            <h1 class="text-[var(--font-size-fluid-lg)] font-bold">
              {@user.display_name || String.split(@user.email, "@") |> List.first()}
            </h1>
            <p class="text-base-content/60 text-[var(--text-sm)]">
              {@follow_counts.followers} {ngettext("follower", "followers", @follow_counts.followers)} · {@follow_counts.following} {gettext(
                "following"
              )}
            </p>
          </div>
        </div>

        <%!-- Tabs --%>
        <div class="tabs tabs-boxed mb-[var(--space-md)]">
          <.link
            navigate={
              if @user.username,
                do: ~p"/users/@#{@user.username}/followers",
                else: ~p"/users/#{@user.id}/followers"
            }
            class={["tab", @live_action == :followers && "tab-active"]}
          >
            {gettext("Followers")}
          </.link>
          <.link
            navigate={
              if @user.username,
                do: ~p"/users/@#{@user.username}/following",
                else: ~p"/users/#{@user.id}/following"
            }
            class={["tab", @live_action == :following && "tab-active"]}
          >
            {gettext("Following")}
          </.link>
        </div>

        <%!-- List --%>
        <div class="divide-base-300 divide-y">
          <%= if @list == [] do %>
            <div class="py-[var(--space-xl)] text-center">
              <.icon
                name="hero-users"
                class="text-base-content/30 mb-[var(--space-sm)] mx-auto h-12 w-12"
              />
              <p class="text-base-content/60">
                <%= if @live_action == :followers do %>
                  {gettext("No followers yet")}
                <% else %>
                  {gettext("Not following anyone yet")}
                <% end %>
              </p>
            </div>
          <% else %>
            <div
              :for={item <- @list}
              class="gap-[var(--space-sm)] py-[var(--space-sm)] flex items-center"
            >
              <.link
                navigate={
                  if item.user.username,
                    do: ~p"/users/@#{item.user.username}",
                    else: ~p"/users/#{item.user.id}"
                }
                class="shrink-0"
              >
                <.avatar user={item.user} class="h-10 w-10" />
              </.link>

              <div class="min-w-0 flex-1">
                <.link
                  navigate={
                    if item.user.username,
                      do: ~p"/users/@#{item.user.username}",
                      else: ~p"/users/#{item.user.id}"
                  }
                  class="block truncate font-medium hover:text-primary"
                >
                  {item.user.display_name || String.split(item.user.email, "@") |> List.first()}
                </.link>
                <p class="text-base-content/60 text-[var(--text-xs)]">
                  {gettext("Since")} {format_date(item.followed_at)}
                </p>
              </div>

              <%!-- Follow/Unfollow button (only if viewing someone else and logged in) --%>
              <%= if @current_scope && item.user.id != @current_scope.user.id do %>
                <%= if is_following?(@current_scope.user.id, item.user.id, @following_ids) do %>
                  <button
                    type="button"
                    phx-click="unfollow"
                    phx-value-user-id={item.user.id}
                    class="btn btn-outline btn-xs"
                  >
                    {gettext("Unfollow")}
                  </button>
                <% else %>
                  <button
                    type="button"
                    phx-click="follow"
                    phx-value-user-id={item.user.id}
                    class="btn btn-primary btn-xs"
                  >
                    {gettext("Follow")}
                  </button>
                <% end %>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"user_identifier" => user_identifier}, _session, socket) do
    case Accounts.get_user_by_identifier(user_identifier) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "User not found")
         |> redirect(to: ~p"/")}

      user ->
        follow_counts = Follows.get_follow_counts(user.id)

        {:ok,
         socket
         |> assign(:user, user)
         |> assign(:follow_counts, follow_counts)}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    user = socket.assigns.user
    live_action = socket.assigns.live_action

    # Load appropriate list based on action
    list =
      case live_action do
        :followers -> Follows.list_followers_for_user(user.id)
        :following -> Follows.list_following_for_user(user.id)
      end

    # Get list of user IDs the current user is following (for follow buttons)
    current_scope = socket.assigns[:current_scope]

    following_ids =
      if current_scope do
        Follows.list_following(current_scope)
        |> Enum.map(& &1.user.id)
        |> MapSet.new()
      else
        MapSet.new()
      end

    page_title =
      case live_action do
        :followers -> "#{user.display_name || "User"}'s Followers"
        :following -> "#{user.display_name || "User"} Following"
      end

    {:noreply,
     socket
     |> assign(:page_title, page_title)
     |> assign(:list, list)
     |> assign(:following_ids, following_ids)}
  end

  @impl true
  def handle_event("follow", %{"user-id" => user_id}, socket) do
    current_scope = socket.assigns.current_scope
    user_id = String.to_integer(user_id)

    case Follows.follow_user(current_scope, user_id) do
      {:ok, _follower} ->
        # Update the following_ids set
        following_ids = MapSet.put(socket.assigns.following_ids, user_id)

        # Update follow counts if viewing the profile user's list
        follow_counts = Follows.get_follow_counts(socket.assigns.user.id)

        {:noreply,
         socket
         |> assign(:following_ids, following_ids)
         |> assign(:follow_counts, follow_counts)
         |> put_flash(:info, gettext("Followed successfully"))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Could not follow user"))}
    end
  end

  @impl true
  def handle_event("unfollow", %{"user-id" => user_id}, socket) do
    current_scope = socket.assigns.current_scope
    user_id = String.to_integer(user_id)

    case Follows.unfollow_user(current_scope, user_id) do
      {:ok, _follower} ->
        # Update the following_ids set
        following_ids = MapSet.delete(socket.assigns.following_ids, user_id)

        # Update follow counts
        follow_counts = Follows.get_follow_counts(socket.assigns.user.id)

        {:noreply,
         socket
         |> assign(:following_ids, following_ids)
         |> assign(:follow_counts, follow_counts)
         |> put_flash(:info, gettext("Unfollowed successfully"))}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, gettext("You are not following this user"))}
    end
  end

  defp is_following?(current_user_id, target_user_id, following_ids) do
    current_user_id != target_user_id && MapSet.member?(following_ids, target_user_id)
  end
end
