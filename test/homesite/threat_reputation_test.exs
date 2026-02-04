defmodule Homesite.ThreatReputationTest do
  use Homesite.DataCase, async: true

  alias Homesite.ThreatReputation
  alias Homesite.ThreatReputation.IpReputation
  import Homesite.AccountsFixtures

  describe "check_ip_status/1" do
    test "returns default status for unknown IP" do
      status = ThreatReputation.check_ip_status("192.168.1.1")

      assert status.blocked == false
      assert status.score == 0
      assert status.action == :normal
    end
  end

  describe "calculate_ip_score/1" do
    test "returns zero score for unknown IP" do
      score_data = ThreatReputation.calculate_ip_score("10.0.0.1")

      assert score_data.total == 0
      assert score_data.failed_login_score == 0
      assert score_data.threshold_action == :normal
    end
  end

  describe "record_threat_event/3" do
    test "should record a threat event" do
      ip_address = "203.0.113.#{:rand.uniform(255)}"

      assert {:ok, event} =
               ThreatReputation.record_threat_event(ip_address, "failed_login",
                 details: %{"email" => "test@example.com"}
               )

      assert event.ip_address == ip_address
      assert event.event_type == "failed_login"
      assert event.details["email"] == "test@example.com"
    end

    test "should update IP reputation after recording event" do
      ip_address = "203.0.113.#{:rand.uniform(255)}"

      {:ok, _event} = ThreatReputation.record_threat_event(ip_address, "suspicious_activity")

      # IP reputation should be created
      ip_rep = Repo.get_by(IpReputation, ip_address: ip_address)
      assert ip_rep != nil
      assert ip_rep.last_seen_at != nil
    end
  end

  describe "auto_block_ip/2" do
    test "should block an IP with progressive duration" do
      ip_address = "203.0.113.#{:rand.uniform(255)}"

      # First block - 15 minutes
      {:ok, ip_rep} = ThreatReputation.auto_block_ip(ip_address, "Test block")

      assert ip_rep.blocked == true
      assert ip_rep.block_count == 1
      assert ip_rep.block_expires_at != nil

      # Check duration is approximately 15 minutes
      duration = DateTime.diff(ip_rep.block_expires_at, ip_rep.blocked_at, :second)
      assert duration == 15 * 60
    end

    test "should increase block duration on subsequent blocks" do
      ip_address = "203.0.113.#{:rand.uniform(255)}"

      # First block
      {:ok, _} = ThreatReputation.auto_block_ip(ip_address)

      # Unblock
      {:ok, _} = ThreatReputation.unblock_ip(ip_address)

      # Second block - should be 1 hour
      {:ok, ip_rep} = ThreatReputation.auto_block_ip(ip_address)

      assert ip_rep.block_count == 2
      duration = DateTime.diff(ip_rep.block_expires_at, ip_rep.blocked_at, :second)
      assert duration == 60 * 60
    end
  end

  describe "unblock_ip/2" do
    test "should unblock a blocked IP" do
      ip_address = "203.0.113.#{:rand.uniform(255)}"

      {:ok, _} = ThreatReputation.auto_block_ip(ip_address)
      {:ok, ip_rep} = ThreatReputation.unblock_ip(ip_address)

      assert ip_rep.blocked == false
      assert ip_rep.blocked_at == nil
      assert ip_rep.block_expires_at == nil
    end

    test "should return error for non-existent IP" do
      assert {:error, :not_found} = ThreatReputation.unblock_ip("192.0.2.1")
    end
  end

  describe "IP watchlist" do
    setup do
      admin = user_fixture(%{role: "admin"})
      %{admin: admin}
    end

    test "should add IP to watchlist", %{admin: admin} do
      ip_address = "203.0.113.#{:rand.uniform(255)}"

      {:ok, entry} =
        ThreatReputation.add_ip_to_watchlist(ip_address, admin,
          boost_score: 10,
          reason: "Test watchlist"
        )

      assert entry.ip_address == ip_address
      assert entry.boost_score == 10
      assert entry.reason == "Test watchlist"
      assert entry.added_by_id == admin.id
    end

    test "should remove IP from watchlist", %{admin: admin} do
      ip_address = "203.0.113.#{:rand.uniform(255)}"
      {:ok, _} = ThreatReputation.add_ip_to_watchlist(ip_address, admin)

      assert {:ok, _} = ThreatReputation.remove_ip_from_watchlist(ip_address)
      assert ThreatReputation.get_ip_watchlist_entry(ip_address) == nil
    end

    test "watchlist boost should affect IP score", %{admin: admin} do
      ip_address = "203.0.113.#{:rand.uniform(255)}"

      # Score without watchlist
      score_before = ThreatReputation.calculate_ip_score(ip_address)
      assert score_before.watchlist_boost == 0

      # Add to watchlist with boost
      {:ok, _} = ThreatReputation.add_ip_to_watchlist(ip_address, admin, boost_score: 10)

      # Invalidate cache to get fresh score
      ThreatReputation.Cache.invalidate_ip(ip_address)

      score_after = ThreatReputation.calculate_ip_score(ip_address)
      assert score_after.watchlist_boost == 10
    end
  end

  describe "country watchlist" do
    setup do
      admin = user_fixture(%{role: "admin"})
      %{admin: admin}
    end

    test "should add country to watchlist", %{admin: admin} do
      {:ok, entry} =
        ThreatReputation.add_country_to_watchlist("RU", admin,
          boost_score: 15,
          reason: "High risk country"
        )

      assert entry.country_code == "RU"
      assert entry.boost_score == 15
    end

    test "should remove country from watchlist", %{admin: admin} do
      {:ok, _} = ThreatReputation.add_country_to_watchlist("CN", admin)

      assert {:ok, _} = ThreatReputation.remove_country_from_watchlist("CN")
      assert ThreatReputation.get_country_watchlist_entry("CN") == nil
    end
  end

  describe "get_dashboard_stats/0" do
    test "should return dashboard statistics" do
      stats = ThreatReputation.get_dashboard_stats()

      assert is_integer(stats.blocked_ips)
      assert is_integer(stats.high_risk_ips)
      assert is_integer(stats.threat_events_24h)
      assert is_integer(stats.auto_blocks_24h)
      assert is_integer(stats.watchlist_ips)
      assert is_integer(stats.watchlist_countries)
    end
  end

  describe "cleanup functions" do
    test "unblock_expired should unblock expired IPs" do
      ip_address = "203.0.113.#{:rand.uniform(255)}"

      # Create an IP reputation with expired block
      {:ok, ip_rep} =
        %IpReputation{}
        |> IpReputation.changeset(%{
          ip_address: ip_address,
          blocked: true,
          blocked_at: DateTime.add(DateTime.utc_now(), -2, :hour),
          block_expires_at: DateTime.add(DateTime.utc_now(), -1, :hour),
          block_count: 1
        })
        |> Repo.insert()

      assert ip_rep.blocked == true

      # Run cleanup
      count = ThreatReputation.unblock_expired()
      assert count >= 1

      # Verify unblocked
      refreshed = Repo.get(IpReputation, ip_rep.id)
      assert refreshed.blocked == false
    end
  end
end
