# Authored Level Authoring Pipeline — Implementation Contract

**Project:** CUSTODIAN  
**Status:** complete-v1; lifecycle hardening implemented; route migration pending
**Last Updated:** 2026-07-20

## Runtime Rules

- `AuthoredLevel2D` is the base for generated production scenes.
- Production scenes contain no Operator, `PlayerController`, gameplay camera, HUD, or global combat director.
- Playtest wrappers instance the canonical Operator and camera and bind `operator_path = NodePath("../Operator")`.
- `LevelLoader.enter_level()` succeeds only after actor placement succeeds.
- A nonempty requested spawn is mandatory and unresolved IDs abort entry.
- A registered `WorldIngressSite` never uses its legacy scene fallback unless `allow_legacy_registered_fallback` is explicitly enabled.
- `WorldIngressSpawner` places only definitions tagged `world_ingress`.
- Placement uses registry order by level ID and squared-distance spacing checks.
- Definitions must declare `presentation_profile` and a `lifecycle` block.
- Registered ingress snapshots source branches, actor, camera, and UI before isolation.
- `LevelLoader` owns the active-instance record and clears it synchronously on world return.
- `AuthoredLevel2D.return_to_main()` completes return through the loader when runtime context is bound.
- World return restores `ProcGenRuntime` and `ConnectedMaps`, resets the originating ingress, and releases the outgoing level.
- The outgoing level is hidden and set to `PROCESS_MODE_DISABLED` before origin restoration begins; deferred freeing must never create a same-frame dual-authority window.
- Origin restoration preflights required branches, actor placement, camera binding, and runtime-map references, and returns a structured success/failure result.
- Failed restoration reactivates the outgoing level with its exact prior visibility/process state and leaves loader/ingress ownership intact.
- A loader-bound `AuthoredLevel2D` never falls through to local legacy restoration after a rejected return.

Allowed presentation profiles are `gameplay`, `vista_approach`, and `cinematic`. Generated levels default to `gameplay`; special presentation must be selected in registry data.

Initial lifecycle policy is:

```json
{
  "cache_policy": "keep_during_route",
  "state_policy": "session"
}
```

The current bridge has no route cache authority. Therefore `keep_during_route` still releases an instance when returning to world origin; it only prevents future route traversal from being forced into destroy-on-every-edge behavior.

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
9. Physics-driven ingress re-entry succeeds without private-method activation.
10. Return has exactly one active gameplay authority before the next process frame.
11. Rejected or impossible origin restoration does not partially restore the world or clear loader ownership.
12. Camera/runtime-map state restores exactly after a successful return.
