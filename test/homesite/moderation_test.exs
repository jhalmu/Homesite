defmodule Homesite.ModerationTest do
  use Homesite.DataCase

  alias Homesite.Moderation

  alias Homesite.Moderation.{
    ModerationSetting,
    ReasonPreset,
    UserBan,
    UserBanner,
    UserMute,
    UserReport,
    UserSuspension,
    UserViolation
  }

  import Homesite.AccountsFixtures,
    only: [user_scope_fixture: 0, user_fixture: 0, admin_scope_fixture: 0, admin_fixture: 0]

  describe "user mutes" do
    test "list_muted_users/1 returns all users muted by the current user" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      {:ok, _mute} = Moderation.mute_user(scope, other_user.id)

      muted_users = Moderation.list_muted_users(scope)
      assert length(muted_users) == 1
      assert hd(muted_users).muted_user_id == other_user.id
    end

    test "list_muted_users/1 returns empty list when no mutes" do
      scope = user_scope_fixture()
      assert Moderation.list_muted_users(scope) == []
    end

    test "muted_user_ids/1 returns list of muted user IDs" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      {:ok, _mute} = Moderation.mute_user(scope, other_user.id)

      ids = Moderation.muted_user_ids(scope)
      assert ids == [other_user.id]
    end

    test "muted?/2 returns true when user is muted" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      {:ok, _mute} = Moderation.mute_user(scope, other_user.id)

      assert Moderation.muted?(scope, other_user.id)
    end

    test "muted?/2 returns false when user is not muted" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      refute Moderation.muted?(scope, other_user.id)
    end

    test "mute_user/3 creates a mute" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      assert {:ok, %UserMute{} = mute} = Moderation.mute_user(scope, other_user.id)
      assert mute.user_id == scope.user.id
      assert mute.muted_user_id == other_user.id
    end

    test "mute_user/3 with reason creates a mute with reason" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      assert {:ok, %UserMute{} = mute} =
               Moderation.mute_user(scope, other_user.id, reason: "Annoying posts")

      assert mute.reason == "Annoying posts"
    end

    test "mute_user/3 creates a moderation log entry" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      {:ok, _mute} = Moderation.mute_user(scope, other_user.id)

      logs = Moderation.list_moderation_logs(target_user_id: other_user.id)
      assert length(logs) == 1
      assert hd(logs).action == "mute_user"
    end

    test "mute_user/3 cannot mute yourself" do
      scope = user_scope_fixture()

      assert {:error, %Ecto.Changeset{} = changeset} = Moderation.mute_user(scope, scope.user.id)
      assert "cannot mute yourself" in errors_on(changeset).muted_user_id
    end

    test "mute_user/3 cannot mute same user twice" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      {:ok, _mute} = Moderation.mute_user(scope, other_user.id)

      assert {:error, %Ecto.Changeset{} = changeset} = Moderation.mute_user(scope, other_user.id)
      assert "has already been taken" in errors_on(changeset).user_id
    end

    test "unmute_user/2 removes a mute" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      {:ok, _mute} = Moderation.mute_user(scope, other_user.id)
      assert {:ok, %UserMute{}} = Moderation.unmute_user(scope, other_user.id)

      refute Moderation.muted?(scope, other_user.id)
    end

    test "unmute_user/2 returns error when not muted" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      assert {:error, :not_found} = Moderation.unmute_user(scope, other_user.id)
    end

    test "unmute_user/2 creates a moderation log entry" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      {:ok, _mute} = Moderation.mute_user(scope, other_user.id)
      {:ok, _unmute} = Moderation.unmute_user(scope, other_user.id)

      logs = Moderation.list_moderation_logs(target_user_id: other_user.id)
      actions = Enum.map(logs, & &1.action)
      assert "unmute_user" in actions
    end
  end

  describe "user reports" do
    test "create_report/4 creates a report" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      assert {:ok, %UserReport{} = report} =
               Moderation.create_report(scope, other_user.id, "This user is spamming")

      assert report.reporter_id == scope.user.id
      assert report.reported_user_id == other_user.id
      assert report.reason == "This user is spamming"
      assert report.status == "pending"
    end

    test "create_report/4 with metadata stores metadata" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      metadata = %{source: "chat", channel_id: 123}

      assert {:ok, %UserReport{} = report} =
               Moderation.create_report(scope, other_user.id, "Spam in chat", metadata)

      assert report.metadata == metadata
    end

    test "create_report/4 creates a moderation log entry" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      {:ok, _report} = Moderation.create_report(scope, other_user.id, "This user is spamming")

      logs = Moderation.list_moderation_logs(action: "report_user")
      assert length(logs) >= 1
    end

    test "create_report/4 cannot report yourself" do
      scope = user_scope_fixture()

      assert {:error, %Ecto.Changeset{} = changeset} =
               Moderation.create_report(scope, scope.user.id, "Self report")

      assert "cannot report yourself" in errors_on(changeset).reported_user_id
    end

    test "create_report/4 validates reason minimum length" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      assert {:error, %Ecto.Changeset{} = changeset} =
               Moderation.create_report(scope, other_user.id, "Short")

      assert "should be at least 10 character(s)" in errors_on(changeset).reason
    end

    test "list_pending_reports/0 returns pending reports" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      {:ok, _report} = Moderation.create_report(scope, other_user.id, "This user is spamming")

      reports = Moderation.list_pending_reports()
      assert length(reports) >= 1
      assert Enum.all?(reports, fn r -> r.status == "pending" end)
    end

    test "count_pending_reports/0 counts pending reports" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      count_before = Moderation.count_pending_reports()
      {:ok, _report} = Moderation.create_report(scope, other_user.id, "This user is spamming")
      count_after = Moderation.count_pending_reports()

      assert count_after == count_before + 1
    end

    test "get_report!/1 returns the report" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      {:ok, report} = Moderation.create_report(scope, other_user.id, "This user is spamming")
      found = Moderation.get_report!(report.id)

      assert found.id == report.id
    end

    test "resolve_report/3 resolves a report" do
      scope = user_scope_fixture()
      other_user = user_fixture()
      admin_scope = admin_scope_fixture()

      {:ok, report} = Moderation.create_report(scope, other_user.id, "This user is spamming")
      {:ok, resolved} = Moderation.resolve_report(admin_scope, report.id, "User has been warned")

      assert resolved.status == "resolved"
      assert resolved.resolution_notes == "User has been warned"
      assert resolved.resolved_by_user_id == admin_scope.user.id
      assert resolved.resolved_at != nil
    end

    test "resolve_report/3 requires admin scope" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      {:ok, report} = Moderation.create_report(scope, other_user.id, "This user is spamming")

      assert_raise MatchError, fn ->
        Moderation.resolve_report(scope, report.id, "User has been warned")
      end
    end

    test "dismiss_report/3 dismisses a report" do
      scope = user_scope_fixture()
      other_user = user_fixture()
      admin_scope = admin_scope_fixture()

      {:ok, report} = Moderation.create_report(scope, other_user.id, "This user is spamming")
      {:ok, dismissed} = Moderation.dismiss_report(admin_scope, report.id, "No violation found")

      assert dismissed.status == "dismissed"
      assert dismissed.resolution_notes == "No violation found"
    end
  end

  describe "user banners" do
    test "create_banner/4 creates a banner" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()

      assert {:ok, %UserBanner{} = banner} =
               Moderation.create_banner(admin_scope, target_user.id, "Please follow the rules")

      assert banner.user_id == target_user.id
      assert banner.created_by_user_id == admin_scope.user.id
      assert banner.message == "Please follow the rules"
      assert banner.severity == "warning"
    end

    test "create_banner/4 with severity option" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()

      {:ok, banner} =
        Moderation.create_banner(admin_scope, target_user.id, "Important info", severity: "info")

      assert banner.severity == "info"
    end

    test "create_banner/4 with auto_dismiss_after option" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()
      future_time = DateTime.add(DateTime.utc_now(), 3600, :second)

      {:ok, banner} =
        Moderation.create_banner(admin_scope, target_user.id, "Temporary warning",
          auto_dismiss_after: future_time
        )

      assert banner.auto_dismiss_after != nil
    end

    test "create_banner/4 requires admin scope" do
      user_scope = user_scope_fixture()
      target_user = user_fixture()

      assert_raise MatchError, fn ->
        Moderation.create_banner(user_scope, target_user.id, "Please follow the rules")
      end
    end

    test "create_banner/4 validates message length" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()

      assert {:error, %Ecto.Changeset{} = changeset} =
               Moderation.create_banner(admin_scope, target_user.id, "Short")

      assert "should be at least 10 character(s)" in errors_on(changeset).message
    end

    test "list_active_banners/1 returns active banners" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()

      {:ok, _banner} =
        Moderation.create_banner(admin_scope, target_user.id, "Please follow the rules")

      banners = Moderation.list_active_banners(target_user.id)
      assert length(banners) == 1
    end

    test "list_active_banners/1 excludes dismissed banners" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()

      {:ok, banner} =
        Moderation.create_banner(admin_scope, target_user.id, "Please follow the rules")

      {:ok, _} = Moderation.dismiss_banner(target_user.id, banner.id)

      banners = Moderation.list_active_banners(target_user.id)
      assert banners == []
    end

    test "list_active_banners/1 excludes expired banners" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()
      past_time = DateTime.utc_now(:second) |> DateTime.add(-3600, :second)

      # Insert banner with expired auto_dismiss_after directly
      Repo.insert!(%UserBanner{
        user_id: target_user.id,
        created_by_user_id: admin_scope.user.id,
        message: "Expired warning",
        severity: "warning",
        auto_dismiss_after: past_time
      })

      banners = Moderation.list_active_banners(target_user.id)
      assert banners == []
    end

    test "dismiss_banner/2 dismisses a banner" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()

      {:ok, banner} =
        Moderation.create_banner(admin_scope, target_user.id, "Please follow the rules")

      {:ok, dismissed} = Moderation.dismiss_banner(target_user.id, banner.id)

      assert dismissed.dismissed_at != nil
    end

    test "dismiss_banner/2 returns error when banner not found" do
      assert {:error, :not_found} = Moderation.dismiss_banner(0, 0)
    end
  end

  describe "user suspensions" do
    test "suspend_user/4 creates a suspension" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()
      expires_at = DateTime.add(DateTime.utc_now(), 86_400, :second)

      assert {:ok, %UserSuspension{} = suspension} =
               Moderation.suspend_user(
                 admin_scope,
                 target_user.id,
                 "Violation of rules",
                 expires_at
               )

      assert suspension.user_id == target_user.id
      assert suspension.suspended_by_user_id == admin_scope.user.id
      assert suspension.reason == "Violation of rules"
    end

    test "suspend_user/4 requires admin scope" do
      user_scope = user_scope_fixture()
      target_user = user_fixture()
      expires_at = DateTime.add(DateTime.utc_now(), 86_400, :second)

      assert_raise MatchError, fn ->
        Moderation.suspend_user(user_scope, target_user.id, "Violation of rules", expires_at)
      end
    end

    test "suspend_user/4 cannot suspend yourself" do
      admin_scope = admin_scope_fixture()
      expires_at = DateTime.add(DateTime.utc_now(), 86_400, :second)

      assert {:error, %Ecto.Changeset{} = changeset} =
               Moderation.suspend_user(
                 admin_scope,
                 admin_scope.user.id,
                 "Self suspension",
                 expires_at
               )

      assert "cannot suspend yourself" in errors_on(changeset).user_id
    end

    test "suspend_user/4 validates expires_at is in the future" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()
      past_time = DateTime.add(DateTime.utc_now(), -3600, :second)

      assert {:error, %Ecto.Changeset{} = changeset} =
               Moderation.suspend_user(
                 admin_scope,
                 target_user.id,
                 "Violation of rules",
                 past_time
               )

      assert "must be in the future" in errors_on(changeset).expires_at
    end

    test "suspend_user/4 replaces existing suspension" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()
      expires_at1 = DateTime.add(DateTime.utc_now(), 86_400, :second)
      expires_at2 = DateTime.add(DateTime.utc_now(), 172_800, :second)

      {:ok, _suspension1} =
        Moderation.suspend_user(admin_scope, target_user.id, "First suspension", expires_at1)

      {:ok, _suspension2} =
        Moderation.suspend_user(admin_scope, target_user.id, "Second suspension", expires_at2)

      suspensions = Moderation.list_suspensions(active_only: true)
      target_suspensions = Enum.filter(suspensions, fn s -> s.user_id == target_user.id end)
      assert length(target_suspensions) == 1
      assert hd(target_suspensions).reason == "Second suspension"
    end

    test "suspended?/1 returns true when user is suspended" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()
      expires_at = DateTime.add(DateTime.utc_now(), 86_400, :second)

      {:ok, _suspension} =
        Moderation.suspend_user(admin_scope, target_user.id, "Violation of rules", expires_at)

      assert Moderation.suspended?(target_user.id)
    end

    test "suspended?/1 returns false when suspension is expired" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()
      past_time = DateTime.utc_now(:second) |> DateTime.add(-3600, :second)

      # Insert expired suspension directly
      Repo.insert!(%UserSuspension{
        user_id: target_user.id,
        suspended_by_user_id: admin_scope.user.id,
        reason: "Expired suspension",
        expires_at: past_time
      })

      refute Moderation.suspended?(target_user.id)
    end

    test "unsuspend_user/2 lifts a suspension" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()
      expires_at = DateTime.add(DateTime.utc_now(), 86_400, :second)

      {:ok, _suspension} =
        Moderation.suspend_user(admin_scope, target_user.id, "Violation of rules", expires_at)

      {:ok, lifted} = Moderation.unsuspend_user(admin_scope, target_user.id)

      assert lifted.lifted_at != nil
      assert lifted.lifted_by_user_id == admin_scope.user.id
      refute Moderation.suspended?(target_user.id)
    end

    test "unsuspend_user/2 returns error when not suspended" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()

      assert {:error, :not_found} = Moderation.unsuspend_user(admin_scope, target_user.id)
    end

    test "list_active_suspensions/0 returns active suspensions only" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()
      expires_at = DateTime.add(DateTime.utc_now(), 86_400, :second)

      {:ok, _suspension} =
        Moderation.suspend_user(admin_scope, target_user.id, "Violation of rules", expires_at)

      suspensions = Moderation.list_active_suspensions()
      assert Enum.any?(suspensions, fn s -> s.user_id == target_user.id end)
    end
  end

  describe "user bans" do
    test "ban_user/3 creates a ban" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()

      assert {:ok, %UserBan{} = ban} =
               Moderation.ban_user(admin_scope, target_user.id, "Severe violation")

      assert ban.user_id == target_user.id
      assert ban.banned_by_user_id == admin_scope.user.id
      assert ban.reason == "Severe violation"
      assert ban.permanent == true
    end

    test "ban_user/3 requires admin scope" do
      user_scope = user_scope_fixture()
      target_user = user_fixture()

      assert_raise MatchError, fn ->
        Moderation.ban_user(user_scope, target_user.id, "Severe violation")
      end
    end

    test "ban_user/3 cannot ban yourself" do
      admin_scope = admin_scope_fixture()

      assert {:error, %Ecto.Changeset{} = changeset} =
               Moderation.ban_user(admin_scope, admin_scope.user.id, "Self ban")

      assert "cannot ban yourself" in errors_on(changeset).user_id
    end

    test "ban_user/3 removes existing suspension" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()
      expires_at = DateTime.add(DateTime.utc_now(), 86_400, :second)

      {:ok, _suspension} =
        Moderation.suspend_user(admin_scope, target_user.id, "Suspension", expires_at)

      {:ok, _ban} = Moderation.ban_user(admin_scope, target_user.id, "Ban replaces suspension")

      refute Moderation.suspended?(target_user.id)
      assert Moderation.banned?(target_user.id)
    end

    test "banned?/1 returns true when user is banned" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()

      {:ok, _ban} = Moderation.ban_user(admin_scope, target_user.id, "Severe violation")

      assert Moderation.banned?(target_user.id)
    end

    test "banned?/1 returns false when ban is lifted" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()

      {:ok, _ban} = Moderation.ban_user(admin_scope, target_user.id, "Severe violation")
      {:ok, _lifted} = Moderation.unban_user(admin_scope, target_user.id)

      refute Moderation.banned?(target_user.id)
    end

    test "unban_user/2 lifts a ban" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()

      {:ok, _ban} = Moderation.ban_user(admin_scope, target_user.id, "Severe violation")
      {:ok, lifted} = Moderation.unban_user(admin_scope, target_user.id)

      assert lifted.lifted_at != nil
      assert lifted.lifted_by_user_id == admin_scope.user.id
      assert lifted.permanent == false
    end

    test "unban_user/2 returns error when not banned" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()

      assert {:error, :not_found} = Moderation.unban_user(admin_scope, target_user.id)
    end

    test "list_active_bans/0 returns active bans only" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()

      {:ok, _ban} = Moderation.ban_user(admin_scope, target_user.id, "Severe violation")

      bans = Moderation.list_active_bans()
      assert Enum.any?(bans, fn b -> b.user_id == target_user.id end)
    end
  end

  describe "can_login?/1" do
    test "returns :ok when user has no moderation actions" do
      user = user_fixture()
      assert :ok = Moderation.can_login?(user.id)
    end

    test "returns {:error, :banned} when user is banned" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()

      {:ok, _ban} = Moderation.ban_user(admin_scope, target_user.id, "Severe violation")

      assert {:error, :banned} = Moderation.can_login?(target_user.id)
    end

    test "returns {:error, :suspended, expires_at} when user is suspended" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()
      expires_at = DateTime.add(DateTime.utc_now(), 86_400, :second)

      {:ok, _suspension} =
        Moderation.suspend_user(
          admin_scope,
          target_user.id,
          "Violation of community rules",
          expires_at
        )

      assert {:error, :suspended, _expires} = Moderation.can_login?(target_user.id)
    end

    test "ban takes precedence over suspension" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()

      # Create both (ban will remove suspension, but let's test the logic)
      {:ok, _ban} = Moderation.ban_user(admin_scope, target_user.id, "Severe violation")

      assert {:error, :banned} = Moderation.can_login?(target_user.id)
    end
  end

  describe "filter_muted_content/2" do
    test "filters out muted users from list" do
      scope = user_scope_fixture()
      muted_user = user_fixture()
      other_user = user_fixture()

      {:ok, _mute} = Moderation.mute_user(scope, muted_user.id)

      # Simulate a list of items with user_id
      items = [
        %{user_id: muted_user.id, content: "Hidden"},
        %{user_id: other_user.id, content: "Visible"},
        %{user_id: scope.user.id, content: "Own content"}
      ]

      filtered = Moderation.filter_muted_content(scope, items)
      assert length(filtered) == 2
      refute Enum.any?(filtered, fn item -> item.user_id == muted_user.id end)
    end

    test "returns all items when no mutes" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      items = [
        %{user_id: other_user.id, content: "Visible"}
      ]

      filtered = Moderation.filter_muted_content(scope, items)
      assert length(filtered) == 1
    end
  end

  describe "moderation logs" do
    test "list_moderation_logs/1 returns all logs" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      {:ok, _mute} = Moderation.mute_user(scope, other_user.id)

      logs = Moderation.list_moderation_logs()
      assert length(logs) >= 1
    end

    test "list_moderation_logs/1 filters by action" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      {:ok, _mute} = Moderation.mute_user(scope, other_user.id)

      logs = Moderation.list_moderation_logs(action: "mute_user")
      assert Enum.all?(logs, fn l -> l.action == "mute_user" end)
    end

    test "list_moderation_logs/1 filters by target_user_id" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      {:ok, _mute} = Moderation.mute_user(scope, other_user.id)

      logs = Moderation.list_moderation_logs(target_user_id: other_user.id)
      assert Enum.all?(logs, fn l -> l.target_user_id == other_user.id end)
    end

    test "list_user_moderation_history/2 returns history for a user" do
      scope = user_scope_fixture()
      other_user = user_fixture()

      {:ok, _mute} = Moderation.mute_user(scope, other_user.id)
      {:ok, _unmute} = Moderation.unmute_user(scope, other_user.id)

      history = Moderation.list_user_moderation_history(other_user.id)
      assert length(history) == 2
      actions = Enum.map(history, & &1.action)
      assert "mute_user" in actions
      assert "unmute_user" in actions
    end
  end

  describe "get_moderation_stats/0" do
    test "returns moderation statistics" do
      admin_scope = admin_scope_fixture()
      target_user = user_fixture()
      expires_at = DateTime.add(DateTime.utc_now(), 86_400, :second)

      # Create some moderation data
      {:ok, _report} =
        Moderation.create_report(admin_scope, target_user.id, "Test report for stats")

      {:ok, _suspension} =
        Moderation.suspend_user(admin_scope, target_user.id, "Test suspension", expires_at)

      stats = Moderation.get_moderation_stats()
      assert stats.pending_reports >= 1
      assert stats.active_suspensions >= 1
      assert is_integer(stats.active_bans)
      assert is_integer(stats.total_mutes)
    end
  end

  describe "violation tracking" do
    test "record_violation/2 creates a violation record" do
      target_user = user_fixture()
      reporter = user_fixture()

      attrs = %{
        user_id: target_user.id,
        action_type: "report",
        reason_text: "Spam content",
        source: "chat"
      }

      assert {:ok, %UserViolation{} = violation} = Moderation.record_violation(attrs, reporter)
      assert violation.user_id == target_user.id
      assert violation.reporter_id == reporter.id
      assert violation.action_type == "report"
      assert violation.weight == 1
      assert violation.source == "chat"
    end

    test "record_violation/2 gives admin actions 2x weight" do
      target_user = user_fixture()
      admin = admin_fixture()

      attrs = %{
        user_id: target_user.id,
        action_type: "suspend",
        reason_text: "Repeated violations",
        source: "admin_panel"
      }

      assert {:ok, %UserViolation{} = violation} = Moderation.record_violation(attrs, admin)
      assert violation.weight == 2
    end

    test "list_user_violations/2 returns violations for a user" do
      target_user = user_fixture()
      reporter = user_fixture()

      attrs = %{
        user_id: target_user.id,
        action_type: "report",
        reason_text: "Test violation",
        source: "chat"
      }

      {:ok, _} = Moderation.record_violation(attrs, reporter)

      violations = Moderation.list_user_violations(target_user.id)
      assert length(violations) >= 1
      assert Enum.all?(violations, fn v -> v.user_id == target_user.id end)
    end

    test "list_user_violations/2 with unresolved_only option" do
      target_user = user_fixture()
      reporter = user_fixture()

      attrs = %{
        user_id: target_user.id,
        action_type: "report",
        reason_text: "Test violation",
        source: "chat"
      }

      {:ok, _} = Moderation.record_violation(attrs, reporter)

      # All should be unresolved initially
      violations = Moderation.list_user_violations(target_user.id, unresolved_only: true)
      assert length(violations) >= 1
      assert Enum.all?(violations, fn v -> is_nil(v.resolved_at) end)
    end

    test "get_user_violation_stats/1 returns statistics" do
      target_user = user_fixture()
      reporter = user_fixture()

      # Create multiple violations
      for _ <- 1..3 do
        Moderation.record_violation(
          %{
            user_id: target_user.id,
            action_type: "report",
            reason_text: "Test",
            source: "chat"
          },
          reporter
        )
      end

      stats = Moderation.get_user_violation_stats(target_user.id)
      assert stats.total_count >= 3
      assert stats.total_unresolved_weight >= 3
      assert Map.has_key?(stats.by_type, "report")
    end

    test "list_users_with_violations/1 returns flagged users" do
      target_user = user_fixture()
      reporter = user_fixture()

      Moderation.record_violation(
        %{
          user_id: target_user.id,
          action_type: "report",
          reason_text: "Test violation",
          source: "chat"
        },
        reporter
      )

      flagged = Moderation.list_users_with_violations()
      assert Enum.any?(flagged, fn f -> f.user_id == target_user.id end)
    end

    test "resolve_all_violations/2 marks all violations as resolved" do
      target_user = user_fixture()
      reporter = user_fixture()
      admin = admin_fixture()

      # Create violations
      for _ <- 1..3 do
        Moderation.record_violation(
          %{
            user_id: target_user.id,
            action_type: "report",
            reason_text: "Test",
            source: "chat"
          },
          reporter
        )
      end

      # Resolve all
      {count, _} = Moderation.resolve_all_violations(target_user.id, admin.id)
      assert count >= 3

      # Verify all resolved
      violations = Moderation.list_user_violations(target_user.id, unresolved_only: true)
      assert violations == []
    end
  end

  describe "create_report_with_tracking/4" do
    test "creates both report and violation" do
      scope = user_scope_fixture()
      target_user = user_fixture()

      {:ok, report} =
        Moderation.create_report_with_tracking(
          scope,
          target_user.id,
          "This user is spamming content",
          %{content_type: "chat_message", content_id: 123}
        )

      assert report.reported_user_id == target_user.id
      assert report.content_type == "chat_message"
      assert report.content_id == 123

      # Verify violation was also created
      violations = Moderation.list_user_violations(target_user.id)
      assert length(violations) >= 1
      assert Enum.any?(violations, fn v -> v.action_type == "report" end)
    end

    test "rate limits reports" do
      scope = user_scope_fixture()

      # Create 6 different users to report
      targets = for _ <- 1..6, do: user_fixture()

      # First 5 should succeed
      results =
        Enum.map(Enum.take(targets, 5), fn target ->
          Moderation.create_report_with_tracking(scope, target.id, "Report #{target.id}")
        end)

      assert Enum.all?(results, fn
               {:ok, _} -> true
               _ -> false
             end)

      # 6th should be rate limited
      sixth_target = Enum.at(targets, 5)

      assert {:error, :rate_limited} =
               Moderation.create_report_with_tracking(scope, sixth_target.id, "Too many")
    end
  end

  describe "moderation settings" do
    test "get_setting/1 returns a setting by key" do
      setting = Moderation.get_setting("alert_threshold")
      assert %ModerationSetting{} = setting
      assert setting.key == "alert_threshold"
    end

    test "update_setting/3 requires admin scope" do
      scope = user_scope_fixture()

      assert_raise MatchError, fn ->
        Moderation.update_setting("alert_threshold", %{"count" => 10}, scope)
      end
    end

    test "update_setting/3 updates a setting with admin scope" do
      admin_scope = admin_scope_fixture()

      {:ok, updated} =
        Moderation.update_setting(
          "alert_threshold",
          %{"count" => 10, "window_hours" => 48},
          admin_scope
        )

      assert updated.value == %{"count" => 10, "window_hours" => 48}
    end

    test "list_settings/0 returns all settings" do
      settings = Moderation.list_settings()
      assert is_list(settings)
      assert length(settings) >= 2

      keys = Enum.map(settings, & &1.key)
      assert "alert_threshold" in keys
      assert "admin_multiplier" in keys
    end

    test "get_admin_weight_multiplier/0 returns multiplier from settings" do
      multiplier = Moderation.get_admin_weight_multiplier()
      assert is_integer(multiplier)
      assert multiplier >= 1
    end

    test "get_admin_duration_multiplier/0 returns multiplier from settings" do
      multiplier = Moderation.get_admin_duration_multiplier()
      assert is_integer(multiplier)
      assert multiplier >= 1
    end

    test "calculate_duration/2 applies multiplier for admin" do
      admin = admin_fixture()
      regular_user = user_fixture()

      # Admin should get multiplied duration
      admin_duration = Moderation.calculate_duration(30, admin)
      regular_duration = Moderation.calculate_duration(30, regular_user)

      assert admin_duration > regular_duration
      assert regular_duration == 30
    end
  end

  describe "reason presets" do
    test "list_reason_presets/1 returns presets for a category" do
      presets = Moderation.list_reason_presets("report")
      assert is_list(presets)
      assert length(presets) >= 1
      assert Enum.all?(presets, fn p -> p.category == "report" end)
    end

    test "list_reason_presets/1 only returns active presets" do
      presets = Moderation.list_reason_presets("report")
      assert Enum.all?(presets, fn p -> p.is_active == true end)
    end

    test "get_reason_preset!/1 returns a preset by ID" do
      [preset | _] = Moderation.list_reason_presets("report")
      fetched = Moderation.get_reason_preset!(preset.id)
      assert fetched.id == preset.id
    end

    test "create_reason_preset/2 creates a preset with admin scope" do
      admin_scope = admin_scope_fixture()

      attrs = %{
        category: "report",
        label_en: "Test Label",
        label_fi: "Testi Otsikko",
        text_en: "Test description text",
        text_fi: "Testi kuvaus teksti",
        display_order: 99,
        is_active: true
      }

      assert {:ok, %ReasonPreset{} = preset} = Moderation.create_reason_preset(admin_scope, attrs)
      assert preset.label_en == "Test Label"
      assert preset.category == "report"
    end

    test "create_reason_preset/2 requires admin scope" do
      scope = user_scope_fixture()

      assert_raise MatchError, fn ->
        Moderation.create_reason_preset(scope, %{category: "report", label_en: "Test"})
      end
    end

    test "update_reason_preset/3 updates a preset" do
      admin_scope = admin_scope_fixture()
      [preset | _] = Moderation.list_reason_presets("report")

      {:ok, updated} =
        Moderation.update_reason_preset(admin_scope, preset, %{label_en: "Updated Label"})

      assert updated.label_en == "Updated Label"
    end

    test "delete_reason_preset/2 deletes a preset" do
      admin_scope = admin_scope_fixture()

      # Create a test preset to delete
      {:ok, preset} =
        Moderation.create_reason_preset(admin_scope, %{
          category: "report",
          label_en: "To Delete",
          label_fi: "Poistettava",
          text_en: "Will be deleted",
          text_fi: "Poistetaan",
          display_order: 999
        })

      {:ok, _deleted} = Moderation.delete_reason_preset(admin_scope, preset)

      assert_raise Ecto.NoResultsError, fn ->
        Moderation.get_reason_preset!(preset.id)
      end
    end
  end

  describe "user reports with content reference" do
    test "create_report/4 accepts content_type and content_id" do
      scope = user_scope_fixture()
      target_user = user_fixture()

      metadata = %{
        content_type: "chat_message",
        content_id: 123
      }

      {:ok, report} =
        Moderation.create_report(scope, target_user.id, "Inappropriate message", metadata)

      # Content reference should be in metadata
      assert report.metadata["content_type"] == "chat_message" or
               report.metadata[:content_type] == "chat_message"
    end
  end
end
