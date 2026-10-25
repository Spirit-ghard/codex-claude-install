#!/usr/bin/env bash
set -euo pipefail

"$(dirname "$0")/install_codex.sh" --check-runtime-only
node_major=0
if command -v node >/dev/null 2>&1; then
  node_major="$(node -p 'Number(process.versions.node.split(".")[0])')"
fi
if (( node_major < 22 )) || ! command -v npm >/dev/null 2>&1; then
  echo "Run install_codex.sh first; it installs Node.js 22+ and npm on Ubuntu/Windows." >&2
  exit 1
fi
npm install --global @anthropic-ai/claude-code
claude --version
