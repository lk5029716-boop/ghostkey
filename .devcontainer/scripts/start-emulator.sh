#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
# ghostkey start-emulator.sh
# Launches Xvfb, VNC, Android emulator, and the noVNC
# web client.  Designed to run as the postStartCommand
# in Codespaces / devcontainer.
# ─────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

export ANDROID_HOME="${ANDROID_HOME:-/opt/android-sdk}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME}}"
export FLUTTER_HOME="${FLUTTER_HOME:-/opt/flutter}"

export PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator:${PATH}"
export PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}"

export DISPLAY="${DISPLAY:-:99}"
export EMULATOR_NAME="${EMULATOR_NAME:-pixel_6}"
export VNC_PORT="${VNC_PORT:-5900}"
export NOVNC_PORT="${NOVNC_PORT:-6080}"
export WEB_PORT="${WEB_PORT:-6081}"
export EMU_CONSOLE_PORT="${EMU_CONSOLE_PORT:-5554}"
export EMU_ADB_PORT="${EMU_ADB_PORT:-5555}"
export EMU_GRPC_PORT="${EMU_GRPC_PORT:-8554}"

AVD_PATH="${HOME}/.android/avd/${EMULATOR_NAME}.avd"

log()  { echo -e "\033[1;34m[start-emulator]\033[0m $*"; }
warn() { echo -e "\033[1;33m[start-emulator]\033[0m $*"; }
err()  { echo -e "\033[1;31m[start-emulator]\033[0m $*" >&2; }

