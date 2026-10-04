# KENNEY ISOMETRIC BLOCKOUT PLAYTEST

- Packet schema: `custodian.task_packet.v2`
- Workstream: `kenney-isometric-blockout-playtest`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `review-kenney-isometric-blockout-feasibility`
- Locks: `presentation-experiments, asset-pipeline`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `144ad871cb17a9abdd566abd4ee49f59509d481a`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Goal: Add the missing playable human-validation layer for reviewed K3D-1 so the user can walk the same A/B spatial sample with the real Operator, real gameplay controller stack, and real gameplay Camera2D while switching instantly between native and Kenney presentation.
- Completion boundary: Preserve the reviewed deterministic K3D-1 capture/metrics rig, extract only its reusable presentation construction, add one Lords-of-Pain-style authored dev level plus standalone playtest wrapper, add a live 1/2/Tab A/B switch that never changes Operator position/camera/collision, keep Kenney geometry presentation-only, and leave the scene ready as the final Kenney walkaround precursor before the active 2.5D realization work.
- Current measured state: K3D-1 is complete and independently reviewed with 0 blocking defects. `kenney_isometric_blockout_feasibility.tscn` renders the sample inside a fixed 1280x720 SubViewport and intentionally owns no Operator/controller/collision. That makes it a valid deterministic comparison rig but a poor human-feel artifact. `lords_of_pain_test_gallery_playtest.tscn` already establishes the desired standalone wrapper pattern with `GameRoot/World/Operator`, `PlayerController`, gameplay `Camera2D`, `LevelPlaytestBootstrap`, and the normal lightweight gameplay support systems. The 16 selected Kenney runtime PNGs are already imported through Asset Pipeline V2. No local ZIP/source filenames are needed.
- Evidence: `custodian/scenes/debug/kenney_isometric_blockout_feasibility.{gd,tscn}`; archived K3D-1 implementation/review receipts; `custodian/game/world/levels/authored/dev/lords_of_pain_test_gallery/lords_of_pain_test_gallery_playtest.tscn`; `custodian/game/world/levels/level_playtest_bootstrap.gd`; `custodian/game/world/levels/authored_level_2d.gd`; `custodian/game/world/camera.gd`; both live Kenney Asset V2 family contracts.
- Task-specific authority: the reviewed K3D-1 scene/script own the frozen A/B visual arrangement; Lords of Pain owns the standalone authored-level playtest precedent; `AuthoredLevel2D`, `LevelPlaytestBootstrap`, Operator, PlayerController, and Camera2D retain their existing runtime authority.
- Work surface: exact files below. Do not modify Operator, PlayerController, Camera2D, Road of Witnesses, Hub runtime, Awakening, procgen, campaign/transition, save, or production boot behavior.
- Change: factor K3D-1 visual construction into one shared experimental presentation builder without changing its output; add one authored dev level using that builder; add one standalone `GameRoot` wrapper with the real Operator/controller/camera stack; add a minimal A/B input/UI controller; update Asset V2 consumer metadata and focused validation ownership; update the K3D tracker/index.
- Preserve: all K3D-1 anchors, sample extents, selected runtime assets, asset pixels, scales/positions/z-order, fixed capture camera, metrics/capture contract, original debug scene path, original focused smoke API, production main scene, and all production gameplay/spatial authorities.
- Non-goals: no new art; no new Asset V2 family/state; no ZIP/source-work/inbox work; no re-ingest; no K3D-2/3D work; no H1 geometry refresh; no Kenney layout redesign; no production Hub integration; no Kenney-derived collision/navigation; no combat encounter population; no generic playtest framework; no broad regression campaign.
- Acceptance: the standalone playtest boots with the real Operator and gameplay camera at Forum South; normal Operator movement works; 1 selects native, 2 selects Kenney, Tab toggles; switching does not move/reset the Operator or change neutral collision/camera authority; both modes use the same shared presentation builder and 16 existing Kenney assets; the old K3D-1 capture rig still passes its focused smoke with the same external contract; only the authored dev level owns neutral envelope collision; production boot remains untouched.
- Validation: keep this lean. Run the new focused playtest smoke, rerun the existing K3D-1 focused smoke, boot the standalone scene for manual movement/toggle and route sanity, then `git diff --check`. Do not run broad `--changed` or full Godot suites unless a focused failure or live repository policy requires it.
- Task overrides: `none`
- Deferred: realized 2.5D foundation/vertical-slice work follows this precursor. The prior live-3D K3D-2/K3D-3 direction is canceled.

