defmodule HomesiteWeb.PostLive.Form do
  use HomesiteWeb, :live_view

  # Note: "unused import" warning is false positive - gettext() used in HEEx template
  import HomesiteWeb.Gettext

  alias Homesite.Content
  alias Homesite.Content.Post

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>{gettext("Use this form to manage post records in your database.")}</:subtitle>
      </.header>

      <.form for={@form} id="post-form" phx-change="validate" phx-submit="save">
        <div class="mb-4">
          <.input field={@form[:title]} type="text" label={gettext("Title")} />
          <%= if @form[:slug].value do %>
            <p class="text-base-content/60 mt-1 text-sm">
              <.icon name="hero-link" class="inline h-4 w-4" /> {gettext("Slug")}:
              <span class="font-mono">{@form[:slug].value}</span>
            </p>
          <% end %>
        </div>
        <.input field={@form[:body]} type="textarea" label={gettext("Body")} rows="12" />

        <div class="form-control mb-4">
          <label class="label">
            <span class="label-text font-semibold">{gettext("Publication Date & Time")}</span>
          </label>
          <div class="flex gap-2">
            <input
              type="date"
              name={@form[:publish_date].name}
              id={@form[:publish_date].id}
              value={format_date(@form[:published_at].value)}
              class="input input-bordered w-40"
            />
            <input
              type="time"
              name={@form[:publish_time].name}
              id={@form[:publish_time].id}
              value={format_time(@form[:published_at].value)}
              class="input input-bordered w-32"
            />
            <button
              type="button"
              phx-click="set-time-now"
              class="btn btn-outline btn-sm"
            >
              {gettext("Now")}
            </button>
          </div>
          <p class="text-base-content/70 mt-2 text-sm">
            <.icon name="hero-information-circle" class="inline h-4 w-4" />
            {gettext("Select when this post should be published")}
          </p>
        </div>

        <div class="divider"></div>

        <div class="form-control">
          <label class="label cursor-pointer justify-start gap-3">
            <input
              type="checkbox"
              name={@form[:is_public].name}
              value="true"
              checked={@is_public}
              class="toggle toggle-primary"
            />
            <span class="label-text font-semibold">{gettext("Make this post publicly visible")}</span>
          </label>
          <p class="text-base-content/60 ml-14 text-sm">
            {gettext("Public posts are visible to everyone. Turn off to make this post private.")}
          </p>
        </div>

        <div class="divider"></div>

        <div class="form-control">
          <label class="label">
            <span class="label-text font-semibold">{gettext("Tags")}</span>
          </label>
          
    <!-- Selected tags -->
          <%= if @selected_tags != [] do %>
            <div class="mb-3 flex flex-wrap gap-2">
              <%= for tag <- @selected_tags do %>
                <div class="badge badge-primary badge-lg gap-2">
                  {tag.name}
                  <button
                    type="button"
                    phx-click="remove-tag"
                    phx-value-tag-id={tag.id}
                    class="btn btn-xs btn-ghost btn-circle"
                  >
                    <.icon name="hero-x-mark" class="h-3 w-3" />
                  </button>
                </div>
                <input type="hidden" name="post[tag_ids][]" value={tag.id} />
              <% end %>
            </div>
          <% else %>
            <input type="hidden" name="post[tag_ids][]" value="" />
          <% end %>
          
    <!-- Tag search/add -->
          <div class="relative">
            <input
              type="text"
              name="tag_search"
              value={@tag_search_query}
              phx-keyup="search-tags"
              phx-debounce="300"
              placeholder={gettext("Search or create tags...")}
              autocomplete="off"
              class="input input-bordered w-full"
            />
            
    <!-- Suggestions dropdown -->
            <%= if @tag_suggestions != [] or @tag_search_query != "" do %>
              <div class="border-base-300 bg-base-100 absolute z-10 mt-1 max-h-60 w-full overflow-y-auto rounded-lg border shadow-lg">
                <%= for {tag, post_count} <- @tag_suggestions do %>
                  <button
                    type="button"
                    phx-click="add-tag"
                    phx-value-tag-id={tag.id}
                    class="flex w-full items-center justify-between px-4 py-2 text-left hover:bg-base-200"
                  >
                    <span>{tag.name}</span>
                    <span class="text-base-content/60 text-sm">{post_count} posts</span>
                  </button>
                <% end %>
                
    <!-- Add exact match button OR create new option -->
                <%= cond do %>
                  <% exact_tag = find_exact_match(@tag_suggestions, @tag_search_query) -> %>
                    <!-- Show "Add" button for exact match -->
                    <button
                      type="button"
                      phx-click="add-tag"
                      phx-value-tag-id={exact_tag.id}
                      class="border-base-300 text-primary flex w-full items-center gap-2 border-t px-4 py-2 text-left font-semibold hover:bg-base-200"
                    >
                      <.icon name="hero-check" class="h-4 w-4" />
                      {gettext("Add")} "{exact_tag.name}"
                    </button>
                  <% @tag_search_query != "" -> %>
                    <!-- Show "Create" button for new tag -->
                    <button
                      type="button"
                      phx-click="create-and-add-tag"
                      phx-value-name={@tag_search_query}
                      class="border-base-300 flex w-full items-center gap-2 border-t px-4 py-2 text-left font-semibold hover:bg-base-200"
                    >
                      <.icon name="hero-plus" class="h-4 w-4" />
                      {gettext("Create")} "{@tag_search_query}"
                    </button>
                  <% true -> %>
                    <!-- Empty query, show nothing -->
                <% end %>
              </div>
            <% end %>
          </div>
          
    <!-- Similar tags warning -->
          <%= if @similar_tags_warning != [] do %>
            <div class="alert alert-warning mt-3">
              <.icon name="hero-information-circle" />
              <div>
                <p class="font-semibold">{gettext("Similar tags exist:")}</p>
                <div class="mt-1 flex flex-wrap gap-2">
                  <%= for tag <- @similar_tags_warning do %>
                    <button
                      type="button"
                      phx-click="add-tag"
                      phx-value-tag-id={tag.id}
                      class="badge badge-sm badge-outline"
                    >
                      {tag.name}
                    </button>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>

          <p class="text-base-content/60 mt-3 text-sm">
            <.icon name="hero-tag" class="inline h-4 w-4" />
            {gettext("Search for tags or type to create new ones")}
          </p>
        </div>

        <div class="divider"></div>

        <footer class="flex gap-3">
          <.button phx-disable-with={gettext("Saving...")} variant="primary">
            {gettext("Save Post")}
          </.button>
          <.button navigate={return_path(@current_scope, @return_to, @post)}>
            {gettext("Cancel")}
          </.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    post =
      Content.get_post!(socket.assigns.current_scope, id)
      |> Homesite.Repo.preload(:tags)

    socket
    |> assign(:page_title, gettext("Edit Post"))
    |> assign(:post, post)
    |> assign(:selected_tags, post.tags || [])
    |> assign(:tag_search_query, "")
    |> assign(:tag_suggestions, [])
    |> assign(:similar_tags_warning, [])
    |> assign(:is_public, post.is_public)
    |> assign(:form, to_form(Content.change_post(socket.assigns.current_scope, post)))
  end

  defp apply_action(socket, :new, _params) do
    post = %Post{user_id: socket.assigns.current_scope.user.id, is_public: true}

    socket
    |> assign(:page_title, gettext("New Post"))
    |> assign(:post, post)
    |> assign(:selected_tags, [])
    |> assign(:tag_search_query, "")
    |> assign(:tag_suggestions, [])
    |> assign(:similar_tags_warning, [])
    |> assign(:is_public, true)
    |> assign(:form, to_form(Content.change_post(socket.assigns.current_scope, post)))
  end

  @impl true
  def handle_event("search-tags", %{"value" => query}, socket) do
    suggestions =
      if String.length(query) >= 2 do
        Content.list_all_public_tags(query)
      else
        []
      end

    {:noreply,
     assign(socket,
       tag_search_query: query,
       tag_suggestions: suggestions,
       similar_tags_warning: []
     )}
  end

  def handle_event("add-tag", %{"tag-id" => tag_id_str}, socket) do
    tag_id = String.to_integer(tag_id_str)

    # Find the tag from suggestions or fetch it
    tag =
      case Enum.find(socket.assigns.tag_suggestions, fn {t, _} -> t.id == tag_id end) do
        {tag, _count} -> tag
        nil -> Homesite.Repo.get!(Content.Tag, tag_id)
      end

    selected_tags = Enum.uniq_by([tag | socket.assigns.selected_tags], & &1.id)

    {:noreply,
     assign(socket,
       selected_tags: selected_tags,
       tag_search_query: "",
       tag_suggestions: [],
       similar_tags_warning: []
     )}
  end

  def handle_event("remove-tag", %{"tag-id" => tag_id_str}, socket) do
    tag_id = String.to_integer(tag_id_str)
    selected_tags = Enum.reject(socket.assigns.selected_tags, &(&1.id == tag_id))
    {:noreply, assign(socket, selected_tags: selected_tags)}
  end

  def handle_event("create-and-add-tag", %{"name" => name}, socket) do
    # Check for similar tags first
    similar = Content.find_similar_tags(name)

    if similar != [] do
      {:noreply, assign(socket, similar_tags_warning: similar)}
    else
      case Content.get_or_create_tag(socket.assigns.current_scope, %{
             "name" => name,
             "is_public" => true
           }) do
        {:ok, tag} ->
          selected_tags = Enum.uniq_by([tag | socket.assigns.selected_tags], & &1.id)

          {:noreply,
           assign(socket,
             selected_tags: selected_tags,
             tag_search_query: "",
             tag_suggestions: [],
             similar_tags_warning: []
           )}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Could not create tag"))}
      end
    end
  end

  def handle_event("validate", %{"post" => post_params}, socket) do
    # Combine date and time into published_at
    post_params = combine_datetime(post_params)

    # Update is_public from params if present, otherwise keep current value
    is_public =
      case post_params["is_public"] do
        "true" -> true
        "false" -> false
        _ -> socket.assigns.is_public
      end

    # Always include is_public in params based on current state
    post_params = Map.put(post_params, "is_public", if(is_public, do: "true", else: "false"))

    changeset =
      Content.change_post(socket.assigns.current_scope, socket.assigns.post, post_params)

    {:noreply,
     socket
     |> assign(:is_public, is_public)
     |> assign(:form, to_form(changeset, action: :validate))}
  end

  def handle_event("set-time-now", _params, socket) do
    # Get current time in UTC
    now = DateTime.utc_now(:second)

    # Update form with current date and time
    post_params = %{
      "publish_date" => Date.to_string(DateTime.to_date(now)),
      "publish_time" => now |> DateTime.to_time() |> Time.to_string() |> String.slice(0, 5)
    }

    # Combine into published_at
    post_params = combine_datetime(post_params)

    # Update the changeset
    changeset =
      Content.change_post(socket.assigns.current_scope, socket.assigns.post, post_params)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    # Combine date and time into published_at before saving
    post_params = combine_datetime(post_params)

    # Handle unchecked checkbox - when checkbox is unchecked, it doesn't send any value
    post_params = Map.put_new(post_params, "is_public", "false")

    # Add selected tag IDs to params
    post_params =
      Map.put(
        post_params,
        "tag_ids",
        Enum.map(socket.assigns.selected_tags, fn tag -> to_string(tag.id) end)
      )

    save_post(socket, socket.assigns.live_action, post_params)
  end

  defp save_post(socket, :edit, post_params) do
    case Content.update_post(socket.assigns.current_scope, socket.assigns.post, post_params) do
      {:ok, post} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Post updated successfully"))
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, post)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_post(socket, :new, post_params) do
    case Content.create_post(socket.assigns.current_scope, post_params) do
      {:ok, post} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Post created successfully"))
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, post)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _post), do: ~p"/posts"
  defp return_path(_scope, "show", post), do: ~p"/posts/#{post}"

  # Helper to format DateTime for date input (YYYY-MM-DD)
  defp format_date(nil), do: Date.utc_today() |> Date.to_string()
  defp format_date(%DateTime{} = dt), do: DateTime.to_date(dt) |> Date.to_string()
  defp format_date(_), do: Date.utc_today() |> Date.to_string()

  # Helper to format DateTime for time input (HH:MM)
  defp format_time(nil), do: "12:00"

  defp format_time(%DateTime{} = dt),
    do: DateTime.to_time(dt) |> Time.to_string() |> String.slice(0, 5)

  defp format_time(_), do: "12:00"

  # Helper to combine date and time params into published_at
  defp combine_datetime(%{"publish_date" => date, "publish_time" => time} = params)
       when is_binary(date) and is_binary(time) and date != "" and time != "" do
    case DateTime.new(Date.from_iso8601!(date), Time.from_iso8601!(time <> ":00")) do
      {:ok, datetime} ->
        params
        |> Map.put("published_at", DateTime.to_iso8601(datetime))
        |> Map.delete("publish_date")
        |> Map.delete("publish_time")

      {:error, _} ->
        params
    end
  end

  defp combine_datetime(params), do: params

  # Find exact matching tag from suggestions (case-insensitive)
  # Returns the tag struct or nil
  defp find_exact_match(suggestions, query) do
    query_lower = String.downcase(query)

    case Enum.find(suggestions, fn {tag, _count} ->
           String.downcase(tag.name) == query_lower
         end) do
      {tag, _count} -> tag
      nil -> nil
    end
  end
end
