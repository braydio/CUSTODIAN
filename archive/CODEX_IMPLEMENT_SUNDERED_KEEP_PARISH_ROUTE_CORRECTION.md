# CODEX TASK — Sundered Keep Procgen → Shore Parish → Front Gate correction

Implement this task directly in the live CUSTODIAN repository. Do not stop at a plan or proposal. Follow repository `AGENTS.md`: update authoritative design documentation first, then runtime, validation, and AI-context documentation.

Repository root:

```text
/home/braydenchaffee/Projects/CUSTODIAN
```

Generated asset archive:

```text
/mnt/data/CUSTODIAN_parish_outer_wall_asset_pack.zip
```

If that exact path is unavailable, locate `CUSTODIAN_parish_outer_wall_asset_pack.zip` in the Codex attachment/workspace mounts. Do not substitute unrelated art. If the archive genuinely cannot be found, stop and report the missing file before changing runtime code.

## Desired production experience

Correct the current route into this sequence:

```text
LIVE PROCGEN CAMPAIGN WORLD
  → generated Sundered Keep frontage and one distant-Keep reveal
  → camera fully returns to Operator
  → short ordinary fade
  → authored Shore Parish / Outer Wall Approach
  → one close-detail camera reveal
  → longer eastbound checkpoint traverse
  → short ordinary fade
  → Sundered Keep Front Gate
```

The generated world stays live and traversable until the player crosses the existing terminal ingress into the authored Parish scene. Do not insert a playable black void, full-screen navigable fog corridor, or any second procgen camera pull.

## User-observed defects to correct

1. Procgen route cells visually render as ocean, so the Operator appears to walk on water.
2. Ordinary procgen trees, props, enemies, collision, and ambient objects occupy the cinematic frontage/reveal corridor.
3. Procgen Camera 2 pans too far toward a fixed subject and removes the Operator from the frame.
4. Camera/presentation authority can remain stuck after walking southward or leaving the expected pathway.
5. The production route uses a player-controlled black transition corridor.
6. Full-screen fog hides the Operator during the Vista → Front Gate handoff.
7. The authored Approach has two camera reveals; only one should retain camera authority.
8. The authored eastbound traverse is too short.
9. The northbound authored path lacks convincing ground shoulders.
10. The eastbound authored path lacks ground south of the path; ocean/horizon should remain north.
11. The duplicate whole-Keep Vista should become a closer Outer Wall / checkpoint detail composition.
12. Arrival in Front Gate can instantly trigger backtracking unless the player hugs one wall.
13. The Front Gate camera exposes a large blank/gray south-arrival area.
14. Reverse traversal and failed handoffs must always restore normal Operator-follow camera state.

## Do not do these things

- Do not route production through Return Causeway.
- Do not load a mapper scene as gameplay.
- Do not delete the generic blackout or occluded-handoff systems merely because this route stops using them.
- Do not use the old fixed authored route master as procgen floor authority.
- Do not let presentation sprites own procgen floor, collision, navigation, or encounter authority.
- Do not add a second procgen camera envelope.
- Do not leave Camera 2 enabled in the authored Parish scene.
- Do not make fog a full-screen navigable mask.
- Do not silently overwrite a different existing asset at one of the generated asset paths.
- Do not mark the task complete without renderer-backed review and route regression tests.

# Phase 0 — preflight and documentation authority

Read at minimum:

```text
AGENTS.md
design/05_levels/SUNDERED_KEEP_PROCGEN_FRONTAGE.md
design/05_levels/SUNDERED_KEEP_VISTA_APPROACH.md
design/05_levels/SUNDERED_KEEP_LARGE_FRONT_GATE.md
design/04_architecture/ROUTE_TRAVERSAL_SYSTEM.md
custodian/docs/ai_context/CURRENT_STATE.md
custodian/docs/ai_context/CONTEXT.md
custodian/docs/ai_context/FILE_INDEX.md
custodian/content/routes/sundered_keep/sundered_keep_route.json
custodian/content/levels/sundered_keep/sundered_keep_approach_outskirts.json
```

