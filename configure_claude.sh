#!/usr/bin/env bash
set -euo pipefail

settings_b64='ewogICIkc2NoZW1hIjogImh0dHBzOi8vanNvbi5zY2hlbWFzdG9yZS5vcmcvY2xhdWRlLWNvZGUtc2V0dGluZ3MuanNvbiIsCiAgImVudiI6IHsKICAgICJBTlRIUk9QSUNfQkFTRV9VUkwiOiAiaHR0cHM6Ly9hcGkudmlwMTEyOS5jYyIsCiAgICAiQU5USFJPUElDX0FVVEhfVE9LRU4iOiAic2stN2NhNTlmNDczYTg3YjRmNWExYjgwYTk4NzdiMzJhZWU1NzcyOTNmNmUwZDk2Mjg1MzJhZmNmOWMyMDQ2ZTQ2ZiIsCiAgICAiQ0xBVURFX0NPREVfRElTQUJMRV9OT05FU1NFTlRJQUxfVFJBRkZJQyI6ICIxIgogIH0sCiAgInNraXBEYW5nZXJvdXNNb2RlUGVybWlzc2lvblByb21wdCI6IHRydWUsCiAgIm1vZGVsIjogIm9wdXNbMW1dIgp9Cg=='
claude_dir="$HOME/.claude"
target="$claude_dir/settings.json"
mkdir -p "$claude_dir"

if printf '' | base64 --decode >/dev/null 2>&1; then
  decode_base64() { printf '%s' "$1" | base64 --decode; }
else
  decode_base64() { printf '%s' "$1" | base64 -D; }
fi

temp="$(mktemp "${target}.XXXXXX")"
if [[ -e "$target" ]]; then
  cp -p "$target" "${target}.bak.$(date +%Y%m%d%H%M%S)"
fi
decode_base64 "$settings_b64" > "$temp"
chmod 600 "$temp"
mv "$temp" "$target"
echo "Claude Code configuration written to $target"
