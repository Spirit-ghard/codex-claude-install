#!/usr/bin/env bash
set -euo pipefail

ensure_node_npm() {
  local node_major=0
  if command -v node >/dev/null 2>&1; then
    node_major="$(node -p 'Number(process.versions.node.split(".")[0])')"
  fi
  if (( node_major >= 22 )) && command -v npm >/dev/null 2>&1; then
    return
  fi

  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
      if ! command -v winget >/dev/null 2>&1; then
        echo "Install Node.js 22+ (winget package OpenJS.NodeJS.LTS), then rerun." >&2
        exit 1
      fi
      winget upgrade --id OpenJS.NodeJS.LTS --exact --accept-package-agreements --accept-source-agreements --silent || \
        winget install --id OpenJS.NodeJS.LTS --exact --accept-package-agreements --accept-source-agreements --silent --force
      export PATH="/c/Program Files/nodejs:$PATH"
      hash -r
      ;;
    Linux*)
      if ! command -v apt-get >/dev/null 2>&1; then
        echo "Automatic Node.js installation is supported on Ubuntu via apt-get." >&2
        exit 1
      fi
      if (( EUID == 0 )); then
        apt-get update
        apt-get install -y ca-certificates curl
        curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
        apt-get install -y nodejs
      else
        command -v sudo >/dev/null 2>&1 || { echo "sudo is required to install Node.js." >&2; exit 1; }
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
        sudo apt-get install -y nodejs
      fi
      ;;
    *)
      echo "Automatic Node.js installation supports Ubuntu and Windows with Git Bash." >&2
      exit 1
      ;;
  esac

  command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1 || {
    echo "Node.js/npm was installed; reopen the shell and rerun this script." >&2
    exit 1
  }
  node_major="$(node -p 'Number(process.versions.node.split(".")[0])')"
  (( node_major >= 22 )) || { echo "Node.js 22 or later is required; found $(node --version)." >&2; exit 1; }
}

ensure_node_npm
npm install --global @anthropic-ai/claude-code
claude --version
