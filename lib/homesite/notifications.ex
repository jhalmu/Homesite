defmodule Homesite.Notifications do
  @moduledoc """
  The Notifications context handles user notifications.

  All functions that access user data require a Scope for authorization.
  """

  import Ecto.Query
  alias Homesite.Repo
  alias Homesite.Accounts.Scope
  alias Homesite.Notifications.Notification

  # PubSub topic
  defp notifications_topic(user_id), do: "user:#{user_id}:notifications"

  @doc """
  Subscribes to notification updates for the current user.
  Broadcasts: {:new_notification, %Notification{}}
  """
  def subscribe(%Scope{} = scope) do
    Phoenix.PubSub.subscribe(Homesite.PubSub, notifications_topic(scope.user.id))
  end

  @doc """
  Unsubscribes from notification updates for the current user.
  """
  def unsubscribe(%Scope{} = scope) do
    Phoenix.PubSub.unsubscribe(Homesite.PubSub, notifications_topic(scope.user.id))
  end

  @doc """
  Creates a notification for a user.
  Broadcasts :new_notification to the user's topic.
  """
  def create_notification(user_id, type, actor_id \\ nil, data \\ %{})
      when is_integer(user_id) and is_binary(type) do
    attrs = %{
      user_id: user_id,
      type: type,
      actor_id: actor_id,
      data: data
    }

    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, notification} ->
        notification = Repo.preload(notification, [:actor])
        broadcast_notification(notification)
        {:ok, notification}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Creates a new_follower notification.
  """
  def notify_new_follower(followed_user_id, %{id: follower_id, email: follower_email}) do
    create_notification(
      followed_user_id,
      "new_follower",
      follower_id,
      %{"follower_email" => follower_email}
    )
  end

  @doc """
  Creates a new_user_registered notification for admins.
  """
  def notify_new_user_registered(admin_user_id, %{id: user_id, email: user_email}) do
    create_notification(
      admin_user_id,
      "new_user_registered",
      user_id,
      %{"user_email" => user_email}
    )
  end

  @doc """
  Creates a report_submitted notification for admins.
  """
  def notify_report_submitted(admin_user_id, reporter, reported_user, reason) do
    create_notification(
      admin_user_id,
      "report_submitted",
      reporter.id,
      %{
        "reporter_email" => reporter.email,
        "reported_user_email" => reported_user.email,
        "reported_user_id" => reported_user.id,
        "reason" => reason
      }
    )
  end

  @doc """
  Creates a follower_post notification when someone you follow publishes.
  """
  def notify_follower_post(follower_user_id, author, post) do
    create_notification(
      follower_user_id,
      "follower_post",
      author.id,
      %{
        "post_id" => post.id,
        "post_title" => post.title,
        "author_name" => author.display_name || author.email
      }
    )
  end

  @doc """
  Creates a system_alert notification for admins.
  """
  def notify_system_alert(admin_user_id, alert_type, message, metadata \\ %{}) do
    create_notification(
      admin_user_id,
      "system_alert",
      nil,
      Map.merge(%{"alert_type" => alert_type, "message" => message}, metadata)
    )
  end

  @doc """
  Lists notifications for the current user.

  Options:
    - `:limit` - Maximum number of notifications (default: 50)
    - `:unread_only` - Only return unread notifications (default: false)
  """
  def list_notifications(%Scope{} = scope, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    unread_only = Keyword.get(opts, :unread_only, false)

    query =
      from n in Notification,
        where: n.user_id == ^scope.user.id,
        order_by: [desc: n.inserted_at, desc: n.id],
        limit: ^limit,
        preload: [:actor]

    query =
      if unread_only do
        from n in query, where: is_nil(n.read_at)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Gets unread notification count for the current user.
  """
  def unread_count(%Scope{} = scope) do
    from(n in Notification,
      where: n.user_id == ^scope.user.id and is_nil(n.read_at),
      select: count()
    )
    |> Repo.one()
  end

  @doc """
  Gets a notification by ID. Raises if not found.
  """
  def get_notification!(id) when is_integer(id) do
    Repo.get!(Notification, id)
    |> Repo.preload([:actor])
  end

  @doc """
  Marks a notification as read.
  Returns {:ok, notification} or raises MatchError if user doesn't own the notification.
  """
  def mark_as_read(%Scope{} = scope, notification_id) when is_integer(notification_id) do
    notification = get_notification!(notification_id)

    # Scope check - user can only mark their own notifications
    true = notification.user_id == scope.user.id

    notification
    |> Notification.mark_read_changeset()
    |> Repo.update()
  end

  @doc """
  Marks all notifications as read for the current user.
  Returns the number of notifications marked as read.
  """
  def mark_all_as_read(%Scope{} = scope) do
    now = DateTime.utc_now(:second)

    {count, _} =
      from(n in Notification,
        where: n.user_id == ^scope.user.id and is_nil(n.read_at)
      )
      |> Repo.update_all(set: [read_at: now])

    count
  end

  @doc """
  Deletes a notification.
  Returns {:ok, notification} or raises MatchError if user doesn't own the notification.
  """
  def delete_notification(%Scope{} = scope, notification_id) when is_integer(notification_id) do
    notification = get_notification!(notification_id)

    # Scope check - user can only delete their own notifications
    true = notification.user_id == scope.user.id

    Repo.delete(notification)
  end

  @doc """
  Deletes old notifications (older than specified days).
  Returns the number of notifications deleted.
  """
  def cleanup_old_notifications(days \\ 30) do
    cutoff = DateTime.add(DateTime.utc_now(:second), -days, :day)

    {count, _} =
      from(n in Notification, where: n.inserted_at < ^cutoff)
      |> Repo.delete_all()

    count
  end

  # Broadcast to user's notification topic
  defp broadcast_notification(%Notification{} = notification) do
    Phoenix.PubSub.broadcast(
      Homesite.PubSub,
      notifications_topic(notification.user_id),
      {:new_notification, notification}
    )
  end
end
