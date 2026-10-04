# KENNEY ISOMETRIC BLOCKOUT FEASIBILITY

- Packet schema: `custodian.task_packet.v2`
- Workstream: `kenney-isometric-blockout-feasibility`
- Status: `ready`
- Dispatch: `manual`
- Priority: `P2`
- Depends on: `none`
- Locks: `presentation-experiments, asset-pipeline`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual, asset-pipeline`
- Paired review workstream: `review-kenney-isometric-blockout-feasibility`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default: experimental Asset V2 writes plus objective presentation/runtime validation`
- Reviewed main: `cf3ba2eb219e`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Goal: Produce a reproducible A/B test of current CUSTODIAN-native 2D presentation versus Kenney Isometric Miniature presentation over one shared Hub approach sample, without changing production gameplay/spatial authority.
- Completion boundary: Inventory seven local Kenney archives; ingest 12–20 selected static PNGs (hard cap 24) from Isometric Miniature Prototype/Bases through two experimental Asset V2 families; build one detached A/B debug scene; prove anchor/camera/route parity and production isolation; record equivalent metrics; emit two 1280x720 captures plus one 2560x720 composite; update the K3D roadmap.
- Current measured state: On `main@cf3ba2eb219e`, H1 remains `in_progress` and `custodian/game/world/hub/first_set/hub_first_set_layout.gd` is not on main, so K3D-1 must read Forum geometry from `HUB_FIRST_SET_BLOCKOUT.md`. Road visual geometry is already centralized in `RoadOfWitnessesPrototype.MODULES`. Asset V2 is PNG/image-oriented; no production mesh/GLB family kind exists. Existing capture and perf patterns live in `moment_capture.gd`, `ambient_enemy_full_actor_perf_bench.gd`, and `procgen_performance_snapshot.gd`.
- Evidence: `design/04_architecture/HUB_FIRST_SET_BLOCKOUT.md`; `custodian/game/world/hub/road_of_witnesses_prototype.gd`; `custodian/content/metadata/assets/schemas/tile.json`; `custodian/tools/assets/asset.py`; `custodian/tools/iteration/godot/moment_capture.gd`; `custodian/tools/validation/ambient_enemy_full_actor_perf_bench.gd`; `custodian/game/world/procgen/diagnostics/procgen_performance_snapshot.gd`; `design/01_systems/KENNEY_PRESENTATION_FEASIBILITY_ROADMAP.md`.
- Task-specific authority: `design/01_systems/KENNEY_PRESENTATION_FEASIBILITY_ROADMAP.md`; `design/04_architecture/HUB_FIRST_SET_BLOCKOUT.md`; live Asset Pipeline V2.
- Work surface: Exact files below. Production Hub, Road, camera, gameplay, procgen, transition, and save-state files are read-only.
- Change: Implement only the exact experimental/debug/assets/report surface below. Prefer the recommended code shape unless current-main syntax requires a local adjustment.
- Preserve: production boot; Camera2D behavior; Road/H1 collision/navigation; Awakening; Operator; procgen; campaign/world transitions; save state; Asset V2 naming/routing.
- Non-goals: no 3D runtime; no mesh/GLB schema; no import of the five 3D packs; no Retro Fantasy/Retro Urban; no Operator art; no production Hub art; no art-direction verdict.
- Acceptance: Seven packs inventoried; 12–20 selected PNGs (<=24) have source filename/hash/dimensions/alpha/state metadata; both families ingest cleanly through Asset V2; A/B share exact anchors, spatial sample, viewport, camera transform, and no collision/navigation/gameplay ownership; metrics use identical settle/sample counts; captures are 1280x720 each and composite is 2560x720; focused + changed-file validation pass; production behavior is unchanged.
- Validation: exact commands below.
- Task overrides: `none`
- Deferred: K3D-2 orthographic 3D; mesh/GLB contract; 3D Kenney packs; K3D-3 Shape/Asset Forge; Retro Fantasy/Retro Urban.

## Exact File Map

