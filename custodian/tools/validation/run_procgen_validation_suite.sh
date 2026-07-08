#!/usr/bin/env bash
set -o pipefail
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
LOG_DIR="$ROOT_DIR/logs"
LOG_FILE="$LOG_DIR/procgen-validation-$(date +%Y%m%d-%H%M%S).log"
overall_code=0
run_slow="${RUN_SLOW_PROCGEN:-0}"

for arg in "$@"; do
	if [[ "$arg" == "--full" ]]; then
		run_slow=1
	fi
done

mkdir -p "$LOG_DIR"
exec > >(tee "$LOG_FILE") 2>&1

run_step() {
	local label="$1"
	shift
	echo
	echo "=== $label ==="
	"$@"
	local code=$?
	echo "=== exit_code=$code ==="
	if [[ "$code" -ne 0 && "$overall_code" -eq 0 ]]; then
		overall_code="$code"
	fi
	return 0
}

cd "$ROOT_DIR" || exit 1
run_step architecture_ownership_smoke python custodian/tools/validation/architecture_ownership_smoke.py

cd "$ROOT_DIR/custodian" || exit 1
run_step terrain_builder_smoke godot --headless --path . --script res://tools/validation/terrain_builder_smoke.gd
run_step procgen_terrain_required_cells_smoke godot --headless --path . --script res://tools/validation/procgen_terrain_required_cells_smoke.gd
run_step procgen_foliage_spawner_smoke godot --headless --path . --script res://tools/validation/procgen_foliage_spawner_smoke.gd
run_step terrain_gameplay_packs_smoke godot --headless --path . --script res://tools/validation/terrain_gameplay_packs_smoke.gd
if [[ "$run_slow" == "1" ]]; then
	run_step procgen_contract_rescue_diagnostic_smoke godot --headless --path . --script res://tools/validation/procgen_contract_rescue_diagnostic_smoke.gd
else
	echo
	echo "=== procgen_contract_rescue_diagnostic_smoke skipped; set RUN_SLOW_PROCGEN=1 or pass --full ==="
fi

if [[ "$overall_code" -ne 0 ]]; then
	echo "procgen validation failed; see $LOG_FILE"
	exit "$overall_code"
fi

echo "procgen validation passed; see $LOG_FILE"
