#!/usr/bin/env bash
# Launch Kurek: Headless daemon + Native Swift Menu Bar Indicator

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

DAEMON_PID_FILE="/tmp/kurek_daemon.pid"
BAR_PID_FILE="/tmp/kurek_bar.pid"

case "$1" in
  stop)
    echo "Stopping Kurek..."
    if [ -f "$DAEMON_PID_FILE" ]; then
      kill "$(cat "$DAEMON_PID_FILE")" 2>/dev/null || true
      rm -f "$DAEMON_PID_FILE"
    fi
    if [ -f "$BAR_PID_FILE" ]; then
      kill "$(cat "$BAR_PID_FILE")" 2>/dev/null || true
      rm -f "$BAR_PID_FILE"
    fi
    pkill -f "kurek_daemon.py" 2>/dev/null || true
    pkill -f "kurekbar" 2>/dev/null || true
    pkill -x "Kurek" 2>/dev/null || true
    echo "Kurek stopped."
    exit 0
    ;;
  status)
    if curl -s http://127.0.0.1:8790/status >/dev/null; then
      echo "Kurek daemon is RUNNING: $(curl -s http://127.0.0.1:8790/status)"
    else
      echo "Kurek daemon is NOT running."
    fi
    exit 0
    ;;
  *)
    echo "=========================================================="
    echo "⚡ LAUNCHING KUREK (Headless DeepSeek Engine + Swift MenuBar)"
    echo "=========================================================="

    # Stop any old instances
    pkill -f "kurek_daemon.py" 2>/dev/null || true
    pkill -f "kurekbar" 2>/dev/null || true
    sleep 0.5

    # 1. Start Python Daemon
    echo "Starting Kurek daemon on http://127.0.0.1:8790..."
    setsid "$DIR/.venv/bin/python" -u "$DIR/kurek_daemon.py" >> /tmp/kurek_daemon.log 2>&1 &
    DAEMON_PID=$!
    echo $DAEMON_PID > "$DAEMON_PID_FILE"

    # Wait for daemon to respond (up to 8 seconds for cold start)
    for i in {1..40}; do
      if curl -s http://127.0.0.1:8790/status >/dev/null; then
        echo "Daemon is online! State: $(curl -s http://127.0.0.1:8790/status)"
        break
      fi
      sleep 0.2
    done

    # 2. Start Menu Bar if on macOS (Darwin)
    if [ "$(uname)" = "Darwin" ]; then
      if [ ! -f "$DIR/menubar/kurekbar" ]; then
        echo "Compiling native Swift menubar item..."
        swiftc -O "$DIR/menubar/KurekBar.swift" -o "$DIR/menubar/kurekbar"
        cp "$DIR/menubar/kurekbar" "/Applications/Kurek.app/Contents/MacOS/Kurek" 2>/dev/null || true
      fi

      echo "Starting KurekBar menu bar app (Fn key monitor active)..."
      if [ -d "/Applications/Kurek.app" ]; then
        open /Applications/Kurek.app
      else
        nohup "$DIR/menubar/kurekbar" >> /tmp/kurek_bar.log 2>&1 &
        BAR_PID=$!
        echo $BAR_PID > "$BAR_PID_FILE"
      fi
      echo ""
      echo "✅ Kurek is live in your macOS Menu Bar!"
      echo "👉 Press the [Fn] key anytime to speak to Kurek."
    else
      echo ""
      echo "✅ Kurek daemon is LIVE on Arch Linux!"
      echo "👉 Toggle listening: curl -X POST http://127.0.0.1:8790/toggle"
      echo "👉 Send prompt:     curl -X POST http://127.0.0.1:8790/prompt -H 'Content-Type: application/json' -d '{\"prompt\": \"...\"}'"
      echo "👉 Bind hotkey in your window manager (Hyprland / i3 / Sway) to trigger: curl -s -X POST http://127.0.0.1:8790/toggle"
    fi

    echo "👉 Logs: tail -f /tmp/kurek_daemon.log"
    echo "👉 To stop: ./launch_kurek.sh stop"
    ;;
esac