Treat this task as the current user decision. Existing documents that say the generated frontage is superseded, or that production should use `playable_blackout` / `occluded_handoff`, are documentation drift.

Before runtime edits:

1. Change `design/05_levels/SUNDERED_KEEP_PROCGEN_FRONTAGE.md` from “superseded” to production authority for the generated-world frontage and distant reveal.
2. Re-scope `design/05_levels/SUNDERED_KEEP_VISTA_APPROACH.md` as the production **Shore Parish / Outer Wall Approach**, entered by a short fade after the generated frontage.
3. State that the Parish scene has exactly one camera envelope.
4. State that its final handoff to Front Gate is an ordinary short fade.
5. State that the procgen frontage and authored Parish are separate production responsibilities:
   - procgen: generated approach, floor/collision/dressing, distant reveal;
   - Parish: authored terrain, close Keep detail, checkpoint traverse;
   - Front Gate: first full Keep map.
6. Create/update a focused task packet:

```text
custodian/docs/ai_context/task_packets/SUNDERED_KEEP_PARISH_ROUTE_CORRECTION.md
```

Status should remain `review` until renderer captures are human-acceptable.

# Phase 1 — ingest the generated assets

Extract the archive into a temporary directory, then copy only its `custodian/` subtree into the repository while preserving paths.

Suggested safe procedure:

```bash
set -euo pipefail

ASSET_ZIP=/mnt/data/CUSTODIAN_parish_outer_wall_asset_pack.zip
TMP_DIR="$(mktemp -d)"
unzip -q "$ASSET_ZIP" -d "$TMP_DIR"

while IFS= read -r -d '' src; do
  rel="${src#"$TMP_DIR/"}"
  dst="$PWD/$rel"
  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" ]] && ! cmp -s "$src" "$dst"; then
    echo "Refusing to overwrite non-identical existing asset: $rel" >&2
    exit 1
  fi
  cp "$src" "$dst"
done < <(find "$TMP_DIR/custodian" -type f -print0)
```

Required assets and contracts:

```text
custodian/content/sprites/world/return_causeway/path/overlays/
sundered_keep_shore_parish_northbound_ground_01.png
```

- 768×1024
- 1 frame
- transparent
- ground shoulders and parish ruin mass for the northbound route

```text
custodian/content/sprites/world/return_causeway/path/overlays/
sundered_keep_outer_wall_east_traverse_ground_01.png
```

- 1024×640
- 1 frame
- transparent
- eastbound walkable/visual extension
- ground primarily south of the path, ocean/horizon north

```text
custodian/content/backgrounds/sundered_keep/approach/near_detail/
sundered_keep_outer_wall_checkpoint_detail_01.png
```

- 2048×1024
- 1 frame
- transparent
- close Outer Wall/checkpoint architecture
- presentation only; no collision authority

```text
custodian/content/backgrounds/sundered_keep/approach/fog/
outer_wall_checkpoint_fog_ribbon_01.png
```

- 9216×384 sheet
- six 1536×384 frames
- transparent
- play at 6–8 fps
- local atmospheric fog only

```text
custodian/content/masters/sundered_keep/overlays/
sundered_keep_front_gate_south_arrival_apron_01.png
```

- 2048×1024
- 1 frame
- transparent
- visual coverage for the Front Gate south arrival

After copy:

- verify exact dimensions;
- verify alpha is not fully opaque;
- run Godot import;
- use linear filtering for these painterly large-format overlays/backgrounds unless an existing role-specific import policy clearly requires otherwise;
- do not bind the fog master sheet directly as one static texture—build a six-frame `SpriteFrames` animation.

# Phase 2 — correct the production route and transition lifecycle

Modify:

```text
custodian/content/routes/sundered_keep/sundered_keep_route.json
```

Production remains:

```text
@world_origin → vista_approach → front_gate
```

but change transition styles:

```diff
enter_vista:
- playable_blackout
+ fade

vista_to_keep_direct:
- occluded_handoff
+ fade

keep_to_vista_direct:
- occluded_handoff
+ fade
```

Keep Return Causeway debug-only.

