#!/usr/bin/env bash
# ============================================================================
#  Findora launcher (macOS / Linux)
#  Connects the app to the backend running locally on THIS machine at port 5000,
#  with no IP address to find and no firewall/Wi-Fi setup.
#
#  How it works: "adb reverse" tunnels the device's 127.0.0.1:5000 through the
#  USB cable to this machine's backend, so the app just talks to 127.0.0.1.
#
#  Before running:
#    1. Start the backend:  cd backend && npm start
#       (wait for "Findora API running on port 5000")
#    2. Connect a phone by USB with USB debugging ON, or start an emulator/simulator
#    3. Run:  ./run.sh
# ============================================================================
set -e
cd "$(dirname "$0")"

echo
echo "[1/2] Linking device to local backend on port 5000 (adb reverse)..."
if ! adb reverse tcp:5000 tcp:5000 2>/dev/null; then
  echo "  !! adb reverse failed (no Android device/emulator, or adb not on PATH)."
  echo "     iOS simulator and desktop don't need it — 127.0.0.1 reaches the backend directly."
fi

echo "[2/2] Starting Findora..."
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:5000/api
