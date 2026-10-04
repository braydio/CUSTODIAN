# KENNEY PRESENTATION FEASIBILITY ROADMAP

**Program ID:** `kenney-presentation-feasibility`  
**Status:** active / K3D-1 implementation complete, technical review pending
**Priority:** P2  
**Reviewed main:** `cf3ba2eb219e`  
**Last Updated:** 2026-10-03  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff  
**Program authority:** this roadmap  
**Related design authority:** `design/00_meta/MASTER_DESIGN_DOCTRINE.md`, `design/01_systems/CAMERA_SYSTEM.md`, `design/04_architecture/HUB_FIRST_SET_BLOCKOUT.md`

## Purpose

Determine which presentation path gives CUSTODIAN the best combination of tactical readability, architectural scale, production efficiency, performance, and reversibility without prematurely rewriting the production runtime.

This is an experiment tracker, not a production-direction change. The live game remains the current 2D runtime with fixed-isometric / 2.5D design intent until a later explicit design decision changes that contract.

The program compares four controlled artifacts:

- **A — current CUSTODIAN-native 2D baseline**
- **B — Kenney Isometric Miniature 2D blockout over the same spatial sample**
- **C — orthographic real-3D Kenney blockout driven by the same 2D spatial/simulation truth**
- **D — 3D-authored-to-2D asset-production test using Kenney Shape and/or Asset Forge**

Retro Fantasy and Retro Urban are deliberately excluded from this roadmap until separate art-direction discussion accepts a role for them.

## Expected Packet Count

**Expected implementation task packets: 3.**

Paired review and correction packets are not counted in the three.

| Slice | Workstream | Artifact | State |
| --- | --- | --- | --- |
| K3D-1 | `kenney-isometric-blockout-feasibility` | A + B: current 2D baseline versus Isometric Miniature 2D blockout | **implemented / paired review pending** |
| K3D-2 | `kenney-orthographic-3d-feasibility` | C: orthographic 3D presentation over preserved 2D spatial truth | planned |
| K3D-3 | `kenney-3d-to-2d-production-feasibility` | D: Shape / Asset Forge production test plus final decision matrix | planned |

Do not pre-author K3D-2 or K3D-3 against speculative APIs. Re-derive each against landed predecessor evidence and this authoring chat.

## Local Source Inputs

The user reports the recommended Kenney archives are already present in `~/Downloads`. K3D-1 must inventory the actual local filenames and pack contents before selecting files.

Expected pack identities:

1. Isometric Miniature Prototype
2. Isometric Miniature Bases
3. Prototype Kit
4. Modular Space Kit
5. Space Station Kit
6. Factory Kit
7. City Kit: Industrial

Archive filenames are not authoritative. Match pack identity from filename and extracted metadata/readme/license where available. Do not fail merely because Kenney used a different ZIP filename than expected.

Do not commit the full downloaded archives or wholesale extracted packs.

K3D-1 matched all seven expected pack identities from their local ZIP metadata and bundled licenses. The source inventory, including archive hashes and the selected-source manifest, is `custodian/docs/ai_context/reports/kenney_presentation/k3d1_source_inventory.json`. A duplicate Space Station Kit download was byte-identical and counted once; the additional Kenney Shape archive is recorded for K3D-3 and excluded from the seven-pack K3D-1 set.

## Shared Spatial Sample

Use a detached debug/evaluation surface derived from the current first-set spatial authority, not the production Hub scene itself.

The sample must include enough of the South Reach / Witness Plaza → North Processional → Forum South → Adjudication Dais approach to judge scale and processional architecture. Preserve the current 32 px authored cell and the same world-space anchors across A, B, and later C.

At minimum preserve:

- `Spawn_SouthReach=(-6,162)`
- Forum South marker `(0,-2464)`
- Adjudication Dais `(0,-3136)`
- the current South Reach / Witness Plaza presentation footprint needed to establish the approach

If the live H1 Hub layout has landed before execution, consume its read-only layout constants where practical. Otherwise derive the sample from `HUB_FIRST_SET_BLOCKOUT.md`. In either case, the experiment must not become a second production layout authority.

The experiment must not edit Hub collision, navigation, world-transition, campaign, or H1 blockout behavior.

## Comparison Contract

Every presentation variant must preserve the same semantic sample:

