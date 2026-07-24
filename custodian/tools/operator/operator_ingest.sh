#!/usr/bin/env bash
set -euo pipefail

APPLY=0
SKIP_INBOX=0
NO_IMPORT=0
NO_VALIDATE=0
NO_MIRROR=0

for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    --dry-run) APPLY=0 ;;
    --skip-inbox) SKIP_INBOX=1 ;;
    --no-import) NO_IMPORT=1 ;;
    --no-validate) NO_VALIDATE=1 ;;
    --no-mirror) NO_MIRROR=1 ;;
    -h|--help)
      cat <<'USAGE'
Usage: tools/operator_ingest.sh [--dry-run|--apply] [--skip-inbox] [--no-import] [--no-validate] [--no-mirror]

Default is --dry-run.

--apply       Actually writes manifests/runtime resources and runs import/update/validation.
--skip-inbox  Skip shared inbox manifest generation; rebuild from existing operator modular source.
--no-import   Skip Godot import.
--no-validate Skip smoke/contract validation.
--no-mirror   Do not generate horizontally mirrored direction counterparts.
USAGE
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

STAMP="$(date +%Y%m%d_%H%M%S)"
REPORT_DIR="reports/operator_ingest"
REPORT="$REPORT_DIR/operator_ingest_$STAMP.log"
CONTRACT_REPORT="$REPORT_DIR/operator_animation_contract_report_$STAMP.json"
mkdir -p "$REPORT_DIR"

exec > >(tee "$REPORT") 2>&1

echo "Operator ingest"
echo "Repo: $REPO_ROOT"
echo "Mode: $([[ "$APPLY" -eq 1 ]] && echo APPLY || echo DRY-RUN)"
echo "Skip inbox: $SKIP_INBOX"
echo "No import: $NO_IMPORT"
echo "No validate: $NO_VALIDATE"
echo "No mirror: $NO_MIRROR"
echo "Report: $REPORT"
echo ""

if [[ -n "$(git status --porcelain)" ]]; then
  echo "WARNING: working tree already has changes. Review git status before committing."
  echo ""
fi

if [[ "$SKIP_INBOX" -eq 0 ]]; then
  echo "== Inbox manifest generation =="
  MANIFEST_ARGS=(--regen --remove-superseded)
  if [[ "$NO_MIRROR" -eq 1 ]]; then
    MANIFEST_ARGS+=(--no-mirror)
  fi
  if [[ "$APPLY" -eq 1 ]]; then
    python3 custodian/tools/pipelines/generate_inbox_manifests.py "${MANIFEST_ARGS[@]}"
  else
    python3 custodian/tools/pipelines/generate_inbox_manifests.py \
      "${MANIFEST_ARGS[@]}" \
      --dry-run
  fi
  echo ""
else
  echo "== Inbox manifest generation skipped =="
  echo ""
fi

echo "== Operator modular runtime build =="
if [[ "$APPLY" -eq 1 ]]; then
  python3 custodian/tools/pipelines/build_operator_modular_runtime.py
else
  python3 custodian/tools/pipelines/build_operator_modular_runtime.py --dry-run --remove-superseded
fi
echo ""

if [[ "$APPLY" -eq 0 ]]; then
  echo "Dry-run complete."
  echo "No Godot import, resource update, or validation was run because --apply was not provided."
  exit 0
fi

if [[ "$NO_IMPORT" -eq 0 ]]; then
  echo "== Godot import =="
  godot --headless --path custodian --import --quit
  echo ""
else
  echo "== Godot import skipped =="
  echo ""
fi

echo "== Operator curated resource update =="
godot --headless --path custodian --script res://tools/pipelines/update_operator_curated_resources.gd
echo ""

echo "== Operator superseded runtime cleanup =="
python3 custodian/tools/pipelines/build_operator_modular_runtime.py --remove-superseded
echo ""

if [[ "$NO_VALIDATE" -eq 0 ]]; then
  echo "== Operator modular smoke test =="
  godot --headless --path custodian --script res://tools/validation/operator_modular_layers_smoke.gd
  godot --headless --path custodian --script res://tools/validation/operator_modular_fast_attack_smoke.gd
  godot --headless --path custodian --script res://tools/validation/operator_modular_defense_ranged_smoke.gd
  godot --headless --path custodian --script res://tools/validation/operator_primary_ranged_modular_fire_smoke.gd
  if [[ -f custodian/content/sprites/enemies/enemy_grunt/runtime/body/enemy_grunt__body__melee__critical_execution_victim_01__e__12f__96.png \
    && -f custodian/content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__critical_execution_01__e__12f__96.png \
    && -f custodian/content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__critical_execution_01__w__12f__96.png ]]; then
    godot --headless --path custodian --script res://tools/validation/grunt_parry_crit_reaction_smoke.gd
  fi
  echo ""

  echo "== Operator animation contract report =="
  python3 custodian/tools/validation/operator_animation_contract_report.py --json > "$CONTRACT_REPORT"
  echo "Wrote $CONTRACT_REPORT"
  echo ""
else
  echo "== Validation skipped =="
  echo ""
fi

echo "Operator ingest complete."
echo "Report: $REPORT"
