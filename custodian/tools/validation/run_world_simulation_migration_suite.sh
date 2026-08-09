#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo_root"
if git ls-files | rg -q '(^|/)__pycache__/|\.pyc$'; then echo "tracked Python cache artifacts remain" >&2; exit 1; fi
if PYTHONDONTWRITEBYTECODE=1 python3 -c 'import pytest' 2>/dev/null; then
  PYTHONDONTWRITEBYTECODE=1 python3 -m pytest python-sim/tests/test_godot_parity_export.py
else
  echo "pytest unavailable; running the same unittest-compatible export tests directly"
  PYTHONDONTWRITEBYTECODE=1 python3 python-sim/tests/test_godot_parity_export.py
fi
PYTHONDONTWRITEBYTECODE=1 python3 python-sim/tools/export_godot_parity_fixtures.py
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
PYTHONDONTWRITEBYTECODE=1 python3 python-sim/tools/export_godot_parity_fixtures.py --output "$tmp_dir"
diff -ru custodian/tools/validation/fixtures/world_simulation "$tmp_dir"
env HOME=/tmp/custodian-godot-home godot --headless --path custodian --import --quit
for smoke in world_simulation_kernel_smoke.gd world_simulation_python_parity_smoke.gd world_simulation_snapshot_roundtrip_smoke.gd campaign_outcome_exactly_once_smoke.gd repair_fabrication_simulation_smoke.gd world_simulation_live_scene_smoke.gd; do
  env HOME=/tmp/custodian-godot-home godot --headless --path custodian --script "res://tools/validation/$smoke"
done
python3 custodian/tools/validation/architecture_ownership_smoke.py
echo "WORLD SIMULATION MIGRATION SUITE: PASS"
