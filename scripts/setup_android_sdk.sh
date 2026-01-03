#!/usr/bin/env bash
set -euo pipefail

########################################
# Config
########################################
SDK_ROOT="$HOME/android-sdk"
CMDLINE_DIR="$SDK_ROOT/cmdline-tools"
LATEST_DIR="$CMDLINE_DIR/latest"

TOOLS_ZIP="tools.zip"
TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

########################################
# Helpers
########################################
is_ci() {
  [[ -n "${GITHUB_ENV:-}" ]]
}

set_env_var() {
  local key="$1"
  local value="$2"

  if is_ci; then
    echo "$key=$value" >> "$GITHUB_ENV"
  else
    export "$key=$value"
  fi
}

########################################
# Begin
########################################
echo "▶ Setting up Android SDK"
mkdir -p "$SDK_ROOT"
cd "$SDK_ROOT"

########################################
# Download cmdline-tools if missing
########################################
if [[ ! -d "$LATEST_DIR" ]]; then
  echo "▶ Downloading Android cmdline-tools"

  rm -f "$TOOLS_ZIP"
  curl -sSL "$TOOLS_URL" -o "$TOOLS_ZIP"

  unzip -q "$TOOLS_ZIP"

  # Google zip extracts as: cmdline-tools/
  rm -rf cmdline-tools.tmp
  mv cmdline-tools cmdline-tools.tmp
  mkdir -p cmdline-tools
  mv cmdline-tools.tmp cmdline-tools/latest

  rm -f "$TOOLS_ZIP"
else
  echo "✔ cmdline-tools already present"
fi

########################################
# Environment variables
########################################
set_env_var ANDROID_HOME "$SDK_ROOT"
set_env_var ANDROID_SDK_ROOT "$SDK_ROOT"
set_env_var PATH "$LATEST_DIR/bin:$PATH"

########################################
# Accept licenses (Termux-safe)
########################################
yes | bash "$LATEST_DIR/bin/sdkmanager" --licenses >/dev/null || true

########################################
# Done
########################################
echo "✔ Android SDK setup complete"
echo "  ANDROID_HOME=$SDK_ROOT"
