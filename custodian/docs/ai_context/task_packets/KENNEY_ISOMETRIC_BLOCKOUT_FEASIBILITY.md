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
- Review rationale: `substantial engineering default: the slice writes experimental Asset V2 content and runtime/debug presentation code, so independent technical review adds useful confidence even though aesthetic preference remains human-owned`
- Reviewed main: `f330527d922e`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Goal: Build a detached, deterministic A/B presentation experiment that compares a CUSTODIAN-native 2D spatial blockout against a Kenney Isometric Miniature presentation of the same South Reach/Witness-to-Forum sample, while proving a bounded third-party-source → Asset Pipeline V2 intake path and preserving all production Hub/gameplay authority.
- Completion boundary: Inventory the seven user-downloaded Kenney archives in `~/Downloads`; select and ingest a bounded 12–20 (hard cap 24) static PNG subset from Isometric Miniature Prototype and Isometric Miniature Bases through two experimental Asset V2 families; build one debug-only A/B comparison scene over one shared spatial sample; prove coordinate/camera/route parity and production isolation; record objective rendering/authoring measurements; emit one deterministic 2560x720 comparison image and K3D-1 report; update the K3D roadmap. Done means the experiment is reproducible and technically measured without changing the production Hub, camera, collision, navigation, procgen, campaign, world-transition, or art-direction authorities.
- Current measured state: At `main@f330527d922e`, the project is Godot 4.7 Forward Plus with a 1280x720 canvas-items viewport. Repository code search shows the game surface is overwhelmingly 2D (265 `Node2D` matches, 72 `Area2D`, 47 `CharacterBody2D`) with only two game-surface `Camera3D` matches; `terminal_planet_preview.gd` already creates a bounded 3D SubViewport path. `HUB_FIRST_SET_BLOCKOUT.md` fixes the 32 px first-set coordinate system and the South Reach/Forum anchors. Asset Pipeline V2 currently exposes PNG/image-oriented kinds including `tile`; `tile.json` routes runtime files through `.png`; no mesh/GLB asset-kind contract exists. The user reports all seven recommended Kenney ZIPs are already in `~/Downloads`.
- Evidence: `custodian/project.godot`; `custodian/game/ui/terminal/terminal_planet_preview.gd`; `design/00_meta/MASTER_DESIGN_DOCTRINE.md`; `design/01_systems/CAMERA_SYSTEM.md`; `design/04_architecture/HUB_FIRST_SET_BLOCKOUT.md`; `design/02_features/procgen/AUTHORED_TILED_ROOM_PIPELINE.md`; `custodian/tools/assets/asset.py`; `custodian/tools/assets/asset_contract.py`; `custodian/tools/assets/asset_naming.py`; `custodian/content/metadata/assets/schemas/tile.json`; `design/01_systems/KENNEY_PRESENTATION_FEASIBILITY_ROADMAP.md`.
- Task-specific authority: `design/01_systems/KENNEY_PRESENTATION_FEASIBILITY_ROADMAP.md`; `design/04_architecture/HUB_FIRST_SET_BLOCKOUT.md`; live Asset Pipeline V2 under `custodian/tools/assets/` and `custodian/content/metadata/assets/`; `custodian/project.godot` for viewport/runtime configuration.
- Work surface: Primary owner is a detached debug presentation experiment under `custodian/scenes/debug/`, plus the two bounded experimental Asset V2 families and one focused validation smoke. Expected report/evidence lives under `custodian/docs/ai_context/reports/kenney_presentation/`. Production Hub/runtime files are read-only inputs unless a tiny non-behavioral read seam is proven necessary.
- Change: Implement the source inventory, bounded experimental asset intake, shared sample, A/B presentation modes, technical measurements, focused validation, and deterministic evidence described below. Reuse current spatial/asset authorities rather than copying production truth. Keep the experiment disposable.
- Preserve: production boot; current Camera2D behavior; all Hub collision/navigation; H1 workstream semantics; Road presentation ownership; Awakening; Operator controls/combat; procgen; campaign/world transitions; save state; Asset V2 naming/routing; current art-direction doctrine.
- Non-goals: Do not convert CUSTODIAN to 3D. Do not import the five 3D Kenney packs into production runtime in K3D-1. Do not implement a mesh/GLB Asset V2 kind. Do not use Retro Fantasy or Retro Urban yet. Do not modify Operator art/animation. Do not choose a winning art direction. Do not commit full Kenney archives or wholesale pack extractions.
- Acceptance: All seven expected pack identities are inventoried from actual local archives; selected Isometric Miniature sources have recorded original filenames, archive identity, SHA-256, pixel dimensions, alpha presence, and semantic state IDs; 12–20 selected PNGs (<=24) pass through `source_work` → normalized `inbox` → Asset V2 ingest with no manual canonical runtime naming; both experimental families report healthy plan/status/doctor evidence; A and B use the same route/anchors/camera and no Kenney presentation node owns collision/navigation/gameplay state; fixed capture A and B are each 1280x720 and compose to one 2560x720 comparison artifact; objective metrics are recorded over equivalent runs; changed-file validation passes; production Hub/gameplay behavior is unchanged.
- Validation: Inspect `custodian/tools/assets/asset.py --help`; run Asset V2 `plan`, `status`, and `doctor` for the two experimental families; add and run one focused K3D-1 structural parity smoke that checks anchor coordinates, camera parity, shared route geometry, presentation-only ownership, and absence of production transition/state mutation; run a headless import if the selected assets require it; run `python custodian/tools/validation/run_validation.py --changed --base <pre-work-main>` once focused checks pass; generate only the two fixed 1280x720 captures plus their 2560x720 composite.
- Task overrides: `none`
- Deferred: K3D-2 orthographic 3D environment; any mesh/GLB Asset V2 contract; Prototype Kit/Modular Space/Space Station/Factory/Industrial runtime import; K3D-3 Shape/Asset Forge production test; Retro Fantasy/Retro Urban art-direction analysis.

