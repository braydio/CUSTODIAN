# Sundered Keep Route / Stage System

- **Status:** base infrastructure implemented and smoke-validated — all 4 stages register and instantiate, causeway approach carries forward full collision/VistaController/exit-trigger logic from the old approach, grand vista handles missing textures gracefully
- **Owner:** world / connected maps
- **Runtime:** `custodian/` Godot 4.x
- **Route controller:** `custodian/game/world/routes/sundered_keep/sundered_keep_approach_route.gd`
- **Stage scenes:** `custodian/game/world/routes/sundered_keep/stages/*.tscn`
- **Base classes:** `custodian/game/world/routes/level_stage.gd`, `custodian/game/world/routes/level_route.gd`
- **Validation:** `custodian/tools/validation/sundered_keep_approach_route_smoke.gd`
- **Not yet connected:** the old `sundered_keep_approach.tscn` remains the active `WorldIngressSite` target; the new route system is not yet wired into `ContractWorldLoader` or `WorldIngressSite`

## Summary

A lightweight Route/Stage level-organization layer that wraps a linear sequence of authored scenes (stages) behind a single route controller. The world map only knows the route controller, never the substages. Each stage is a standalone scene under `routes/<route_name>/stages/`.

This is **not connected** to the live ingress chain yet — it is purely an organizational layer that can be integrated later.

## Architecture

### Base Classes

```
LevelStage (Node2D)
  └─ stage_id: StringName
  └─ next_stage_id: StringName
  └─ stage_complete(next_stage_id) signal
  └─ configure_stage(route, actor, config)
  └─ get_entry_spawn() -> Marker2D
  └─ get_camera_bounds() -> Rect2
  └─ complete_stage(target_stage_id) — emits stage_complete

LevelRoute (Node2D)
  └─ initial_stage_id: StringName
  └─ final_target_scene: PackedScene
  └─ register_stage(id, scene)
  └─ _load_stage(id) — instantiates, wires stage_complete
  └─ _on_stage_complete(next_id) — loads next stage or final target
  └─ _enter_front_gate() — instantiates final_target_scene, calls configure_connection/enter_from_main
```

### Stage Contract

Each stage must:
- Have a unique `stage_id` (StringName)
- Have a `next_stage_id` (what to advance to after completion)
- Provide an `EntrySpawn` Marker2D child for player placement
- Emit `stage_complete(next_stage_id)` when the player exits
- Not own transitions or scene loading — the route controller handles that

### Route Contract

The route controller:
- Registers all stages in `_ready()` via `register_stage()`
- Loads the initial stage on `enter_from_main(actor)`
- Wires each stage's `stage_complete` signal to `_on_stage_complete()`
- Advances to the next stage, or (for `front_gate`) instantiates `final_target_scene`
- Calls `configure_connection(main_map, return_position)` and `enter_from_main(actor)` on the final target

## Sundered Keep Route

### Stage Sequence

```
vista_one (4s auto-advance)
    │
    ▼
pre_level (player walks to exit trigger)
    │
    ▼
grand_vista (5s or interact-to-skip)
    │
    ▼
causeway_approach (full gameplay, exit at traverse_end)
    │
    ▼
front_gate (sundered_keep_map.tscn)
```

### Stage Details

#### Vista One (`sundered_keep_vista_one`)
- Auto-advances after 4 seconds
- Renders horizon sky, far sea, distant keep, vista fog band
- Presentation only — no collision, no interactables
- Textures loaded from `content/backgrounds/sundered_keep/`

#### Pre-Level (`sundered_keep_pre_level`)
- Gameplay stub with EntrySpawn and ExitToGrandVistaTrigger
- Exit trigger fires when the actor enters it, calling `complete_stage()`
- Backdrop renders ocean underlay and cliff depth underlay
- `next_stage_id`: `grand_vista`

#### Grand Vista (`sundered_keep_grand_vista`)
- Auto-advances after 5 seconds, or interact-to-skip
- Renders panorama, fog overlay, foreground parapet, shadow vignette, ocean spray overlay
- Expects textures in `content/backgrounds/sundered_keep/grand_vista/`
- Handles missing textures gracefully via `push_warning` + null return
- `next_stage_id`: `causeway_approach`

#### Causeway Approach (`sundered_keep_causeway_approach`)
- Extends `LevelStage` with `stage_id = &"causeway_approach"` and `next_stage_id = &"front_gate"`
- Carries forward full underlay/path/occlusion/collision logic from old `SunderedKeepApproach`
- Retains `SunderedKeepVistaController` for progress-based visual tracking
- Replaces old `SunderedKeepTransitionTrigger` with `ExitToFrontGate` Area2D at `TRAVERSE_END_POS`
- Exit trigger calls `vista_controller.play_final_fade()` then `complete_stage()`
- Retains all 13 `SegmentShape2D` boundary rails on layer/mask 1
- Retains 6 markers: EntrySpawn, RevealStart, RevealFull, TraverseStart, TraverseEnd, ReturnTopdown
- Distant vista sprites (HorizonSky, FarSea, DistantSunderedKeep, VistaFogBand) removed — those live in `vista_one` stage
- `VistaController.vista_root_path` redirected to `../UnderlayRoot` since the dedicated VistaRoot no longer exists

## Implementation Notes

- The route system is not yet connected to the live procgen ingress chain (`WorldIngressSite` / `ContractWorldLoader`). Integration should replace direct approach-scene loading with route-scene loading in `WorldIngressSite._enter_approach()`.
- `SunderedKeepMap` is script-only (`.gd`). The route's `final_target_scene` expects a `PackedScene`, so `sundered_keep_map.tscn` wrapper was created.
- Stage scenes should remain thin — all substantive logic lives in the `.gd` script, the `.tscn` is a minimal stub (script + EntrySpawn + CameraBounds).
- `VistaController` reference paths now point to `../UnderlayRoot` instead of `../VistaRoot` since the distant vista sprites moved out of the causeway approach.

## Next Agent Slice

### Goal
Connect the route system to the live procgen ingress chain, replacing the direct approach-scene load in `WorldIngressSite` with route-scene load.

### Files
- `custodian/game/world/procgen/ingress/world_ingress_site.gd` — replace `approach_scene.instantiate()` with the route scene
- `custodian/game/systems/core/systems/contract_world_loader.gd` — replace `SUNDERED_KEEP_APPROACH_SCENE` with `SUNDERED_KEEP_ROUTE_SCENE`, pass route controller the `main_map` and `return_position` directly
- `custodian/game/world/routes/level_route.gd` — ensure `configure_connection()` is called before `enter_from_main()` in the ingress flow
- `custodian/tools/validation/sundered_keep_approach_route_smoke.gd` — extend to validate the full route→final_scene handoff

### Constraints
- Existing `WorldIngressSite.configure(ingress_id, approach_scene, target_scene_path, target_spawn_id)` API must remain backward-compatible for any other map routes.
- The route controller replaces both `approach_scene` and `target_scene_path` — either the route must accept them dynamically, or `WorldIngressSite` must be updated to pass the route scene and skip the target path.
- `SunderedKeepTransitionTrigger` in the old approach directly loads `SunderedKeepMap`. The route controller must handle the same fade and map instantiation.
- Deterministic fixed-step simulation is a hard constraint — route advancement must not introduce frame-dependent behavior.

### Acceptance
- Route smoke test passes.
- `WorldIngressSite` can be configured with a route scene instead of an approach scene.
- Route controller receives `main_map` and `return_position` from the ingress flow.
- Final target map (`SunderedKeepMap`) receives working `configure_connection()` and `enter_from_main()` calls with correct return position.