## Workstream identity

```text
workstream: kenney-isometric-blockout-playtest
branch: agent/kenney-isometric-blockout-playtest
closing summary: KENNEY_ISOMETRIC_BLOCKOUT_PLAYTEST_CLAUDE_SUMMARY.md
```

This is K3D-1P, a validation-support extension. It is not a fourth major feasibility slice and must not be renamed K3D-2.

## Exact files

| Action | Path |
| --- | --- |
| create | `custodian/scenes/debug/kenney_isometric_blockout_presentation.gd` |
| modify | `custodian/scenes/debug/kenney_isometric_blockout_feasibility.gd` |
| preserve | `custodian/scenes/debug/kenney_isometric_blockout_feasibility.tscn` |
| create | `custodian/game/world/levels/authored/dev/kenney_isometric_blockout_playtest/kenney_isometric_blockout_playtest_level.gd` |
| create | `custodian/game/world/levels/authored/dev/kenney_isometric_blockout_playtest/kenney_isometric_blockout_playtest_level.tscn` |
| create | `custodian/game/world/levels/authored/dev/kenney_isometric_blockout_playtest/kenney_isometric_blockout_playtest.tscn` |
| create | `custodian/game/world/levels/authored/dev/kenney_isometric_blockout_playtest/README.md` |
| create | `custodian/tools/validation/levels/kenney_isometric_blockout_playtest_smoke.gd` |
| modify | `custodian/tools/validation/validation_manifest.json` |
| modify | `custodian/content/metadata/assets/families/kenney_iso_miniature_prototype_ref.asset.json` |
| modify | `custodian/content/metadata/assets/families/kenney_iso_miniature_bases_ref.asset.json` |
| modify | `design/01_systems/KENNEY_PRESENTATION_FEASIBILITY_ROADMAP.md` |
| modify | `custodian/docs/ai_context/task_packets/README.md` |

Do not modify the committed K3D-1 report, metrics JSON, inventory JSON, or the three K3D-1 capture PNGs. They are frozen evidence from the reviewed experiment.

## Existing asset truth

No Kenney input is missing for this work.

Existing Asset V2 families:

```text
kenney_iso_miniature_prototype_ref
kenney_iso_miniature_bases_ref
```

Runtime domain:

```text
res://content/tiles/experiments/kenney_feasibility/
```

All selected states are static one-frame omni PNGs at 256x512 source/runtime dimensions.

Prototype states (10):

```text
floor_s
slab_s
block_s
wall_s
wall_corner_s
stairs_s
slope_s
doorway_s
column_s
pole_s
```

Bases states (6):

```text
base_grass_flat_s
base_stone_flat_s
base_stone_high_s
square_stone_flat_s
base_dirt_detail_s
square_dirt_high_s
```

The current loader already resolves them using:

```text
kenney_iso_miniature_prototype_ref_<state>_256.png
kenney_iso_miniature_bases_ref_<state>_256.png
```

Do not ask for local archive filenames. Do not touch `asset_drop/source_work`, `asset_drop/inbox`, or ingest jobs.

## 1. Extract one shared presentation builder

Create `custodian/scenes/debug/kenney_isometric_blockout_presentation.gd`.

This helper exists only to make the already-reviewed visual construction callable from both the deterministic capture rig and the playable authored dev level. It must not own input, camera, collision, navigation, Operator/controller, capture, metrics, or scene lifecycle.

Use the current K3D-1 script as source of truth. Move/refactor, without redesigning:

- `ROAD_SCRIPT`
- `CELL_SIZE`
- `ANCHORS`
- `SAMPLE_REGIONS`
- `KENNEY_DOMAIN`
- `PROTOTYPE_STATES`
- `BASE_STATES`
- Kenney texture loading/validation
- shared backdrop/route/anchor construction
- native presentation construction
- Kenney presentation construction
- the sprite/polygon/line/label helpers used by those builders

