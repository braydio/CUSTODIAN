#!/usr/bin/env bash
# Refresh the /tmp/custodian_combo_check_src symlink directory
# so modular_combo_check.py picks up new/edited sprite files.
set -euo pipefail

SRC="/tmp/custodian_combo_check_src"

echo "Rebuilding $SRC …"
rm -rf "$SRC"
mkdir -p "$SRC/lower" "$SRC/upper"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NEW_OP="$PROJECT_ROOT/custodian/content/sprites/operator/new_operator"
RUNTIME_MOD="$PROJECT_ROOT/custodian/content/sprites/operator/runtime/modules/new_operator"

link_lower() { ln -s "$1" "$SRC/lower/$2" 2>/dev/null || true; }
link_upper() { ln -s "$1" "$SRC/upper/$2" 2>/dev/null || true; }

# ── Lower body from runtime (locomotion) ──
for anim in idle_01 run_01 walk_01; do
    for f in "$RUNTIME_MOD/lower_body/locomotion/$anim"/*.png; do
        [ -f "$f" ] || continue
        base=$(basename "$f")
        # Strip __unarmed__ so domain resolves to idle/run/walk
        newname=$(echo "$base" | sed 's/__unarmed__/__/')
        link_lower "$f" "$newname"
    done
done

# ── Lower body from source modular (fast actions) ──
for anim in fast_strike_01 fast_windup_01 fast_recovery_01; do
    for f in "$NEW_OP/modular/fast_attack"/*modular_lower_body*.png; do
        [ -f "$f" ] || continue
        base=$(basename "$f")
        newname=$(echo "$base" | sed 's/__unarmed__/__/')
        link_lower "$f" "$newname"
    done
done

# ── Upper body from runtime (locomotion) ──
for anim in idle_01 run_01 walk_01; do
    for f in "$RUNTIME_MOD/upper_body/locomotion/$anim"/*.png; do
        [ -f "$f" ] || continue
        link_upper "$f" "$(basename "$f")"
    done
done

# ── Upper body fast-attack phases from generated runtime actions ──
for anim in fast_windup_01 fast_strike_01 fast_recovery_01; do
    for f in "$RUNTIME_MOD/upper_body/actions/unarmed/fast_attack/$anim"/*.png; do
        [ -f "$f" ] || continue
        link_upper "$f" "$(basename "$f")"
    done
done

# ── Source fallback for any fast-attack phase missing from generated runtime ──
for f in "$NEW_OP/modular/fast_attack"/*modular_upper_body*.png; do
    [ -f "$f" ] || continue
    base=$(basename "$f")
    # Already in runtime? skip to avoid collision
    [ -f "$SRC/upper/$base" ] && continue
    link_upper "$f" "$base"
done

lower_count=$(find "$SRC/lower" -maxdepth 1 -name '*.png' | wc -l)
upper_count=$(find "$SRC/upper" -maxdepth 1 -name '*.png' | wc -l)
echo "Done — $lower_count lower + $upper_count upper = $((lower_count + upper_count)) total"
