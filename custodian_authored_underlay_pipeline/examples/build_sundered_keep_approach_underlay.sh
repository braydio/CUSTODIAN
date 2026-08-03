#!/usr/bin/env bash
set -euo pipefail

# Run from the CUSTODIAN repository root.
PIPELINE_PYTHON="${PIPELINE_PYTHON:-custodian_authored_underlay_pipeline/.venv/bin/python}"

"${PIPELINE_PYTHON}" custodian/tools/content/slice_authored_underlay.py \
  --source art_source/underlays/sundered_keep/approach/sundered_keep_approach_master.png \
  --repo-root . \
  --godot-root custodian \
  --asset-id sundered_keep_approach \
  --output-res-dir content/backgrounds/sundered_keep/approach/runtime/plates \
  --manifest-res-path content/backgrounds/sundered_keep/approach/runtime/sundered_keep_approach.plates.json \
  --runtime-scene-res-path game/world/approaches/sundered_keep/generated/sundered_keep_approach_underlay_runtime.tscn \
  --preview-scene-res-path scenes/debug/generated/sundered_keep_approach_underlay_preview.tscn \
  --world-origin-x -1536 \
  --world-origin-y -1236 \
  --world-units-per-pixel 1.0 \
  --plate-size 2048 \
  --bleed 16 \
  --z-index -120 \
  --texture-filter linear_mipmaps \
  --preload-margin-world 768 \
  --unload-margin-world 1536 \
  --max-loads-per-tick 2 \
  --clean

# Import generated resources.
godot --headless --path custodian --editor --quit

# Validate the runtime scene and manifest.
godot --headless \
  --path custodian \
  --script res://tools/validation/authored_underlay_plate_pipeline_smoke.gd \
  -- \
  --manifest=res://content/backgrounds/sundered_keep/approach/runtime/sundered_keep_approach.plates.json \
  --scene=res://game/world/approaches/sundered_keep/generated/sundered_keep_approach_underlay_runtime.tscn
