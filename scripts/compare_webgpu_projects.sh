#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN_DEFAULT="/home/yuiseki/Workspaces/repos/_godot/davnotdev-godot-src/bin/godot.linuxbsd.editor.x86_64.llvm"
GODOT_BIN="${GODOT_BIN:-$GODOT_BIN_DEFAULT}"
DISPLAY_VALUE="${DISPLAY_VALUE:-:0}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-45}"
QUIT_AFTER="${QUIT_AFTER:-3}"
RENDERING_DRIVER="${RENDERING_DRIVER:-webgpu}"
RENDERING_METHOD="${RENDERING_METHOD:-forward_plus}"
STAMP_BASE="${RUN_TAG:-$(date +%Y%m%d-%H%M%S)}"
STAMP="${STAMP_BASE}-$(printf '%s-%s' "$RENDERING_DRIVER" "$RENDERING_METHOD" | tr '/ ' '__')-$$"
RUN_DIR="$ROOT_DIR/logs/$STAMP"
SUMMARY_TSV="$RUN_DIR/summary.tsv"
SUMMARY_MD="$RUN_DIR/summary.md"

mkdir -p "$RUN_DIR"

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "Godot binary not found or not executable: $GODOT_BIN" >&2
  exit 1
fi

mapfile -t PROJECT_DIRS < <(find "$ROOT_DIR" -maxdepth 1 -mindepth 1 -type d -name '[0-9][0-9][0-9]_*' | sort)

if [[ "${#PROJECT_DIRS[@]}" -eq 0 ]]; then
  echo "No numbered project directories found under $ROOT_DIR" >&2
  exit 1
fi

printf "project\tstatus\telapsed_s\twebgpu\tshader_count\tscene_load\tready\twgsl_error_count\terror_count\tlog_file\n" > "$SUMMARY_TSV"

run_project() {
  local project_dir="$1"
  local project_name
  project_name="$(basename "$project_dir")"
  local log_file="$RUN_DIR/${project_name}.log"
  local start_ns end_ns elapsed_ms elapsed_s status ready webgpu shader_count scene_load wgsl_error_count error_count

  start_ns="$(date +%s%N)"
  set +e
  DISPLAY="$DISPLAY_VALUE" timeout --signal=TERM "${TIMEOUT_SECONDS}s" \
    "$GODOT_BIN" \
    --verbose \
    --quit-after "$QUIT_AFTER" \
    --rendering-driver "$RENDERING_DRIVER" \
    --rendering-method "$RENDERING_METHOD" \
    --path "$project_dir" \
    >"$log_file" 2>&1
  status=$?
  set -e
  end_ns="$(date +%s%N)"

  elapsed_ms="$(( (end_ns - start_ns) / 1000000 ))"
  elapsed_s="$(awk "BEGIN { printf \"%.3f\", $elapsed_ms / 1000 }")"

  if rg -q "WebGpu v[0-9.]+ \\(wgpu\\)" "$log_file"; then
    webgpu="yes"
  else
    webgpu="no"
  fi

  if rg -q "${project_name} ready" "$log_file"; then
    ready="yes"
  else
    ready="no"
  fi

  shader_count="$(rg -c "^Shader '" "$log_file" 2>/dev/null || echo 0)"

  if rg -q "Loading resource: res://main.tscn" "$log_file"; then
    scene_load="yes"
  else
    scene_load="no"
  fi

  wgsl_error_count="$(rg -c "WGSL compilation" "$log_file" 2>/dev/null || echo 0)"

  error_count="$(rg -c "ERROR:|CRITICAL:|SCRIPT ERROR:" "$log_file" 2>/dev/null || echo 0)"

  case "$status" in
    0) status="ok" ;;
    124) status="timeout" ;;
    137) status="killed" ;;
    *) status="exit_${status}" ;;
  esac

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$project_name" "$status" "$elapsed_s" "$webgpu" "$shader_count" "$scene_load" "$ready" "$wgsl_error_count" "$error_count" "$log_file" \
    >> "$SUMMARY_TSV"
}

for project_dir in "${PROJECT_DIRS[@]}"; do
  run_project "$project_dir"
done

{
  echo "# WebGPU Compare"
  echo
  echo "- timestamp: \`$STAMP\`"
  echo "- godot: \`$GODOT_BIN\`"
  echo "- display: \`$DISPLAY_VALUE\`"
  echo "- timeout: \`${TIMEOUT_SECONDS}s\`"
  echo "- quit-after: \`$QUIT_AFTER\`"
  echo "- rendering-driver: \`$RENDERING_DRIVER\`"
  echo "- rendering-method: \`$RENDERING_METHOD\`"
  echo
  echo "| project | status | elapsed_s | webgpu | shader_count | scene_load | ready | wgsl_error_count | error_count |"
  echo "| --- | --- | ---: | --- | ---: | --- | --- | ---: | ---: |"
  tail -n +2 "$SUMMARY_TSV" | while IFS=$'\t' read -r project status elapsed_s webgpu shader_count scene_load ready wgsl_error_count error_count log_file; do
    echo "| $project | $status | $elapsed_s | $webgpu | $shader_count | $scene_load | $ready | $wgsl_error_count | $error_count |"
  done
  echo
  echo "## Logs"
  echo
  tail -n +2 "$SUMMARY_TSV" | while IFS=$'\t' read -r project status elapsed_s webgpu shader_count scene_load ready wgsl_error_count error_count log_file; do
    echo "- \`$project\`: \`$log_file\`"
  done
} > "$SUMMARY_MD"

echo "$SUMMARY_MD"
