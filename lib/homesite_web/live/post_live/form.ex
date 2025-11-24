defmodule HomesiteWeb.PostLive.Form do
  use HomesiteWeb, :live_view

  alias Homesite.Content
  alias Homesite.Content.Post

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage post records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="post-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:body]} type="textarea" label="Body" />
        <.input field={@form[:slug]} type="text" label="Slug" />

        <div class="fieldset mb-4">
          <label class="label mb-2">
            <span class="label-text font-semibold">Publication Date & Time</span>
          </label>
          <div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
            <div>
              <.input
                field={@form[:publish_date]}
                type="date"
                label="Date"
                value={format_date(@form[:published_at].value)}
              />
            </div>
            <div>
              <.input
                field={@form[:publish_time]}
                type="time"
                label="Time"
                value={format_time(@form[:published_at].value)}
              />
            </div>
          </div>
          <p class="text-base-content/70 mt-2 text-sm">
            <.icon name="hero-information-circle" class="inline h-4 w-4" />
            Select when this post should be published
          </p>
        </div>

        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Post</.button>
          <.button navigate={return_path(@current_scope, @return_to, @post)}>Cancel</.button>
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
    post = Content.get_post!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Post")
    |> assign(:post, post)
    |> assign(:form, to_form(Content.change_post(socket.assigns.current_scope, post)))
  end

  defp apply_action(socket, :new, _params) do
    post = %Post{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Post")
    |> assign(:post, post)
    |> assign(:form, to_form(Content.change_post(socket.assigns.current_scope, post)))
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    # Combine date and time into published_at
    post_params = combine_datetime(post_params)

    changeset =
      Content.change_post(socket.assigns.current_scope, socket.assigns.post, post_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    # Combine date and time into published_at before saving
    post_params = combine_datetime(post_params)
    save_post(socket, socket.assigns.live_action, post_params)
  end

  defp save_post(socket, :edit, post_params) do
    case Content.update_post(socket.assigns.current_scope, socket.assigns.post, post_params) do
      {:ok, post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post updated successfully")
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
         |> put_flash(:info, "Post created successfully")
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
end
