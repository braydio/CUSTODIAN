# CUSTODIAN | Surface Material Lab: Normal & Height Maps | Full Buildout Roadmap V1

**Status:** approved program design and authored task-packet sequence; no production implementation or art approval implied.  
**Audit baseline:** braydio/CUSTODIAN main@ebfe3810eec146d7202a4378324b0f32c9e12fee (2026-11-08).  
**Authoring chat:** not-recorded (replace only with the exact user-supplied current conversation URL).  
**Implementation scope:** A deterministic offline bake and opt-in Godot material workflow for making a few approved sprites react convincingly to local light without changing their silhouette or surface gameplay geometry.

## Verified starting condition

WorldLightingDirector, LightingProfile, LightRig2D and Godot 4.7 CanvasItem rendering exist. Existing asset import is non-Operator Asset V2 and Operator specialized Workbench. Search did not establish any authored production-normal/heightmap pipeline; .png.import normal-map fields are import metadata, not proof of real approved surface maps.

## Intended gameplay/presentation payoff and operating mechanics

1. A normal map stores 2D tangent-space outward surface directions encoded in RGB; under a 2D light it lets an apparent rivet/crease/lintel turn bright or dark. A height map stores grayscale relative relief; on its own it does not add actual depth, collision or 3D geometry.
2. A versioned source-immutable baker accepts exact approved diffuse art and an optional separately reviewed artist-authored grayscale height source. From height it computes normalized gradients, controls strength/smoothing, edge handling, alpha-safe extrusion and tangent channel sign compatible with Godot 4.7. Brightness-to-height is a preview-only heuristic, never presumed true shape.
3. Source geometry remains pixel-exact with no rescale, no alpha matte, no cross-cell contamination and no baked lighting replacement. Batch work must preserve frame order/dimensions/anchors for animated input and hash-pin all source/profile inputs.
4. Generate 3 cheap preview modes for each trial: flat/original, normal-lit A/B and exaggerated debug normal directions. Reversible property changes; report pixel integrity, map channel/range, seams, gradient statistics and original/light result.
5. Proof integration uses Godot CanvasTexture normal_texture or a verified CanvasItem material seam on one existing light-rig environment prop; preserve native pixel filtering, lighting director and baseline diffuse path. Height-to-parallax or ambient occlusion is opt-in later and never required for v1.
6. Production routing is separately gated: if Asset V2 contracts support auxiliary maps, bind the verified role through one source of truth; otherwise first design a versioned semantic extension and migration. Do not direct-write arbitrary derived files into generated runtime directories.

## Core boundaries

**Preserve:** Original RGBA source masters and canonical runtime names, Operator source/animation authority, Asset V2 family schema and catalog, light rig behavior, nearest-neighbor pixel art, collision/traversal and no per-tile unique materials.

**Explicit non-goals:** No replacement for 3D sculpting, no automatic artistic approval, no true geometry displacement, no global lighting rewrite, no per-frame lighting animation authored in source PNGs, no gameplay changes.

**Measure success:** At least two distinct real approved sprites tested with fixed light positions and pixel-accurate A/B. Baker is hash-stable across two identical runs, outputs dimension-exact normal RGB/height L (plus agreed alpha handling), has no NaN/unbounded slopes or edge halos, and can be disabled to return the original rendering. Production adoption requires human preference for the normal-lit result at native scale.

**Art / Asset Pipeline V2:** No new source illustration is needed for the offline pipeline or first A/B. All baked images are disposable under ignored .ai/surface_material_lab/ until individually reviewed; any accepted normal/height auxiliary image must follow verified Asset V2 family role and exact original source/canvas dimensions. Do not invent family IDs or treat derived PNGs as approved art.

**Human-owned review:** A/B is a real gate: if the effect makes tiny sprites mushy, busy, inconsistent with black-gold art or visually noisier, keep the flat asset. Height-based parallax is not included in the default completion target.

## Dependency DAG and staged production

| Slice | Workstream ID | Deliverable | Depends on review | Visual decision |
|---|---|---|---|---|
| 1 | surface-normal-height-baker-v1 | Source-safe deterministic map baker | none | conditional |
| 2 | surface-normal-height-lighting-proof-v1 | One-scene Godot lighting A/B | review-surface-normal-height-baker-v1 | required |
| 3 | surface-normal-height-asset-v2-handoff-v1 | Review-gated production material binding | review-surface-normal-height-lighting-proof-v1 | required |

### 1. Source-safe deterministic map baker

**Implementation:** surface-normal-height-baker-v1  
**Independent review:** review-surface-normal-height-baker-v1  
**Dependency:** none  
**Primary locks:** surface-map-baker  
**Priority:** P2

**Change:** Add strict source hash + geometry verification, optional grayscale relief input, signed normal-gradient conversion, alpha/edge safety, nearest-neighbor pixel semantics, reproducible PNG/JSON outputs and three read-only comparison modes. Expose inspect/plan/bake/report with dry-run; never mutate approved diffuse/input files.