| Action | Path | Contract |
| --- | --- | --- |
| create | `custodian/scenes/debug/kenney_isometric_blockout_feasibility.tscn` | one debug-only A/B scene |
| create | `custodian/scenes/debug/kenney_isometric_blockout_feasibility.gd` | shared geometry, A/B switching, metrics, fixed capture |
| create | `custodian/tools/validation/kenney_isometric_blockout_feasibility_smoke.gd` | structural parity/isolation smoke |
| modify | `custodian/tools/validation/validation_manifest.json` | register test id `kenney_isometric_blockout_feasibility` |
| create | `custodian/content/metadata/assets/families/kenney_iso_miniature_prototype_ref.asset.json` | experimental Asset V2 family |
| create | `custodian/content/metadata/assets/families/kenney_iso_miniature_bases_ref.asset.json` | experimental Asset V2 family |
| create | `custodian/asset_drop/source_work/experiments/kenney_presentation/<family>/<state>_source.png` | selected source masters only |
| create | `custodian/asset_drop/inbox/<family>/<state>.png` | normalized selected inputs only |
| create | `custodian/docs/ai_context/reports/kenney_presentation/k3d1_source_inventory.json` | structured seven-pack + selected-source inventory |
| create | `custodian/docs/ai_context/reports/kenney_presentation/k3d1_metrics.json` | structured A/B metrics |
| create | `custodian/docs/ai_context/reports/kenney_presentation/k3d1_native.png` | 1280x720 evidence |
| create | `custodian/docs/ai_context/reports/kenney_presentation/k3d1_kenney.png` | 1280x720 evidence |
| create | `custodian/docs/ai_context/reports/kenney_presentation/k3d1_ab_compare.png` | 2560x720 evidence |
| create | `custodian/docs/ai_context/reports/kenney_presentation/K3D1_ISOMETRIC_BLOCKOUT_REPORT.md` | compact conclusions + human questions |
| modify | `design/01_systems/KENNEY_PRESENTATION_FEASIBILITY_ROADMAP.md` | landed SHA, counts, validation, metrics, handoff |

Read-only inputs:

- `custodian/game/world/hub/road_of_witnesses_prototype.gd`
- `design/04_architecture/HUB_FIRST_SET_BLOCKOUT.md`
- `custodian/tools/iteration/godot/moment_capture.gd`
- `custodian/tools/validation/ambient_enemy_full_actor_perf_bench.gd`
- `custodian/game/world/procgen/diagnostics/procgen_performance_snapshot.gd`

Do **not** instance `custodian/scenes/hub_road_of_witnesses_prototype.tscn` in the experiment: it brings Operator, Camera2D, PlayerController, and Road collision. Read `RoadOfWitnessesPrototype.MODULES` and reuse the existing Road textures as visual-only Sprite2D nodes instead.

## 1. Inventory + Select Assets

Inventory actual ZIPs in `~/Downloads`; filenames are not authoritative. Expected identities:

1. Isometric Miniature Prototype
2. Isometric Miniature Bases
3. Prototype Kit
4. Modular Space Kit
5. Space Station Kit
6. Factory Kit
7. City Kit: Industrial

Use a one-time local probe rather than manual browsing:

```bash
python - <<'PY'
from pathlib import Path
import hashlib, json, zipfile
root = Path.home() / "Downloads"
need = ("isometric","prototype","modular","space","station","factory","industrial")
rows = []
for p in sorted(root.glob("*.zip")):
    try:
        with zipfile.ZipFile(p) as z:
            names = z.namelist()
    except zipfile.BadZipFile:
        continue
    hay = (p.stem + "\n" + "\n".join(names[:300])).lower().replace("_"," ").replace("-"," ")
    if any(k in hay for k in need):
        rows.append({"file":str(p),"sha256":hashlib.sha256(p.read_bytes()).hexdigest(),"members":len(names),"sample":names[:50]})
print(json.dumps(rows, indent=2))
PY
```

Write the resolved inventory to `k3d1_source_inventory.json`. Do not commit ZIPs or wholesale extractions.

Select **12–20 PNGs, hard cap 24**, only from Isometric Miniature Prototype/Bases. Minimum useful roles when present: base/platform, straight edge, corner, wall/mass, stair/ramp, vertical cue, threshold/gate, civic volume.

Each selected record must include:

```text
pack, archive_member, sha256, width, height, alpha, family, state_id, semantic_role
```

## 2. Asset Pipeline V2

Families:

```text
kenney_iso_miniature_prototype_ref
kenney_iso_miniature_bases_ref
```

Source/inbox naming:

```text
custodian/asset_drop/source_work/experiments/kenney_presentation/<family>/<state>_source.png
custodian/asset_drop/inbox/<family>/<state>.png
```

Preserve original pixels and alpha exactly. No resize, palette conversion, or resampling.

Use this family shape, filling exact dimensions after inventory:

