defmodule Homesite.SystemTest do
  use ExUnit.Case, async: true

  alias Homesite.System

  describe "version/0" do
    test "returns version in expected format" do
      version = System.version()

      # Format: YYYY.MM.DD-xxxxxxx or with "unknown" if git unavailable
      assert is_binary(version)

      assert Regex.match?(~r/^\d{4}\.\d{2}\.\d{2}-[a-f0-9]+$/, version) or
               version =~ "unknown"
    end
  end

  describe "git_sha/0" do
    test "returns a string" do
      sha = System.git_sha()
      assert is_binary(sha)
    end

    test "returns either a short hash or unknown" do
      sha = System.git_sha()
      assert Regex.match?(~r/^[a-f0-9]{7,}$/, sha) or sha == "unknown"
    end
  end

  describe "build_time/0" do
    test "returns an ISO 8601 timestamp" do
      build_time = System.build_time()
      assert is_binary(build_time)

      # Should be parseable as ISO 8601
      assert {:ok, _dt, _offset} = DateTime.from_iso8601(build_time)
    end
  end

  describe "changelog/0" do
    test "returns a list of grouped commits" do
      changelog = System.changelog()
      assert is_list(changelog)

      for {type, commits} <- changelog do
        assert is_atom(type)
        assert is_list(commits)

        for commit <- commits do
          assert Map.has_key?(commit, :hash)
          assert Map.has_key?(commit, :description)
          assert Map.has_key?(commit, :type)
          assert Map.has_key?(commit, :message)
        end
      end
    end

    test "only includes valid commit types" do
      changelog = System.changelog()

      # All types should be from the known set
      valid_types = [
        :feat,
        :fix,
        :security,
        :perf,
        :refactor,
        :docs,
        :test,
        :i18n,
        :chore,
        :other
      ]

      types = Enum.map(changelog, fn {type, _} -> type end)

      for type <- types do
        assert type in valid_types, "Unexpected type: #{type}"
      end
    end
  end

  describe "runtime_info/0" do
    test "returns expected runtime information keys" do
      info = System.runtime_info()

      assert Map.has_key?(info, :elixir_version)
      assert Map.has_key?(info, :otp_version)
      assert Map.has_key?(info, :phoenix_version)
      assert Map.has_key?(info, :ecto_version)
      assert Map.has_key?(info, :uptime)
      assert Map.has_key?(info, :environment)
    end

    test "returns valid version strings" do
      info = System.runtime_info()

      assert is_binary(info.elixir_version)
      assert is_binary(info.otp_version)
      assert is_binary(info.phoenix_version)
      assert is_binary(info.ecto_version)
    end

    test "returns uptime as a string" do
      info = System.runtime_info()
      assert is_binary(info.uptime)
    end
  end
end
