#!/usr/bin/env bash
set -o pipefail
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
LOG_DIR="$ROOT_DIR/logs"
LOG_FILE="$LOG_DIR/procgen-validation-$(date +%Y%m%d-%H%M%S).log"
overall_code=0

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

if [[ "$overall_code" -ne 0 ]]; then
	echo "procgen validation failed; see $LOG_FILE"
	exit "$overall_code"
fi

echo "procgen validation passed; see $LOG_FILE"