```json
{
  "schema": "custodian.asset_family.v2",
  "id": "<family>",
  "kind": "tile",
  "runtime": {
    "domain": "tiles/experiments/kenney_feasibility",
    "owner": "<family>"
  },
  "canvas": {"width": "<max selected width>", "height": "<max selected height>"},
  "direction_policy": "omni",
  "auto_mirror": false,
  "states": {
    "<state>": {
      "required": true,
      "layer": "body",
      "action_group": "tile",
      "variant": "<state>",
      "layout": "copy",
      "frame_width": "<exact source width>",
      "frame_height": "<exact source height>"
    }
  },
  "aliases": {},
  "consumers": [
    {"type": "scene", "path": "res://scenes/debug/kenney_isometric_blockout_feasibility.tscn"}
  ]
}
```

Do not hand-name runtime outputs. Asset V2 owns canonical runtime naming.

## 3. Recommended Scene/Code Shape

Scene tree:

```text
KenneyIsometricBlockoutFeasibility (Node2D)
├── SharedSpatialSample (Node2D)
│   └── AnchorMarkers (Node2D)
├── NativePresentation (Node2D)
├── KenneyPresentation (Node2D)
└── Camera2D
```

No `CollisionObject2D`, `NavigationRegion2D`, `NavigationAgent2D`, Operator, PlayerController, transition, campaign, or procgen nodes anywhere in this scene.

Recommended script spine:

```gdscript
extends Node2D

enum PresentationMode { NATIVE, KENNEY }

const CELL_SIZE := 32
const VIEW_SIZE := Vector2i(1280, 720)
const ANCHORS := {
    &"spawn_south_reach": Vector2(-6, 162),
    &"forum_south": Vector2(0, -2464),
    &"adjudication_dais": Vector2(0, -3136),
}
const SAMPLE_REGIONS := {
    &"north_processional": Rect2(-512, -2400, 1024, 1152),
    &"ashen_forum": Rect2(-1280, -4032, 2560, 1792),
}
const CAPTURE_CAMERA_POSITION := Vector2(0, -2000)
const CAPTURE_CAMERA_ZOOM := Vector2(0.30, 0.30)
const SETTLE_FRAMES := 30
const SAMPLE_FRAMES := 120

@onready var native_root: Node2D = %NativePresentation
@onready var kenney_root: Node2D = %KenneyPresentation
@onready var camera: Camera2D = %Camera2D

func set_presentation_mode(mode: PresentationMode) -> void:
    native_root.visible = mode == PresentationMode.NATIVE
    kenney_root.visible = mode == PresentationMode.KENNEY

func parity_snapshot() -> Dictionary:
    return {
        "cell_size": CELL_SIZE,
        "anchors": ANCHORS.duplicate(true),
        "sample_regions": SAMPLE_REGIONS.duplicate(true),
        "viewport": VIEW_SIZE,
        "camera_position": camera.position,
        "camera_zoom": camera.zoom,
    }
```

Keep all shared anchor/region truth outside both presentation roots. A and B may differ only in visual children.

### Native mode

- Build Road visuals from `RoadOfWitnessesPrototype.MODULES`; do not copy its module coordinates into a second constant table.
- Reuse existing `road_of_witnesses_<id>_underlay_<WxH>.png` and foreground textures.
- Use neutral debug `Polygon2D` / `Line2D` primitives for North Processional and Ashen Forum because H1 production presentation is not on main.
- If H1 lands before claim, prefer its read-only layout constants only when they exactly match the locked design; do not absorb H1 runtime/collision.

### Kenney mode

- Place only Asset V2 runtime outputs from the two experimental families.
- Fit the same `SAMPLE_REGIONS` and anchors.
- Never create presentation-specific walkability or collision.

## 4. Metrics + Capture

Do not build a new profiler or screenshot subsystem.

For metrics, copy the existing measurement pattern from:

- `ambient_enemy_full_actor_perf_bench.gd::_measure_run()`
- `procgen_performance_snapshot.gd::runtime_snapshot()`

For each mode, after exactly 30 settle frames, sample exactly 120 frames and record:

```text
frame_ms_p50
frame_ms_p95
OBJECT_NODE_COUNT
RENDER_TOTAL_OBJECTS_IN_FRAME
RENDER_TOTAL_DRAW_CALLS_IN_FRAME
presentation_node_count
selected_runtime_asset_count
manual_or_generated_instance_count
```

Write both mode records to `k3d1_metrics.json`. If a requested metric is unavailable, store `null`, never `0` as a substitute.

For capture, reuse the exact `moment_capture.gd` pattern inside the debug script:

```gdscript
RenderingServer.force_draw(false)
var image := get_viewport().get_texture().get_image()
assert(image != null and not image.is_empty())
var error := image.save_png(path)
assert(error == OK)
```

Use the fixed camera constants above for both modes. Save A and B at 1280x720. Compose them left/right with `Image.blit_rect()` into exactly 2560x720. No separate capture utility.

