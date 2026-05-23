#!/usr/bin/env bash
set -euo pipefail

cd /home/braydenchaffee/Projects/CUSTODIAN
mkdir -p .ai

case "${1:-elevation}" in
elevation | terrain | touched | codex-elevation)
  npx repomix@latest \
    --include "AGENTS.md,AGENTS_ADDENDUM.md,custodian/AGENTS.md,custodian/game/world/elevation/**/*.gd,custodian/game/world/procgen/proc_gen_tilemap.gd,custodian/game/world/procgen/terrain/**/*.gd,custodian/game/actors/operator/operator.gd,custodian/game/actors/base/vehicle_base.gd,custodian/tools/validation/*elevation*.gd,custodian/tools/validation/*terrain*.gd,design/features/implementation/TERRAIN_BUILDER_ELEVATION_INTEGRATION.md,custodian/docs/ai_context/CURRENT_STATE.md,custodian/docs/ai_context/FILE_INDEX.md" \
    --ignore "custodian/addons/**,custodian/content/_aseprite/**,custodian/content/sprites/**,custodian/assets/tiles/**,custodian/docs/archive/**,**/*.png,**/*.jpg,**/*.webp,**/*.aseprite,**/*.ase,**/*.import,**/*.uid,.ai/**" \
    --compress \
    --style xml \
    -o .ai/custodian-elevation-slice.xml
  ;;

elevation-diff | terrain-diff)
  npx repomix@latest \
    --include "AGENTS.md,AGENTS_ADDENDUM.md,custodian/AGENTS.md,custodian/game/world/elevation/**/*.gd,custodian/game/world/procgen/proc_gen_tilemap.gd,custodian/game/world/procgen/terrain/**/*.gd,custodian/game/actors/operator/operator.gd,custodian/game/actors/base/vehicle_base.gd,custodian/tools/validation/*elevation*.gd,custodian/tools/validation/*terrain*.gd,design/features/implementation/TERRAIN_BUILDER_ELEVATION_INTEGRATION.md,custodian/docs/ai_context/CURRENT_STATE.md,custodian/docs/ai_context/FILE_INDEX.md" \
    --include-diffs \
    --include-logs \
    --include-logs-count 10 \
    --ignore "custodian/addons/**,custodian/content/_aseprite/**,custodian/content/sprites/**,custodian/assets/tiles/**,custodian/docs/archive/**,**/*.png,**/*.jpg,**/*.webp,**/*.aseprite,**/*.ase,**/*.import,**/*.uid,.ai/**" \
    --compress \
    --style xml \
    -o .ai/custodian-elevation-slice-with-diff.xml
  ;;

*)
  echo "Usage: $0 {elevation|elevation-diff}" >&2
  exit 1
  ;;
esac