Expose a narrow API equivalent to:

```gdscript
class_name KenneyIsometricBlockoutPresentation
extends RefCounted

const ROAD_SCRIPT := preload("res://game/world/hub/road_of_witnesses_prototype.gd")
const CELL_SIZE := 32
const EVALUATION_BOUNDS := Rect2(-2600, -4300, 5200, 4650)

const ANCHORS := {
	&"spawn_south_reach": Vector2(-6, 162),
	&"forum_south": Vector2(0, -2464),
	&"adjudication_dais": Vector2(0, -3136),
}

const SAMPLE_REGIONS := {
	&"north_processional": Rect2(-512, -2400, 1024, 1152),
	&"ashen_forum": Rect2(-1280, -4032, 2560, 1792),
}

const KENNEY_DOMAIN := "res://content/tiles/experiments/kenney_feasibility"

const PROTOTYPE_STATES := [
	"floor_s", "slab_s", "block_s", "wall_s", "wall_corner_s",
	"stairs_s", "slope_s", "doorway_s", "column_s", "pole_s",
]

const BASE_STATES := [
	"base_grass_flat_s", "base_stone_flat_s", "base_stone_high_s",
	"square_stone_flat_s", "base_dirt_detail_s", "square_dirt_high_s",
]

static func load_kenney_textures() -> Dictionary:
	# current loader logic

static func selected_textures_valid(textures: Dictionary) -> bool:
	# all 16 Texture2D values; each Vector2(256, 512)

static func build(
	shared_sample: Node2D,
	anchor_markers: Node2D,
	native_root: Node2D,
	kenney_root: Node2D,
	textures: Dictionary
) -> void:
	# exact current K3D-1 visual construction
```

Local private helper names may differ if live code has a cleaner shape. The behavioral contract may not.

### Freeze requirement

Do not improve the layout during extraction. Preserve exactly:

- Road module data source `RoadOfWitnessesPrototype.MODULES`;
- native Processional/Forum rectangles, ceremonial axis and Dais;
- the Kenney 10x9 floor sequence;
- every Kenney base/prop position;
- every Kenney scale;
- every z-index;
- route extent and anchor labels;
- evaluation backdrop geometry/color.

This packet makes artifact B walkable. It does not re-author artifact B.

## 2. Preserve the reviewed K3D-1 rig

Modify `custodian/scenes/debug/kenney_isometric_blockout_feasibility.gd` only enough to delegate presentation construction.

Keep these existing external constants/methods available because the current focused smoke consumes them:

```text
CELL_SIZE
VIEW_SIZE
ANCHORS
SAMPLE_REGIONS
CAPTURE_POS
CAPTURE_ZOOM
SETTLE_FRAMES
SAMPLE_FRAMES
set_presentation_mode()
parity_snapshot()
selected_runtime_asset_count()
selected_textures_valid()
```

Recommended compatibility spine:

```gdscript
const PRESENTATION := preload(
	"res://scenes/debug/kenney_isometric_blockout_presentation.gd"
)

const CELL_SIZE := PRESENTATION.CELL_SIZE
const ANCHORS := PRESENTATION.ANCHORS
const SAMPLE_REGIONS := PRESENTATION.SAMPLE_REGIONS
const PROTOTYPE_STATES := PRESENTATION.PROTOTYPE_STATES
const BASE_STATES := PRESENTATION.BASE_STATES
```

In `_ready()`:

```gdscript
_kenney_textures = PRESENTATION.load_kenney_textures()
PRESENTATION.build(
	shared_sample,
	anchor_markers,
	native_root,
	kenney_root,
	_kenney_textures
)
```

Then retain all existing capture/metrics/mode behavior.

Do not modify `kenney_isometric_blockout_feasibility.tscn`. Do not change its SubViewport, capture camera, capture paths, metrics schema, sample counts, or committed evidence.

## 3. Add the authored walkaround level

Create `custodian/game/world/levels/authored/dev/kenney_isometric_blockout_playtest/kenney_isometric_blockout_playtest_level.gd`.

Extend `AuthoredLevel2D` exactly as the Lords of Pain gallery does.

The level owns the shared A/B visuals, neutral evaluation-envelope collision, spawn/POI markers, A/B switching, and a small developer readout. It does not own Operator/controller/camera/combat systems.

