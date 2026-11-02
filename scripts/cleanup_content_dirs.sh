#!/usr/bin/env bash
set -Eeuo pipefail

# CUSTODIAN content directory cleanup.
#
# Default behavior:
#   - Moves selected dirs into .cleanup_quarantine/<timestamp>/...
#   - Does NOT permanently delete.
#   - Skips dirs with live references unless FORCE=1.
#   - Writes a cleanup report under docs/ai_context/cleanup_reports/.
#
# Permanent delete:
#   PURGE=1 bash scripts/cleanup_content_dirs.sh
#
# Include more aggressive review-only targets:
#   AGGRESSIVE=1 bash scripts/cleanup_content_dirs.sh
#
# Ignore reference guard:
#   FORCE=1 bash scripts/cleanup_content_dirs.sh

ROOT="${1:-$HOME/Projects/CUSTODIAN/custodian}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
PURGE="${PURGE:-0}"
FORCE="${FORCE:-0}"
AGGRESSIVE="${AGGRESSIVE:-0}"

cd "$ROOT"

if [[ ! -f "project.godot" ]]; then
  echo "ERROR: '$ROOT' does not look like the Godot project root. Expected project.godot."
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: '$ROOT' is not inside a git worktree. Refusing destructive cleanup."
  exit 1
fi

QUARANTINE=".cleanup_quarantine/$STAMP"
REPORT_DIR="docs/ai_context/cleanup_reports"
REPORT="$REPORT_DIR/content_cleanup_$STAMP.md"

mkdir -p "$REPORT_DIR"
mkdir -p "$QUARANTINE"

# Keep quarantine out of git noise.
grep -qxF ".cleanup_quarantine/" .git/info/exclude 2>/dev/null || {
  echo ".cleanup_quarantine/" >> .git/info/exclude
}

# Low-risk cleanup targets.
# These are vendor/sample packs, scratch exports, disabled pipeline folders,
# duplicated extracted copies, debug folders, or old generated road exports.
DEFAULT_REMOVE=(
  "content/sprites/additional-charsets"
  "content/sprites/dev"
  "content/sprites/misc"
  "content/sprites/modulating"

  "content/sprites/_pipeline/archive"
  "content/sprites/_pipeline/logs"
  "content/sprites/_pipeline/test"
  "content/sprites/_pipeline/inbox_disabled"

  "content/sprites/environment/ambient_critter/done-replaced"

  "content/props/ruins/extracted"

  "content/tiles/debug"
  "content/tiles/source/placeholder-tileset"

  "content/tiles/roads_paths/legacy/paths_exports_nested_copy"
  "content/tiles/roads_paths/legacy/road_piece_exports_game32_previous"
  "content/tiles/roads_paths/legacy/tool_pycache_previous"
)

# Review-only targets. These smell like generated/vendor/intermediate folders,
# but I would not delete them blindly until the grep guard passes cleanly.
AGGRESSIVE_REMOVE=(
  "content/_aseprite/sprites/additional-charsets"
  "content/_aseprite/sprites/dev"

  "content/sprites/_pipeline/inbox"
  "content/sprites/_pipeline/normalized"

  "content/sprites/operator/runtime/live_review"
  "content/sprites/enemies/enemy_brawler/index-parts"
  "content/sprites/enemies/enemy_scout/exports"

  "content/tiles/interiors/asset_exports"
  "content/tiles/interiors/source/tilize"

  "content/props/gothic_compound/misc"
)

BELL_DRIFT_PATHS=(
  "content/dialogue/ash_bell"
  "content/items/lore/ash_bell_items.json"
  "content/procgen/special_rooms/ash_bell_forlorn_ritualant_room.json"
  "content/procgen/special_rooms/gothic_compound/09_bell_frame_gothic_small.png"
)

removed=()
skipped_missing=()
skipped_refs=()
skipped_errors=()

