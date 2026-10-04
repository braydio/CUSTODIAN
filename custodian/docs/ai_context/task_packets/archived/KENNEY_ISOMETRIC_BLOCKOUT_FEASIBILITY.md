# KENNEY ISOMETRIC BLOCKOUT FEASIBILITY

- Packet schema: `custodian.task_packet.v2`
- Workstream: `kenney-isometric-blockout-feasibility`
- Status: `complete`
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
- Review rationale: `substantial engineering default: Asset V2 writes plus objective presentation/runtime validation`
- Reviewed main: `cf3ba2eb219e`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Goal: Build a deterministic A/B test of CUSTODIAN-native 2D versus Kenney Isometric Miniature presentation over one shared Hub-approach sample, without moving production spatial/gameplay authority.
- Completion boundary: Inventory seven local Kenney packs; ingest 12–20 selected PNGs (hard cap 24) from Isometric Miniature Prototype/Bases through Asset V2; build one debug A/B scene; prove parity/isolation; record equivalent metrics; emit two 1280x720 captures plus one 2560x720 composite; update the roadmap.
- Current measured state: On `main@cf3ba2eb219e`, H1 is still `in_progress`; `game/world/hub/first_set/hub_first_set_layout.gd` is absent. Use `HUB_FIRST_SET_BLOCKOUT.md` for Forum geometry and `RoadOfWitnessesPrototype.MODULES` for Road visual geometry. Asset V2 is image/PNG-oriented. Reuse existing capture/perf patterns.
- Evidence: `design/04_architecture/HUB_FIRST_SET_BLOCKOUT.md`; `custodian/game/world/hub/road_of_witnesses_prototype.gd`; `custodian/tools/assets/asset.py`; `custodian/tools/iteration/godot/moment_capture.gd`; `custodian/tools/validation/ambient_enemy_full_actor_perf_bench.gd`; `custodian/game/world/procgen/diagnostics/procgen_performance_snapshot.gd`.
- Task-specific authority: K3D roadmap; Hub first-set blockout design; live Asset Pipeline V2.
- Work surface: exact files below; production Hub/Road/camera/gameplay/procgen/transition/save files are read-only.
- Change: implement only the experimental files/assets/evidence below.
- Preserve: production boot, Camera2D, H1/Road collision/navigation, Awakening, Operator, procgen, campaign/transitions, save state, Asset V2 routing.
- Non-goals: no live 3D; no mesh/GLB schema; no five 3D packs; no Retro Fantasy/Urban; no Operator art; no production Hub art; no art-direction verdict.
- Acceptance: all seven packs inventoried; selected PNGs have source/hash/dimensions/alpha/state metadata; both families ingest cleanly; A/B share anchors/sample/camera and own no gameplay/collision/navigation; metrics use equal samples; captures have exact dimensions; focused + changed validation pass.
- Validation: exact commands below.
- Task overrides: `none`
- Deferred: K3D-2, mesh/GLB, 3D packs, K3D-3, Retro Fantasy/Urban.

## Exact Files

| Action | Path |
| --- | --- |
| create | `custodian/scenes/debug/kenney_isometric_blockout_feasibility.{tscn,gd}` |
| create | `custodian/tools/validation/kenney_isometric_blockout_feasibility_smoke.gd` |
| modify | `custodian/tools/validation/validation_manifest.json` |
| create | `custodian/content/metadata/assets/families/kenney_iso_miniature_prototype_ref.asset.json` |
| create | `custodian/content/metadata/assets/families/kenney_iso_miniature_bases_ref.asset.json` |
| create | `custodian/asset_drop/source_work/experiments/kenney_presentation/<family>/<state>_source.png` |
| create | `custodian/asset_drop/inbox/<family>/<state>.png` |
| create | `custodian/docs/ai_context/reports/kenney_presentation/k3d1_{source_inventory,metrics}.json` |
| create | `custodian/docs/ai_context/reports/kenney_presentation/k3d1_{native,kenney}.png` |
| create | `custodian/docs/ai_context/reports/kenney_presentation/k3d1_ab_compare.png` |
| create | `custodian/docs/ai_context/reports/kenney_presentation/K3D1_ISOMETRIC_BLOCKOUT_REPORT.md` |
| modify | `design/01_systems/KENNEY_PRESENTATION_FEASIBILITY_ROADMAP.md` |

Do not instance `scenes/hub_road_of_witnesses_prototype.tscn`: it includes Operator, Camera2D, PlayerController, and collision. Read `RoadOfWitnessesPrototype.MODULES` and reuse its existing Road textures as visual-only sprites.

## 1. Local Packs + Asset V2

Expected ZIP identities in `~/Downloads`: Isometric Miniature Prototype; Isometric Miniature Bases; Prototype Kit; Modular Space Kit; Space Station Kit; Factory Kit; City Kit: Industrial. Filenames are not authoritative. Do not commit ZIPs/extractions.

One-time inventory probe:

```bash
python - <<'PY'
from pathlib import Path
import hashlib,json,zipfile
rows=[]
for p in sorted((Path.home()/"Downloads").glob("*.zip")):
    try:
        with zipfile.ZipFile(p) as z: names=z.namelist()
    except zipfile.BadZipFile: continue
    hay=(p.stem+"\n"+"\n".join(names[:300])).lower().replace("_"," ").replace("-"," ")
    if any(k in hay for k in ("isometric","prototype","modular","space","station","factory","industrial")):
        rows.append({"file":str(p),"sha256":hashlib.sha256(p.read_bytes()).hexdigest(),"members":len(names),"sample":names[:50]})
print(json.dumps(rows,indent=2))
PY
```

Write `k3d1_source_inventory.json`. For each selected PNG record:
`pack, archive_member, sha256, width, height, alpha, family, state_id, semantic_role`.

Select **12–20, max 24**, only from Isometric Miniature Prototype/Bases. Cover the smallest useful set of platform/base, edge, corner, wall/mass, stair/ramp, vertical cue, threshold/gate, civic volume where available.

Families:

```text
kenney_iso_miniature_prototype_ref
kenney_iso_miniature_bases_ref
```

Preserve source pixels/alpha exactly. No resize, resample, or palette conversion. Use:

```json
{
  "schema":"custodian.asset_family.v2",
  "id":"<family>",
  "kind":"tile",
  "runtime":{"domain":"tiles/experiments/kenney_feasibility","owner":"<family>"},
  "canvas":{"width":"<max W>","height":"<max H>"},
  "direction_policy":"omni",
  "auto_mirror":false,
  "states":{
    "<state>":{
      "required":true,"layer":"body","action_group":"tile","variant":"<state>",
      "layout":"copy","frame_width":"<exact W>","frame_height":"<exact H>"
    }
  },
  "aliases":{},
  "consumers":[{"type":"scene","path":"res://scenes/debug/kenney_isometric_blockout_feasibility.tscn"}]
}
```

Asset V2 owns runtime filenames.

## 2. Debug Scene

Required tree:

```text
KenneyIsometricBlockoutFeasibility
├── SharedSpatialSample
│   └── AnchorMarkers
├── NativePresentation
├── KenneyPresentation
└── Camera2D
```

No collision/navigation/body/controller/transition/campaign/procgen nodes.

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
const CAPTURE_POS := Vector2(0, -2000)
const CAPTURE_ZOOM := Vector2(0.30, 0.30)
const SETTLE_FRAMES := 30
const SAMPLE_FRAMES := 120

@onready var native_root: Node2D = %NativePresentation
@onready var kenney_root: Node2D = %KenneyPresentation
@onready var camera: Camera2D = %Camera2D

func set_presentation_mode(mode: PresentationMode) -> void:
    native_root.visible = mode == PresentationMode.NATIVE
    kenney_root.visible = mode == PresentationMode.KENNEY

func parity_snapshot() -> Dictionary:
    return {"cell_size":CELL_SIZE,"anchors":ANCHORS.duplicate(true),
        "regions":SAMPLE_REGIONS.duplicate(true),"viewport":VIEW_SIZE,
        "camera_position":camera.position,"camera_zoom":camera.zoom}
