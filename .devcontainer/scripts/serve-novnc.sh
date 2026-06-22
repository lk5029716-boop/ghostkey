#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
# ghostkey serve-novnc.sh
# Serves the noVNC web client on a dedicated HTTP port.
# The page auto-connects to the VNC WebSocket proxy.
# ─────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

NOVNC_PORT="${WEB_PORT:-6081}"
VNC_WS_HOST="${VNC_WS_HOST:-localhost}"
VNC_WS_PORT="${NOVNC_PORT:-6080}"
NOVNC_SOURCE="${NOVNC_SOURCE:-/opt/novnc}"
SERVE_DIR="/tmp/novnc-web"

log()  { echo -e "\033[1;35m[novnc-web]\033[0m $*"; }
warn() { echo -e "\033[1;33m[novnc-web]\033[0m $*"; }

# ── 1. Prepare the web directory ──────────────────────
prepare_web_dir() {
  mkdir -p "${SERVE_DIR}"

  if [ -d "${NOVNC_SOURCE}" ]; then
    log "Copying noVNC files from ${NOVNC_SOURCE} …"
    # Copy required static assets (no symlinks)
    cp -rL "${NOVNC_SOURCE}/app" "${SERVE_DIR}/app/" 2>/dev/null || true
    cp -rL "${NOVNC_SOURCE}/core" "${SERVE_DIR}/core/" 2>/dev/null || true
    cp -rL "${NOVNC_SOURCE}/vendor" "${SERVE_DIR}/vendor/" 2>/dev/null || true
    cp "${NOVNC_SOURCE}/vnc.html" "${SERVE_DIR}/vnc.html" 2>/dev/null || true
    cp "${NOVNC_SOURCE}/vnc_lite.html" "${SERVE_DIR}/vnc_lite.html" 2>/dev/null || true
    log "noVNC static files copied."
  else
    warn "noVNC source not found at ${NOVNC_SOURCE}."
    warn "Will use CDN-based HTML client instead."
  fi

  # Create our custom auto-connect page
  cat > "${SERVE_DIR}/index.html" <<- 'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ghostkey — Live Preview</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #0f0f0f;
      color: #e0e0e0;
      height: 100vh;
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }
    #toolbar {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 8px 16px;
      background: #1a1a2e;
      border-bottom: 1px solid #333;
      -webkit-app-region: drag;
    }
    #toolbar h1 {
      font-size: 14px;
      font-weight: 600;
      color: #b388ff;
      letter-spacing: 0.5px;
    }
    #toolbar .badge {
      font-size: 11px;
      padding: 2px 8px;
      border-radius: 10px;
      background: #333;
    }
    #toolbar .badge.connected { background: #2e7d32; color: #a5d6a7; }
    #toolbar .badge.disconnected { background: #b71c1c; color: #ef9a9a; }
    #controls {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-left: auto;
      -webkit-app-region: no-drag;
    }
    #controls button {
      background: #333;
      border: 1px solid #555;
      color: #ccc;
      padding: 4px 12px;
      border-radius: 4px;
      cursor: pointer;
      font-size: 12px;
    }
    #controls button:hover { background: #444; }
    #controls button.primary { background: #7c4dff; border-color: #7c4dff; color: #fff; }
    #controls button.primary:hover { background: #651fff; }
    #screen-container {
      flex: 1;
      display: flex;
      align-items: center;
      justify-content: center;
      background: #000;
      position: relative;
      overflow: hidden;
    }
    #device-frame {
      position: relative;
      border-radius: 36px;
      box-shadow: 0 0 0 2px #333, 0 0 30px rgba(0,0,0,0.8);
      background: #000;
      display: inline-block;
    }
    #device-frame .notch {
      position: absolute;
      top: 0;
      left: 50%;
      transform: translateX(-50%);
      width: 150px;
      height: 28px;
      background: #000;
      border-radius: 0 0 16px 16px;
      z-index: 10;
    }
    #device-frame .notch-inner {
      display: flex;
      align-items: center;
      justify-content: center;
      height: 100%;
      gap: 6px;
    }
    #device-frame .notch-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #1a1a2e;
    }
    #device-frame .notch-camera {
      width: 12px;
      height: 12px;
      border-radius: 50%;
      background: #1a1a2e;
      border: 1px solid #333;
    }
    #screen {
      width: 412px;
      height: 890px;
      border: none;
      border-radius: 32px;
      display: block;
    }
    #status-bar {
      padding: 4px 16px;
      background: #1a1a2e;
      border-top: 1px solid #333;
      font-size: 11px;
      display: flex;
      gap: 16px;
    }
    #status-bar .status-item { color: #888; }
    #status-bar .status-item.ok { color: #a5d6a7; }
    #status-bar .status-item.err { color: #ef9a9a; }
    a { color: #b388ff; }
    @media (max-width: 768px) {
      #screen { width: 320px; height: 690px; }
      #device-frame { border-radius: 24px; }
      #device-frame .notch { width: 100px; height: 20px; }
    }
  </style>
</head>
<body>
  <div id="toolbar">
    <h1>🔑 ghostkey</h1>
    <span id="connection-badge" class="badge disconnected">Disconnected</span>
    <span id="device-badge" class="badge">Pixel 6 • Android 14</span>
    <div id="controls">
      <button id="rotate-btn" title="Rotate">↻</button>
      <button id="home-btn" title="Home">⌂</button>
      <button id="back-btn" title="Back">‹</button>
      <button id="recent-btn" title="Recent">☰</button>
      <button id="fullscreen-btn" title="Fullscreen">⛶</button>
      <button id="reconnect-btn" class="primary">Connect</button>
    </div>
  </div>
  <div id="screen-container">
    <div id="device-frame">
      <canvas id="screen" width="412" height="890"></canvas>
      <div class="notch"><div class="notch-inner"><div class="notch-camera"></div><div class="notch-dot"></div></div></div>
    </div>
  </div>
  <div id="status-bar">
    <span class="status-item" id="status-vnc">VNC: disconnected</span>
    <span class="status-item" id="status-emulator">Emulator: checking...</span>
    <span class="status-item" id="status-flutter">Flutter: idle</span>
    <span class="status-item" id="status-fps">FPS: --</span>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/@novnc/novnc@1.4.0/dist/rfb.min.js"></script>
  <script>
  (function() {
    'use strict';

    const HOST = window.location.hostname || 'localhost';
    const WS_PORT = '${VNC_WS_PORT}';
    const WS_URL = `ws://${HOST}:${WS_PORT}`;

    let rfb = null;
    let connected = false;
    let reconnectTimer = null;
    let lastFrameTime = 0;
    let frameCount = 0;
    let fpsInterval = null;

    const statusBadge = document.getElementById('connection-badge');
    const statusVNC = document.getElementById('status-vnc');
    const statusEmu = document.getElementById('status-emulator');
    const statusFPS = document.getElementById('status-fps');
    const connectBtn = document.getElementById('reconnect-btn');
    const canvas = document.getElementById('screen');

    // ── FPS counter ──
    function startFPS() {
      if (fpsInterval) return;
      frameCount = 0;
      lastFrameTime = performance.now();
      fpsInterval = setInterval(() => {
        const now = performance.now();
        const elapsed = now - lastFrameTime;
        if (elapsed > 0) {
          const fps = Math.round((frameCount * 1000) / elapsed);
          statusFPS.textContent = `FPS: ${fps}`;
        }
        frameCount = 0;
        lastFrameTime = performance.now();
      }, 2000);
    }

    function stopFPS() {
      if (fpsInterval) {
        clearInterval(fpsInterval);
        fpsInterval = null;
      }
      statusFPS.textContent = 'FPS: --';
    }

    // ── RFB connection ──
    function connect() {
      if (rfb && connected) {
        disconnect();
      }

      const url = WS_URL;
      console.log(`Connecting to ${url} …`);

      updateStatus('connecting', 'Connecting…');

      try {
        rfb = new RFB(canvas, url, {
          credentials: { password: 'ghostkey' },
          shared: true,
          clipViewport: true,
          dragViewport: true,
        });

        rfb.addEventListener('connect', onConnected);
        rfb.addEventListener('disconnect', onDisconnected);
        rfb.addEventListener('securityfailure', onSecurityFailure);
        rfb.addEventListener('desktopname', onDesktopName);
        rfb.addEventListener('capabilities', onCapabilities);

        // Track frames for FPS
        rfb.addEventListener('framebufferupdate', () => {
          frameCount++;
        });
      } catch (e) {
        console.error('Failed to create RFB:', e);
        updateStatus('error', `Connection error: ${e.message}`);
        scheduleReconnect();
      }
    }

    function disconnect() {
      if (rfb) {
        try {
          rfb.disconnect();
        } catch(e) {}
        rfb.removeEventListener('connect', onConnected);
        rfb.removeEventListener('disconnect', onDisconnected);
        rfb.removeEventListener('securityfailure', onSecurityFailure);
        rfb = null;
      }
      connected = false;
      stopFPS();
    }

    function onConnected() {
      console.log('VNC connected');
      connected = true;
      updateStatus('connected', 'Connected');
      statusVNC.textContent = 'VNC: connected';
      statusVNC.className = 'status-item ok';
      connectBtn.textContent = 'Disconnect';
      connectBtn.className = '';
      startFPS();
      clearReconnect();

      // Send a few keys to wake the device screen
      setTimeout(() => {
        if (rfb && connected) {
          // Send KEY_DOWN + KEY_UP for Power button to wake screen
          try {
            rfb.sendKey(107, 0, true);
            setTimeout(() => rfb.sendKey(107, 0, false), 100);
          } catch(e) {}
        }
      }, 2000);
    }

    function onDisconnected(e) {
      console.log('VNC disconnected:', e.detail);
      connected = false;
      updateStatus('disconnected', 'Disconnected');
      statusVNC.textContent = 'VNC: disconnected';
      statusVNC.className = 'status-item err';
      connectBtn.textContent = 'Connect';
      connectBtn.className = 'primary';
      stopFPS();
      scheduleReconnect();
    }

    function onSecurityFailure(e) {
      console.error('VNC security failure:', e.detail);
      updateStatus('error', `Auth failed: ${e.detail?.reason || 'unknown'}`);
      scheduleReconnect();
    }

    function onDesktopName(e) {
      console.log('Desktop name:', e.detail.name);
    }

    function onCapabilities(e) {
      console.log('Capabilities:', e.detail.capabilities);
    }

    function updateStatus(state, text) {
      statusBadge.textContent = text;
      statusBadge.className = `badge ${state}`;
    }

    // ── Auto-reconnect ──
    function scheduleReconnect() {
      clearReconnect();
      updateStatus('disconnected', 'Reconnecting in 5s…');
      reconnectTimer = setTimeout(() => {
        console.log('Auto-reconnecting…');
        connect();
      }, 5000);
    }

    function clearReconnect() {
      if (reconnectTimer) {
        clearTimeout(reconnectTimer);
        reconnectTimer = null;
      }
    }

    // ── Control buttons ──
    function sendKeyToEmulator(keyCode) {
      // Use ADB via fetch to a simple HTTP bridge or directly via noVNC
      if (rfb && connected) {
        rfb.sendKey(keyCode, 0, true);
        setTimeout(() => rfb.sendKey(keyCode, 0, false), 100);
      }
    }

    document.getElementById('rotate-btn').addEventListener('click', () => {
      // Send F11 or rotate via adb API if available
      fetch('/api/rotate', { method: 'POST' }).catch(() => {
        // Fallback: try sending volume keys as rotation hint
        if (rfb && connected) {
          // Send Ctrl+F11 for rotation
          rfb.sendKey(0xFFC9, 0, true);  // F11
          setTimeout(() => rfb.sendKey(0xFFC9, 0, false), 100);
        }
      });
    });

    document.getElementById('home-btn').addEventListener('click', () => {
      // Home key (KEYCODE_HOME = 3)
      sendKeyToEmulator(0x24);  // XK_Home
    });

    document.getElementById('back-btn').addEventListener('click', () => {
      // Back key (KEYCODE_BACK = 4)
      sendKeyToEmulator(0xFF1B);  // XK_Escape or Back
    });

    document.getElementById('recent-btn').addEventListener('click', () => {
      // Overview/Recent (KEYCODE_APP_SWITCH = 187)
      // Use Ctrl+Tab or similar
      if (rfb && connected) {
        // Press and release F12 for overview
        rfb.sendKey(0xFFCC, 0, true);  // F12
        setTimeout(() => rfb.sendKey(0xFFCC, 0, false), 100);
      }
    });

    document.getElementById('fullscreen-btn').addEventListener('click', () => {
      if (!document.fullscreenElement) {
        document.getElementById('screen-container').requestFullscreen?.();
      } else {
        document.exitFullscreen?.();
      }
    });

    connectBtn.addEventListener('click', () => {
      if (connected) {
        disconnect();
      } else {
        clearReconnect();
        connect();
      }
    });

    // ── Keyboard passthrough ──
    document.addEventListener('keydown', (e) => {
      // Let the VNC client handle it
      if (rfb && connected && e.target === document.body) {
        e.preventDefault();
        // The RFB client on the canvas handles its own keyboard events
        // We don't need to forward them here
      }
    });

    // ── Status polling for emulator/Flutter ──
    setInterval(() => {
      fetch('/api/status')
        .then(r => r.json())
        .then(data => {
          if (data.emulator) {
            statusEmu.textContent = `Emulator: ${data.emulator}`;
            statusEmu.className = data.emulator === 'running' ? 'status-item ok' : 'status-item';
          }
          const statusFlutter = document.getElementById('status-flutter');
          if (data.flutter) {
            statusFlutter.textContent = `Flutter: ${data.flutter}`;
            statusFlutter.className = data.flutter === 'running' ? 'status-item ok' : 'status-item';
          }
        })
        .catch(() => {});
    }, 10000);

    // ── Auto-connect on load ──
    setTimeout(() => {
      connect();
    }, 1000);
  })();
  </script>
</body>
</html>
HTML

  # Replace VNC_WS_PORT placeholder with actual value (heredoc is quoted so vars don't expand)
  sed -i "s/\${VNC_WS_PORT}/${VNC_WS_PORT}/g" "${SERVE_DIR}/index.html"

  log "Custom index.html with auto-connect created."
}

