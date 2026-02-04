defmodule Homesite.ThreatReputation.SecurityAuditLogTest do
  use Homesite.DataCase, async: true

  alias Homesite.ThreatReputation
  alias Homesite.ThreatReputation.SecurityAuditLog

  import Homesite.AccountsFixtures

  describe "security audit logging" do
    setup do
      admin = user_fixture(%{is_admin: true})
      %{admin: admin}
    end

    test "log_security_action/5 creates an audit log entry", %{admin: admin} do
      assert {:ok, log} =
               ThreatReputation.log_security_action(
                 admin,
                 "ip_watchlist_add",
                 "ip_address",
                 "192.168.1.1",
                 details: %{boost_score: 15, reason: "Test"}
               )

      assert log.admin_id == admin.id
      assert log.action_type == "ip_watchlist_add"
      assert log.target_type == "ip_address"
      assert log.target_value == "192.168.1.1"
      assert log.details == %{boost_score: 15, reason: "Test"}
    end

    test "log_security_action/5 includes IP address when provided", %{admin: admin} do
      assert {:ok, log} =
               ThreatReputation.log_security_action(
                 admin,
                 "ip_manual_block",
                 "ip_address",
                 "10.0.0.1",
                 ip_address: "203.0.113.1"
               )

      assert log.ip_address == "203.0.113.1"
    end

    test "list_security_audit_logs/1 returns logs", %{admin: admin} do
      {:ok, _} =
        ThreatReputation.log_security_action(admin, "ip_watchlist_add", "ip_address", "1.1.1.1")

      {:ok, _} =
        ThreatReputation.log_security_action(
          admin,
          "ip_watchlist_remove",
          "ip_address",
          "2.2.2.2"
        )

      {:ok, _} =
        ThreatReputation.log_security_action(admin, "country_watchlist_add", "country_code", "US")

      logs = ThreatReputation.list_security_audit_logs()

      assert length(logs) == 3

      action_types = Enum.map(logs, & &1.action_type)
      assert "ip_watchlist_add" in action_types
      assert "ip_watchlist_remove" in action_types
      assert "country_watchlist_add" in action_types
    end

    test "list_security_audit_logs/1 filters by action_type", %{admin: admin} do
      {:ok, _} =
        ThreatReputation.log_security_action(admin, "ip_watchlist_add", "ip_address", "1.1.1.1")

      {:ok, _} =
        ThreatReputation.log_security_action(
          admin,
          "ip_watchlist_remove",
          "ip_address",
          "2.2.2.2"
        )

      {:ok, _} =
        ThreatReputation.log_security_action(admin, "country_watchlist_add", "country_code", "US")

      logs = ThreatReputation.list_security_audit_logs(action_type: "ip_watchlist_add")

      assert length(logs) == 1
      assert hd(logs).target_value == "1.1.1.1"
    end

    test "list_security_audit_logs/1 filters by admin_id", %{admin: admin} do
      admin2 = user_fixture(%{is_admin: true})

      {:ok, _} =
        ThreatReputation.log_security_action(admin, "ip_watchlist_add", "ip_address", "1.1.1.1")

      {:ok, _} =
        ThreatReputation.log_security_action(admin2, "ip_watchlist_add", "ip_address", "2.2.2.2")

      logs = ThreatReputation.list_security_audit_logs(admin_id: admin.id)

      assert length(logs) == 1
      assert hd(logs).target_value == "1.1.1.1"
    end

    test "count_security_audit_logs/1 returns correct count", %{admin: admin} do
      {:ok, _} =
        ThreatReputation.log_security_action(admin, "ip_watchlist_add", "ip_address", "1.1.1.1")

      {:ok, _} =
        ThreatReputation.log_security_action(admin, "ip_watchlist_add", "ip_address", "2.2.2.2")

      assert ThreatReputation.count_security_audit_logs() == 2
      assert ThreatReputation.count_security_audit_logs(action_type: "ip_watchlist_add") == 2
      assert ThreatReputation.count_security_audit_logs(action_type: "ip_watchlist_remove") == 0
    end
  end

  describe "SecurityAuditLog schema" do
    test "action_types/0 returns valid action types" do
      types = SecurityAuditLog.action_types()

      assert "ip_watchlist_add" in types
      assert "ip_watchlist_remove" in types
      assert "country_watchlist_add" in types
      assert "country_watchlist_remove" in types
      assert "ip_manual_block" in types
      assert "ip_manual_unblock" in types
      assert "threshold_change" in types
      assert "alert_config_change" in types
    end

    test "describe_action/1 returns human-readable descriptions" do
      assert SecurityAuditLog.describe_action("ip_watchlist_add") == "Added IP to watchlist"
      assert SecurityAuditLog.describe_action("ip_manual_block") == "Manually blocked IP"
      assert SecurityAuditLog.describe_action("unknown") == "unknown"
    end
  end
end
