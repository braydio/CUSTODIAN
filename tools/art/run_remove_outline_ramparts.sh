#!/usr/bin/env bash
set -euo pipefail

cd "${CUSTODIAN_REPO:-$HOME/Projects/CUSTODIAN}"

TARGET_DIR="${1:-custodian/content/tiles/sundered_keep/walls/ramparts}"
LUA_SCRIPT="${LUA_SCRIPT:-tools/art/remove_external_outline_batch.lua}"
ASEPRITE_BIN="${ASEPRITE_BIN:-aseprite}"

OUTLINE_WIDTH="${OUTLINE_WIDTH:-1}"
DARK_THRESHOLD="${DARK_THRESHOLD:-105}"
ALPHA_THRESHOLD="${ALPHA_THRESHOLD:-0}"

if ! command -v "$ASEPRITE_BIN" >/dev/null 2>&1; then
  echo "ERROR: Aseprite not found: $ASEPRITE_BIN" >&2
  exit 1
fi

if [[ ! -f "$LUA_SCRIPT" ]]; then
  echo "ERROR: Missing Lua script: $LUA_SCRIPT" >&2
  exit 1
fi

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "ERROR: Target dir does not exist: $TARGET_DIR" >&2
  echo "Hint: your earlier extractor may have written to:" >&2
  echo "  custodian/content/tiles/sundered/walls/ramparts" >&2
  exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$TARGET_DIR/.outline_backup_$STAMP"
mkdir -p "$BACKUP_DIR"

count=0

while IFS= read -r -d '' src; do
  base="$(basename "$src")"
  tmp="$(mktemp --suffix=.png)"

  cp -p "$src" "$BACKUP_DIR/$base"

  "$ASEPRITE_BIN" -b "$src" \
    --script-param "outlineWidth=$OUTLINE_WIDTH" \
    --script-param "darkThreshold=$DARK_THRESHOLD" \
    --script-param "alphaThreshold=$ALPHA_THRESHOLD" \
    --script-param "output=$tmp" \
    --script "$LUA_SCRIPT"

  if [[ ! -s "$tmp" ]]; then
    rm -f "$tmp"
    echo "ERROR: Aseprite did not write output for: $src" >&2
    exit 1
  fi

  mv "$tmp" "$src"
  echo "cleaned: $src"
  count=$((count + 1))
done < <(find "$TARGET_DIR" -maxdepth 1 -type f -iname '*.png' -print0 | sort -z)

echo
echo "Done. Cleaned $count PNG(s)."
echo "Backup saved to: $BACKUP_DIR"
echo "Params: outlineWidth=$OUTLINE_WIDTH darkThreshold=$DARK_THRESHOLD alphaThreshold=$ALPHA_THRESHOLD"