```

Native mode: build Road visuals from `RoadOfWitnessesPrototype.MODULES` and existing underlay/foreground textures; use neutral `Polygon2D/Line2D` for North Processional + Forum. Kenney mode: use only the two experimental families over the same `SharedSpatialSample`.

If H1 lands before claim, consume its read-only layout constants only if they match locked design. Do not import its collision/runtime ownership.

## 3. Metrics + Capture

Reuse `ambient_enemy_full_actor_perf_bench.gd::_measure_run()` and `procgen_performance_snapshot.gd::runtime_snapshot()`. For each mode: 30 settle frames + 120 sample frames. Write `k3d1_metrics.json` with:

`frame_ms_p50, frame_ms_p95, OBJECT_NODE_COUNT, RENDER_TOTAL_OBJECTS_IN_FRAME, RENDER_TOTAL_DRAW_CALLS_IN_FRAME, presentation_node_count, selected_runtime_asset_count, instance_count`.

Unavailable metric = `null`, not `0`.

Reuse the `moment_capture.gd` viewport-save pattern in the debug script:

```gdscript
RenderingServer.force_draw(false)
var image := get_viewport().get_texture().get_image()
assert(image != null and not image.is_empty())
assert(image.save_png(path) == OK)
```

Use `CAPTURE_POS/CAPTURE_ZOOM` for both modes. Save 1280x720 A/B and compose left/right with `Image.blit_rect()` into exactly 2560x720. No new capture/profiler subsystem.

## 4. Exact Smoke

Create `custodian/tools/validation/kenney_isometric_blockout_feasibility_smoke.gd`, mirroring the `extends SceneTree` + `CUSTODIAN_TEST_RESULT_JSON:` pattern in `road_of_witnesses_production_smoke.gd`.

Assert:

1. cell, three anchors, two sample regions, viewport, `CAPTURE_POS`, `CAPTURE_ZOOM` exactly match this packet;
2. A/B `parity_snapshot()` is identical;
3. exactly one presentation root is visible after mode switch;
4. neither presentation root owns collision, navigation, CharacterBody2D, Area2D, controller, transition, campaign, or procgen authority;
5. project main scene is not this debug scene;
6. selected Kenney textures resolve non-null.

Manifest entry:

```json
{
  "id":"kenney_isometric_blockout_feasibility",
  "type":"godot_script",
  "script":"res://tools/validation/kenney_isometric_blockout_feasibility_smoke.gd",
  "tier":"integration",
  "tags":["kenney","presentation","assets","experiment"],
  "owners":[
    "custodian/scenes/debug/kenney_isometric_blockout_feasibility.gd",
    "custodian/scenes/debug/kenney_isometric_blockout_feasibility.tscn",
    "custodian/content/metadata/assets/families/kenney_iso_miniature_prototype_ref.asset.json",
    "custodian/content/metadata/assets/families/kenney_iso_miniature_bases_ref.asset.json",
    "custodian/content/tiles/experiments/kenney_feasibility/**",
    "custodian/tools/validation/kenney_isometric_blockout_feasibility_smoke.gd"
  ],
  "timeout_sec":45,
  "needs_import":true
}
```

## 5. Validation + Handoff

Run:

```bash
python custodian/tools/assets/asset.py --help
python custodian/tools/assets/asset.py plan kenney_iso_miniature_prototype_ref --verbose
python custodian/tools/assets/asset.py plan kenney_iso_miniature_bases_ref --verbose
python custodian/tools/assets/asset.py ingest kenney_iso_miniature_prototype_ref --yes --godot-import
python custodian/tools/assets/asset.py ingest kenney_iso_miniature_bases_ref --yes --godot-import
python custodian/tools/assets/asset.py status kenney_iso_miniature_prototype_ref --verbose
python custodian/tools/assets/asset.py status kenney_iso_miniature_bases_ref --verbose
python custodian/tools/assets/asset.py doctor
python custodian/tools/validation/run_validation.py --test kenney_isometric_blockout_feasibility
python custodian/tools/validation/run_validation.py --changed --base cf3ba2eb219e
git diff --check
```

`K3D1_ISOMETRIC_BLOCKOUT_REPORT.md` contains only: pack matches + selected count; A/B metric table; validation result; comparison path; technical drift/defects; human questions on readability, scale, architecture, depth/clutter, CUSTODIAN fit.

Docs drift at reviewed main: H1 is not landed; 2.5D/fixed-isometric design language still coexists with Camera2D/fundamentally-2D runtime docs; Asset V2 is PNG-oriented. Record changes if execution disproves any of those facts. Do not alter doctrine.

Before `complete`, add required completion/feedback receipts and update the roadmap.

- Next workstream: `review-kenney-isometric-blockout-feasibility`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Refresh reason: `none before paired technical review; K3D-2 requires the user's A/B judgment and planning refresh after review.`
- Next action: `finish and land K3D-1, then run the paired technical review; return the report and comparison to the authoring chat before K3D-2.`
- Blockers or open questions: `review is gated only on K3D-1 landing.`

## Completion Record

- Implemented against `main@9093c9ff1613` after a fast-forward sync.
- Seven expected Kenney pack identities inventoried; 16 selected original PNGs ingested through two Asset V2 families. All runtime images passed source/runtime RGBA pixel comparison.
- Detached A/B scene and integration smoke added. Production Hub, Road, camera, collision/navigation, procgen, campaign, and transition authority were not modified.
- Both captures are 1280×720; the composite is 2560×720. See `custodian/docs/ai_context/reports/kenney_presentation/K3D1_ISOMETRIC_BLOCKOUT_REPORT.md` and adjacent evidence files.
- Changed validation passed: 13 selected, 13 passed. Asset V2 plan/status/doctor checks passed. The unsupported `asset.py doctor --verbose` packet command was corrected to `asset.py doctor`.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: Initial worktree creation was still processing Git LFS when the user paused the task; resuming after checkout completed recovered cleanly. The host window rendered at 931×523, not the fixed contract size, and the first image composition used incompatible formats. An initial verification looked for normalized inbox files after ingestion, when Asset V2 had already moved them into its archive; the archived receipts resolved the check.
- Root cause / contributing factors: Fresh worktree LFS hydration, host display scaling, `Image.blit_rect` format requirements, and assuming the inbox remains populated after successful ingest.
- Prevention / pipeline improvement: Resume an interrupted workstream after checkout completes; use a fixed-size `SubViewport`, normalize image formats before composition, and verify intake hashes using Asset V2 receipts plus runtime hashes. The unsupported doctor flag was removed from this packet.
- Tooling / docs drift discovered: The live `asset.py doctor` CLI has no `--verbose` option.
- Follow-up: `fixed-in-scope`
- What worked: Asset V2 receipts plus deterministic pixel checks; focused and changed validation.
