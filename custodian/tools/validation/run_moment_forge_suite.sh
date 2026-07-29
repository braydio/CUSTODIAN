#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo_root"

python3 -m py_compile custodian/tools/iteration/*.py
python3 custodian/tools/validation/moment_forge_smoke.py
godot --headless --path custodian --script \
  res://tools/validation/moment_forge_runtime_smoke.gd
