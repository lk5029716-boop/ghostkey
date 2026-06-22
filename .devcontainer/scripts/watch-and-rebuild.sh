#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
# ghostkey watch-and-rebuild.sh
# Watches lib/ for .dart changes and sends 'R' to the
# Flutter process to trigger hot reload.
# ─────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

WATCH_DIR="${PROJECT_DIR}/lib"
FLUTTER_PID_FILE="/tmp/flutter.pid"
LOG_FILE="/tmp/hotreload.log"
POLL_INTERVAL="${POLL_INTERVAL:-1}"

log()  { echo -e "\033[1;36m[watch]\033[0m $(date '+%H:%M:%S') $*" | tee -a "${LOG_FILE}"; }
warn() { echo -e "\033[1;33m[watch]\033[0m $(date '+%H:%M:%S') $*" | tee -a "${LOG_FILE}"; }
err()  { echo -e "\033[1;31m[watch]\033[0m $(date '+%H:%M:%S') $*" | tee -a "${LOG_FILE}" >&2; }

# ── Ensure watch target exists ────────────────────────
if [ ! -d "${WATCH_DIR}" ]; then
  err "Watch directory ${WATCH_DIR} does not exist."
  exit 1
fi

log "Watching ${WATCH_DIR} for .dart changes …"
log "Hot reload log: ${LOG_FILE}"

# ── Function: get Flutter PID ─────────────────────────
get_flutter_pid() {
  # Try PID file first
  if [ -f "${FLUTTER_PID_FILE}" ]; then
    local pid
    pid=$(cat "${FLUTTER_PID_FILE}" 2>/dev/null || echo "")
    if [ -n "${pid}" ] && kill -0 "${pid}" 2>/dev/null; then
      echo "${pid}"
      return
    fi
  fi

  # Fallback: pgrep
  local pid
  pid=$(pgrep -f "flutter.*run.*emulator" 2>/dev/null || true)
  if [ -n "${pid}" ]; then
    echo "${pid}"
    return
  fi

  # Further fallback: look for dart process running the app
  pid=$(pgrep -f "dart.*kernel.*flutter" 2>/dev/null || true)
  echo "${pid}"
}

# ── Function: trigger hot reload ──────────────────────
trigger_hot_reload() {
  local pid
  pid=$(get_flutter_pid)
  if [ -z "${pid}" ]; then
    return 1
  fi

  # Flutter uses stdin 'R' for hot reload, but we need
  # to send it to the right process. Try SIGUSR1 first
  # (Flutter handles SIGUSR1 as hot reload), then fall
  # back to writing to stdin via /proc.
  if kill -USR1 "${pid}" 2>/dev/null; then
    return 0
  fi

  # Fallback: try writing 'R' to the process's stdin
  if [ -e "/proc/${pid}/fd/0" ]; then
    echo 'R' > "/proc/${pid}/fd/0" 2>/dev/null && return 0
  fi

  # Try finding the dart process that's actually running the app
  local dart_pid
  dart_pid=$(pgrep -f "flutter_tools" 2>/dev/null || true)
  if [ -n "${dart_pid}" ]; then
    # Try SIGUSR1 on parent flutter process instead
    local parent_pid
    parent_pid=$(ps -o ppid= -p "${dart_pid}" 2>/dev/null | tr -d ' ' || true)
    if [ -n "${parent_pid}" ]; then
      kill -USR1 "${parent_pid}" 2>/dev/null && return 0
    fi
  fi

  return 1
}

# ── Try to find the Flutter process (wait up to 60s) ──
wait_for_flutter() {
  log "Waiting for Flutter process …"
  local timeout=60
  local elapsed=0
  while [ $elapsed -lt $timeout ]; do
    local pid
    pid=$(get_flutter_pid)
    if [ -n "${pid}" ]; then
      log "Flutter process found (PID: ${pid})."
      return 0
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done
  warn "Flutter process not found after ${timeout}s."
  warn "The app may not be running yet. Watcher will keep trying."
  return 1
}

wait_for_flutter || true

# ── Main watch loop ──────────────────────────────────
# Use inotifywait when available, otherwise poll stat
if command -v inotifywait &>/dev/null; then
  log "Using inotifywait for file watching."
  # inotifywait doesn't re-trigger for events while we're processing,
  # so we batch changes within a 500ms window
  inotifywait -m -r \
    -e modify,create,delete,move \
    --format '%w%f' \
    "${WATCH_DIR}" \
    2>/dev/null | while read -r changed_file; do
      # Only trigger on .dart files
      if [[ "${changed_file}" != *.dart ]]; then
        continue
      fi

      log "Change detected: ${changed_file#"${PROJECT_DIR}/"}"

      # Debounce: collect changes within 500ms
      sleep 0.5

      if trigger_hot_reload; then
        log "Hot reload triggered."
      else
        # Process may not be ready yet — try again
        sleep 1
        if trigger_hot_reload; then
          log "Hot reload triggered (retry)."
        else
          warn "Could not trigger hot reload — Flutter process not reachable."
        fi
      fi
    done
else
  # Fallback: poll file mtimes
  log "inotifywait not available — using stat-based polling (every ${POLL_INTERVAL}s)."
  log "Install inotify-tools for faster file watching."

  local last_mtime=0
  # Precompute file list mtime
  while true; do
    local current_mtime
    current_mtime=$(find "${WATCH_DIR}" -name '*.dart' -type f -printf '%T@\n' 2>/dev/null | sort -rn | head -1 || echo "0")

    if [ "$(echo "${current_mtime} > ${last_mtime}" | bc -l 2>/dev/null || echo "0")" = "1" ]; then
      log "Change detected in lib/ …"
      if trigger_hot_reload; then
        log "Hot reload triggered at $(date '+%H:%M:%S')."
      else
        # Retry once
        sleep 1
        trigger_hot_reload || warn "Flutter process not reachable."
      fi
      last_mtime="${current_mtime}"
    fi

    sleep "${POLL_INTERVAL}"
  done
fi