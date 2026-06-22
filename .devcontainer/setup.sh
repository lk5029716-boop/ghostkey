#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
# ghostkey devcontainer setup.sh
# Run once after container build to finish SDK setup,
# create an AVD, and pre-warm the emulator cache.
# ─────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

export ANDROID_HOME="${ANDROID_HOME:-/opt/android-sdk}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME}}"
export FLUTTER_HOME="${FLUTTER_HOME:-/opt/flutter}"

export PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator:${PATH}"
export PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}"

log()  { echo -e "\033[1;32m[setup]\033[0m $*"; }
warn() { echo -e "\033[1;33m[setup]\033[0m $*"; }
err()  { echo -e "\033[1;31m[setup]\033[0m $*" >&2; }

# Prevent parallel runs
LOCKFILE="/tmp/ghostkey_setup.lock"
exec 200>"${LOCKFILE}"
flock -n 200 || { log "Another setup process is running — exiting."; exit 0; }

# ── 1. Android SDK ────────────────────────────────────
ensure_android_sdk() {
  log "Checking Android SDK …"
  mkdir -p "${ANDROID_HOME}"

  if [ ! -f "${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager" ]; then
    log "Downloading Android command-line tools …"
    mkdir -p "${ANDROID_HOME}/cmdline-tools"
    local url="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    local zip="/tmp/cmdline-tools.zip"
    wget -q "${url}" -O "${zip}"
    unzip -q "${zip}" -d "${ANDROID_HOME}/cmdline-tools/"
    mv "${ANDROID_HOME}/cmdline-tools/cmdline-tools" "${ANDROID_HOME}/cmdline-tools/latest"
    rm -f "${zip}"
    log "Command-line tools installed."
  else
    log "Command-line tools already present."
  fi

  log "Accepting SDK licenses …"
  yes | sdkmanager --sdk_root="${ANDROID_HOME}" --licenses 2>/dev/null || true

  log "Installing SDK components …"
  sdkmanager --sdk_root="${ANDROID_HOME}" \
    "platform-tools" \
    "emulator" \
    "platforms;android-34" \
    "build-tools;34.0.0" \
    "system-images;android-34;google_apis_playstore;x86_64" \
    2>&1 | tail -5 || warn "Some SDK components may already be installed."

  yes | sdkmanager --sdk_root="${ANDROID_HOME}" --licenses 2>/dev/null || true

  log "Android SDK ready."
}

# ── 2. Flutter SDK ────────────────────────────────────
ensure_flutter() {
  log "Checking Flutter SDK …"
  if [ ! -f "${FLUTTER_HOME}/bin/flutter" ]; then
    log "Downloading Flutter SDK …"
    sudo mkdir -p "${FLUTTER_HOME}"
    sudo chown "$(id -u):$(id -g)" "${FLUTTER_HOME}"
    local version="3.22.3"
    local url="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${version}-stable.tar.xz"
    wget -q "${url}" -O /tmp/flutter.tar.xz
    tar xf /tmp/flutter.tar.xz -C /opt/
    rm -f /tmp/flutter.tar.xz
    log "Flutter SDK installed."
  else
    log "Flutter SDK already present."
  fi

  export PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}"
  flutter config --no-analytics 2>/dev/null || true
  flutter config --android-sdk "${ANDROID_HOME}" 2>/dev/null || true

  log "Running flutter doctor …"
  flutter doctor 2>&1 | head -20 || true
}

# ── 3. Accept Android licenses via Flutter ────────────
accept_licenses() {
  log "Accepting Android licenses through Flutter …"
  flutter doctor --android-licenses 2>/dev/null || true
  yes | sdkmanager --sdk_root="${ANDROID_HOME}" --licenses 2>/dev/null || true
}