Use the existing fade implementation. Do not invent another transition system. If fade timing is centrally configurable, target approximately 0.22 seconds out and 0.28 seconds in; otherwise retain the existing normal fade duration.

Guarantee on every successful, reversed, aborted, or failed transition:

- presentation framing is cleared;
- presentation bounds override is cleared;
- shared camera follows Operator;
- temporary source/destination visibility is restored consistently;
- no black CanvasLayer remains visible;
- route transition lock is released or rolled back correctly.

The Sundered Keep route must no longer instantiate `PlayableBlackoutBridge2D` or an occluded handoff.

Harden the generic playable-blackout implementation only where low-risk:

- add reverse/abort cleanup;
- add a bounded timeout;
- restore source-world visibility and camera state on failure.

Do not expand scope into redesigning every route transition.

# Phase 3 — repair the procgen frontage

Existing relevant code includes:

```text
custodian/game/world/procgen/landmarks/sundered_keep/
sundered_keep_frontage_builder.gd
sundered_keep_frontage_camera_director.gd
sundered_keep_frontage_validator.gd

custodian/game/world/vistas/sundered_keep/
sundered_keep_procgen_vista_presentation.gd
sundered_keep_procgen_vista_presentation.tscn
```

## 3A. Materialize visible ground

Find where `sundered_keep_frontage.floor_cells`, `primary_route_cells`, terraces, and side-pocket cells are merged into accepted procgen authority.

Ensure frontage walkable cells are consumed before final terrain/floor rendering and are not removed by later terrain, road, cliff, or cleanup passes.

For every primary route and hard-clearance cell:

- a visible floor tile or approved terrain visual must exist;
- it must not display the ocean/void presentation through the gameplay surface;
- it must be walkable;
- it must not receive an impassable cliff, wall, prop blocker, or authored-site collision.

Presentation ocean/storm sprites must remain below generated floor and below the Operator. Do not solve the water-walking defect by placing another opaque rectangle over the map.

Add a post-generation assertion/report for:

```text
frontage_required_floor_cell_missing_visual
frontage_required_floor_cell_blocked
frontage_required_floor_cell_ocean_exposed
```

## 3B. Protect the reveal corridor from ordinary dressing

Add a canonical procgen query such as:

```gdscript
func is_sundered_keep_frontage_protected(cell: Vector2i) -> bool:
    ...
```

The protected set must include at least:

```text
primary_route_cells
hard_clearance_cells
fortress_exclusion_cells
presentation_clearance_cells
```

Add `presentation_clearance_cells` to the frontage result if needed. Derive it from the first camera envelope and the immediate visible approach—not one giant rectangular claim.

All ordinary placement systems must consult the same query:

- foliage;
- random props;
- ambient anchors;
- ordinary enemy spawns;
- portal/site dressing;
- collision-owner prop blockers;
- streaming/reveal placement.

The side pocket may contain deliberately selected set dressing or an encounter. Do not sterilize the entire frontage.

## 3C. Keep only one procgen camera reveal

The procgen frontage camera must use only the first reveal envelope.

`frontage_weight` may continue to control restrained visual alpha if useful, but it must not own camera position, zoom, offset, follow target, or bounds.

In `sundered_keep_procgen_vista_presentation.gd`:

- remove the second/frontage camera pull;
- do not use `FRONTAGE_REVEAL_ZOOM` or `FRONTAGE_REVEAL_OFFSET` for camera ownership;
- preserve the distant-Keep first reveal;
- keep Operator visible in the bottom quarter at the apex.

Target framing:

```text
zoom ≈ 0.84
Operator screen-space Y: 68%–86% of viewport height
Operator remains horizontally inside the central 60% of the frame
```

Use an Operator-relative focal point and cap the blend; do not lerp 100% to a fixed gate anchor. A suitable starting implementation is:

```gdscript
var first_focus := _operator.global_position + Vector2(0.0, -220.0)
_presentation_anchor.global_position = _operator.global_position.lerp(
    first_focus,
    first_weight * 0.68
)
```

Tune through renderer review rather than treating those numbers as immutable.

