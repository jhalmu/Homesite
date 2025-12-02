defmodule HomesiteWeb.FeedFolderLive.Index do
  @moduledoc """
  LiveView for managing feed folders.
  Allows users to create, edit, and delete folders for organizing feed sources.
  """
  use HomesiteWeb, :live_view

  alias Homesite.ExternalFeeds
  alias Homesite.ExternalFeeds.FeedFolder

  @impl true
  def mount(_params, _session, socket) do
    folders = ExternalFeeds.list_feed_folders(socket.assigns.current_scope)

    {:ok,
     assign(socket,
       folders: folders,
       page_title: gettext("Feed Folders"),
       editing_folder_id: nil,
       form: to_form(ExternalFeeds.change_feed_folder(%FeedFolder{}))
     )}
  end

  @impl true
  def handle_event("new_folder", _params, socket) do
    changeset = ExternalFeeds.change_feed_folder(%FeedFolder{})
    {:noreply, assign(socket, form: to_form(changeset), editing_folder_id: :new)}
  end

  @impl true
  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, editing_folder_id: nil)}
  end

  @impl true
  def handle_event("edit_folder", %{"id" => id}, socket) do
    folder_id = String.to_integer(id)
    folder = ExternalFeeds.get_feed_folder!(socket.assigns.current_scope, folder_id)
    changeset = ExternalFeeds.change_feed_folder(folder)

    {:noreply, assign(socket, form: to_form(changeset), editing_folder_id: folder_id)}
  end

  @impl true
  def handle_event("save_folder", %{"feed_folder" => folder_params}, socket) do
    case socket.assigns.editing_folder_id do
      :new ->
        create_folder(socket, folder_params)

      folder_id when is_integer(folder_id) ->
        update_folder(socket, folder_id, folder_params)

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_folder", %{"id" => id}, socket) do
    folder_id = String.to_integer(id)
    folder = ExternalFeeds.get_feed_folder!(socket.assigns.current_scope, folder_id)

    case ExternalFeeds.delete_feed_folder(socket.assigns.current_scope, folder) do
      {:ok, _folder} ->
        folders = ExternalFeeds.list_feed_folders(socket.assigns.current_scope)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Folder deleted successfully"))
         |> assign(folders: folders, editing_folder_id: nil)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to delete folder"))}
    end
  end

  defp create_folder(socket, folder_params) do
    case ExternalFeeds.create_feed_folder(socket.assigns.current_scope, folder_params) do
      {:ok, _folder} ->
        folders = ExternalFeeds.list_feed_folders(socket.assigns.current_scope)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Folder created successfully"))
         |> assign(folders: folders, editing_folder_id: nil)
         |> assign(form: to_form(ExternalFeeds.change_feed_folder(%FeedFolder{})))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp update_folder(socket, folder_id, folder_params) do
    folder = ExternalFeeds.get_feed_folder!(socket.assigns.current_scope, folder_id)

    case ExternalFeeds.update_feed_folder(socket.assigns.current_scope, folder, folder_params) do
      {:ok, _folder} ->
        folders = ExternalFeeds.list_feed_folders(socket.assigns.current_scope)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Folder updated successfully"))
         |> assign(folders: folders, editing_folder_id: nil)
         |> assign(form: to_form(ExternalFeeds.change_feed_folder(%FeedFolder{})))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
