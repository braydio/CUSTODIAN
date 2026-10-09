#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "pack-context: run inside a CUSTODIAN Git checkout" >&2
  exit 2
}
cd "$REPO_ROOT"
mkdir -p .ai .ai/task-context

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

  task)
    INCLUDE="${2:-}"
    NAME="${3:-task-context}"
    if [ -z "$INCLUDE" ]; then
      echo "Usage: $0 task \"<comma-separated repo-relative include globs>\" [name]" >&2
      exit 2
    fi
    SAFE_NAME="$(printf '%s' "$NAME" | tr -cs 'A-Za-z0-9._-' '-')"
    OUTPUT=".ai/task-context/${SAFE_NAME}.xml"
    npx repomix@latest \
      --include "AGENTS.md,custodian/AGENTS.md,$INCLUDE" \
      --compress \
      --style xml \
      -o "$OUTPUT"
    echo "$OUTPUT"
    ;;

  *)
    echo "Usage: $0 {all|procgen|combat|ui|diff|task <include-globs> [name]}" >&2
    exit 1
    ;;
esac