## Plan

### 1. Inventory the actual downloads first

Do not guess ZIP filenames. Search `~/Downloads` for ZIPs and match the seven expected pack identities from filenames and archive contents.

A suitable one-time inventory shape is:

```bash
python - <<'PY'
from pathlib import Path
import hashlib, json, zipfile

root = Path.home() / "Downloads"
wanted = (
    "isometric miniature prototype",
    "isometric miniature bases",
    "prototype kit",
    "modular space kit",
    "space station kit",
    "factory kit",
    "city kit industrial",
)

rows = []
for path in sorted(root.glob("*.zip")):
    normalized = path.stem.lower().replace("_", " ").replace("-", " ")
    try:
        with zipfile.ZipFile(path) as zf:
            names = zf.namelist()
    except zipfile.BadZipFile:
        continue
    haystack = (normalized + "\n" + "\n".join(names[:250])).lower()
    if not any(token in haystack for token in wanted):
        continue
    rows.append({
        "file": str(path),
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "members": len(names),
        "sample_members": names[:40],
    })
print(json.dumps(rows, indent=2))
PY
```

Refine matching if Kenney archive naming differs. Do not extract unrelated archives.

Write the final source inventory to:

`custodian/docs/ai_context/reports/kenney_presentation/K3D1_SOURCE_INVENTORY.md`

For every matched pack record:

- local archive filename;
- pack identity;
- archive SHA-256;
- file/member count;
- included readme/license identity when present;
- available source formats;
- whether the pack is used in K3D-1 or reserved for K3D-2.

Do not commit the original ZIPs.

### 2. Select a bounded isometric vocabulary

Use only Isometric Miniature Prototype and Isometric Miniature Bases in B.

Target 12–20 total PNGs, hard cap 24. Prefer the smallest set that can express:

- floor/platform/base;
- straight boundary/edge;
- corner/turn;
- wall or major mass;
- stair/ramp/elevation cue;
- column/pillar/vertical cue;
- threshold/gate;
- simple civic/building volume where the actual pack provides one.