- identical named anchors and route extents;
- identical Operator start/end positions where an Operator is used;
- identical 1280x720 evaluation viewport;
- equivalent camera transform/framing for comparison captures;
- no variant-specific collision or navigation advantage;
- no production world-state mutation.

Objective measurements come before subjective visual judgment.

Record at minimum:

1. anchor/world-coordinate parity;
2. scene/node count and texture or mesh count;
3. median frame time and renderer draw-call counters over the same fixed observation interval when available;
4. import/runtime memory counters when available without invasive tooling;
5. production asset count and manual placement count;
6. any occlusion or route-readability defect that can be proven structurally;
7. one deterministic comparison artifact at the end of each slice.

Human-owned evaluation dimensions:

- tactical readability;
- sense of scale;
- architectural legibility;
- visual depth;
- atmosphere;
- perceived clutter/occlusion;
- whether the presentation still feels like CUSTODIAN.

Agents may report observations but must not choose the winning art direction.

## K3D-1 — Isometric Miniature Blockout

**Goal:** establish the apples-to-apples 2D comparison and prove the source-pack intake path.

Use **Isometric Miniature Prototype** and **Isometric Miniature Bases** only for the visual blockout. Inventory all seven packs for later slices.

Selected Kenney PNG inputs are experimental CUSTODIAN assets and therefore must use Asset Pipeline V2 rather than being copied directly into runtime content.

### Experimental asset families

Family 1:

- ID: `kenney_iso_miniature_prototype_ref`
- kind: `tile`
- runtime owner: `kenney_iso_miniature_prototype_ref`
- runtime domain: `tiles/experiments/kenney_feasibility`
- direction policy: `omni`
- animation: false
- frame count: 1 per selected state
- alpha: preserve source alpha
- source/runtime pixel dimensions: preserve each selected source image exactly; record exact dimensions after inventory and use per-state frame-size overrides where required by the live V2 contract

Family 2:

- ID: `kenney_iso_miniature_bases_ref`
- kind: `tile`
- runtime owner: `kenney_iso_miniature_bases_ref`
- runtime domain: `tiles/experiments/kenney_feasibility`
- direction policy: `omni`
- animation: false
- frame count: 1 per selected state
- alpha: preserve source alpha
- source/runtime pixel dimensions: preserve each selected source image exactly; record exact dimensions after inventory and use per-state frame-size overrides where required by the live V2 contract

Source-work roots:

- `custodian/asset_drop/source_work/experiments/kenney_presentation/kenney_iso_miniature_prototype_ref/`
- `custodian/asset_drop/source_work/experiments/kenney_presentation/kenney_iso_miniature_bases_ref/`

Each selected unprocessed source must be renamed:

- `<semantic_state_id>_source.png`

Normalized inbox roots:

- `custodian/asset_drop/inbox/kenney_iso_miniature_prototype_ref/`
- `custodian/asset_drop/inbox/kenney_iso_miniature_bases_ref/`

Each normalized file must be:

- `<semantic_state_id>.png`

Family contracts:

- `custodian/content/metadata/assets/families/kenney_iso_miniature_prototype_ref.asset.json`
- `custodian/content/metadata/assets/families/kenney_iso_miniature_bases_ref.asset.json`

Use `schema: custodian.asset_family.v2` and the current live `tile` kind schema. Define states only for the bounded subset actually selected after source inventory. Use semantic lowercase state IDs based on observed role. Do not stretch or resample artwork to force common dimensions.

Target **12–20 total selected PNGs**, hard cap **24**, across the two isometric packs. Cover the smallest useful vocabulary such as platform/base, straight edge, corner, wall/mass, stair/ramp, column/vertical cue, threshold/gate, and simple civic-volume pieces when those roles exist in the packs.

K3D-1 exits with:

- complete seven-pack inventory report;
- bounded selected-source manifest for the two isometric packs;
- both experimental families ingested/verified through Asset V2;
- one detached A/B debug comparison surface;
- structural parity smoke coverage;
- one `2560x720` A/B comparison image composed from two `1280x720` captures at the same camera transform;
- objective measurement report;
- no production Hub or gameplay behavior changed.

## K3D-2 — Orthographic 3D Presentation Spike

Re-derive after K3D-1 technical review and user/ChatGPT planning refresh.

Build C using a bounded subset of Prototype Kit, Modular Space Kit, Space Station Kit, Factory Kit, and City Kit: Industrial.

The intended architecture to test is:

