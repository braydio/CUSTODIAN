#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/home/braydenchaffee/Projects/CUSTODIAN"
PAI_DIR="/home/braydenchaffee/Production/AI-Tools/pai-opencode"

WORKSPACE_MAIN="${CUSTODIAN_MAIN_WORKSPACE:-1}"
WORKSPACE_ART="${CUSTODIAN_ART_WORKSPACE:-2}"
STARTUP_DELAY_SECONDS="${CUSTODIAN_STARTUP_DELAY_SECONDS:-6}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

exec_in_workspace() {
  local workspace="$1"
  local command="$2"

  hyprctl dispatch exec "[workspace ${workspace} silent] ${command}"
}

require_cmd hyprctl
require_cmd kitty
require_cmd aseprite
require_cmd codex

if ! command -v godot >/dev/null 2>&1; then
  echo "Missing required command: godot" >&2
  exit 1
fi

if [[ ! -d "$PAI_DIR" ]]; then
  echo "Missing directory: $PAI_DIR" >&2
  exit 1
fi

godot_cmd="$(printf 'kitty --detach --title %q bash -lc %q' \
  "custodian-godot-ai" \
  "cd \"$ROOT_DIR\" && exec godot --editor --path custodian")"

codex_cmd="$(printf 'kitty --detach --title %q bash -lc %q' \
  "custodian-codex" \
  "cd \"$ROOT_DIR\" && exec codex")"

aseprite_cmd="$(printf '%q' "aseprite")"

pai_cmd="$(printf 'kitty --detach --title %q bash -lc %q' \
  "pai" \
  "cd \"$PAI_DIR\" && exec pai")"

exec_in_workspace "$WORKSPACE_MAIN" "$godot_cmd"

sleep "$STARTUP_DELAY_SECONDS"

exec_in_workspace "$WORKSPACE_MAIN" "$codex_cmd"

exec_in_workspace "$WORKSPACE_ART" "$aseprite_cmd"

exec_in_workspace "$WORKSPACE_ART" "$pai_cmd"
