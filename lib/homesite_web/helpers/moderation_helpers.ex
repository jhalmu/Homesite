defmodule HomesiteWeb.Helpers.ModerationHelpers do
  @moduledoc """
  Shared helper functions for moderation UI formatting.

  Used by both logs.ex and dashboard.ex to format action badges and labels.
  """
  use Gettext, backend: HomesiteWeb.Gettext

  @action_badges %{
    "ban" => "badge-error",
    "unban" => "badge-success",
    "suspend" => "badge-warning",
    "unsuspend" => "badge-success",
    "mute_user" => "badge-info",
    "unmute_user" => "badge-info",
    "report_user" => "badge-warning",
    "report_resolve" => "badge-success",
    "report_dismiss" => "badge-ghost",
    "banner_create" => "badge-warning",
    "banner_dismiss" => "badge-ghost"
  }

  @doc """
  Returns the DaisyUI badge class for a moderation action.
  """
  def action_badge_class(action) do
    Map.get(@action_badges, action, "badge-ghost")
  end

  @doc """
  Returns a human-readable label for a moderation action.
  Uses gettext for internationalization.
  """
  def format_action(action) do
    action_labels()[action] || action
  end

  defp action_labels do
    %{
      "ban" => gettext("Ban"),
      "unban" => gettext("Unban"),
      "suspend" => gettext("Suspend"),
      "unsuspend" => gettext("Unsuspend"),
      "mute_user" => gettext("Mute User"),
      "unmute_user" => gettext("Unmute User"),
      "report_user" => gettext("Report User"),
      "report_resolve" => gettext("Report Resolved"),
      "report_dismiss" => gettext("Report Dismissed"),
      "banner_create" => gettext("Warning Sent"),
      "banner_dismiss" => gettext("Banner Dismissed")
    }
  end

  @doc """
  Returns a shorter label for dashboard display.
  """
  def format_action_short(action) do
    short_labels()[action] || action
  end

  defp short_labels do
    %{
      "ban" => gettext("Ban"),
      "unban" => gettext("Unban"),
      "suspend" => gettext("Suspend"),
      "unsuspend" => gettext("Unsuspend"),
      "mute_user" => gettext("Mute"),
      "unmute_user" => gettext("Unmute"),
      "report_user" => gettext("Report"),
      "report_resolve" => gettext("Resolved"),
      "report_dismiss" => gettext("Dismissed"),
      "banner_create" => gettext("Warning"),
      "banner_dismiss" => gettext("Dismissed")
    }
  end
end