Do not select assets merely because they look interesting.

For every selected source record:

- pack;
- archive member/original filename;
- semantic role;
- proposed family;
- state ID;
- exact source width x height;
- frames: 1;
- animation: false;
- direction: omni;
- alpha present/absent;
- SHA-256.

### 3. Stage through Asset Pipeline V2

Create source-work roots:

```text
custodian/asset_drop/source_work/experiments/kenney_presentation/kenney_iso_miniature_prototype_ref/
custodian/asset_drop/source_work/experiments/kenney_presentation/kenney_iso_miniature_bases_ref/
```

Rename each selected source master:

```text
<state_id>_source.png
```

Copy, do not destructively move, from the extracted local pack staging directory.

Normalize to:

```text
custodian/asset_drop/inbox/kenney_iso_miniature_prototype_ref/<state_id>.png
custodian/asset_drop/inbox/kenney_iso_miniature_bases_ref/<state_id>.png
```

Normalization contract:

- preserve original pixel dimensions exactly;
- preserve true alpha exactly;
- preserve aspect ratio and registration;
- no stretch;
- no palette conversion;
- no resampling unless the live source is demonstrably malformed, in which case stop and record the defect rather than silently "fixing" it.

Create:

```text
custodian/content/metadata/assets/families/kenney_iso_miniature_prototype_ref.asset.json
custodian/content/metadata/assets/families/kenney_iso_miniature_bases_ref.asset.json
```

Use the current `custodian.asset_family.v2` contract and current `tile` kind. Both families are static `omni` references with runtime domain `tiles/experiments/kenney_feasibility`. The family-level canvas must be a truthful positive size required by the live schema; selected states whose source dimensions differ must use the current supported per-state `frame_width` / `frame_height` overrides. Each state is one frame and non-animated.

Suggested semantic fields per state:

```text
layer: body
action_group: reference
variant: <state_id>
layout: copy
required: true only for the subset actually used by the A/B scene
recommended: false unless a selected but non-required comparison role is intentionally kept
```

Do not hand-author canonical runtime filenames. Let Asset V2 route them.

Verify through the live CLI, starting with:

```bash
python custodian/tools/assets/asset.py --help
python custodian/tools/assets/asset.py plan kenney_iso_miniature_prototype_ref --verbose
python custodian/tools/assets/asset.py plan kenney_iso_miniature_bases_ref --verbose
python custodian/tools/assets/asset.py ingest kenney_iso_miniature_prototype_ref --yes --godot-import
python custodian/tools/assets/asset.py ingest kenney_iso_miniature_bases_ref --yes --godot-import
python custodian/tools/assets/asset.py status kenney_iso_miniature_prototype_ref --verbose
python custodian/tools/assets/asset.py status kenney_iso_miniature_bases_ref --verbose
python custodian/tools/assets/asset.py doctor --verbose
```

If current `asset.py --help` differs, follow the live command contract rather than this packet's example invocation.

### 4. Build one shared spatial sample

Preferred debug surface:

```text
custodian/scenes/debug/kenney_isometric_blockout_feasibility.tscn
custodian/scenes/debug/kenney_isometric_blockout_feasibility.gd
```

If a separate data helper materially simplifies parity, use a debug-only helper under the same `custodian/scenes/debug/` ownership. Do not create a production presentation framework in K3D-1.

The sample should cover:

```text
South Reach / current Witness Plaza context
→ North Processional
→ Forum South
→ Adjudication Dais
```

Preserve:

```text
cell size                 32 px
Spawn_SouthReach          (-6,162)
Forum South marker        (0,-2464)
Adjudication Dais         (0,-3136)
evaluation viewport       1280x720
```

Use one shared semantic/spatial model for both modes.

Mode A:

- existing CUSTODIAN-native 2D presentation where live content exists;
- neutral existing project blockout primitives for sample areas that have design geometry but no landed production presentation;
- no Kenney art.