```text
2D deterministic spatial/simulation truth
→ presentation adapter
→ XZ 3D placement
→ orthographic Camera3D
```

Do not migrate combat, collision, navigation, procgen, save state, or world authority to 3D in this slice.

The 3D spike must reproduce the same sample/anchors used in K3D-1 and collect the same comparison metrics. It must also record occlusion behavior, lighting/shadow readability, import cost, and whether existing 2D Operator presentation can coexist cleanly with the 3D environment.

If production adoption of GLB/mesh assets is proposed, K3D-2 must document and, only if needed for the experiment, narrowly prototype the missing mesh/GLB Asset V2 contract rather than forcing mesh content through PNG semantics.

## K3D-3 — Shape / Asset Forge 3D-to-2D Production Test

Re-derive after reviewed K3D-2 and user/ChatGPT planning refresh.

Create one small representative CUSTODIAN hard-surface asset family through a 3D authoring path, then render normalized 2D outputs for the existing runtime.

Representative subject should exercise silhouette, face depth, and material grouping, such as a civic console, locker, relay housing, hardstand fixture, or similarly bounded prop. Do not use the Operator or another character as the first Shape test.

Test:

- Kenney Shape where pixel/depth extrusion is appropriate;
- Asset Forge if available for modular construction and fixed-camera sprite rendering;
- repeatable camera/projection;
- repeatable palette/material treatment;
- output alpha and registration;
- time/steps from source construction to Asset V2 verified runtime asset.

The final K3D-3 report must compare three viable production directions:

1. current 2D-native art;
2. 3D-authored / 2D-rendered art;
3. live orthographic 3D presentation over 2D simulation.

Do not change `MASTER_DESIGN_DOCTRINE.md` until the user explicitly selects a production direction.

## Validation Strategy

For all slices:

1. prove coordinate/state/asset contracts first;
2. run the narrow focused smoke for the experiment;
3. run current Asset V2 plan/status/doctor checks for any ingested experimental families;
4. run changed-file validation once at closeout;
5. generate only the minimum deterministic visual evidence required for the human comparison.

Do not use full-motion capture unless a later slice identifies a motion/occlusion question that still cannot be answered from structured evidence and a fixed comparison image.

## Program End

This program is complete only when A–D exist, or a slice produces decisive evidence that makes a later artifact unnecessary, and the user has enough evidence to choose or reject a future presentation direction.

A final choice must explicitly state whether CUSTODIAN will:

- remain 2D-native;
- adopt 3D-authored-to-2D production for selected asset classes;
- adopt an orthographic 3D presentation layer while preserving 2D simulation;
- or continue experimentation.

Rejected experimental runtime assets/families must be removed or explicitly retained as non-production references in the closeout slice. No experimental Kenney asset may silently become production canon merely because it exists in the repository.

## Documentation Drift Check

Current live docs are compatible but imprecise about dimensionality:

- `MASTER_DESIGN_DOCTRINE.md` describes CUSTODIAN as 2.5D isometric with fixed isometric presentation.
- `CAMERA_SYSTEM.md` describes a top-down tactical `Camera2D` runtime.
- `AUTHORED_TILED_ROOM_PIPELINE.md` states the runtime is fundamentally 2D and stairs link separate 2D floors.
- `terminal_planet_preview.gd` proves a bounded `Node3D / MeshInstance3D / Camera3D` path can coexist inside the project.
- Asset Pipeline V2 currently routes supported asset kinds through PNG/image semantics; there is no production mesh/GLB family kind.

Treat those as current truth during the experiment. Do not "repair" them into a 3D commitment. Record any newly discovered contradiction in the slice report and route a real design-authority change back through this program.

## Current Program Position

**Current slice:** K3D-1 `kenney-isometric-blockout-feasibility`  
**State:** Implemented against `main@9093c9ff1613`; H1 remains in progress, so the experiment reads locked Forum geometry from design and Road visuals from `RoadOfWitnessesPrototype.MODULES`. Seven expected pack identities were matched, 16 selected images passed Asset V2 ingestion and source/runtime pixel checks, and fixed-camera A/B evidence is recorded in `custodian/docs/ai_context/reports/kenney_presentation/`.
**Next gate:** complete the paired technical review, then return to the authoring chat with the A/B comparison and measurements before K3D-2 is authored.
**Expected remaining implementation packets after K3D-1:** 2.
