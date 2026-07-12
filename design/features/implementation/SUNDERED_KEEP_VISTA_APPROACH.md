# Sundered Keep Vista Approach Implementation

- **Status:** route-master runtime composition implemented
- **Runtime scene:** `custodian/game/world/approaches/sundered_keep/sundered_keep_approach.tscn`
- **Runtime script:** `custodian/game/world/approaches/sundered_keep/sundered_keep_approach.gd`
- **Controller:** `custodian/game/world/approaches/sundered_keep/sundered_keep_vista_controller.gd`
- **Primary design authority:** `design/05_levels/SUNDERED_KEEP_VISTA_APPROACH.md`
- **Task packet:** `custodian/docs/ai_context/task_packets/SUNDERED_KEEP_ROUTE_MASTER_APPROACH.md`

## Current Contract

The production approach is one authored Godot scene. It does not use a TileSet and does not split assets into one scene per image.

`PlayableRoot` renders one active terrain sprite:

```text
res://content/sprites/world/return_causeway/path/sundered_keep_approach_route_master.png
```

The previous five path chunks are retained only behind the disabled `USE_ROUTE_MASTER == false` legacy branch.

Support assets are layered under:

```text
res://content/backgrounds/sundered_keep/approach/
res://content/backgrounds/sundered_keep/approach/fog/
```

`VistaRoot` fades from `RevealStart` to `RevealFull`. `GrandVistaRoot` stays hidden during the first reveal and traversal gap, then uses the later `SecondVistaStart` / `SecondVistaFull` / `SecondVistaEnd` window. `ApproachFinalGateShadowVeil` starts hidden and fades in from `SecondVistaEnd` toward `ReturnTopdown`.

Collision remains separate from art: `Collision/PathBoundaryCollision` is a `StaticBody2D` made from mapper-authored thick `CapsuleShape2D` rails. Image alpha is not collision authority.

## Validation

```bash
cd custodian
godot --headless --path . --import
python3 tools/validation/sundered_keep_approach_asset_audit.py
godot --headless --path . --script res://tools/validation/sundered_keep_approach_smoke.gd
```