# ── 4. Create AVD ─────────────────────────────────────
create_avd() {
  log "Creating AVD 'pixel_6' …"
  local avd_name="pixel_6"
  local image="system-images;android-34;google_apis_playstore;x86_64"

  # Check if AVD already exists
  if avdmanager list avd -c 2>/dev/null | grep -q "${avd_name}"; then
    log "AVD '${avd_name}' already exists."
    return
  fi

  # Create device definition if needed
  echo no | avdmanager create avd \
    --force \
    --name "${avd_name}" \
    --device "pixel_6" \
    --package "${image}" \
    --tag "google_apis_playstore" \
    --abi "x86_64" \
    2>&1 | tail -5 || {
    warn "AVD creation had an issue — trying alternative approach."
    echo no | avdmanager create avd \
      --force \
      --name "${avd_name}" \
      --package "${image}" \
      --tag "google_apis_playstore" \
      --abi "x86_64" \
      2>&1 | tail -5 || true
  }

  # Configure hardware acceleration
  local avd_config="${HOME}/.android/avd/${avd_name}.avd/config.ini"
  if [ -f "${avd_config}" ]; then
    {
      echo "hw.ramSize=2048"
      echo "hw.gpuMode=host"
      echo "hw.gpuEnabled=yes"
      echo "hw.audioInput=no"
      echo "hw.audioOutput=no"
      echo "hw.camera=no"
      echo "hw.sensors.light=false"
      echo "hw.sensors.pressure=false"
      echo "hw.sensors.humidity=false"
      echo "hw.sensors.proximity=false"
      echo "hw.lcd.density=420"
      echo "hw.lcd.width=1080"
      echo "hw.lcd.height=2400"
      echo "disk.dataPartition.size=4G"
      echo "fastboot.forceColdBoot=yes"
    } >> "${avd_config}"
  fi

  log "AVD '${avd_name}' created successfully."
}

# ── 5. Pre-warm emulator cache ────────────────────────
prewarm_emulator() {
  log "Pre-warming emulator image cache …"
  local avd_name="pixel_6"

  # Start Xvfb for headless emulator
  export DISPLAY="${DISPLAY:-:99}"
  if ! pgrep -x Xvfb >/dev/null; then
    Xvfb "${DISPLAY}" -screen 0 1440x900x24 &
    sleep 1
    log "Xvfb started on ${DISPLAY}."
  fi

  # Start emulator briefly to build shader cache
  log "Starting emulator for cache prewarming (will kill after 60s) …"
  timeout 60 \
    emulator -avd "${avd_name}" \
      -no-window \
      -gpu swiftshader_indirect \
      -memory 2048 \
      -noaudio \
      -read-only \
      -no-snapshot \
      -grpc 8554 \
      2>&1 | head -10 || true

  # Give ADB a moment and then shut down
  sleep 2
  adb emu kill 2>/dev/null || true
  adb kill-server 2>/dev/null || true

  log "Emulator cache prewarmed."
}

# ── 6. Create VNC password file ───────────────────────
setup_vnc() {
  log "Setting up VNC password …"
  mkdir -p "${HOME}/.vnc"
  # Default password: "ghostkey" — user can change later
  echo "ghostkey" | vncpasswd -f > "${HOME}/.vnc/passwd" 2>/dev/null || true
  chmod 600 "${HOME}/.vnc/passwd" 2>/dev/null || true
  log "VNC password set to 'ghostkey'"
}

# ── 7. Flutter project setup ──────────────────────────
setup_flutter_project() {
  log "Setting up Flutter project dependencies …"
  cd "${PROJECT_DIR}"
  flutter pub get 2>&1 | tail -5 || warn "flutter pub get had issues — run it manually later."
  log "Flutter project ready."
}

# ── Main ──────────────────────────────────────────────
main() {
  log "=== ghostkey devcontainer setup ==="
  log "Project: ${PROJECT_DIR}"
  log "ANDROID_HOME: ${ANDROID_HOME}"
  log "FLUTTER_HOME: ${FLUTTER_HOME}"

  ensure_android_sdk
  ensure_flutter
  accept_licenses
  create_avd
  setup_vnc
  setup_flutter_project

  # Prewarming is optional — it can take a while
  if [ "${PREWARM:-true}" = "true" ]; then
    prewarm_emulator || warn "Prewarming skipped (expected in first run)."
  fi

  log ""
  log "╔══════════════════════════════════════════════════╗"
  log "║  Setup complete!                                 ║"
  log "║                                                  ║"
  log "║  Start the emulator:                             ║"
  log "║    .devcontainer/scripts/start-emulator.sh       ║"
  log "║                                                  ║"
  log "║  Access noVNC:  http://localhost:6081/vnc.html   ║"
  log "║  VNC direct:    localhost:5900 (password: ghostkey) ║"
  log "╚══════════════════════════════════════════════════╝"
  log ""
}

main "$@"