When the Operator:

- walks south before the reveal;
- reverses after the apex;
- leaves the semantic route corridor;
- teleports;
- deactivates the map;
- starts a route transition;

the camera must immediately or smoothly return to normal Operator follow, with no persistent blacking or stale presentation bounds.

## 3D. Procgen visual cleanup

At supported camera zooms, every visible region must resolve to deliberate content:

- generated terrain;
- cliff/drop treatment;
- storm/ocean underlay;
- distant Keep;
- fog;
- foreground separator.

No clear color, gray fallback, raw TileMap boundary, or rectangular presentation edge may be visible.

Near-detail props in the procgen side pocket are optional but, if added, must be deterministic, grounded, and outside the primary route.

# Phase 4 — re-scope the authored scene as Shore Parish / Outer Wall Approach

Relevant files:

```text
custodian/game/world/approaches/sundered_keep/
sundered_keep_approach.gd
sundered_keep_approach.tscn
sundered_keep_vista_controller.gd
sundered_keep_reveal_director.gd

custodian/content/levels/sundered_keep/
sundered_keep_approach_outskirts.json

custodian/scenes/debug/
sundered_keep_approach_mapper.tscn
```

## 4A. Exactly one camera envelope

Retain Camera 1.

Disable Camera 2 as production camera authority. Do not merely hide debug labels or triggers. Ensure these become zero/disabled for production:

```text
_second_enter_progress
_second_return_progress
_second_enter_weight
_second_return_weight
_second_camera_weight
```

The second trigger may remain as a semantic/checkpoint event hook, but cannot change:

- follow target;
- camera anchor;
- zoom;
- offset;
- presentation bounds.

Camera 1 remains reversible and returns fully to ordinary gameplay framing before the eastbound traverse.

Update debug state and smoke expectations so `SECOND_DISABLED` is explicit, not mistaken for incomplete execution.

## 4B. Wire the northbound ground overlay

Add the generated northbound asset under a visual-only terrain/overlay root associated with `ShoreParish` / the northbound approach.

Requirements:

- it sits below Operator and above deep underlay;
- transparent pixels remain transparent;
- it provides ground shoulders on both sides of the northbound path;
- it does not obscure the current route master’s central walkable lane;
- it owns no collision;
- it is placed/fitted from authored data, not an unexplained magic transform buried in code.

Add an authored overlay record to `sundered_keep_approach_outskirts.json` or the project’s existing canonical approach layout document. Store:

- texture path;
- target rect;
- z role;
- filtering;
- semantic subregion.

Use the production mapper to tune the target rect.

## 4C. Lengthen and ground the eastbound traverse

Move the final Parish/checkpoint section east by approximately 300–365 world pixels.

Target the final exit near:

```text
x ≈ 1220–1280
```

rather than the current `x ≈ 915`, provided visual/collision review confirms coverage.

Update, through mapper-owned data:

```text
checkpoint_entry
beach_handoff
level_exit
eastbound subregion rects
camera bounds
collision rails
exit threshold
minimap geometry if applicable
```

Wire:

```text
sundered_keep_outer_wall_east_traverse_ground_01.png
```

so:

- the route extends east;
- ground/ruins occupy the south/camera-near side;
- ocean, cliffs, and horizon remain north/camera-far;
- the route does not appear to hover over void;
- the extension has correct boundary rails and cannot be walked off.

Use `sundered_keep_approach_mapper.tscn` to extend rails. Do not hand-edit a single collision segment in isolation if the mapper can own the update.

## 4D. Replace the duplicate whole-Keep Vista with close checkpoint detail

Wire:

```text
sundered_keep_outer_wall_checkpoint_detail_01.png
```

as a presentation-only close Outer Wall/checkpoint composition.

It should replace or substantially suppress the duplicate distant whole-Keep visual used in the former second reveal.

The scene should now read:

```text
Shore Parish ruins
→ close outer-wall foundations
→ ruined checkpoint/security works
→ gateward transition
```

Do not add another full-citadel skyline.

Use existing deterministic props sparingly near the checkpoint:

- 1–2 braziers;
- barricade/crates;
- chain/winch or checkpoint debris;
- no props on the primary walking lane.

Do not bake interactive collision into the new background sprite.

## 4E. Wire the local fog animation

Build a `SpriteFrames` resource from:

```text
outer_wall_checkpoint_fog_ribbon_01.png
```

Contract:

```text
6 frames
1536×384 each
6–8 fps
looping
```

Fog requirements:

- local world-space ribbon near the checkpoint;
- below Operator where possible;
- maximum alpha over the primary route approximately 0.30;
- never full-screen;
- never used as transition authority;
- Operator silhouette remains readable at all times.

Remove or disable the full-screen final occlusion treatment that requires the player to navigate unseen.

## 4F. Preserve/rebuild collision and minimap authority

The generated ground assets are visual overlays only.

Continue to use mapper-authored boundary rails for the authored Parish route.

After extension:

- collision must keep the Operator on the path;
- collision cannot block the path itself;
- reverse traversal remains possible;
- minimap route matches the extended east traverse;
- final exit is a readable threshold rather than an accidental overlap zone.

# Phase 5 — Front Gate arrival and visual coverage

Relevant files:

```text
custodian/game/world/sundered_keep/sundered_keep_map.tscn
custodian/game/world/sundered_keep/sundered_keep_map.gd
custodian/game/world/levels/level_exit_2d.gd
custodian/content/levels/sundered_keep/front_gate.json
custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.json
```

## 5A. Prevent immediate backtracking

In `sundered_keep_map.tscn`, set:

```gdscript
Exit_Backtrack.arrival_guard_radius = 144.0
```

Ensure `EntrySpawn` is at least 128 world pixels inside the playable level from the backtrack exit center. Derive actual runtime positions and adjust the authored spawn/exit—not merely the debug marker—if they overlap.

Arrival behavior:

1. Front Gate activates at `EntrySpawn`.
2. The backtrack exit is armed against the arriving Operator.
3. The player may move normally.
4. Backtracking becomes available only after leaving the guard radius and deliberately re-entering the exit.
5. The player must never immediately bounce back to Parish.

## 5B. Wire the south-arrival apron

Add:

```text
sundered_keep_front_gate_south_arrival_apron_01.png
```

under the Front Gate playable presentation so it covers the currently blank/gray lower camera area.

Requirements:

- align it around the real `entrance_tile` / `EntrySpawn`;
- place it above deep ocean/void underlay and below gameplay actors;
- preserve transparency;
- it owns no collision unless the existing mapped collision already supports the intended terrain;
- it must cover the default gameplay camera and transition fade framing at arrival;
- do not scale it so aggressively that its texture becomes visibly soft or inconsistent.

Before placement, inspect the current `sundered_keep_main_overlay.png` alpha/source bounds. If the gray area is caused by a fitting bug rather than missing art, fix the fitting bug first and use the apron only as the intended south extension.

# Phase 6 — validation and renderer review

Update existing tests whose assertions encode the obsolete route.

Add focused regression coverage.

## Required new/updated checks

### Procgen frontage

- required route cells always have visible floor;
- route/hard-clearance cells are not ocean-exposed;
- route/hard-clearance cells have no blockers;
- ordinary props/enemies/foliage reject protected frontage cells;
- side pocket remains available for deliberate content;
- only first camera weight can own camera framing;
- Operator is in lower-quarter target band at reveal apex;
- walking south/reversing releases camera authority;
- no presentation edge or clear color is exposed.

### Route transitions

- production `enter_vista` is `fade`;
- production Vista → Front Gate is `fade`;
- reverse Front Gate → Vista is `fade`;
- Sundered Keep production does not instantiate playable blackout;
- Sundered Keep production does not instantiate occluded handoff;
- failed/aborted transition restores Operator camera and visibility;
- no black layer remains after reverse traversal.

### Authored Parish

- Camera 2 framing is disabled;
- Camera 1 still works forward and backward;
- east traverse has increased by at least 300 world pixels;
- collision rails cover the extension;
- generated assets exist at exact dimensions and have alpha;
- fog sheet builds exactly six frames;
- fog route opacity does not exceed the readability limit;
- exit marker and checkpoint marker are ordered and reachable.