cleanup() {
  log "Shutting down …"
  adb emu kill 2>/dev/null || true
  killall -9 qemu-system-x86_64 2>/dev/null || true
  killall -9 Xvfb 2>/dev/null || true
  killall -9 vncserver 2>/dev/null || true
  killall -9 websockify 2>/dev/null || true
  exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# ── 1. Start Xvfb ────────────────────────────────────
start_xvfb() {
  log "Starting Xvfb on display ${DISPLAY} …"
  if pgrep -x Xvfb >/dev/null; then
    log "Xvfb already running."
  else
    Xvfb "${DISPLAY}" -screen 0 1920x1080x24 -ac &
    sleep 1
    # Verify
    if ! pgrep -x Xvfb >/dev/null; then
      err "Xvfb failed to start."
      return 1
    fi
    log "Xvfb running on ${DISPLAY}"
  fi
}

# ── 2. Start VNC server ──────────────────────────────
start_vnc() {
  log "Starting VNC server on port ${VNC_PORT} …"
  # Stop any existing server on our display
  vncserver -kill "${DISPLAY}" 2>/dev/null || true
  sleep 1

  # Start TigerVNC
  vncserver "${DISPLAY}" \
    -rfbport "${VNC_PORT}" \
    -geometry 1920x1080 \
    -depth 24 \
    -localhost no \
    -alwaysshared \
    -SecurityTypes VncAuth \
    -PasswordFile "${HOME}/.vnc/passwd" \
    2>&1 | head -5 || {
    warn "VNC server start had issues — continuing."
  }

  sleep 1
  log "VNC server running on port ${VNC_PORT} (display ${DISPLAY})"
}

# ── 3. Start Android emulator ────────────────────────
start_emulator() {
  log "Starting Android emulator '${EMULATOR_NAME}' …"

  # Check if already running
  if adb devices 2>/dev/null | grep -q "emulator-${EMU_ADB_PORT}"; then
    log "Emulator already running."
    return
  fi

  # Verify AVD exists
  if [ ! -d "${AVD_PATH}" ]; then
    err "AVD '${EMULATOR_NAME}' not found at ${AVD_PATH}."
    err "Run setup.sh first, or create the AVD manually:"
    err "  avdmanager create avd -n ${EMULATOR_NAME} -k 'system-images;android-34;google_apis_playstore;x86_64'"
    return 1
  fi

  # Determine acceleration
  ACCEL=""
  if [ -c /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    ACCEL="-accel on"
    log "KVM acceleration available."
  else
    ACCEL="-accel off"
    warn "KVM not available — emulator will be slow (software rendering)."
  fi

  # Write custom config for optimal headless operation
  local config="${AVD_PATH}/config.ini"
  if [ -f "${config}" ]; then
    # Ensure GPU is set for SwiftShader
    if grep -q "^hw.gpuMode=" "${config}" 2>/dev/null; then
      sed -i 's/^hw.gpuMode=.*/hw.gpuMode=host/' "${config}"
    else
      echo "hw.gpuMode=host" >> "${config}"
    fi
    if grep -q "^hw.gpuEnabled=" "${config}" 2>/dev/null; then
      sed -i 's/^hw.gpuEnabled=.*/hw.gpuEnabled=yes/' "${config}"
    else
      echo "hw.gpuEnabled=yes" >> "${config}"
    fi
  fi

  # Launch emulator
  nohup emulator \
    -avd "${EMULATOR_NAME}" \
    -no-window \
    -gpu swiftshader_indirect \
    -memory 2048 \
    -noaudio \
    -read-only \
    -no-snapshot-load \
    -no-snapshot-save \
    -port "${EMU_CONSOLE_PORT}" \
    -grpc "${EMU_GRPC_PORT}" \
    -verbose \
    ${ACCEL} \
    > /tmp/emulator.log 2>&1 &

  EMU_PID=$!
  log "Emulator started (PID: ${EMU_PID}). Log: /tmp/emulator.log"

  # Wait for ADB to detect the device
  log "Waiting for ADB device …"
  local timeout=180
  local elapsed=0
  while [ $elapsed -lt $timeout ]; do
    if adb devices 2>/dev/null | grep -q "emulator-${EMU_CONSOLE_PORT}"; then
      log "ADB device detected after ${elapsed}s."
      break
    fi
    sleep 5
    elapsed=$((elapsed + 5))
  done

  if [ $elapsed -ge $timeout ]; then
    err "Timed out waiting for emulator (${timeout}s)."
    err "Check /tmp/emulator.log for details."
    tail -30 /tmp/emulator.log
    return 1
  fi

  # Wait for boot to complete
  log "Waiting for boot to complete …"
  adb -s "emulator-${EMU_CONSOLE_PORT}" wait-for-device 2>/dev/null || true

  local boot_timeout=180
  elapsed=0
  while [ $elapsed -lt $boot_timeout ]; do
    local boot_completed
    boot_completed=$(adb -s "emulator-${EMU_CONSOLE_PORT}" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r\n' || echo "")
    if [ "${boot_completed}" = "1" ]; then
      log "Android boot completed after ~${elapsed}s."
      break
    fi
    sleep 5
    elapsed=$((elapsed + 5))
  done

  if [ $elapsed -ge $boot_timeout ]; then
    warn "Boot check timed out — device may still be starting."
  fi

  log "Emulator ready."
}

# ── 4. Launch Flutter app ────────────────────────────
launch_flutter() {
  log "Preparing Flutter project …"
  cd "${PROJECT_DIR}"

  # Ensure dependencies
  if [ ! -f "${PROJECT_DIR}/.dart_tool/package_config.json" ]; then
    flutter pub get 2>&1 | tail -3 || true
  fi

  log "Launching Flutter app on emulator …"
  # We run in the background so this script can continue to monitor
  nohup flutter run \
    -d "emulator-${EMU_CONSOLE_PORT}" \
    --debug \
    --pid-file=/tmp/flutter.pid \
    > /tmp/flutter_run.log 2>&1 &

  FLUTTER_PID=$!
  log "Flutter running (PID: ${FLUTTER_PID}). Log: /tmp/flutter_run.log"

  # Wait a moment then check if it started
  sleep 10
  if kill -0 "${FLUTTER_PID}" 2>/dev/null; then
    log "Flutter app launched successfully."
  else
    warn "Flutter process exited — check /tmp/flutter_run.log"
    tail -20 /tmp/flutter_run.log
  fi
}

# ── 5. Start websockify (VNC → WebSocket) ────────────
start_websockify() {
  log "Starting websockify (VNC→WebSocket proxy on port ${NOVNC_PORT}) …"
  nohup python3 -m websockify \
    --web /opt/novnc \
    "${NOVNC_PORT}" \
    "localhost:${VNC_PORT}" \
    > /tmp/websockify.log 2>&1 &

  WS_PID=$!
  sleep 1
  log "Websockify running (PID: ${WS_PID}). Port ${NOVNC_PORT} → VNC ${VNC_PORT}"
  log "noVNC URL: http://localhost:${NOVNC_PORT}/vnc.html"
}

# ── 6. Start noVNC web client ────────────────────────
start_web_client() {
  log "Starting noVNC web server on port ${WEB_PORT} …"
  bash "${SCRIPT_DIR}/serve-novnc.sh" &
  sleep 1
  log "Web client: http://localhost:${WEB_PORT}"
}

# ── 7. Start file watcher for hot reload ─────────────
start_watcher() {
  log "Starting file watcher for hot reload …"
  bash "${SCRIPT_DIR}/watch-and-rebuild.sh" &
  log "File watcher started."
}

# ── Main ──────────────────────────────────────────────
main() {
  log "╔══════════════════════════════════════════════════╗"
  log "║  ghostkey Live Preview                           ║"
  log "║  Starting Android emulator + VNC + Flutter …    ║"
  log "╚══════════════════════════════════════════════════╝"

  start_xvfb
  start_vnc
  start_emulator || {
    err "Emulator failed to start — browser preview unavailable."
    err "Check /tmp/emulator.log for details."
    # Still start VNC/web so user can access the environment
  }

  # Launch services that don't depend on emulator first
  start_websockify
  start_web_client

  # Then launch Flutter (which depends on emulator)
  if adb devices 2>/dev/null | grep -q "emulator"; then
    launch_flutter || warn "Flutter launch failed — app not running."
    start_watcher
  else
    warn "No emulator detected — skipping Flutter launch."
    warn "Re-run with: bash ${SCRIPT_DIR}/start-emulator.sh"
  fi

  log ""
  log "╔══════════════════════════════════════════════════╗"
  log "║  All services running!                           ║"
  log "║                                                  ║"
  log "║  noVNC web client:  http://localhost:${WEB_PORT}  ║"
  log "║  Direct VNC:        localhost:${VNC_PORT}         ║"
  log "║  VNC password:      ghostkey                     ║"
  log "║  Emulator console:  telnet localhost:${EMU_CONSOLE_PORT} ║"
  log "║  ADB:               emulator-${EMU_CONSOLE_PORT}  ║"
  log "║                                                  ║"
  log "║  Flutter hot reload triggers on lib/ changes     ║"
  log "╚══════════════════════════════════════════════════╝"
  log ""

  # Keep running
  log "Monitoring services. Press Ctrl+C to stop all."
  wait
}

main "$@"