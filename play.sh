#!/usr/bin/env bash
set -eu
project_dir="$(cd "$(dirname "$0")" && pwd)"
if [[ -n "${GODOT_BIN:-}" ]]; then
  candidates=("$GODOT_BIN")
else
  candidates=(godot4 godot "$HOME/.local/share/axel-godot/Godot_v4.6.3-stable_linux.x86_64")
fi
engine=""
for candidate in "${candidates[@]}"; do
  if command -v "$candidate" >/dev/null && version=$("$candidate" --version) && [[ "$version" == 4.* ]]; then
    engine="$candidate"
    break
  fi
done
if [[ -z "$engine" ]]; then
  echo "Godot 4 is required. Set GODOT_BIN to your Godot 4 executable." >&2
  exit 1
fi
case "${1:-saved}" in
  saved) args=() ;;
  compatibility) args=(--rendering-method gl_compatibility) ;;
  mobile) args=(--rendering-method mobile) ;;
  forward+) args=(--rendering-method forward_plus) ;;
  fsr2) args=(--rendering-method forward_plus -- --fsr2) ;;
  *) echo 'Usage: play.sh [compatibility|mobile|forward+|fsr2]' >&2; exit 2 ;;
esac
exec "$engine" --path "$project_dir" "${args[@]}"
