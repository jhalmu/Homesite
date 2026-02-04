defmodule Homesite.ThreatReputation.Monitor do
  @moduledoc """
  Real-time threat monitoring GenServer.

  Tracks threat events in sliding windows and detects attack patterns:
  - Brute force attacks (many failed logins from single IP)
  - Credential stuffing (many failed logins across many usernames)
  - Distributed attacks (many IPs targeting same resource)

  Broadcasts updates via PubSub for live dashboard updates.

  ## Usage

      # Get current monitoring stats
      Monitor.get_stats()

      # Subscribe to real-time updates
      Phoenix.PubSub.subscribe(Homesite.PubSub, "threat_monitor")

  ## PubSub Events

      {:threat_event, event}           - New threat event recorded
      {:attack_detected, attack_info}  - Attack pattern detected
      {:stats_updated, stats}          - Stats update (every 10 seconds)
  """

  use GenServer

  require Logger

  @pubsub Homesite.PubSub
  @topic "threat_monitor"

  # Sliding window configuration
  @window_size_seconds 300
  @bucket_size_seconds 10
  @num_buckets div(@window_size_seconds, @bucket_size_seconds)

  # Attack detection thresholds
  @brute_force_threshold 10
  @credential_stuffing_threshold 20
  @distributed_attack_threshold 5

  # Stats broadcast interval
  @stats_interval_ms 10_000

  # State structure
  defstruct [
    # Sliding window buckets for events: %{bucket_index => [events]}
    :event_buckets,
    # Current bucket index
    :current_bucket,
    # Tracked IPs in window: %{ip => count}
    :ip_counts,
    # Tracked usernames in window: %{username => count}
    :username_counts,
    # Recent attacks detected
    :recent_attacks,
    # Stats
    :total_events,
    :events_in_window,
    :unique_ips_in_window,
    # Timers
    :bucket_timer,
    :stats_timer
  ]

  # Client API

  @doc """
  Starts the threat monitor.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Records a threat event for real-time monitoring.

  Called from ThreatReputation.record_threat_event/3.
  """
  def record_event(event) do
    GenServer.cast(__MODULE__, {:record_event, event})
  end

  @doc """
  Gets current monitoring statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  @doc """
  Gets recent detected attacks.
  """
  def get_recent_attacks do
    GenServer.call(__MODULE__, :get_recent_attacks)
  end

  @doc """
  Gets the list of currently active threat IPs (in the sliding window).
  """
  def get_active_threats do
    GenServer.call(__MODULE__, :get_active_threats)
  end

  @doc """
  Resets all monitoring state.
  """
  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  @doc """
  Returns the PubSub topic for threat monitoring updates.
  """
  def topic, do: @topic

  # Server Callbacks

  @impl true
  def init(_opts) do
    state = %__MODULE__{
      event_buckets: init_buckets(),
      current_bucket: 0,
      ip_counts: %{},
      username_counts: %{},
      recent_attacks: [],
      total_events: 0,
      events_in_window: 0,
      unique_ips_in_window: 0,
      bucket_timer: nil,
      stats_timer: nil
    }

    # Start timers
    bucket_timer = Process.send_after(self(), :rotate_bucket, @bucket_size_seconds * 1000)
    stats_timer = Process.send_after(self(), :broadcast_stats, @stats_interval_ms)

    state = %{state | bucket_timer: bucket_timer, stats_timer: stats_timer}

    Logger.info("ThreatReputation.Monitor started")
    {:ok, state}
  end

  @impl true
  def handle_cast({:record_event, event}, state) do
    state = add_event(state, event)

    # Broadcast the event
    Phoenix.PubSub.broadcast(@pubsub, @topic, {:threat_event, event})

    # Check for attack patterns
    state = detect_attacks(state, event)

    {:noreply, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = build_stats(state)
    {:reply, stats, state}
  end

  def handle_call(:get_recent_attacks, _from, state) do
    {:reply, Enum.take(state.recent_attacks, 20), state}
  end

  def handle_call(:get_active_threats, _from, state) do
    threats =
      state.ip_counts
      |> Enum.sort_by(fn {_ip, count} -> count end, :desc)
      |> Enum.take(50)
      |> Enum.map(fn {ip, count} -> %{ip: ip, event_count: count} end)

    {:reply, threats, state}
  end

  def handle_call(:reset, _from, state) do
    new_state = %{
      state
      | event_buckets: init_buckets(),
        current_bucket: 0,
        ip_counts: %{},
        username_counts: %{},
        recent_attacks: [],
        total_events: 0,
        events_in_window: 0,
        unique_ips_in_window: 0
    }

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_info(:rotate_bucket, state) do
    state = rotate_bucket(state)

    # Schedule next rotation
    bucket_timer = Process.send_after(self(), :rotate_bucket, @bucket_size_seconds * 1000)

    {:noreply, %{state | bucket_timer: bucket_timer}}
  end

  def handle_info(:broadcast_stats, state) do
    stats = build_stats(state)
    Phoenix.PubSub.broadcast(@pubsub, @topic, {:stats_updated, stats})

    # Schedule next broadcast
    stats_timer = Process.send_after(self(), :broadcast_stats, @stats_interval_ms)

    {:noreply, %{state | stats_timer: stats_timer}}
  end

  # Private functions

  defp init_buckets do
    0..(@num_buckets - 1)
    |> Enum.map(fn i -> {i, []} end)
    |> Map.new()
  end

  defp add_event(state, event) do
    bucket = state.current_bucket
    events = [event | Map.get(state.event_buckets, bucket, [])]
    event_buckets = Map.put(state.event_buckets, bucket, events)

    # Update IP counts
    ip = event.ip_address
    ip_counts = Map.update(state.ip_counts, ip, 1, &(&1 + 1))

    # Update username counts if present
    username = get_in(event.details, ["email"]) || get_in(event.details, [:email])

    username_counts =
      if username do
        Map.update(state.username_counts, username, 1, &(&1 + 1))
      else
        state.username_counts
      end

    %{
      state
      | event_buckets: event_buckets,
        ip_counts: ip_counts,
        username_counts: username_counts,
        total_events: state.total_events + 1,
        events_in_window: state.events_in_window + 1,
        unique_ips_in_window: map_size(ip_counts)
    }
  end

  defp rotate_bucket(state) do
    # Move to next bucket
    next_bucket = rem(state.current_bucket + 1, @num_buckets)

    # Get events being evicted (oldest bucket)
    evicted_events = Map.get(state.event_buckets, next_bucket, [])

    # Update counts by removing evicted events
    {ip_counts, username_counts, evicted_count} =
      Enum.reduce(evicted_events, {state.ip_counts, state.username_counts, 0}, fn event,
                                                                                  {ips, users,
                                                                                   count} ->
        ip = event.ip_address
        username = get_in(event.details, ["email"]) || get_in(event.details, [:email])

        ips =
          case Map.get(ips, ip, 0) do
            n when n <= 1 -> Map.delete(ips, ip)
            n -> Map.put(ips, ip, n - 1)
          end

        users =
          if username do
            case Map.get(users, username, 0) do
              n when n <= 1 -> Map.delete(users, username)
              n -> Map.put(users, username, n - 1)
            end
          else
            users
          end

        {ips, users, count + 1}
      end)

    # Clear the bucket for new events
    event_buckets = Map.put(state.event_buckets, next_bucket, [])

    %{
      state
      | event_buckets: event_buckets,
        current_bucket: next_bucket,
        ip_counts: ip_counts,
        username_counts: username_counts,
        events_in_window: max(0, state.events_in_window - evicted_count),
        unique_ips_in_window: map_size(ip_counts)
    }
  end

  defp detect_attacks(state, event) do
    ip = event.ip_address
    ip_count = Map.get(state.ip_counts, ip, 0)

    attacks = []

    # Brute force detection: single IP with many events
    attacks =
      if ip_count >= @brute_force_threshold do
        attack = %{
          type: :brute_force,
          ip: ip,
          event_count: ip_count,
          detected_at: DateTime.utc_now()
        }

        handle_attack(attack)
        [attack | attacks]
      else
        attacks
      end

    # Credential stuffing detection: many unique usernames targeted
    attacks =
      if map_size(state.username_counts) >= @credential_stuffing_threshold do
        attack = %{
          type: :credential_stuffing,
          unique_usernames: map_size(state.username_counts),
          detected_at: DateTime.utc_now()
        }

        handle_attack(attack)
        [attack | attacks]
      else
        attacks
      end

    # Distributed attack detection: many IPs targeting in short window
    attacks =
      if state.unique_ips_in_window >= @distributed_attack_threshold and
           state.events_in_window >= @distributed_attack_threshold * 2 do
        attack = %{
          type: :distributed_attack,
          unique_ips: state.unique_ips_in_window,
          event_count: state.events_in_window,
          detected_at: DateTime.utc_now()
        }

        handle_attack(attack)
        [attack | attacks]
      else
        attacks
      end

    # Add new attacks to recent list (dedupe by type within last minute)
    recent_attacks = add_attacks_to_recent(state.recent_attacks, attacks)

    %{state | recent_attacks: recent_attacks}
  end

  defp add_attacks_to_recent(recent, new_attacks) do
    one_minute_ago = DateTime.add(DateTime.utc_now(), -60, :second)

    # Filter out old attacks
    recent =
      Enum.filter(recent, fn attack ->
        DateTime.compare(attack.detected_at, one_minute_ago) == :gt
      end)

    # Add new attacks if not duplicate type in last minute
    Enum.reduce(new_attacks, recent, fn attack, acc ->
      already_reported =
        Enum.any?(acc, fn existing ->
          existing.type == attack.type and
            DateTime.compare(existing.detected_at, one_minute_ago) == :gt
        end)

      if already_reported do
        acc
      else
        [attack | acc]
      end
    end)
    |> Enum.take(100)
  end

  defp handle_attack(attack) do
    # Broadcast attack detection
    Phoenix.PubSub.broadcast(@pubsub, @topic, {:attack_detected, attack})

    # Log the attack
    Logger.warning("Attack detected: #{inspect(attack)}")

    # Auto-blocking is handled by subscribers listening to :attack_detected events
    # This keeps the monitor stateless with respect to the database
    :ok
  end

  defp build_stats(state) do
    %{
      total_events: state.total_events,
      events_in_window: state.events_in_window,
      unique_ips_in_window: state.unique_ips_in_window,
      unique_usernames_in_window: map_size(state.username_counts),
      window_size_seconds: @window_size_seconds,
      events_per_minute: calculate_events_per_minute(state),
      top_ips:
        state.ip_counts
        |> Enum.sort_by(fn {_ip, count} -> count end, :desc)
        |> Enum.take(10)
        |> Enum.map(fn {ip, count} -> %{ip: ip, count: count} end),
      recent_attack_count: length(state.recent_attacks)
    }
  end

  defp calculate_events_per_minute(state) do
    # Events per minute = events in window / (window size in minutes)
    window_minutes = @window_size_seconds / 60
    Float.round(state.events_in_window / window_minutes, 1)
  end
end
