@echo off
REM ===========================================================================
REM  Findora launcher (Windows)
REM  Connects the app to the backend running locally on THIS PC at port 5000,
REM  with no IP address to find and no firewall/Wi-Fi setup.
REM
REM  How it works: "adb reverse" tunnels the phone's 127.0.0.1:5000 through the
REM  USB cable to this PC's backend. So the app just talks to 127.0.0.1 and it
REM  reaches your local backend.
REM
REM  Before running:
REM    1. Start the backend:  in the backend folder run  npm start
REM       (wait for "Findora API running on port 5000")
REM    2. Plug the phone in by USB with USB debugging ON  (or start an emulator)
REM    3. Double-click this file, or run  run.bat  in a terminal
REM ===========================================================================

cd /d "%~dp0"

echo.
echo [1/2] Linking device to local backend on port 5000 (adb reverse)...
adb reverse tcp:5000 tcp:5000
if %errorlevel% neq 0 (
  echo.
  echo  !! Could not run "adb reverse". Check that:
  echo     - the phone is connected by USB with USB debugging ON, OR an emulator is running
  echo     - "adb" is on your PATH ^(it ships with Android SDK platform-tools^)
  echo.
  echo  The app will still launch, but it may not reach the backend until this works.
  echo.
)

echo [2/2] Starting Findora...
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:5000/api

pause
