#!/usr/bin/env bash
set -eu
project_dir="$(cd "$(dirname "$0")" && pwd)"
engine="${GODOT_BIN:-godot}"
if ! command -v "$engine" >/dev/null && [[ -z "${GODOT_BIN:-}" ]]; then
  engine="$HOME/.local/share/axel-godot/Godot_v4.6.3-stable_linux.x86_64"
fi
case "${1:-compatibility}" in
  compatibility) args=(--rendering-method gl_compatibility) ;;
  mobile) args=(--rendering-method mobile) ;;
  forward+) args=(--rendering-method forward_plus) ;;
  fsr2) args=(--rendering-method forward_plus -- --fsr2) ;;
  *) echo 'Usage: play.sh [compatibility|mobile|forward+|fsr2]' >&2; exit 2 ;;
esac
exec "$engine" --path "$project_dir" "${args[@]}"