Mode B:

- same geometry and route;
- selected Isometric Miniature assets as presentation-only pieces;
- no extra collision, walkability, route shortcut, or camera advantage.

Switching A/B may use a debug toggle or deterministic launch parameter. The exact private implementation is flexible; the spatial truth must not be duplicated.

### 5. Add focused technical validation

Add a focused smoke under the existing validation conventions and register it in `custodian/tools/validation/validation_manifest.json`.

The smoke must prove at minimum:

1. the shared sample exposes the exact required anchors;
2. A and B resolve those anchors identically;
3. both modes use the same 1280x720 camera transform/framing contract;
4. both modes use the same route extents/walkable test geometry;
5. Kenney presentation nodes do not own `CollisionObject2D`, navigation authority, world transition, campaign state, Operator state, or procgen state;
6. B can be disabled without changing A/runtime state;
7. debug scene is not referenced by production boot/world entry.

Prefer data/node assertions over screenshots.

### 6. Collect equivalent measurements

Use the same launch, camera, viewport, and observation interval for A and B.

Record:

- total node count;
- presentation node count;
- texture/resource count where practical;
- median frame time or FPS over a fixed interval;
- draw calls when available from stable Godot performance monitors;
- memory counters when available without invasive instrumentation;
- selected runtime-asset count;
- manual placement count or generated instance count;
- source selection/normalization/ingest steps that required human/manual intervention.

Do not build a profiler subsystem for this packet.

Write:

`custodian/docs/ai_context/reports/kenney_presentation/K3D1_ISOMETRIC_BLOCKOUT_REPORT.md`

### 7. Produce minimal visual evidence

Generate exactly:

- A capture: 1280x720;
- B capture: 1280x720;
- side-by-side composite: 2560x720.

Use the same camera transform and world sample.

Durable comparison artifact:

`custodian/docs/ai_context/reports/kenney_presentation/k3d1_ab_compare.png`

This image is evidence, not a production asset and does not enter Asset Pipeline V2.

Do not auto-approve aesthetic quality. The report should leave the following questions explicitly for the user:

- Which is more readable tactically?
- Which communicates Hub scale better?
- Does the miniature language feel usefully architectural or too toy-like?
- Are platform/edge depth cues helping or cluttering?
- Which pieces, if any, suggest a CUSTODIAN-specific future art vocabulary?

### 8. Closeout and handoff

Update `design/01_systems/KENNEY_PRESENTATION_FEASIBILITY_ROADMAP.md` with:

- K3D-1 landed SHA;
- exact selected asset counts;
- focused/changed validation results;
- measured A/B metrics;
- source inventory status;
- technical review status when available;
- current program position.

Do not author K3D-2 as ready from inside this implementation workstream.

## Documentation Drift Check

Before closeout, re-read the live dimensionality and asset authorities named in this packet.

If code and docs disagree about the current 2D runtime or Asset V2 image contract, record the exact drift in the K3D-1 report and make only a narrow factual repair if it is independent of the unresolved art-direction decision.

Do not edit `MASTER_DESIGN_DOCTRINE.md` to declare a 3D direction.

## Completion Truth

Before setting complete, populate the normal `custodian.task_completion.v1` receipt with exact yes/no scalars and concrete evidence.

## Execution Feedback

Before setting complete, populate the normal `custodian.task_feedback.v1` receipt and mirror it in the closing summary.

## Handoff

- Next workstream: `kenney-orthographic-3d-feasibility`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Refresh reason: `K3D-2 must be re-derived against the landed A/B evidence, selected-source reality, technical review, and the user's visual judgment before any 3D presentation architecture is frozen.`
- Next action: `Bring the K3D-1 report and 2560x720 A/B comparison back to the authoring chat, decide what K3D-2 must preserve/test, then author K3D-2 against current main.`
- Blockers or open questions: `none for K3D-1; K3D-2 intentionally waits for the post-K3D-1 design refresh.`
