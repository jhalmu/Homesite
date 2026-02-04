defmodule Homesite.ThreatReputation.MonitorTest do
  use Homesite.DataCase, async: false

  alias Homesite.ThreatReputation.Monitor
  alias Homesite.ThreatReputation.ThreatEvent

  setup do
    # Reset monitor state before each test
    Monitor.reset()
    :ok
  end

  describe "record_event/1" do
    test "should track events in the sliding window" do
      event = build_event("192.168.1.1", "failed_login")
      Monitor.record_event(event)

      stats = Monitor.get_stats()
      assert stats.events_in_window == 1
      assert stats.unique_ips_in_window == 1
    end

    test "should track multiple events from same IP" do
      ip = "192.168.1.100"

      for _ <- 1..5 do
        Monitor.record_event(build_event(ip, "failed_login"))
      end

      stats = Monitor.get_stats()
      assert stats.events_in_window == 5
      assert stats.unique_ips_in_window == 1

      top_ips = stats.top_ips
      assert length(top_ips) == 1
      assert hd(top_ips).ip == ip
      assert hd(top_ips).count == 5
    end

    test "should track events from multiple IPs" do
      for i <- 1..3 do
        Monitor.record_event(build_event("192.168.1.#{i}", "failed_login"))
      end

      stats = Monitor.get_stats()
      assert stats.events_in_window == 3
      assert stats.unique_ips_in_window == 3
    end
  end

  describe "get_stats/0" do
    test "should return monitoring statistics" do
      stats = Monitor.get_stats()

      assert Map.has_key?(stats, :total_events)
      assert Map.has_key?(stats, :events_in_window)
      assert Map.has_key?(stats, :unique_ips_in_window)
      assert Map.has_key?(stats, :events_per_minute)
      assert Map.has_key?(stats, :top_ips)
      assert Map.has_key?(stats, :window_size_seconds)
    end

    test "should calculate events per minute" do
      # Add some events (use different IPs to avoid brute force detection)
      for i <- 1..5 do
        Monitor.record_event(build_event("192.168.1.#{i}", "failed_login"))
      end

      stats = Monitor.get_stats()
      # 5 events in 5 minute window = 1 event/minute
      assert stats.events_per_minute == 1.0
    end
  end

  describe "get_active_threats/0" do
    test "should return list of active threat IPs sorted by count" do
      # Add events with different counts
      for _ <- 1..5 do
        Monitor.record_event(build_event("192.168.1.1", "failed_login"))
      end

      for _ <- 1..3 do
        Monitor.record_event(build_event("192.168.1.2", "failed_login"))
      end

      Monitor.record_event(build_event("192.168.1.3", "failed_login"))

      threats = Monitor.get_active_threats()
      assert length(threats) == 3

      # Should be sorted by count descending
      [first, second, third] = threats
      assert first.ip == "192.168.1.1"
      assert first.event_count == 5
      assert second.ip == "192.168.1.2"
      assert second.event_count == 3
      assert third.ip == "192.168.1.3"
      assert third.event_count == 1
    end
  end

  describe "get_recent_attacks/0" do
    test "should return empty list initially" do
      attacks = Monitor.get_recent_attacks()
      assert attacks == []
    end
  end

  describe "reset/0" do
    test "should clear all monitoring state" do
      # Add some events
      for _ <- 1..5 do
        Monitor.record_event(build_event("192.168.1.1", "failed_login"))
      end

      stats_before = Monitor.get_stats()
      assert stats_before.events_in_window == 5

      # Reset
      :ok = Monitor.reset()

      stats_after = Monitor.get_stats()
      assert stats_after.events_in_window == 0
      assert stats_after.unique_ips_in_window == 0
    end
  end

  describe "topic/0" do
    test "should return the PubSub topic" do
      assert Monitor.topic() == "threat_monitor"
    end
  end

  describe "PubSub broadcasts" do
    test "should broadcast threat_event when event is recorded" do
      Phoenix.PubSub.subscribe(Homesite.PubSub, Monitor.topic())

      event = build_event("192.168.1.1", "failed_login")
      Monitor.record_event(event)

      assert_receive {:threat_event, ^event}, 1000
    end
  end

  describe "username tracking" do
    test "should track unique usernames from event details" do
      # Events with email in details
      Monitor.record_event(
        build_event("192.168.1.1", "failed_login", %{"email" => "user1@test.com"})
      )

      Monitor.record_event(
        build_event("192.168.1.2", "failed_login", %{"email" => "user2@test.com"})
      )

      Monitor.record_event(
        build_event("192.168.1.3", "failed_login", %{"email" => "user1@test.com"})
      )

      stats = Monitor.get_stats()
      assert stats.unique_usernames_in_window == 2
    end
  end

  describe "attack detection" do
    test "should detect brute force attack when threshold exceeded" do
      Phoenix.PubSub.subscribe(Homesite.PubSub, Monitor.topic())
      ip = "10.0.0.99"

      # Send enough events to trigger brute force detection (threshold is 10)
      for _ <- 1..10 do
        Monitor.record_event(build_event(ip, "failed_login"))
      end

      # Should receive attack detection broadcast
      assert_receive {:attack_detected, %{type: :brute_force, ip: ^ip}}, 1000

      attacks = Monitor.get_recent_attacks()
      assert length(attacks) >= 1
      assert Enum.any?(attacks, fn a -> a.type == :brute_force and a.ip == ip end)
    end

    test "should detect distributed attack when many IPs attack" do
      Phoenix.PubSub.subscribe(Homesite.PubSub, Monitor.topic())

      # Send events from many different IPs (threshold is 5 IPs with 10+ events)
      for i <- 1..6 do
        for _ <- 1..2 do
          Monitor.record_event(build_event("10.0.1.#{i}", "failed_login"))
        end
      end

      # Should receive distributed attack detection (5+ IPs, 10+ events)
      assert_receive {:attack_detected, %{type: :distributed_attack}}, 1000
    end
  end

  # Helper to build a threat event struct
  defp build_event(ip_address, event_type, details \\ %{}) do
    %ThreatEvent{
      ip_address: ip_address,
      event_type: event_type,
      severity: "medium",
      score_impact: 5,
      details: details,
      inserted_at: DateTime.utc_now()
    }
  end
end
