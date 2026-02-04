defmodule Homesite.SettingsSecurityAlertsTest do
  use Homesite.DataCase, async: true

  alias Homesite.Settings

  describe "security_alert_config/0" do
    test "returns default config when not set" do
      config = Settings.security_alert_config()

      assert config.enabled == false
      assert config.level == :critical
      assert config.threshold == 100
    end

    test "returns stored config" do
      Settings.update_security_alert_config(%{
        enabled: true,
        level: :auto_blocks,
        threshold: 50
      })

      config = Settings.security_alert_config()

      assert config.enabled == true
      assert config.level == :auto_blocks
      assert config.threshold == 50
    end
  end

  describe "security_alerts_enabled?/0" do
    test "returns false by default" do
      refute Settings.security_alerts_enabled?()
    end

    test "returns true when enabled" do
      Settings.update_security_alert_config(%{enabled: true, level: :critical})

      assert Settings.security_alerts_enabled?()
    end
  end

  describe "security_alert_level/0" do
    test "returns :critical by default" do
      assert Settings.security_alert_level() == :critical
    end

    test "returns configured level" do
      Settings.update_security_alert_config(%{enabled: true, level: :verbose})

      assert Settings.security_alert_level() == :verbose
    end
  end

  describe "update_security_alert_config/1" do
    test "creates config if it doesn't exist" do
      assert {:ok, _} =
               Settings.update_security_alert_config(%{
                 enabled: true,
                 level: :threshold,
                 threshold: 75
               })

      config = Settings.security_alert_config()
      assert config.enabled == true
      assert config.level == :threshold
      assert config.threshold == 75
    end

    test "updates existing config" do
      Settings.update_security_alert_config(%{enabled: true, level: :critical})
      Settings.update_security_alert_config(%{enabled: false, level: :verbose, threshold: 200})

      config = Settings.security_alert_config()
      assert config.enabled == false
      assert config.level == :verbose
      assert config.threshold == 200
    end

    test "accepts string keys" do
      assert {:ok, _} =
               Settings.update_security_alert_config(%{
                 "enabled" => true,
                 "level" => "auto_blocks",
                 "threshold" => 60
               })

      config = Settings.security_alert_config()
      assert config.enabled == true
      assert config.level == :auto_blocks
      assert config.threshold == 60
    end
  end

  describe "alert_levels/0" do
    test "returns all alert levels" do
      levels = Settings.alert_levels()

      assert levels == [:critical, :auto_blocks, :threshold, :verbose]
    end
  end

  describe "should_alert?/1" do
    test "returns false when alerts disabled" do
      Settings.update_security_alert_config(%{enabled: false, level: :verbose})

      refute Settings.should_alert?(:attack_detected)
      refute Settings.should_alert?(:ip_auto_blocked)
      refute Settings.should_alert?(:threshold_exceeded)
      refute Settings.should_alert?(:ip_warning)
    end

    test "critical level only alerts on attacks" do
      Settings.update_security_alert_config(%{enabled: true, level: :critical})

      assert Settings.should_alert?(:attack_detected)
      refute Settings.should_alert?(:ip_auto_blocked)
      refute Settings.should_alert?(:threshold_exceeded)
      refute Settings.should_alert?(:ip_warning)
    end

    test "auto_blocks level alerts on attacks and blocks" do
      Settings.update_security_alert_config(%{enabled: true, level: :auto_blocks})

      assert Settings.should_alert?(:attack_detected)
      assert Settings.should_alert?(:ip_auto_blocked)
      refute Settings.should_alert?(:threshold_exceeded)
      refute Settings.should_alert?(:ip_warning)
    end

    test "threshold level alerts on attacks, blocks, and threshold" do
      Settings.update_security_alert_config(%{enabled: true, level: :threshold})

      assert Settings.should_alert?(:attack_detected)
      assert Settings.should_alert?(:ip_auto_blocked)
      assert Settings.should_alert?(:threshold_exceeded)
      refute Settings.should_alert?(:ip_warning)
    end

    test "verbose level alerts on everything" do
      Settings.update_security_alert_config(%{enabled: true, level: :verbose})

      assert Settings.should_alert?(:attack_detected)
      assert Settings.should_alert?(:ip_auto_blocked)
      assert Settings.should_alert?(:threshold_exceeded)
      assert Settings.should_alert?(:ip_warning)
    end

    test "returns false for unknown alert types" do
      Settings.update_security_alert_config(%{enabled: true, level: :verbose})

      refute Settings.should_alert?(:unknown_type)
    end
  end
end