has_external_refs() {
  local rel="$1"

  # Look for references outside the target dir itself.
  # Exclude Godot import metadata and quarantine noise.
  git grep -n --fixed-strings "$rel/" -- . \
    ':(exclude).cleanup_quarantine/**' \
    ':(exclude)**/*.import' \
    ':(exclude)**/*.uid' \
    ':(exclude)**/.godot/**' \
    2>/dev/null \
    | grep -v "^${rel}/" \
    || true
}

remove_or_quarantine() {
  local rel="$1"

  if [[ ! -e "$rel" ]]; then
    skipped_missing+=("$rel")
    return 0
  fi

  local refs
  refs="$(has_external_refs "$rel")"

  if [[ -n "$refs" && "$FORCE" != "1" ]]; then
    skipped_refs+=("$rel")
    {
      echo
      echo "## Skipped due to references: $rel"
      echo
      echo '```'
      echo "$refs" | head -80
      echo '```'
    } >> "$REPORT"
    return 0
  fi

  if [[ "$PURGE" == "1" ]]; then
    rm -rf -- "$rel"
    removed+=("PURGED: $rel")
  else
    local dest="$QUARANTINE/$rel"
    mkdir -p "$(dirname "$dest")"
    mv -- "$rel" "$dest"
    removed+=("QUARANTINED: $rel -> $dest")
  fi
}

{
  echo "# CUSTODIAN content cleanup report"
  echo
  echo "- Timestamp UTC: $STAMP"
  echo "- Project root: $ROOT"
  echo "- PURGE: $PURGE"
  echo "- FORCE: $FORCE"
  echo "- AGGRESSIVE: $AGGRESSIVE"
  echo
  echo "## Intent"
  echo
  echo "Remove generated/vendor/scratch/duplicate content directories from active content paths while preserving source/runtime asset ownership."
  echo
  echo "## Documentation drift noted"
  echo
  echo "The no-bells design direction is not reflected in these still-present paths:"
  for p in "${BELL_DRIFT_PATHS[@]}"; do
    echo "- $p"
  done
  echo
  echo "Recommended follow-up: do a separate Ash Bell rename/deprecation migration, update active design docs, and only then remove/rename runtime files."
} > "$REPORT"

echo "Cleaning default targets..."
for rel in "${DEFAULT_REMOVE[@]}"; do
  remove_or_quarantine "$rel"
done

if [[ "$AGGRESSIVE" == "1" ]]; then
  echo "Cleaning aggressive review targets..."
  for rel in "${AGGRESSIVE_REMOVE[@]}"; do
    remove_or_quarantine "$rel"
  done
fi

{
  echo
  echo "## Removed / quarantined"
  if [[ "${#removed[@]}" -eq 0 ]]; then
    echo "- None"
  else
    for item in "${removed[@]}"; do
      echo "- $item"
    done
  fi

  echo
  echo "## Missing targets"
  if [[ "${#skipped_missing[@]}" -eq 0 ]]; then
    echo "- None"
  else
    for item in "${skipped_missing[@]}"; do
      echo "- $item"
    done
  fi

  echo
  echo "## Skipped due to references"
  if [[ "${#skipped_refs[@]}" -eq 0 ]]; then
    echo "- None"
  else
    for item in "${skipped_refs[@]}"; do
      echo "- $item"
    done
  fi

  echo
  echo "## Post-cleanup commands to run"
  echo
  echo '```bash'
  echo 'git status --short'
  echo 'find content -type d -empty -print'
  echo 'grep -R "ash_bell\|bell_frame" -n content game docs design 2>/dev/null || true'
  echo 'cd "$PWD" && godot --headless --editor --quit 2>/tmp/custodian_godot_import_check.log || true'
  echo 'tail -120 /tmp/custodian_godot_import_check.log'
  echo '```'
} >> "$REPORT"

echo
echo "Cleanup complete."
echo "Report: $REPORT"

if [[ "$PURGE" != "1" ]]; then
  echo "Quarantine: $QUARANTINE"
  echo "Nothing was permanently deleted. Inspect the quarantine, then delete it manually when satisfied."
fi

echo
echo "Next:"
echo "  git status --short"
echo "  less '$REPORT'"