Use:

```gdscript
extends AuthoredLevel2D
class_name KenneyIsometricBlockoutPlaytestLevel

const PRESENTATION := preload(
	"res://scenes/debug/kenney_isometric_blockout_presentation.gd"
)

enum PresentationMode { NATIVE, KENNEY }

const EVALUATION_BOUNDS := PRESENTATION.EVALUATION_BOUNDS

const BOUNDARY_SEGMENTS := [
	[Vector2(-2600, -4300), Vector2(2600, -4300)],
	[Vector2(2600, -4300), Vector2(2600, 350)],
	[Vector2(2600, 350), Vector2(-2600, 350)],
	[Vector2(-2600, 350), Vector2(-2600, -4300)],
]

const AUTHORING_MARKERS := {
	"spawn": {
		"node_name": "Spawn_Main",
		"label": "FORUM SOUTH PLAYTEST",
		"kind": "spawn",
		"position": Vector2(0, -2464),
	},
	"south_reach": {
		"node_name": "Spawn_SouthReach",
		"label": "SOUTH REACH",
		"kind": "poi",
		"position": Vector2(-6, 162),
	},
	"adjudication_dais": {
		"node_name": "AdjudicationDais",
		"label": "ADJUDICATION DAIS",
		"kind": "poi",
		"position": Vector2(0, -3136),
	},
}
```

Return `BOUNDARY_SEGMENTS` and `AUTHORING_MARKERS` through the normal AuthoredLevel2D overrides.

The four boundary segments are deliberately the only new collision. Do not add collision to Kenney walls, columns, bases, stairs, slopes, doorways, or native presentation geometry. A and B must have identical movement freedom.

`Spawn_Main` is intentionally Forum South. The current Kenney arrangement is concentrated around Processional/Forum, so the user should begin inside the useful comparison area. Keep `Spawn_SouthReach` as a real POI/anchor.

On ready:

```gdscript
func _ready() -> void:
	super._ready()
	_kenney_textures = PRESENTATION.load_kenney_textures()
	PRESENTATION.build(
		%SharedSpatialSample,
		%AnchorMarkers,
		%NativePresentation,
		%KenneyPresentation,
		_kenney_textures
	)
	set_presentation_mode(PresentationMode.KENNEY)
```

### A/B controls

Implement exactly:

```text
1   -> native
2   -> Kenney
Tab -> toggle
```

Do not add project input actions. Use dev-only `_unhandled_input()` + `InputEventKey` and ignore echoes.

Mode switching must only toggle presentation visibility and refresh the UI label. It must not write Operator position/velocity, camera position/zoom/follow target, collision, spawn, bootstrap, bounds, or controller state.

Use a persistent screen-space label similar to:

```text
K3D-1P · KENNEY · 1 NATIVE · 2 KENNEY · TAB TOGGLE · COLLISION: ENVELOPE ONLY
```

## 4. Authored level scene

Create `kenney_isometric_blockout_playtest_level.tscn` with:

```text
KenneyIsometricBlockoutPlaytestLevel
├── SharedSpatialSample
│   └── AnchorMarkers
├── NativePresentation
├── KenneyPresentation
├── Collision
│   └── PathBoundaryCollision
├── Markers
│   ├── Spawn_Main
│   ├── Spawn_SouthReach
│   └── AdjudicationDais
├── NavigationRoot
└── PlaytestUI
    └── ModeLabel
```

`PlaytestUI` is a `CanvasLayer`.

Set:

```text
camera_bounds = Rect2(-2600, -4300, 5200, 4650)
draw_placeholder_grid = false
placeholder_canvas_size = Vector2(5200, 4650)
```

`Collision/PathBoundaryCollision` must exist as `StaticBody2D` so `AuthoredLevel2D` can populate the boundary rails.

Do not create an AuthoredNavigationProvider just to satisfy structure. `NavigationRoot` may remain empty; this dev scene has no AI navigation requirement.

## 5. Standalone real-Operator wrapper

Create `custodian/game/world/levels/authored/dev/kenney_isometric_blockout_playtest/kenney_isometric_blockout_playtest.tscn`.