### Front Gate

- `arrival_guard_radius >= 144`;
- EntrySpawn and backtrack exit are separated appropriately;
- one second of simulation after arrival does not transition back;
- leaving and re-entering the guard radius does permit backtracking;
- south apron covers the arrival camera footprint;
- no large gray/clear region is visible at normal arrival framing.

## Existing validation to run

From `custodian/`:

```bash
env HOME=/tmp/custodian-godot-home godot --headless --path . --import

env HOME=/tmp/custodian-godot-home godot --headless --path . \
  --script res://tools/validation/sundered_keep_procgen_frontage_smoke.gd

env HOME=/tmp/custodian-godot-home godot --headless --path . \
  --script res://tools/validation/sundered_keep_world_vista_smoke.gd

env HOME=/tmp/custodian-godot-home godot --headless --path . \
  --script res://tools/validation/sundered_keep_ingress_smoke.gd

env HOME=/tmp/custodian-godot-home godot --headless --path . \
  --script res://tools/validation/sundered_keep_approach_smoke.gd

env HOME=/tmp/custodian-godot-home godot --headless --path . \
  --script res://tools/validation/sundered_keep_approach_outskirts_mapper_smoke.gd

env HOME=/tmp/custodian-godot-home godot --headless --path . \
  --script res://tools/validation/sundered_keep_route_graph_smoke.gd

env HOME=/tmp/custodian-godot-home godot --headless --path . \
  --script res://tools/validation/route_profile_selection_smoke.gd

env HOME=/tmp/custodian-godot-home godot --headless --path . \
  --script res://tools/validation/sundered_keep_large_layout_smoke.gd

bash tools/validation/run_procgen_validation_suite.sh
bash tools/validation/run_route_pipeline_suite.sh
```

Adjust commands only if a listed test has been renamed locally; document every substitution.

## Renderer-backed review

Generate review captures at 2560×1440:

```text
reports/sundered_keep_route_correction/
```

Required captures:

```text
procgen_normal_gameplay.png
procgen_first_reveal_apex.png
procgen_reverse_south_camera_released.png
parish_northbound_ground.png
parish_camera1_apex.png
parish_east_traverse_start.png
parish_checkpoint_detail.png
parish_final_exit.png
front_gate_arrival.png
front_gate_after_guard_release.png
```

Acceptance from captures:

- Operator remains visible and readable;
- no walking on water;
- no random props/actors in reveal corridor;
- no black navigable corridor;
- no full-screen fog navigation;
- northbound ground exists on both sides;
- eastbound route has south-side terrain and north-side ocean;
- checkpoint composition is close-detail, not a duplicate whole Keep;
- Front Gate lower frame is intentionally dressed;
- transitions and reverse travel always restore normal camera.

# Phase 7 — documentation and completion report

Update:

```text
design/05_levels/SUNDERED_KEEP_PROCGEN_FRONTAGE.md
design/05_levels/SUNDERED_KEEP_VISTA_APPROACH.md
design/05_levels/SUNDERED_KEEP_LARGE_FRONT_GATE.md
design/04_architecture/ROUTE_TRAVERSAL_SYSTEM.md
custodian/docs/ai_context/CURRENT_STATE.md
custodian/docs/ai_context/CONTEXT.md
custodian/docs/ai_context/FILE_INDEX.md
REQUIRED_ASSETS.md
```

Mark the five generated assets as integrated, with exact runtime paths, dimensions, and frame counts.

Document remaining visual-tuning issues honestly. Do not claim production acceptance merely because headless tests pass.

Final response must include:

1. concise summary of behavior changed;
2. complete changed-file list grouped by docs/runtime/content/tests;
3. exact asset paths and placement roles;
4. validation commands and pass/fail results;
5. renderer capture paths;
6. unresolved defects or human-review items;
7. explicit documentation-drift corrections made.

Do not push or open a PR unless separately instructed. Make the working-tree implementation complete and reviewable.