# ── 2. Start HTTP server ─────────────────────────────
start_server() {
  log "Starting HTTP server on port ${NOVNC_PORT} …"

  # Use Python's http.server (no extra deps needed)
  cd "${SERVE_DIR}"

  # Use a heredoc piped to python3 to avoid shell quoting issues
  python3 /dev/stdin \
    --port "${NOVNC_PORT}" \
    --dir "${SERVE_DIR}" \
    2>&1 <<- 'PYEOF'
import http.server
import socketserver
import json
import subprocess
import sys
import os

PORT = int(sys.argv[sys.argv.index('--port') + 1])
DIRECTORY = sys.argv[sys.argv.index('--dir') + 1]

class StatusHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_GET(self):
        if self.path == '/api/status':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            status = self._get_status()
            self.wfile.write(json.dumps(status).encode())
        elif self.path == '/api/rotate':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            try:
                subprocess.run(
                    ['adb', 'shell', 'settings', 'put', 'system', 'user_rotation', '1'],
                    capture_output=True, timeout=5
                )
                self.wfile.write(json.dumps({'ok': True}).encode())
            except Exception as e:
                self.wfile.write(json.dumps({'ok': False, 'error': str(e)}).encode())
        else:
            super().do_GET()

    def _get_status(self):
        result = {'emulator': 'unknown', 'flutter': 'unknown'}
        try:
            r = subprocess.run(
                ['adb', 'devices'],
                capture_output=True, text=True, timeout=5
            )
            if 'emulator' in r.stdout:
                result['emulator'] = 'running'
                boot = subprocess.run(
                    ['adb', 'shell', 'getprop', 'sys.boot_completed'],
                    capture_output=True, text=True, timeout=5
                )
                if boot.stdout.strip() == '1':
                    result['emulator'] = 'booted'
            else:
                result['emulator'] = 'stopped'
        except Exception:
            pass

        try:
            r = subprocess.run(
                ['pgrep', '-f', 'flutter.*run'],
                capture_output=True, text=True, timeout=5
            )
            result['flutter'] = 'running' if r.stdout.strip() else 'stopped'
        except Exception:
            pass

        return result

    def log_message(self, format, *args):
        pass

os.chdir(DIRECTORY)

with socketserver.TCPServer(('', PORT), StatusHandler) as httpd:
    print('noVNC web server on port {} (PID: {})'.format(PORT, os.getpid()))
    httpd.serve_forever()
PYEOF
}

# ── Main ──────────────────────────────────────────────
main() {
  log "Preparing noVNC web directory …"
  prepare_web_dir

  log "Starting noVNC web server on port ${NOVNC_PORT} …"
  log "URL: http://localhost:${NOVNC_PORT}"
  start_server
}

main "$@"