Use `lords_of_pain_test_gallery_playtest.tscn` as the direct precedent.

Required resources:

```text
res://game/world/levels/authored/dev/kenney_isometric_blockout_playtest/kenney_isometric_blockout_playtest_level.tscn
res://game/actors/operator/operator.tscn
res://game/systems/core/player_controller.gd
res://game/world/camera.gd
res://game/world/levels/level_playtest_bootstrap.gd
res://game/systems/core/systems/combat.gd
res://game/systems/core/systems/navigation_system.gd
res://game/systems/core/systems/enemy_director.gd
res://game/systems/core/systems/wave_manager.gd
res://game/ui/hud/custodian_hud.tscn
```

Required tree:

```text
GameRoot
├── Combat
├── NavigationSystem
├── EnemyDirector
├── WaveManager
├── CustodianHUD
└── World
    ├── Level
    ├── Projectiles
    ├── Enemies
    ├── Allies
    ├── Items
    ├── ConnectedMaps
    ├── Operator
    ├── PlayerController
    ├── Camera2D
    └── LevelPlaytestBootstrap
```

Copy the Lords of Pain support-system configuration unless the live precedent changed.

Bindings:

```text
PlayerController.operator_path = "../Operator"
LevelPlaytestBootstrap.profile = "full"
LevelPlaytestBootstrap.spawn_id = &"Spawn_Main"
WaveManager.debug_spawn_grunt_on_start = false
```

The `GameRoot/World/Operator` hierarchy is required by existing CameraController/Operator lookups. Do not put Operator or gameplay Camera2D inside the K3D SubViewport. The playable level renders directly in the normal world canvas.

## 6. Asset V2 consumer metadata only

Modify both existing family JSONs. Do not change schema, states, canvas, runtime domain, or pixels.

Append this consumer to each:

```json
{
  "type": "scene",
  "path": "res://game/world/levels/authored/dev/kenney_isometric_blockout_playtest/kenney_isometric_blockout_playtest_level.tscn"
}
```

Keep the existing feasibility-scene consumer.

No asset plan/ingest is required merely because consumer metadata changed. If live tooling requires a metadata/catalog refresh, do only that refresh. Never restage or re-ingest source art for this packet.

## 7. Focused validation only

Create `custodian/tools/validation/levels/kenney_isometric_blockout_playtest_smoke.gd`.

Keep it small. It should only check:

1. wrapper root is `GameRoot`;
2. `World/Level`, `World/Operator`, `World/PlayerController`, `World/Camera2D` and `World/LevelPlaytestBootstrap` exist;
3. Operator is a real `CharacterBody2D`;
4. bootstrap places Operator at `Spawn_Main=(0,-2464)` after startup;
5. both presentation roots exist;
6. native/Kenney switching leaves exactly one visible;
7. switching preserves Operator global position;
8. presentation roots contain no collision/navigation/body/controller/transition/campaign/procgen authority;
9. experiment collision is only the neutral `Collision/PathBoundaryCollision` envelope;
10. all 16 Kenney textures validate;
11. camera bounds equal `Rect2(-2600,-4300,5200,4650)`;
12. production `application/run/main_scene` is not the playtest.

Do not synthesize keyboard movement, combat, camera smoothing, or other full gameplay behavior in this smoke. Existing runtime suites already own those behaviors; the manual boot below proves this wrapper is usable.

Add manifest ID `kenney_isometric_blockout_playtest` with owners:

```text
custodian/scenes/debug/kenney_isometric_blockout_presentation.gd
custodian/game/world/levels/authored/dev/kenney_isometric_blockout_playtest/**
custodian/tools/validation/levels/kenney_isometric_blockout_playtest_smoke.gd
```

Also add the new shared builder to the existing `kenney_isometric_blockout_feasibility` owners so changes to shared visual construction select both focused tests.

## 8. Human-facing README

Create the local README with:

```text
# Kenney Isometric Blockout Playtest

Run:
res://game/world/levels/authored/dev/kenney_isometric_blockout_playtest/kenney_isometric_blockout_playtest.tscn

Normal Operator movement/combat controls are live.

Presentation:
1   Native
2   Kenney
Tab Toggle

Operator, gameplay Camera2D, spawn, and collision do not change when switching.
Collision is intentionally the outer evaluation envelope only.

Human validation:
- Operator/architecture scale
- route readability while moving
- depth and occlusion
- normal gameplay-camera compatibility
- whether the presentation vocabulary is useful for CUSTODIAN

The literal Kenney art is not approved production art.
```

