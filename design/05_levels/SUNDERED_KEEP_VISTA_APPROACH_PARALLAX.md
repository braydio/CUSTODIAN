# Sundered Keep Vista Approach Parallax

**Project:** CUSTODIAN  
**Status:** blocked — replacement plates require alpha validation and visual review  
**Parent specification:** `design/05_levels/SUNDERED_KEEP_VISTA_APPROACH.md`

## Purpose

Add presentation-only depth without changing the authored route, collision,
progression, reveal timing, camera authority, or Grand Vista composition.

## Current review gate

The existing first-vista composition is the only active Vista background
authority. The shared `SunderedKeepParallaxRig` still creates its empty
`BaseDepth`, `RevealDepth`, and `ForegroundDepth` roots for compatibility, but
all six supplementary layer gates default to `false`.

The inspected source revisions have these blockers:

| Asset group | Current verdict |
|---|---|
| Far cliff islands | baked checkerboard in clouds and island silhouettes |
| Causeway far arches | baked checkerboard in fog and architecture |
| Lower cliff depth | nearly opaque checkerboard across the canvas |
| Ocean mist pair | left contains checkerboard; right is a mismatched hard-edged landscape |
| Near edge mist pair | baked checkerboard inside both bright mist edges |
| Foreground ruined arch | alpha is usable, but scale/coverage is compositionally unsafe |

The invalid plate hashes are rejected by
`validate_sundered_keep_parallax_assets.py`. Replacing a file removes that
specific source-revision failure, after which alpha checks and four-background
review sheets remain required.

## Runtime ownership

`SunderedKeepApproach` constructs the shared rig and copies its exported review
gates before `build(...)`. Disabled layers are not constructed or loaded.
Return Causeway uses the same safe defaults and retains only its compatible
distant Keep landmark.

The rig owns decorative `Node2D`, `Parallax2D`, and `Sprite2D` nodes only. It
never owns collision, navigation, route state, markers, exits, camera behavior,
combat, or simulation.

## Approved tuning envelope

These are inactive starting values for clean replacement plates:

| Layer | Vista scroll scale | Maximum plate alpha | Default |
|---|---:|---:|---|
| Far cliff islands | `(0.08, 0.04)` | `0.22` | disabled |
| Causeway far arches | `(0.14, 0.07)` | `0.16` | disabled |
| Lower cliff depth | `(0.24, 0.13)` | `0.28` | disabled |
| Ocean mist | `(0.42, 0.24)` | `0.14` | disabled |
| Near edge mist | `(0.82, 0.72)` | `0.08` | disabled |
| Foreground ruined arch | `(1.04, 1.02)` | `0.0` | disabled |

The foreground arch must remain invisible until a later event-driven framing
pass is separately reviewed. Causeway arches are evaluated only after the far
cliffs, lower cliffs, and ocean mist establish a clean minimal stack.

## Asset review

Run:

```bash
python custodian/tools/validation/validate_sundered_keep_parallax_assets.py \
  --review-dir reports/sundered_keep_parallax_asset_review
```

Review every generated sheet over red, green, black, and white. Approval
requires real alpha around the subject, no checkerboard, no rectangular sky or
fog plate, no hard unrelated landscape boundary, and a coherent left/right
mist pair.

## Validation

- `sundered_keep_parallax_depth_smoke.gd` proves review-blocked layers are not
  built in either production level.
- `return_causeway_parallax_smoke.gd` preserves the distant Keep compatibility
  path without loading rejected supplementary plates.
- Existing Vista route, reveal, collision, roof, fog-coverage, and authored-exit
  smokes remain regressions.
