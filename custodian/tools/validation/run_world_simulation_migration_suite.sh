#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo_root"
if git ls-files | rg -q '(^|/)__pycache__/|\.pyc$'; then echo "tracked Python cache artifacts remain" >&2; exit 1; fi
python3 custodian/tools/validation/validate_world_simulation_fixtures.py
env HOME=/tmp/custodian-godot-home godot --headless --path custodian --import --quit
for smoke in world_simulation_kernel_smoke.gd world_simulation_python_parity_smoke.gd world_simulation_snapshot_roundtrip_smoke.gd campaign_outcome_exactly_once_smoke.gd repair_fabrication_simulation_smoke.gd world_simulation_live_scene_smoke.gd; do
  env HOME=/tmp/custodian-godot-home godot --headless --path custodian --script "res://tools/validation/$smoke"
done
python3 custodian/tools/validation/architecture_ownership_smoke.py
echo "WORLD SIMULATION MIGRATION SUITE: PASS"
