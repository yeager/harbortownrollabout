#!/usr/bin/env bash
set -uo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
mode="${1:-native}"
case "$mode" in
  native) launcher=("$project_dir/play.sh" dlss-lab) ;;
  fsr2) launcher=("$project_dir/play.sh" dlss-lab-fsr2) ;;
  dlss)
    if [[ -z "${GODOT_BIN:-}" ]]; then
      echo 'Set GODOT_BIN to the locally built NGX-enabled Godot editor binary.' >&2
      exit 2
    fi
    launcher=("$project_dir/play.sh" dlss-lab-dlss)
    ;;
  *) echo 'Usage: dlss_lab/profile.sh [native|fsr2|dlss]' >&2; exit 2 ;;
esac

stamp="$(date -u +%Y%m%dT%H%M%S%NZ)"
tag="${DLSS_LAB_TAG:-$mode}"
out_root="${DLSS_LAB_OUTPUT_DIR:-$project_dir/dlss_lab/runs}"
run_dir="$out_root/${stamp}_${tag}"
mkdir -p "$out_root"
mkdir "$run_dir"

record() {
  local label="$1"
  shift
  printf '%s\n' "[$label]" | tee -a "$run_dir/metadata.txt"
  if "$@" >>"$run_dir/metadata.txt" 2>&1; then
    :
  else
    printf '%s\n' unavailable >>"$run_dir/metadata.txt"
  fi
}

{
  printf 'run_utc=%s\nmode=%s\ntag=%s\n' "$stamp" "$mode" "$tag"
  printf 'host=%s\n' "$(uname -a)"
  printf 'display=%s\n' "${XDG_SESSION_TYPE:-unknown}"
} >"$run_dir/metadata.txt"

godot_bin="${GODOT_BIN:-}"
if [[ -z "$godot_bin" ]]; then
  if command -v godot >/dev/null 2>&1; then godot_bin="$(command -v godot)"
  else godot_bin="$HOME/.local/share/axel-godot/Godot_v4.6.3-stable_linux.x86_64"
  fi
fi
printf 'godot_binary=%s\n' "$godot_bin" >>"$run_dir/metadata.txt"
record godot_version "$godot_bin" --version
if command -v nvidia-smi >/dev/null 2>&1; then
  record nvidia_gpu nvidia-smi --query-gpu=name,driver_version,pstate,power.limit --format=csv
else
  printf '[nvidia_gpu]\nunavailable\n' >>"$run_dir/metadata.txt"
fi

printf 'Output: %s\n' "$run_dir"
"${launcher[@]}" 2>&1 | tee "$run_dir/run.log"
app_status=${PIPESTATUS[0]}
if [[ "$mode" == dlss ]]; then
  awk '
    /\[NGX DLSS\] DLSS-(SR|RR) frame evaluated successfully/ { evaluated = 1 }
    /\[NGX DLSS\] Context unavailable after NGX initialization failed/ { fallback = 1 }
    END {
      print "ngx_frame_evaluation_observed=" (evaluated ? "yes" : "no")
      print "ngx_init_fallback_observed=" (fallback ? "yes" : "no")
    }
  ' "$run_dir/run.log" >>"$run_dir/metadata.txt"
fi
if command -v nvidia-smi >/dev/null 2>&1; then
  record nvidia_gpu_after nvidia-smi --query-gpu=name,driver_version,pstate,power.draw,utilization.gpu,memory.used --format=csv
fi
exit "$app_status"
