#!/usr/bin/env bash
set -euo pipefail

# Clash Verge Rev Ubuntu installer and subscription setup.
# Run as: bash clash_install_config.sh

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SUBSCRIPTION_URL='https://ss.xytc.store/api/v1/dy/1f6bb2443928517788622d1eb5460aef'

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This installer is for Ubuntu/Linux and the bundled .deb package." >&2
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1 || ! command -v dpkg >/dev/null 2>&1; then
  echo "apt-get and dpkg are required. This script targets Ubuntu/Debian." >&2
  exit 1
fi

if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
  TARGET_USER="$SUDO_USER"
else
  TARGET_USER="${USER:-$(id -un)}"
fi
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
if [[ -z "$TARGET_HOME" || ! -d "$TARGET_HOME" ]]; then
  echo "Could not resolve the target user's home directory." >&2
  exit 1
fi

run_as_target() {
  if [[ "$(id -un)" == "$TARGET_USER" ]]; then
    "$@"
  else
    sudo -u "$TARGET_USER" env HOME="$TARGET_HOME" "$@"
  fi
}

as_root() {
  if (( EUID == 0 )); then
    "$@"
  else
    sudo "$@"
  fi
}

DEB_PATH=""
shopt -s nullglob
deb_candidates=("$SCRIPT_DIR"/*.deb)
shopt -u nullglob
if (( ${#deb_candidates[@]} == 0 )); then
  echo "No .deb package found beside this script." >&2
  exit 1
fi
if (( ${#deb_candidates[@]} > 1 )); then
  echo "More than one .deb package was found; keep only the intended Clash package in this folder." >&2
  printf '  %s\n' "${deb_candidates[@]}" >&2
  exit 1
fi
DEB_PATH="${deb_candidates[0]}"

if ! command -v curl >/dev/null 2>&1; then
  as_root apt-get update
  as_root apt-get install -y curl ca-certificates
fi

echo "Installing Clash Verge package..."
as_root dpkg -i "$DEB_PATH" || as_root apt-get install -f -y

APP_HOME="$TARGET_HOME/.local/share/io.github.clash-verge-rev.clash-verge-rev"
PROFILES_DIR="$APP_HOME/profiles"
run_as_target mkdir -p "$PROFILES_DIR"

PROFILE_UID="R$(date +%s)"
PROFILE_FILE="$PROFILE_UID.yaml"
PROFILE_PATH="$PROFILES_DIR/$PROFILE_FILE"
TEMP_PROFILE="$(mktemp)"
trap 'rm -f "$TEMP_PROFILE"' EXIT

echo "Downloading subscription configuration..."
run_as_target curl -fL --retry 3 --connect-timeout 20 --max-time 120 \
  -A 'clash-verge-rev' \
  -H 'Accept: text/yaml, application/yaml, application/octet-stream, */*' \
  "$SUBSCRIPTION_URL" -o "$TEMP_PROFILE"

if [[ ! -s "$TEMP_PROFILE" ]]; then
  echo "The subscription response was empty." >&2
  exit 1
fi
if ! grep -Eq '(^|[[:space:]])(proxies|proxy-providers):' "$TEMP_PROFILE"; then
  echo "The subscription did not return a Clash YAML profile. The provider may require a converter or a different User-Agent." >&2
  exit 1
fi

run_as_target cp "$TEMP_PROFILE" "$PROFILE_PATH"
run_as_target chmod 600 "$PROFILE_PATH"

PROFILES_YAML="$APP_HOME/profiles.yaml"
TEMP_INDEX="$(mktemp)"
trap 'rm -f "$TEMP_PROFILE" "$TEMP_INDEX"' EXIT
cat > "$TEMP_INDEX" <<EOF
# Profiles Config for Clash Verge
current: "$PROFILE_UID"
items:
  - uid: "$PROFILE_UID"
    type: remote
    name: "subscription"
    file: "$PROFILE_FILE"
    url: "$SUBSCRIPTION_URL"
    updated: $(date +%s)
    option:
      allow_auto_update: true
      update_interval: 360
EOF
run_as_target cp "$TEMP_INDEX" "$PROFILES_YAML"
run_as_target chmod 600 "$PROFILES_YAML"
rm -f "$TEMP_INDEX"

BASHRC="$TARGET_HOME/.bashrc"
run_as_target touch "$BASHRC"
if ! grep -Fqx 'export http_proxy="http://127.0.0.1:7897"' "$BASHRC" 2>/dev/null; then
  run_as_target bash -c 'cat >> "$HOME/.bashrc" <<'"'"'EOF'"'"'

# >>> clash-install-config proxy settings >>>
export http_proxy="http://127.0.0.1:7897"
export https_proxy="http://127.0.0.1:7897"
export all_proxy="socks5://127.0.0.1:7897"
export HTTP_PROXY="$http_proxy"
export HTTPS_PROXY="$https_proxy"
export ALL_PROXY="$all_proxy"
alias proxy_on="export http_proxy=\"http://127.0.0.1:7897\"; export https_proxy=\"http://127.0.0.1:7897\"; export all_proxy=\"socks5://127.0.0.1:7897\""
alias proxy_off="unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY"
# <<< clash-install-config proxy settings <<<
EOF'
fi

echo "Clash Verge installed and subscription configured for $TARGET_USER."
echo "Proxy settings were added to $BASHRC. Run: source ~/.bashrc"
echo "Clash Verge was not started. Use ./clash_start.sh when you want to launch it."
