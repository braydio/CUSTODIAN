# Sundered Keep Route / Stage System

- **Status:** experimental and smoke-validated, but not the configured production ingress — all 4 stages register and instantiate, causeway approach carries forward collision/VistaController/exit-trigger logic from the old approach, and the current hotfix keeps base underlay/backdrop/camera framing stable while production uses the continuous one-scene approach
- **Owner:** world / connected maps
- **Runtime:** `custodian/` Godot 4.x
- **Route controller:** `custodian/game/world/routes/sundered_keep/sundered_keep_approach_route.gd`
- **Stage scenes:** `custodian/game/world/routes/sundered_keep/stages/*.tscn`
- **Base classes:** `custodian/game/world/routes/level_stage.gd`, `custodian/game/world/routes/level_route.gd`
- **Validation:** `custodian/tools/validation/sundered_keep_approach_route_smoke.gd`, `custodian/tools/validation/sundered_keep_approach_route_visual_smoke.gd`
- **Active configured ingress:** `custodian/content/levels/sundered_keep/front_gate.json` points `sundered_keep_front_gate` at `res://game/world/approaches/sundered_keep/sundered_keep_approach.tscn`

## Summary

A lightweight Route/Stage level-organization layer that wraps a linear sequence of authored scenes (stages) behind a single route controller. The world map and level registry know the route controller, not the substages. Each stage is a standalone scene under `routes/<route_name>/stages/`.

This route is not the configured production ingress. It remains a smoke-covered prototype of the Route/Stage organization layer. The implementation is still **stage-cut based**: `LevelRoute` queue-frees one stage and instantiates the next. Production uses the continuous authored approach scene, keeping only the final Sundered Keep map load as a true scene handoff.

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
- `VistaController.vista_root_path` is intentionally empty so it cannot fade `UnderlayRoot`; fog/occlusion nodes remain individually bound
- `UnderlayRoot.modulate.a` stays `1.0`; only fog/occlusion/veil layers should fade
- Stage scripts override `get_camera_bounds()` with explicit `Rect2` values because the legacy `.tscn` `CameraBounds` nodes are `Node2D`, not `ReferenceRect`
- All route stages create a bottommost `BackdropVoidFill` so missing transparent coverage renders as dark void instead of gray background

## Implementation Notes

- The route is not connected through the level registry wrapper. `front_gate.json` points at the continuous approach scene because this route hard-swaps presentation stages.
- `SunderedKeepMap` is script-only (`.gd`). The route's `final_target_scene` expects a `PackedScene`, so `sundered_keep_map.tscn` wrapper was created.
- Stage scenes should remain thin — all substantive logic lives in the `.gd` script, the `.tscn` is a minimal stub (script + EntrySpawn + CameraBounds).
- The current route-stage flow remains visually discontinuous by design because substages are separate scenes. Do not add more hard-swapped vista stages for the production entrance; prefer merging vista_one/pre_level/grand_vista/causeway_approach into one continuous approach scene.

## Next Agent Slice

### Goal
Either retire this stage-cut route or convert it into a continuous authored approach scene with route beats before reconnecting it to production ingress.

### Files
- `custodian/game/world/routes/sundered_keep/sundered_keep_approach_route.gd`
- `custodian/game/world/routes/sundered_keep/stages/*.gd`
- `custodian/game/world/approaches/sundered_keep/sundered_keep_approach.gd` — reference model for one-scene layered traversal
- `custodian/tools/validation/sundered_keep_approach_route_smoke.gd`
- `custodian/tools/validation/sundered_keep_approach_route_visual_smoke.gd`

### Constraints
- Preserve `LevelDefinition` / `LevelLoader` entry and final `SunderedKeepMap` handoff.
- Keep base underlay/backdrop always visible; never bind `VistaController.vista_root_path` to `UnderlayRoot`.
- Keep collision rails and exit trigger deterministic and separate from presentation layers.
- Deterministic fixed-step simulation is a hard constraint — route advancement must not introduce frame-dependent behavior.

### Acceptance
- Route smoke test passes.
- Route visual smoke test passes.
- The player experiences one continuous walk/vista/traverse before the final front-gate map transition.
- No route beat queue-frees and replaces the visible approach during ordinary traversal.
- Final target map (`SunderedKeepMap`) still receives working `configure_connection()` and `enter_from_main()` calls with correct return position.
