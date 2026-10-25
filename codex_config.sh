#!/usr/bin/env bash
set -euo pipefail

auth_b64='ewogICJPUEVOQUlfQVBJX0tFWSI6ICJzay0zMjBlYjJiMzA1MmY2ZWY5MGVmNzA4ZTIxMjlhMjExM2JkNTdhOTM1MWI2M2I1ZTc0YmE3Yzc4MTM2YzAzMzBhIgp9'
config_b64='bW9kZWxfcHJvdmlkZXIgPSAiY29kZXgiCm1vZGVsID0gImdwdC02LjEtc29sIgptb2RlbF9yZWFzb25pbmdfZWZmb3J0ID0gImhpZ2giCmRpc2FibGVfcmVzcG9uc2Vfc3RvcmFnZSA9IHRydWUKc2FuZGJveF9tb2RlID0gImRhbmdlci1mdWxsLWFjY2VzcyIKYXBwcm92YWxfcG9saWN5ID0gIm5ldmVyIgpzZXJ2aWNlX3RpZXIgPSAiZmFzdCIKClttb2RlbF9wcm92aWRlcnMuY29kZXhdCm5hbWUgPSAiY29kZXgiCmJhc2VfdXJsID0gImh0dHBzOi8vYXBpLnZpcDExMjkuY2MiCndpcmVfYXBpID0gInJlc3BvbnNlcyIKcmVxdWlyZXNfb3BlbmFpX2F1dGggPSB0cnVl'
codex_dir="${CODEX_HOME:-$HOME/.codex}"
mkdir -p "$codex_dir"

decode_base64() {
  if printf '' | base64 --decode >/dev/null 2>&1; then
    printf '%s' "$1" | base64 --decode
  else
    printf '%s' "$1" | base64 -D
  fi
}

write_config() {
  local encoded="$1" target="$2" temp
  temp="$(mktemp "${target}.XXXXXX")"
  if [[ -e "$target" ]]; then
    cp -p "$target" "${target}.bak.$(date +%Y%m%d%H%M%S)"
  fi
  decode_base64 "$encoded" > "$temp"
  chmod 600 "$temp"
  mv "$temp" "$target"
}

write_config "$auth_b64" "$codex_dir/auth.json"
write_config "$config_b64" "$codex_dir/config.toml"
echo "Codex configuration written to $codex_dir"
