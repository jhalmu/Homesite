defmodule HomesiteWeb.PostLive.Form do
  use HomesiteWeb, :live_view

  import Ecto.Query

  alias Homesite.Content
  alias Homesite.Content.Post
  alias Homesite.Media

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>{gettext("Use this form to manage post records in your database.")}</:subtitle>
      </.header>

      <.form for={@form} id="post-form" phx-change="validate" phx-submit="save">
        <div class="mb-[var(--space-sm)]">
          <.input field={@form[:title]} type="text" label={gettext("Title")} />
          <%= if @form[:slug].value do %>
            <p class="text-base-content/60 mt-[var(--space-inline)] text-[var(--text-sm)]">
              <.icon name="hero-link" class="inline h-4 w-4" /> {gettext("Slug")}:
              <span class="font-mono">{@form[:slug].value}</span>
            </p>
          <% end %>
        </div>
        <.input
          field={@form[:body]}
          type="textarea"
          label={gettext("Body")}
          rows="12"
          phx-hook="AutoGrow"
          id="post-body-textarea"
        />

        <div class="form-control mb-[var(--space-sm)]">
          <label class="label">
            <span class="label-text font-semibold">{gettext("Publication Date & Time")}</span>
          </label>
          <div class="gap-[var(--space-xs)] flex">
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
          <p class="text-base-content/70 mt-[var(--space-xs)] text-[var(--text-sm)]">
            <.icon name="hero-information-circle" class="inline h-4 w-4" />
            {gettext("Select when this post should be published")}
          </p>
        </div>

        <div class="divider"></div>

        <div class="form-control">
          <label class="label gap-[var(--space-xs)] cursor-pointer justify-start">
            <input
              type="checkbox"
              name={@form[:is_public].name}
              value="true"
              checked={@is_public}
              class="toggle toggle-primary"
            />
            <span class="label-text font-semibold">{gettext("Make this post publicly visible")}</span>
          </label>
          <p class="text-base-content/60 text-[var(--text-sm)] ml-14">
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
            <div class="mb-[var(--space-xs)] gap-[var(--space-xs)] flex flex-wrap">
              <%= for tag <- @selected_tags do %>
                <div class="badge badge-primary badge-lg gap-[var(--space-xs)]">
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
              <div class="border-base-300 bg-base-100 mt-[var(--space-inline)] absolute z-10 max-h-60 w-full overflow-y-auto rounded-lg border shadow-lg">
                <%= for {tag, post_count} <- @tag_suggestions do %>
                  <button
                    type="button"
                    phx-click="add-tag"
                    phx-value-tag-id={tag.id}
                    class="px-[var(--space-sm)] py-[var(--space-xs)] flex w-full items-center justify-between text-left hover:bg-base-200"
                  >
                    <span>{tag.name}</span>
                    <span class="text-base-content/60 text-[var(--text-sm)]">{post_count} posts</span>
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
                      class="border-base-300 text-primary gap-[var(--space-xs)] px-[var(--space-sm)] py-[var(--space-xs)] flex w-full items-center border-t text-left font-semibold hover:bg-base-200"
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
                      class="border-base-300 gap-[var(--space-xs)] px-[var(--space-sm)] py-[var(--space-xs)] flex w-full items-center border-t text-left font-semibold hover:bg-base-200"
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
            <div class="alert alert-warning mt-[var(--space-xs)]">
              <.icon name="hero-information-circle" />
              <div>
                <p class="font-semibold">{gettext("Similar tags exist:")}</p>
                <div class="gap-[var(--space-xs)] mt-[var(--space-inline)] flex flex-wrap">
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

          <p class="text-base-content/60 mt-[var(--space-xs)] text-[var(--text-sm)]">
            <.icon name="hero-tag" class="inline h-4 w-4" />
            {gettext("Search for tags or type to create new ones")}
          </p>
        </div>

        <div class="divider"></div>
        
    <!-- Media Items -->
        <div class="form-control">
          <label class="label">
            <span class="label-text font-semibold">{gettext("Featured Image")}</span>
          </label>

          <%= if @hero_image do %>
            <div class="mb-[var(--space-xs)]">
              <article class="card card-side bg-base-200 shadow-lg">
                <figure class="w-32">
                  <img
                    src={"data:#{@hero_image.content_type};base64,#{Base.encode64(@hero_image.thumb_data)}"}
                    alt={@hero_image.alt_text}
                    class="h-full w-full object-cover"
                  />
                </figure>
                <div class="card-body p-4">
                  <h3 class="card-title text-[var(--text-sm)]">
                    {@hero_image.title || @hero_image.original_filename}
                  </h3>
                  <div class="card-actions justify-end">
                    <button
                      type="button"
                      phx-click="remove-hero"
                      class="btn btn-ghost btn-xs"
                    >
                      <.icon name="hero-x-mark" class="h-3 w-3" />
                      {gettext("Remove")}
                    </button>
                  </div>
                </div>
              </article>
              <input type="hidden" name="post[hero_image_id]" value={@hero_image.id} />
            </div>
          <% else %>
            <input type="hidden" name="post[hero_image_id]" value="" />
          <% end %>

          <button
            type="button"
            phx-click="toggle-media-picker"
            class="btn btn-outline btn-sm"
          >
            <.icon name="hero-photo" class="h-4 w-4" />
            {if @hero_image, do: gettext("Change Image"), else: gettext("Select Image")}
          </button>

          <p class="text-base-content/60 mt-[var(--space-xs)] text-[var(--text-sm)]">
            <.icon name="hero-information-circle" class="inline h-4 w-4" />
            {gettext("Select a featured image for your post")}
          </p>

          <div class="divider text-[var(--text-xs)]">{gettext("OR use external URL")}</div>

          <.input
            field={@form[:featured_image_url]}
            type="url"
            label={gettext("Featured Image URL")}
            placeholder="https://example.com/image.jpg"
          />
          <.input
            field={@form[:featured_image_alt]}
            type="text"
            label={gettext("Image Alt Text")}
            placeholder={gettext("Describe the image for accessibility")}
          />
        </div>
        
    <!-- Media Picker Modal -->
        <%= if @show_media_picker do %>
          <div class="modal modal-open">
            <div class="modal-box max-w-4xl">
              <h3 class="text-[var(--text-lg)] font-bold">{gettext("Select Media")}</h3>
              
    <!-- Search -->
              <div class="form-control mt-[var(--space-sm)]">
                <input
                  type="text"
                  placeholder={gettext("Search media...")}
                  value={@media_search}
                  phx-keyup="search-media"
                  phx-debounce="300"
                  class="input input-bordered"
                />
              </div>
              
    <!-- Media Grid -->
              <div class="mt-[var(--space-sm)] max-h-96 overflow-y-auto">
                <%= if @available_media == [] do %>
                  <div class="alert">
                    <.icon name="hero-information-circle" />
                    <span>
                      {gettext("No media available. Upload images in the Media Library first.")}
                    </span>
                  </div>
                <% else %>
                  <div class="gap-[var(--space-sm)] grid grid-cols-3">
                    <%= for media <- @available_media do %>
                      <button
                        type="button"
                        phx-click="select-hero"
                        phx-value-id={media.id}
                        class="card card-compact bg-base-200 transition-all hover:ring-primary hover:ring-2"
                      >
                        <figure class="aspect-square">
                          <img
                            src={"data:#{media.content_type};base64,#{Base.encode64(media.thumb_data)}"}
                            alt={media.alt_text}
                            class="h-full w-full object-cover"
                          />
                        </figure>
                        <div class="card-body">
                          <p class="text-[var(--text-xs)] truncate">
                            {media.title || media.original_filename}
                          </p>
                        </div>
                      </button>
                    <% end %>
                  </div>
                <% end %>
              </div>

              <div class="modal-action">
                <button
                  type="button"
                  phx-click="toggle-media-picker"
                  class="btn"
                >
                  {gettext("Close")}
                </button>
              </div>
            </div>
          </div>
        <% end %>

        <div class="divider"></div>

        <footer class="gap-[var(--space-xs)] flex">
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
      |> Homesite.Repo.preload([:tags, :media_items])

    # Find hero image if exists
    hero_image =
      case Enum.find(post.media_items, fn _item ->
             # You could add a context field check here in the future
             true
           end) do
        nil -> nil
        media -> media
      end

    socket
    |> assign(:page_title, gettext("Edit Post"))
    |> assign(:post, post)
    |> assign(:selected_tags, post.tags || [])
    |> assign(:tag_search_query, "")
    |> assign(:tag_suggestions, [])
    |> assign(:similar_tags_warning, [])
    |> assign(:is_public, post.is_public)
    |> assign(:hero_image, hero_image)
    |> assign(:show_media_picker, false)
    |> assign(:media_search, "")
    |> assign(:available_media, [])
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
    |> assign(:hero_image, nil)
    |> assign(:show_media_picker, false)
    |> assign(:media_search, "")
    |> assign(:available_media, [])
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

  def handle_event("toggle-media-picker", _params, socket) do
    show_picker = !socket.assigns.show_media_picker

    available_media =
      if show_picker do
        Media.list_media_items(socket.assigns.current_scope)
      else
        []
      end

    {:noreply,
     assign(socket,
       show_media_picker: show_picker,
       available_media: available_media,
       media_search: ""
     )}
  end

  def handle_event("search-media", %{"value" => query}, socket) do
    available_media =
      if String.trim(query) == "" do
        Media.list_media_items(socket.assigns.current_scope)
      else
        Media.search_media_items(socket.assigns.current_scope, query)
      end

    {:noreply,
     assign(socket,
       media_search: query,
       available_media: available_media
     )}
  end

  def handle_event("select-hero", %{"id" => id}, socket) do
    media_item = Media.get_media_item!(socket.assigns.current_scope, id)

    {:noreply,
     assign(socket,
       hero_image: media_item,
       show_media_picker: false,
       media_search: "",
       available_media: []
     )}
  end

  def handle_event("remove-hero", _params, socket) do
    {:noreply, assign(socket, hero_image: nil)}
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
    # Get current time in user's timezone using Timex
    timezone = socket.assigns.current_scope.user.timezone || "Europe/Helsinki"
    now = Timex.now(timezone)

    # Get existing form params to preserve them
    existing_params = socket.assigns.form.params || %{}

    # Update form with current date and time, preserving other fields
    post_params =
      existing_params
      |> Map.put("publish_date", Date.to_string(DateTime.to_date(now)))
      |> Map.put(
        "publish_time",
        now |> DateTime.to_time() |> Time.to_string() |> String.slice(0, 5)
      )

    # Combine into published_at
    post_params = combine_datetime(post_params)

    # Update the changeset preserving existing data
    changeset =
      Content.change_post(socket.assigns.current_scope, socket.assigns.post, post_params)

    {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
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
        # Update media association if hero image is selected
        update_media_association(socket, post)

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
        # Add media association if hero image is selected
        update_media_association(socket, post)

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

  defp update_media_association(socket, post) do
    # Clear existing media associations
    Homesite.Repo.delete_all(
      from pm in "post_media_items",
        where: pm.post_id == ^post.id
    )

    # Add hero image if selected
    if socket.assigns.hero_image do
      Homesite.Repo.insert_all("post_media_items", [
        %{
          post_id: post.id,
          media_item_id: socket.assigns.hero_image.id,
          context: "hero",
          display_order: 0,
          inserted_at: DateTime.utc_now(:second),
          updated_at: DateTime.utc_now(:second)
        }
      ])
    end
  end

  defp return_path(_scope, "index", _post), do: ~p"/posts"
  defp return_path(_scope, "show", post), do: ~p"/posts/#{post}"

  # Helper to format DateTime for date input (YYYY-MM-DD)
  defp format_date(nil), do: Date.utc_today() |> Date.to_string()
  defp format_date(%DateTime{} = dt), do: DateTime.to_date(dt) |> Date.to_string()

  defp format_date(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, dt, _} -> DateTime.to_date(dt) |> Date.to_string()
      _ -> Date.utc_today() |> Date.to_string()
    end
  end

  defp format_date(_), do: Date.utc_today() |> Date.to_string()

  # Helper to format DateTime for time input (HH:MM)
  defp format_time(nil), do: "12:00"

  defp format_time(%DateTime{} = dt),
    do: DateTime.to_time(dt) |> Time.to_string() |> String.slice(0, 5)

  defp format_time(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, dt, _} -> DateTime.to_time(dt) |> Time.to_string() |> String.slice(0, 5)
      _ -> "12:00"
    end
  end

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