## 5. Exact Smoke

Create:

`custodian/tools/validation/kenney_isometric_blockout_feasibility_smoke.gd`

Mirror the `extends SceneTree` + structured-result pattern used by `road_of_witnesses_production_smoke.gd`.

Test must instantiate:

`res://scenes/debug/kenney_isometric_blockout_feasibility.tscn`

and assert:

1. `CELL_SIZE == 32`.
2. Required anchors exactly equal `(-6,162)`, `(0,-2464)`, `(0,-3136)`.
3. Required sample regions exactly equal the locked North Processional/Ashen Forum Rect2 values.
4. A and B return identical `parity_snapshot()` except presentation mode.
5. viewport is 1280x720; camera is exactly `(0,-2000)` with zoom `(0.30,0.30)`.
6. exactly one of `NativePresentation` / `KenneyPresentation` is visible after each mode switch.
7. neither presentation root contains collision, navigation, CharacterBody2D, Area2D, Operator/controller, transition, campaign, or procgen authority.
8. project main scene is not this debug scene.
9. selected Kenney textures resolve and are non-null in B.
10. structured result prints `CUSTODIAN_TEST_RESULT_JSON:` and exits nonzero on failure.

Register exactly this manifest entry shape:

```json
{
  "id": "kenney_isometric_blockout_feasibility",
  "type": "godot_script",
  "script": "res://tools/validation/kenney_isometric_blockout_feasibility_smoke.gd",
  "tier": "integration",
  "tags": ["kenney", "presentation", "assets", "experiment"],
  "owners": [
    "custodian/scenes/debug/kenney_isometric_blockout_feasibility.gd",
    "custodian/scenes/debug/kenney_isometric_blockout_feasibility.tscn",
    "custodian/content/metadata/assets/families/kenney_iso_miniature_prototype_ref.asset.json",
    "custodian/content/metadata/assets/families/kenney_iso_miniature_bases_ref.asset.json",
    "custodian/content/tiles/experiments/kenney_feasibility/**",
    "custodian/tools/validation/kenney_isometric_blockout_feasibility_smoke.gd"
  ],
  "timeout_sec": 45,
  "needs_import": true
}
```

## 6. Commands / Closeout

Run in this order:

```bash
python custodian/tools/assets/asset.py --help

python custodian/tools/assets/asset.py plan kenney_iso_miniature_prototype_ref --verbose
python custodian/tools/assets/asset.py plan kenney_iso_miniature_bases_ref --verbose

python custodian/tools/assets/asset.py ingest kenney_iso_miniature_prototype_ref --yes --godot-import
python custodian/tools/assets/asset.py ingest kenney_iso_miniature_bases_ref --yes --godot-import

python custodian/tools/assets/asset.py status kenney_iso_miniature_prototype_ref --verbose
python custodian/tools/assets/asset.py status kenney_iso_miniature_bases_ref --verbose
python custodian/tools/assets/asset.py doctor --verbose

python custodian/tools/validation/run_validation.py --test kenney_isometric_blockout_feasibility
python custodian/tools/validation/run_validation.py --changed --base cf3ba2eb219e
git diff --check
```

Compact report `K3D1_ISOMETRIC_BLOCKOUT_REPORT.md` must contain only:

- exact pack matches + selected count;
- A/B metric table from `k3d1_metrics.json`;
- focused + changed validation result;
- comparison image path;
- any technical defect/drift;
- five human questions: tactical readability, scale, architecture, depth/clutter, CUSTODIAN fit.

Update the roadmap with landed SHA/counts/results. Do not author K3D-2 inside this workstream.

## Documentation Drift Check

At reviewed main:

- H1 is still in progress; do not claim first-set runtime art/layout has landed.
- 2.5D/fixed-isometric design language coexists with current Camera2D/fundamentally-2D runtime docs.
- Asset V2 remains image/PNG-oriented.

If execution finds those facts changed, record the exact changed authority in the K3D-1 report. Do not turn the experiment into a doctrine or mesh-pipeline migration.

## Completion / Handoff

Before `complete`, add the required `custodian.task_completion.v1` and `custodian.task_feedback.v1` receipts.

- Next workstream: `kenney-orthographic-3d-feasibility`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Refresh reason: `K3D-2 must be re-derived from landed A/B evidence, review findings, and human visual judgment.`
- Next action: `Bring k3d1_ab_compare.png and K3D1_ISOMETRIC_BLOCKOUT_REPORT.md back to the authoring chat before K3D-2 is authored.`
- Blockers or open questions: `none for K3D-1`
