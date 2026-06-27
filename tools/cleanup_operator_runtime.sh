#!/usr/bin/env bash
set -euo pipefail

APPLY=0
if [[ "${1:-}" == "--apply" ]]; then
  APPLY=1
elif [[ "${1:-}" != "" && "${1:-}" != "--dry-run" ]]; then
  echo "Usage: $0 [--dry-run|--apply]"
  exit 2
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

OP="custodian/content/sprites/operator"
REPORT_ROOT="reports/operator_runtime_cleanup"
STAMP="$(date +%Y%m%d_%H%M%S)"
QUARANTINE="$REPORT_ROOT/quarantine_$STAMP"
REPORT="$REPORT_ROOT/cleanup_report_$STAMP.txt"

mkdir -p "$REPORT_ROOT"

log() {
  echo "$*" | tee -a "$REPORT"
}

res_path_for() {
  local path="$1"
  echo "res://${path#custodian/}"
}

has_reference() {
  local path="$1"
  local res_path
  res_path="$(res_path_for "$path")"

  rg --fixed-strings --quiet "$res_path" \
    custodian design reports \
    --glob '*.gd' \
    --glob '*.tscn' \
    --glob '*.tres' \
    --glob '*.theme' \
    --glob '*.cfg' \
    --glob '*.json' \
    --glob '*.md' \
    2>/dev/null
}

stage_path() {
  local path="$1"
  local reason="$2"

  [[ -e "$path" ]] || return 0

  if has_reference "$path"; then
    log "SKIP referenced: $path :: $reason"
    return 0
  fi

  log "MOVE candidate: $path :: $reason"

  if [[ "$APPLY" -eq 1 ]]; then
    mkdir -p "$QUARANTINE/$(dirname "$path")"
    mv "$path" "$QUARANTINE/$path"
  fi
}

stage_file_if_unreferenced() {
  local file="$1"
  local reason="$2"

  [[ -f "$file" ]] || return 0

  if has_reference "$file"; then
    log "SKIP referenced file: $file :: $reason"
    return 0
  fi

  log "MOVE file: $file :: $reason"

  if [[ "$APPLY" -eq 1 ]]; then
    mkdir -p "$QUARANTINE/$(dirname "$file")"
    mv "$file" "$QUARANTINE/$file"

    if [[ -f "$file.import" ]]; then
      mkdir -p "$QUARANTINE/$(dirname "$file.import")"
      mv "$file.import" "$QUARANTINE/$file.import"
      log "MOVE paired import: $file.import"
    fi
  fi
}

log "Operator runtime cleanup"
log "Repo: $REPO_ROOT"
log "Mode: $([[ "$APPLY" -eq 1 ]] && echo APPLY || echo DRY-RUN)"
log "Report: $REPORT"
log ""

if [[ -n "$(git status --porcelain)" ]]; then
  log "WARNING: git working tree has changes. This script quarantines files, but review git diff/status after."
  log ""
fi

log "Protected canonical runtime path:"
log "  $OP/runtime/modules/new_operator"
log ""

# 1) Quarantine obvious review/temp directories if unreferenced.
stage_path "$OP/runtime/live_review" "runtime visual review exports, not canonical runtime"
stage_path "$OP/new_operator/modular/recombinator/review" "recombinator review images"
stage_path "$OP/new_operator/modular/recombinator/gif" "recombinator preview gifs"
stage_path "$OP/new_operator/modular/run/temp" "temporary run folder"

# 2) Remove orphan .import files whose source asset is already gone.
log ""
log "Scanning orphan .import files..."
while IFS= read -r import_file; do
  source_file="${import_file%.import}"
  if [[ ! -e "$source_file" ]]; then
    log "ORPHAN import: $import_file"
    if [[ "$APPLY" -eq 1 ]]; then
      mkdir -p "$QUARANTINE/$(dirname "$import_file")"
      mv "$import_file" "$QUARANTINE/$import_file"
    fi
  fi
done < <(find "$OP" -type f -name '*.import' | sort)

# 3) Quarantine obvious non-runtime review/generated junk if unreferenced.
log ""
log "Scanning obvious cleanup file patterns..."

while IFS= read -r file; do
  stage_file_if_unreferenced "$file" "preview gif/html/review/temp/recovered/duplicate artifact"
done < <(
  find "$OP/runtime" "$OP/new_operator/modular" -type f \( \
    -iname '*.gif' -o \
    -iname '*.html' -o \
    -iname '*Recovered*' -o \
    -iname '*_review.png' -o \
    -iname '*_review.png.import' -o \
    -iname '*-Recovered*' -o \
    -iname '*_temp*' -o \
    -iname '*ALTERNATE*' -o \
    -iname '*-sheet.png.png' -o \
    -iname '*-sheet.png.png.import' \
  \) | sort
)

# 4) Quarantine runtime .aseprite/.aseprite.uid only if unreferenced.
# Source .aseprite files outside runtime are intentionally preserved.
log ""
log "Scanning runtime Aseprite leftovers..."
while IFS= read -r file; do
  stage_file_if_unreferenced "$file" "Aseprite source/uid inside runtime tree"
done < <(
  find "$OP/runtime" -type f \( -iname '*.aseprite' -o -iname '*.aseprite.uid' \) | sort
)

log ""
log "Cleanup staging complete."

if [[ "$APPLY" -eq 1 ]]; then
  log "Quarantine created at: $QUARANTINE"
else
  log "Dry-run only. To apply:"
  log "  tools/cleanup_operator_runtime.sh --apply"
fi

log ""
log "Next validation commands:"
log "  python3 custodian/tools/pipelines/build_operator_modular_runtime.py --remove-superseded"
log "  godot --headless --path custodian --import --quit"
log "  godot --headless --path custodian --script res://tools/pipelines/update_operator_curated_resources.gd"
log "  godot --headless --path custodian --script res://tools/validation/operator_modular_layers_smoke.gd"
log "  python3 custodian/tools/validation/operator_animation_contract_report.py --json > $REPORT_ROOT/operator_animation_contract_report_$STAMP.json"
