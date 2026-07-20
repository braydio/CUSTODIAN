# Authored Level Authoring Pipeline — Implementation Contract

**Project:** CUSTODIAN  
**Status:** active  
**Last Updated:** 2026-07-19

## Runtime Rules

- `AuthoredLevel2D` is the base for generated production scenes.
- Production scenes contain no Operator, `PlayerController`, gameplay camera, HUD, or global combat director.
- Playtest wrappers instance the canonical Operator and camera and bind `operator_path = NodePath("../Operator")`.
- `LevelLoader.enter_level()` succeeds only after actor placement succeeds.
- A nonempty requested spawn is mandatory and unresolved IDs abort entry.
- A registered `WorldIngressSite` never uses its legacy scene fallback unless `allow_legacy_registered_fallback` is explicitly enabled.
- `WorldIngressSpawner` places only definitions tagged `world_ingress`.
- Placement uses registry order by level ID and squared-distance spacing checks.

## Generated Layout

```text
custodian/game/world/levels/authored/<region>/<level_id>/
  <level_id>.gd
  <level_id>.tscn
  <level_id>_playtest.tscn
  <level_id>_authoring.tscn
  README.md

custodian/content/levels/<region>/<level_id>/
  <level_id>.json
  <level_id>.levelgen.json

custodian/tools/validation/levels/<level_id>_smoke.gd
design/05_levels/<LEVEL_ID>.md
```

## CLI

```bash
cd custodian
godot --headless --path . \
  --script res://tools/level_authoring/create_level.gd -- \
  --level-id ash_bell_lower_works \
  --display-name "Ash-Bell — Lower Works" \
  --region ash_bell \
  --spawn-id Spawn_Main \
  --return-spawn-id Return_Main \
  --playtest-profile movement \
  --canvas-size 2048x2048
```

Required: `--level-id`, `--display-name`, `--region`.

Safety: `--dry-run`, `--no-register`, `--force-generated`, `--adopt-existing`, `--output-root`, `--json-report`.

## Acceptance

1. Generated `.gd`, `.tscn`, and JSON resources parse/load.
2. Production scene has stable roots and no Operator.
3. Named entry spawn resolves.
4. Playtest and authoring scenes instantiate.
5. Registry is unchanged after any failed generation.
6. Existing unmanaged files are never overwritten.
7. Generated manifest lists every managed path.
8. Generic and Sundered compatibility smokes pass.