## 9. Documentation truth

Update `design/01_systems/KENNEY_PRESENTATION_FEASIBILITY_ROADMAP.md`:

- keep major implementation packet count at 3;
- add K3D-1P `kenney-isometric-blockout-playtest` as a support extension outside that count;
- K3D-1 remains complete/reviewed;
- K3D-1P becomes the active ready implementation;
- K3D-2 remains refresh-required and is explicitly gated by completed K3D-1P human walkaround/A-B judgment;
- do not claim an art-direction verdict.

Update the Kenney series section and task packet index in `custodian/docs/ai_context/task_packets/README.md`.

Documentation drift at authoring time: the roadmap previously routed directly from static K3D-1 comparison evidence to user A/B judgment. The user's actual runtime check showed that artifact cannot support the intended experiential decision because it has no real Operator/controller/gameplay camera. K3D-1P closes that gap. H1 remains a separate in-progress workstream and is not a dependency for this frozen K3D-1 sample.

## Lean closeout

Run only:

```bash
python custodian/tools/validation/run_validation.py --test kenney_isometric_blockout_playtest
python custodian/tools/validation/run_validation.py --test kenney_isometric_blockout_feasibility
git diff --check
```

Then manually run:

```text
res://game/world/levels/authored/dev/kenney_isometric_blockout_playtest/kenney_isometric_blockout_playtest.tscn
```

Manual sanity:

1. Operator appears at Forum South.
2. Normal movement works.
3. Gameplay camera follows.
4. Press 1, 2 and Tab while standing and walking.
5. Operator does not teleport/reset.
6. Both presentations occupy the same world sample.
7. Walk toward the Dais and back toward South Reach long enough to prove the scene is genuinely usable.

Do not run `--changed`, broad Godot validation, full Asset V2 ingest, or unrelated suites unless a focused failure or repository policy makes them necessary.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: `kenney_isometric_blockout_presentation.gd` now supplies the exact shared K3D-1 A/B construction to the unchanged capture scene and the new authored walkaround. The new standalone wrapper contains the real Operator/controller/gameplay-camera stack; its focused smoke verifies Forum South spawn, 1/2/Tab switching, unchanged Operator/camera/boundary state, empty navigation authority, all 16 assets, bounds, and production boot isolation. Both focused K3D-1 and K3D-1P smokes pass. A GUI run confirmed W/S movement and camera follow across the sample, with 1/2/Tab presentation changes; the only runtime warning is the expected NavigationSystem notice that this presentation-only experiment has no floor TileMap.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: The first clean-worktree smoke could not resolve the `AuthoredLevel2D` global class because the worktree had not generated Godot's global class cache; the initial UI label also overlapped the standalone HUD. Both were fixed before completion. The normal NavigationSystem emits a no-floor-TileMap warning because this experiment intentionally provides no gameplay floor or AI navigation.
- Root cause / contributing factors: The new test initially skipped the editor import/class-scan phase, and the label started in the HUD's top-left screen area; the playtest's required empty `NavigationRoot` is deliberate.
- Prevention / pipeline improvement: Mark the new validation entry `needs_import: true` so fresh worktrees build the class cache before the focused smoke; position the readout beyond the HUD footprint. No additional pipeline change is required.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: The existing focused K3D-1 smoke protected the frozen capture contract; the new focused smoke and brief GUI movement/toggle check covered the playable wrapper without broad validation.

## Next Handoff

- Next workstream: `isometric-2-5d-presentation-foundation`
- Next packet state: `ready / dependency satisfied after this packet completes`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Refresh reason: `none; the active fixed-isometric 2.5D direction and successor packets are authored on current main.`
- Next action: `After K3D-1P lands, execute isometric-2-5d-presentation-foundation. Preserve user walkaround notes as tuning input for the later Forum vertical slice.`
- Blockers or open questions: `none; the canceled live-3D K3D-2/K3D-3 workstreams must not be authored.`
