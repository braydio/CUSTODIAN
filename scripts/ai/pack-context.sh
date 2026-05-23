#!/usr/bin/env bash
set -euo pipefail

cd /home/braydenchaffee/Projects/CUSTODIAN
mkdir -p .ai

case "${1:-all}" in
  all|arch|architecture)
    npx repomix@latest \
      --include "AGENTS.md,AGENTS_ADDENDUM.md,custodian/AGENTS.md,custodian/project.godot,custodian/autoload/**/*.gd,custodian/game/**/*.gd,custodian/game/**/*.tscn,custodian/content/**/*.json,custodian/docs/**/*.md" \
      --ignore "custodian/addons/**,custodian/content/_aseprite/**,custodian/content/sprites/**,custodian/assets/tiles/**,custodian/docs/archive/**,**/*.png,**/*.jpg,**/*.webp,**/*.aseprite,**/*.ase,**/*.import,**/*.uid,.ai/**" \
      --compress \
      --style xml \
      -o .ai/custodian-architecture.xml
    ;;

  procgen)
    npx repomix@latest \
      --include "AGENTS.md,AGENTS_ADDENDUM.md,custodian/AGENTS.md,custodian/game/world/**/*.gd,custodian/game/world/**/*.tscn,custodian/game/enemies/procgen/**/*.gd,custodian/content/procgen/**/*.json,custodian/content/tiles/**/*.json,custodian/content/tiles/**/*.tres,custodian/docs/**/*procgen*.md,custodian/docs/**/*terrain*.md" \
      --ignore "custodian/addons/**,custodian/content/_aseprite/**,custodian/content/sprites/**,custodian/docs/archive/**,**/*.png,**/*.import,**/*.uid,.ai/**" \
      --compress \
      --style xml \
      -o .ai/custodian-procgen.xml
    ;;

  combat)
    npx repomix@latest \
      --include "AGENTS.md,AGENTS_ADDENDUM.md,custodian/AGENTS.md,custodian/autoload/**/*.gd,custodian/game/systems/core/**/*.gd,custodian/game/systems/combat/**/*.gd,custodian/game/enemies/**/*.gd,custodian/game/resources/**/*.gd,custodian/game/fabrication/**/*.gd,custodian/content/ammo_types/**/*.json,custodian/content/items/**/*.json,custodian/content/resources/**/*.json,custodian/content/fabrication/**/*.json,custodian/docs/**/*combat*.md,custodian/docs/**/*resource*.md" \
      --ignore "custodian/addons/**,custodian/content/_aseprite/**,custodian/content/sprites/**,custodian/docs/archive/**,**/*.png,**/*.import,**/*.uid,.ai/**" \
      --compress \
      --style xml \
      -o .ai/custodian-combat.xml
    ;;

  ui)
    npx repomix@latest \
      --include "AGENTS.md,AGENTS_ADDENDUM.md,custodian/AGENTS.md,custodian/game/ui/**/*.gd,custodian/game/ui/**/*.tscn,custodian/game/ui/**/*.tres,custodian/game/rendering/**/*.gdshader,custodian/content/dialogue/**/*.json,custodian/content/items/lore/**/*.json,custodian/docs/**/*ui*.md,custodian/docs/**/*terminal*.md" \
      --ignore "custodian/addons/**,custodian/content/_aseprite/**,custodian/content/sprites/**,custodian/docs/archive/**,**/*.png,**/*.import,**/*.uid,.ai/**" \
      --compress \
      --style xml \
      -o .ai/custodian-ui.xml
    ;;

  diff)
    npx repomix@latest \
      --include-diffs \
      --include-logs \
      --include-logs-count 10 \
      --ignore "custodian/addons/**,custodian/content/_aseprite/**,custodian/content/sprites/**,custodian/docs/archive/**,**/*.png,**/*.import,**/*.uid,.ai/**" \
      --compress \
      --style xml \
      -o .ai/custodian-current-diff.xml
    ;;

  *)
    echo "Usage: $0 {all|procgen|combat|ui|diff}" >&2
    exit 1
    ;;
esac
