#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This launcher is for the Ubuntu/Linux Clash Verge package." >&2
  exit 1
fi

if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
  echo "No graphical display detected. Clash Verge is a GUI application and cannot start in this terminal-only session." >&2
  echo "Run this script from a desktop Ubuntu session, or use a headless mihomo/core deployment instead." >&2
  exit 1
fi

APP=""
if command -v clash-verge >/dev/null 2>&1; then
  APP="$(command -v clash-verge)"
elif command -v clash-verge-rev >/dev/null 2>&1; then
  APP="$(command -v clash-verge-rev)"
fi

if [[ -z "$APP" ]]; then
  echo "Clash Verge executable was not found on PATH. Install it with ./clash_install_config.sh first." >&2
  exit 1
fi

if pgrep -x "$(basename "$APP")" >/dev/null 2>&1; then
  echo "Clash Verge is already running."
  exit 0
fi

nohup "$APP" >/tmp/clash-verge.log 2>&1 &
echo "Clash Verge started. Log: /tmp/clash-verge.log"