**Acceptance:** Two synthetic relief fixtures and one selected real approved input yield repeatable byte-identical maps; same width/height/frame grid/alpha masks, no channel overflow or matte, intentional flat-height produces neutral normal, corrupted/ambiguous path is refused, runtime unchanged.

**Validation:** custodian/tools/validation/asset_pipeline_cli_ux_smoke.py; custodian/tools/validation/asset_workbench_review_smoke.py; new pure baker gradient/channel/hash/alpha tests; changed-file validation.

**Next deferred:** Godot lighting trial and production Asset V2 map role; no parallax.

### 2. One-scene Godot lighting A/B

**Implementation:** surface-normal-height-lighting-proof-v1  
**Independent review:** review-surface-normal-height-lighting-proof-v1  
**Dependency:** review-surface-normal-height-baker-v1  
**Primary locks:** surface-map-lighting-proof  
**Priority:** P2

**Change:** Bind a map via Godot 4.7 CanvasTexture/light-compatible 2D resource, add flat/normal lit toggle, neutral light + moving light review, nearest filtering and fallback to flat. Evaluate two visually different approved sprites without touching their canonical Asset V2/runtime bindings.

**Acceptance:** Normal effect demonstrably reacts to an existing LightRig2D, does not alter silhouette, alpha, layer order or UI, and disabling returns exact diffuse baseline. Record native-scale ROI A/B and positive/negative human preference separately. No shared-material explosion.

**Validation:** custodian/tools/validation/lighting_system_smoke.gd; custodian/tools/validation/world_atmosphere_smoke.gd; new dev A/B scene and material-restore smoke; changed-file validation.

**Next deferred:** Universal material rollout and Asset V2 schema binding until explicit visual PASS.

### 3. Review-gated production material binding

**Implementation:** surface-normal-height-asset-v2-handoff-v1  
**Independent review:** review-surface-normal-height-asset-v2-handoff-v1  
**Dependency:** review-surface-normal-height-lighting-proof-v1  
**Primary locks:** surface-map-asset-v2, asset-pipeline  
**Priority:** P3

**Change:** Audit actual family support for normal/height roles. If supported, implement hash-bound diffuse-to-normal dependency, atomic review/ingest/status/doctor and consumer binding with rollback. If unsupported, stop at a proposed versioned schema amendment, validate compatibility and return for authoring approval before changing family files. Use the real Asset V2 owner; keep Operator specialized.

**Acceptance:** One explicitly approved non-Operator asset round-trips from immutable diffuse through accepted auxiliary-map contract to runtime CanvasTexture; stale source forces re-review; missing normal restores diffuse; all undo/rollback and generated/catalog checks pass. No unauthorized new schema.

**Validation:** custodian/tools/validation/asset_pipeline_cli_ux_smoke.py; custodian/tools/validation/asset_workbench_review_smoke.py; custodian/tools/validation/lighting_system_smoke.gd; new contract/consumer/rollback smoke; changed-file validation.

**Next deferred:** Parallax/displacement, broad automated conversions and unreviewed bulk art.

## Integration and file ownership

- New library code and tests are **planned outputs**, not already published runtime features. Workstream packets name the recommended repository-relative owners and exact focused baselines.
- Required inputs for each packet are this document plus the current-main source owners named in its Evidence section; no chat-only schemas, reference ZIPs or art are needed to claim the first slice.
- Every implementation stage gets a separate post-land fresh-context review. The implementation workstream does not self-approve its review. Only the first implementation/review pair opts in to automatic authoring preflight; successors remain draft/manual pending predecessor review and a refreshed repository/claim audit.
- Before any new production texture, family or runtime art route, inspect design/04_architecture/ASSET_PIPELINE_V2.md, the registered family schema and the actual consumer. New art requires source/alpha/dimension/animation contracts, human review, and explicit source_work/inbox routing.
- Deterministic tests and source/geometry/contracts precede visual inspection. Material aesthetic decisions require a minimal ROI/short-motion handoff. The default is no new full-screen recording or unnecessary LFS generation.

## Documentation drift and change hygiene

Do not interpret generic .png.import normal_map/invert_color properties as a production map inventory. Older image pipeline notes with generated runtime filenames require reconciliation against current Asset V2 and Operator specialized ownership before binding secondary textures.

This document is a forward plan, not a claim that every planned stage is implemented. On each stage closeout, reconcile impacted live design, CURRENT_STATE.md, FILE_INDEX.md, actual code, test ownership and asset registry truth. Do not rewrite unrelated historical state or bypass independent reviews.

## Release / stop conditions

1. Never assume a partial implementation is ready/auto without the current packet authoring preflight and remote publication receipts.
2. The review of every stage must archive PASS before the dependent stage becomes claimable. A review finding keeps the original workstream identity and enters its bounded correction/re-review lifecycle.
3. A human/ChatGPT visual decision is mandatory for final subjective polish; technical PASS does not imply aesthetic approval.
4. If a new runtime gameplay authority, unapproved art family, or incompatible schema is necessary, stop and return the smallest explicit decision/proof to the authoring chat instead of silently inventing ownership.
