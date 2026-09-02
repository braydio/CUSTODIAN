# Operator Art Agent System

## Status

**V2 semantic repair workstation plus reference/palette hardening implemented; canonical publication remains external.**

This document defines the long-horizon architecture and phased delivery plan
for an agent-operated Operator art workstation. V1 now provides guarded,
deterministic editing and visual inspection of existing Workbench V2 documents.
V2 adds confined capabilities, semantic landmarks and masks, non-destructive
draft layers, metrics/QA, review packets, richer renders, and a thin local MCP
adapter. Publication and pose synthesis remain explicit later graduations.

The canonical V2 acceptance runner is `operator art pilot` (also
`python3 custodian/tools/validation/operator_art_agent_v2_pilot.py`). It opens
the real eight-frame east Vigil walk, persists fixture-provenance landmarks and
near/far leg masks through public services, shifts the far leg in a draft,
temporarily bakes and performs bounded pixel cleanup, emits a review packet,
then restores the Workbench byte-exactly. Protected Operator source, runtime,
generated data, actor resources, and sockets are hashed before and after. The
runner never publishes; engineering PASS and art-capability status are separate.

### Reference, transition, and palette hardening

Sessions resolve immutable canonical references only by semantic identity,
render target-tail/reference-head transition comparisons, and can persist an
edit scope enforced at the shared mutation boundary. Palette reports sort
deterministically by sRGB luminance and RGB. Recoloring follows hash-locked
plan, explicit ambiguity resolution, non-mutating preview, plan-id-only atomic
apply, and review. Destination colors come from the reference palette or are
explicitly preserved; mappings are animation-wide and alpha/silhouette hashes
must remain exact. Source Session recolor writes a separate registered
candidate and never overwrites its original or converter candidates.

### Implemented V2 capability

V2 hardens the `.ai` boundary with resolved path containment, per-session
capability sidecars, a strict request/response handshake, idempotent operation
keys, numeric/cel validation, and true no-op handling. Pure-Python safety and
semantic validation run even when Aseprite is unavailable.

Operator anatomy is expressed as near/far landmarks and scanline-RLE part
masks. Semantic shifts, copies, replacements, and mirrors first create
`__ART_DRAFT__*` layers; source bindings do not change until an explicit bake.
Every draft is registered as an immutable `DraftRecord` (source/destination
mask, layer, frame, and fingerprints) the moment it is created. Baking a draft
takes only its `draft_id` — the caller cannot redirect a draft at a different
mask, layer, or frame — and each kind clears different pixels at bake time:
`shift`/`mirror` clear the original source region, `copy` clears nothing, and
`replace` requires a second destination mask and clears only that mask's
region. A draft whose source, destination, or draft-layer pixels changed since
creation fails closed instead of baking. Draft discard and Workbench backup
undo remain exact.

Landmark and mask staleness are frame-local: each frame's own render
fingerprint is compared independently, so editing one frame cannot mark
landmarks or masks stale on unrelated frames. Masks validate against
`operator_part_schema.json` and reject malformed/out-of-canvas/empty
polygons and rectangles before ever reaching Aseprite; masks carry a
persisted `CURRENT`/`STALE` status and support union/subtract/intersect/
dilate/erode/alpha-region derivation with parent tracking. QA covers seven
finding classes — structural, registration, anatomy, pixel_art, animation,
weapon, and semantic (stale masks/landmarks/drafts, unresolved gap repair) —
and metrics report real per-trajectory loop-seam displacement instead of a
first-frame-vs-last-frame SHA comparison. Uncalibrated artistic measurements
stay advisory; `publish_authorized` is `false` unconditionally. Reference
assembly also resolves same-direction idle-ready posture and locomotion
walk/run siblings deterministically (never by mtime or filename recency), and
`profile_measure.py` bootstraps provisional style-profile numbers from an
explicit canonical sample set that nothing auto-accepts. The local stdio MCP
adapter exposes the same service through explicit per-tool JSON schemas
(`additionalProperties: false`, enforced at dispatch time) and contains no
publish, git, shell, or arbitrary filesystem tool.

### Implemented V1 capability

`operator art` starts a semantic session under `.ai/operator_art_agent/` and
reuses `animation_workbench.ensure()` rather than resolving source itself. It
supports inspect, Aseprite-composite render, exact paint/erase, deterministic
integer square-brush strokes, same-layer cross-frame copy, overlap-safe region
move, close, and byte-exact latest undo.

Every mutation requires a non-stale/no-migration Workbench, a process lock, an
expected document SHA, an editable manifest binding, a valid timeline slot, an
unchanged cel placement, and document coordinates inside the binding rectangle.
Lua rechecks those boundaries independently. Python takes a complete workbench
backup, journals the request/response and hashes, and restores the backup on
bridge failure. Render output includes transparent frames, a strip, a contact
sheet, baseline diff, and before/after sheet.

Neither V1 nor V2 has canonical publish, runtime rebuild, frame/timing
mutation, resize, rotation, socket mutation, embedded image-model, or automatic
commit capability.

## Source Session subsystem

Incoming high-resolution PNGs use a separate pre-canonical Source Session under
`.ai/operator_art_agent/source_sessions/`; they are never opened as permissive
Workbench documents. Source paths are confined to `asset_drop/inbox` and
`asset_drop/source_work`. A session stages an immutable copy, records its hash
and fixed sheet geometry, analyzes every frame, then asks the existing pixel-art
converter for one shared crop, scale, and placement across the complete sheet.

Normalization owns exactly one `global_scale`. Per-frame registrations contain
integer `dx`/`dy` only, are bounded to ±12 pixels, and fail when the translation
would clip visible pixels. The converter's CLI and programmatic API share the
same preparation and candidate-generation core. Crisp, balanced, and clustered
candidates remain review artifacts; selecting one copies it to the session's
`registered/candidate.png`. Review produces frame metrics, a contact sheet,
silhouette sheet, and GIF. Handoff may copy only a passing reviewed candidate to
the Operator asset-drop inbox; it does not write canonical source, generated
runtime output, or invoke Workbench publication.

Normalization geometry protects the shared animation envelope. When reviewed
body landmarks are available, registration should prefer support-foot contact,
hip center, then head center. Antennae, shields, muzzles, cloak tips, and other
peripheral equipment protect against clipping but must never independently
determine per-frame character scale.

## Objective

The target is not an MCP pixel-painting server. The target is an autonomous,
auditable character-animation production system that can inspect semantic
Operator animation contracts, work inside disposable Aseprite sessions,
observe and critique rendered results, validate modular/runtime composition,
and eventually publish through the existing transactional pipeline.

A mature invocation should support a request such as:

> Complete the Operator `melee_1h` locomotion suite in the approved elevated
> three-quarter perspective, preserve Vigil dagger presentation, repair
> proportion drift, create missing directions, preview in Godot, and publish
> only artifacts that pass structural, visual, modular, weapon, and runtime QA.

The intended production loop is:

```text
request
  -> semantic inventory and source resolution
  -> durable art task and reference assembly
  -> disposable Workbench V2/V3 session
  -> pose/timing plan
  -> journaled Aseprite edits
  -> rendered observation and independent critique
  -> bounded repair iterations
  -> structural, art, modular, and weapon QA
  -> runtime build, Godot import, and focused validation
  -> Moment Forge playback and final review
  -> transactional publish through Workbench
  -> task-scoped commit
```

## Existing authority to preserve

The Art Agent is built above, not instead of:

- `custodian/tools/operator/animation_workbench.py`
- `custodian/tools/operator/animation_workbench_model.py`
- `custodian/tools/operator/animation_frame_contract.py`
- `custodian/tools/aseprite/operator_animation_workbench.lua`
- `custodian/tools/operator/operator_cli.py`
- the canonical Operator source PNG grammar and generated runtime/catalog
  pipeline

Workbench V2 remains the provenance, stale-source, dependency, transaction,
rollback, rebuild, import, and publication authority. Canonical PNGs remain
source authority. Aseprite documents and all Art Agent task data remain
disposable work surfaces outside `res://`.

```text
Codex / human / future client
             |
       CLI or thin MCP
             |
      ArtAgentService
       /     |      \
 planner  visual QA  reports
       \     |      /
       Workbench service
             |
       Aseprite bridge
             |
  canonical PNG publication gate
             |
 runtime build -> Godot -> validation
```

## Non-negotiable boundaries

1. Canonical Operator PNGs remain authority.
2. MCP handlers contain no art, publication, source-resolution, or shell logic.
3. No MCP mutation tool writes canonical source or generated runtime output.
4. Workbench is the sole canonical publication and rollback gate.
5. Autonomous mutations occur only in manifest-authorized `.ai` sessions.
6. Every mutation is bounded, journaled, hash-addressed, and reversible.
7. Agent-created layers use reserved names and never publish unless an explicit
   publish binding authorizes them.
8. Reference, guide, landmark, annotation, and critic layers never export.
9. Semantic animation identity cannot be changed by pixel-edit operations.
10. Gameplay timing, speed, transitions, hit windows, stamina, movement,
    collision, damage, and simulation state are outside Art Agent authority.
11. Frame-count changes remain dependency-audited Workbench migrations, never
    an incidental consequence of drawing.
12. Weapon presentation follows body-owned pose and authored socket/grip
    contracts; the Art Agent cannot silently transfer gameplay ownership.
13. Pixel edits are integer-grid native. Resampling, filtering, fractional
    transforms, and arbitrary smooth rotation fail closed unless a future
    explicit contract allows them.
14. No publication claim may rely on structural validation alone. Runtime-scale
    visual review is mandatory for motion, perspective, or readability work.
15. An autonomous queue is bounded by an explicitly approved profile/scope and
    cannot discover its own authority to publish unrelated assets.

## Product surfaces

### Shared service

All clients call one typed `ArtAgentService`. It owns task/session lifecycle,
semantic planning, bridge requests, observation products, QA orchestration,
and Workbench delegation.

### CLI

The reproducible automation surface extends the existing Operator CLI:

```bash
operator art doctor
operator art inspect melee_1h locomotion run_01 e
operator art task melee_1h locomotion run_01 e \
  --weapon vigil_pattern_dagger \
  --goal "convert to elevated three-quarter perspective"
operator art author <task-id>
operator art review <task-id>
operator art critique <task-id>
operator art repair <task-id> --until-green
operator art runtime-preview <task-id>
operator art publish <task-id> --dry-run
operator art publish <task-id>
operator art autopilot --profile melee_1h --required
```

Commands unavailable at the current phase must report `NOT_IMPLEMENTED` rather
than pretending to succeed.

### MCP server

The local MCP server is named `operator-art`. It is a thin adapter over the
same service and models used by the CLI. It must be local-only by default,
path-allowlisted to repository and `.ai` task roots, reject arbitrary commands
and arbitrary filesystem paths, and return structured errors and artifact
links rather than console prose.

Changing agent providers, the TUI, or MCP transport must not change production
art semantics.

## Capability model

### Observation tools

```text
open_animation
inspect_document
inspect_layer
inspect_frame
sample_pixel
sample_palette
snapshot
render_frame
render_layer
render_composite
render_strip
render_contact_sheet
render_onion_skin
render_silhouette
render_reference_compare
compare_frames
compare_reference
get_frame_metrics
get_landmarks
validate_animation
publish_dry_run
```

### Primitive mutation tools

```text
paint_pixels
brush_stroke
erase_pixels
draw_line
flood_fill
copy_region
move_region
mirror_region
replace_color
create_frame
duplicate_frame
delete_frame
set_frame_duration
create_layer
clear_layer
copy_cel
set_landmarks
save
undo_operation
```

Direct pixel mutation must clone the target cel image, edit the clone, and
replace the cel image inside an Aseprite transaction so undo state and journal
state agree.

### Semantic mutation tools

Later phases may add intent-bearing operations:

```text
shift_part
copy_part
replace_part
repair_seam
move_far_foot
adjust_knee
normalize_head_scale
shift_weapon_grip
close_waist_seam
redraw_cloak_tip
```

The service resolves semantic part/mask/frame/bounds data. The agent supplies
the artistic decision; it does not invent unrestricted pixel coordinates when
a semantic operation is available.

## Durable art task

Every job lives under:

```text
.ai/operator_art_agent/<task-id>/
```

Minimum layout:

```text
task.json
plan.json
references.json
landmarks.json
operations.jsonl
observations.jsonl
critic.jsonl
validation.json
publish_transaction.json
previews/
reports/
```

`task.json` records goal, semantic identity, source/publish contracts,
constraints, autonomy level, approved scope, publish policy, current phase,
resume cursor, and Workbench context fingerprint. Task IDs are stable and task
state is restartable. `.ai` state never becomes production authority.

Every mutation journal entry includes at least:

```json
{
  "operation_id": 491,
  "frame": 3,
  "layer": "upper_body",
  "bounds": [34, 27, 18, 31],
  "action": "paint_pixels",
  "before_hash": "...",
  "after_hash": "...",
  "undoable": true
}
```

## Aseprite deterministic editing bridge

Add:

```text
custodian/tools/aseprite/operator_art_agent.lua
```

The bridge accepts versioned JSON requests and emits versioned JSON responses.
It validates document/session identity, editable-layer allowlists, frame and
bounds limits, expected before-hashes, and operation IDs before mutation.
Requests are idempotent: replaying a completed operation returns its recorded
result without applying it twice.

Bridge responsibilities are intentionally narrow:

- inspect sprites, frames, layers, cels, palette, and pixels;
- execute deterministic integer-grid edits inside transactions;
- create/delete only explicitly authorized temporary frames/layers;
- render requested observation artifacts;
- save disposable Aseprite state;
- return exact pixel/document hashes and changed bounds.

It cannot resolve canonical sources, choose art intent, run arbitrary Lua,
publish, invoke Git, or write outside its manifest-authorized workspace.

## Machine-readable Operator art profile

Create human and tooling authorities together:

```text
design/02_features/animation/OPERATOR_ART_STYLE_BIBLE.md
custodian/content/data/operator/authoring/operator_art_profile.json
custodian/content/data/operator/authoring/operator_direction_projection.json
custodian/content/data/operator/authoring/operator_landmark_schema.json
```

Numbers are not guessed during roadmap implementation. They are bootstrapped
from reviewed canonical frames, reported with sample provenance and confidence,
then explicitly accepted before enforcement.

The profile eventually covers:

- canvas classes and registration pivot/baseline;
- perspective mode and directional near/far conventions;
- hood, visor, torso, shoulder, hip, limb, boot, cloak, and trim geometry;
- outline weight, lighting direction, palette groups, alpha rules, and allowed
  antialias behavior;
- per-direction authored/mirrored/contract-resolved ownership;
- hand/grip, weapon tip, support-hand, weapon angle, and z-order conventions;
- tolerances for scale, baseline, centroid, landmark, seam, and trajectory
  continuity.

## Authoring landmarks

Landmarks are session metadata, not a runtime skeleton and not production
pixels. The initial schema should support:

```text
head_center, hood_top
shoulder_near, shoulder_far
elbow_near, elbow_far
hand_near, hand_far
hip_near, hip_far
knee_near, knee_far
ankle_near, ankle_far
toe_near, toe_far
cloak_tip_1, cloak_tip_2
weapon_grip, weapon_tip
```

Every landmark stores frame, point, semantic side, confidence, provenance, and
whether it was inferred or human-approved. Low-confidence inference may inform
critique but cannot fail publication until calibrated.

## Operator pose rig

Add a drafting-only Operator cutout rig under:

```text
custodian/tools/operator/art_rig/
```

It should adapt the existing named humanoid scaffold into reviewed Operator
parts: head, torso, near/far upper/lower arms and hands, near/far thighs/shins/
feet, cloak parts, and weapon reference. Part masks and integer transforms may
produce a rough pose; agent pixel cleanup produces the candidate frame.

The rig is never canonical art, never runtime authority, and never exported.

## Animation plans and recipes

Recipes live under:

```text
custodian/tools/operator/art_recipes/
```

Initial recipes: `run`, `walk`, `idle`, `fast_attack`, and `heavy_attack`.
Recipes define animation grammar rather than artwork: loop behavior, preferred
frame count, named phases, required landmarks, trajectory expectations, and
QA tolerances.

Before mutation, the planner emits an `AnimationPlan` with semantic identity,
frame phases, pose intent, leading limbs, body offsets, perspective constraints,
reference dependencies, weapon rules, and immutable gameplay constraints.

## Reference intelligence

For a requested animation, reference assembly should resolve exact provenance
for the same direction neutral pose, matching lower/upper layers, posture,
weapon presentation, nearest related action, canonical head/hood, neighboring
direction where contractually relevant, and current runtime composite.

Reference selection is deterministic and semantic. Modification time, filename
recency, directory order, arbitrary glob choice, and archives never select
authority. Every reference records why it was selected and whether it is
canonical, generated, drafting-only, or review-only.

## Visual observation and critique loop

The minimum useful system is iterative:

```text
edit -> render -> observe -> critique -> repair -> render
```

Preview output includes:

```text
strip.png
contact_sheet.png
animation.gif
onion_skin.png
silhouette.png
reference_compare.png
```

Artist and critic contexts are logically separated. A critic receives a fresh
snapshot, immutable constraints, references, numeric QA, and rendered images.
It returns structured, localized defects with frame, severity, bounds/landmarks,
evidence, and repair intent. It cannot mutate art or lower acceptance thresholds.

Repair iteration is bounded by configured attempts, wall time, and changed-pixel
budget. Exhaustion yields `NEEDS_HUMAN_REVIEW`; it never publishes by optimism.

## Human annotation

An optional non-exporting `__REVIEW_NOTES` layer supports direct art direction.
The initial convention is:

- red: wrong/remove/repair;
- cyan: target/move here;
- yellow: preserve.

`operator art ingest-notes` extracts frame-local connected regions and records
them as review observations. Annotation color semantics are configurable and
the layer is forbidden from every export/publish binding.

## Art QA

Add:

```text
custodian/tools/operator/art_agent/qa.py
```

QA has five distinct layers.

### Structural QA

- exact dimensions, frame count, alpha, strip layout, editable layers, and
  source/publish contracts;
- no bleed, accidental background, unknown export layer, stale source, or
  unexpected changed bounds;
- existing Workbench and runtime production validations remain authoritative.

### Registration QA

- baseline, alpha bounds, centroid, head, hip, height, and width continuity;
- tolerances come from accepted art profile/recipe data, not hardcoded guesses.

### Anatomy QA

- continuity of head scale and upper/lower limb lengths using landmarks;
- perspective-aware near/far tolerances and explicit confidence handling.

### Pixel-art QA

- isolated noise, unexpected semitransparency, palette outliers, outline gaps,
  accidental resampling, filtering, or soft antialiasing.

### Animation QA

- head, hip, feet, grip, weapon tip, and cloak trajectories;
- duplicate/reversed frames, foot teleporting, excess bob, weapon popping,
  body-scale drift, static secondary motion, and loop discontinuity.

Numeric QA assists judgment; it does not claim aesthetic correctness by itself.

## Modular and weapon-aware authoring

Later phases coordinate lower body, upper body, cape, head, weapon, and FX
without transferring ownership. QA must cover waist seams, synchronized clocks,
grip welding, weapon orientation, near/far arm z-order, tip trajectory, and
runtime composite popping.

For ranged weapons, calibrated metadata may include grip, support grip, muzzle,
ejection, angle, and z. Metadata changes use their existing owner and validation
path and require an explicit task scope; pixel authoring alone cannot change
socket authority.

## Creation mode and Workbench V3 extension

Workbench V2 edits an existing authoritative source. Creation mode is a later,
additive Workbench capability—not a rewrite.

A creation session has no source contract and an explicit proposed publish
contract. Publication must verify that the target does not exist, validate the
candidate, write the new canonical source transactionally, rebuild/import/test,
and delete the newly created source during rollback if any mandatory stage
fails. Existing-target races fail closed.

Creation mode cannot graduate until an intentionally absent fixture proves
successful publish and exact rollback restoration.

## Autonomy levels

| Level | Authority |
| --- | --- |
| Inspect | Read-only semantic inspection, rendering, comparison, and QA. |
| Draft | Mutate only an approved `.ai` task/workbench. |
| Produce | Plan and iterate autonomously inside the approved task budget. |
| Publish | Publish one explicitly requested identity through Workbench after all gates pass. |
| Autopilot | Process an explicitly approved bounded profile/scope queue and publish only under its stated policy. |

Default is Inspect. Each elevation is explicit and recorded in `task.json`.
`green_auto` may exist only for a bounded approved identity/scope and never
bypasses publish dry-run, structural QA, runtime QA, visual review artifacts,
or Workbench rollback.

## Runtime validation and reports

Publication is incomplete until production rebuild/import/resource validation
passes. Animation changes whose acceptance depends on motion, perspective,
weapon readability, or cadence also run the smallest relevant Moment Forge
scenario and inspect the runtime-scale result.

Each publish candidate produces:

```text
reports/operator_art_agent/<task-id>/
  before.png
  after.png
  overlay.png
  contact_sheet.png
  animation.gif
  metrics.json
  operations.json
  report.html
```

The report shows per-frame before/after/difference, localized critic findings,
registration/palette/seam/weapon/runtime results, source and candidate hashes,
Workbench transaction state, validation commands, and unresolved review items.

## Planned file layout

```text
design/02_features/animation/
  OPERATOR_ART_AGENT_SYSTEM.md
  OPERATOR_ART_STYLE_BIBLE.md
  OPERATOR_ANIMATION_RECIPES.md

custodian/tools/operator/art_agent/
  __init__.py
  service.py
  models.py
  planner.py
  references.py
  landmarks.py
  pose.py
  qa.py
  critic.py
  publisher.py
  report.py
  mcp_server.py

custodian/tools/operator/art_recipes/
  run.json
  walk.json
  idle.json
  fast_attack.json
  heavy_attack.json

custodian/tools/aseprite/
  operator_art_agent.lua
  operator_art_rig.lua

custodian/content/data/operator/authoring/
  operator_art_profile.json
  operator_direction_projection.json
  operator_landmark_schema.json

custodian/tools/validation/
  operator_art_agent_smoke.py
  operator_art_quality_smoke.py
  operator_art_publish_smoke.py
  operator_art_mcp_smoke.py
```

## Roadmap

### Phase 0 — Canon and boundaries

**Deliverables**

- this design authority;
- `OPERATOR_ART_STYLE_BIBLE.md` skeleton with explicit unknowns;
- typed task, operation, observation, artifact, error, autonomy, and capability
  schemas;
- security/path/authority threat review for local MCP and Lua execution;
- documentation ownership and validation routing.

**Exit criteria**

- canonical PNG and Workbench publication authority are unambiguous;
- no mutation path can bypass `.ai`, layer/cel allowlists, journaling, or hashes;
- gameplay and frame-contract authority boundaries are explicit;
- Phases 1–3 acceptance fixtures are frozen before implementation.

### Phase 1 — Deterministic Aseprite editing bridge

**Deliverables**

- versioned JSON bridge;
- inspect, paint, erase, stroke, copy, move, frame, layer, render, snapshot,
  save, and undo primitives;
- transactions, cloned-cel editing, idempotent operation journal, and exact
  before/after hashes.

**Exit criteria**

An automated fixture creates a temporary `96x96` document, applies known
edits, saves/reopens, verifies exact RGBA hashes, undoes/restores, and proves
pixel identity with its baseline. It writes only under `.ai`.

### Phase 2 — Art Agent service, CLI, and thin MCP

**Deliverables**

- typed service/models and task resume behavior;
- `operator art doctor|inspect|task` plus draft-only mutation commands;
- local thin MCP observation/mutation tools;
- path allowlists, capability checks, operation budgets, and structured errors.

**Exit criteria**

On the live six-frame melee run workspace, a client adds one orange pixel to an
agent-owned temporary layer, renders it, erases it, and proves the document
returns pixel-identically to baseline. Canonical source remains unchanged.

### Phase 3 — Visual observation and defect recognition

**Deliverables**

- frame, strip, contact-sheet, onion-skin, silhouette, before/after, and
  reference comparison rendering;
- artifact-return support in CLI/MCP;
- first structured critic contract and bounded critique loop.

**Exit criteria**

The system identifies deliberately injected oversized-hood, shifted-baseline,
missing-dagger, and duplicate-frame defects with correct frame localization.

**Architecture checkpoint:** stop here. Review bridge safety, task durability,
visual usefulness, MCP thinness, and Workbench boundaries before Phase 4.

### Phase 4 — Art profile and landmarks

Bootstrap reviewed profile measurements and landmark tooling from canonical
art. Quantify frame height, head/hip/foot/grip/tip trajectories with provenance
and confidence. No guessed tolerances become publication gates.

### Phase 5 — Semantic body-part operations and pose rig

Add reviewed masks, drafting rig, and integer part operations. Prove a displaced
leg can be repaired without altering unrelated torso pixels.

### Phase 6 — Full animation authoring pilot

Add `AnimationPlan`, recipes, reference assembly, and missing-frame drafting.
The first production eval is:

```text
profile: melee_1h
group: locomotion
action: run_01
direction: e
frames: 6
frame size: 96x96
weapon: vigil_pattern_dagger
```

The pilot must preserve Operator identity, produce the approved elevated
three-quarter projection and crossover gait, keep scale/loop continuity, and
pass visual QA. It remains draft-only until separately approved for publish.

### Phase 7 — Modular composition and weapons

Coordinate lower/upper/head/cape/weapon/FX, validate zero-popping composition,
and add explicit socket-calibration integration without changing gameplay
ownership.

### Phase 8 — Creation mode

Add nonexistent-source Workbench creation contracts, transactional new-source
publication, rebuild/import/test, and exact rollback deletion/restoration.

### Phase 9 — Bounded art autopilot

Consume `operator_animation_contract_report.py` as a read-only queue source.
An approved `operator art autopilot --profile melee_1h --required` scope ends
only when required missing/suspicious coverage is zero and structural, visual,
modular, weapon, runtime, and report gates are green—or returns a structured
human-review/blocker state.

### Phase 10 — Art Director mode

Plan and execute approved family-scale perspective/style migrations: inventory
affected identities, identify shared poses, migrate directional ownership,
coordinate modular layers and sockets, inspect runtime playback, repair
outliers, publish a review site, update docs, and commit task-owned files.

This phase does not grant authority to change combat timing or gameplay feel.

## First implementation slice — V1 delivered

The delivered V1 slice is intentionally narrower than the complete Phases 0–3
roadmap:

1. preserve Workbench V2 unchanged as publication authority;
2. add versioned session/request/response models;
3. build deterministic Aseprite editing over existing `.ai` workbenches only;
4. add the shared Python service and thin `operator art` CLI;
5. journal every mutation with full-document backups and SHA guards;
6. render transparent observation/contact-sheet/diff products;
7. prove inspect/edit/render/erase/restore against the live six-frame east
   melee run without canonical publication.

MCP, temporary agent-layer creation, injected-defect criticism, publication,
pose synthesis, autonomous art creation, socket calibration, and autopilot are
explicitly deferred.

## Validation strategy

Each phase adds its focused deterministic test before capability graduation.
The complete future validation ladder is:

1. JSON/schema/model unit tests;
2. exact RGBA Aseprite bridge fixture and replay/idempotency tests;
3. path/layer/frame/bounds/capability rejection tests;
4. task crash/resume and journal consistency tests;
5. observation artifact and injected-defect tests;
6. landmark/profile/trajectory QA fixtures;
7. semantic part isolation and modular seam tests;
8. creation/publish/rollback fixture tests;
9. existing Workbench, Operator contract, modular, posture, Vigil, compatibility,
   import, and headless project-load validation;
10. relevant Moment Forge runtime playback and human review of report artifacts.

Tests must never use production canonical assets as mutable fixtures.

## Documentation migration plan

When implementation begins, preserve the distinction:

```text
Workbench V2/V3
  transactional source resolution, migration, publication, and rollback

Modular Alignment Repair
  manual repair conveyor; never automatically redraws pixels

Operator Art Agent
  authorized, journaled autonomous pixel author inside approved `.ai` scope
```

Update implementation state—not roadmap aspiration—in:

- `OPERATOR_ANIMATION_WORKBENCH.md`
- `custodian/tools/operator/README.md`
- `custodian/tools/aseprite/README.md`
- `custodian/docs/SPRITE_PIPELINE_CHEATSHEET.md`
- `custodian/docs/ai_context/CURRENT_STATE.md`
- `custodian/docs/ai_context/FILE_INDEX.md`
- `custodian/docs/ai_context/AGENT_TOOLING_BY_ASK.md`
- `custodian/docs/ai_context/VALIDATION_RECIPES.md`

Do not edit current Workbench or Alignment Repair claims as though Art Agent
capabilities exist before their phase is implemented and validated.

## Open decisions before the next slice

- exact MCP SDK/runtime and process supervision model;
- task schema versioning and migration policy;
- maximum operation/pixel/frame budgets and timeout defaults;
- reserved temporary/review layer naming;
- reference artifact retention and report cleanup policy;
- critic model/provider boundary and deterministic fallback when unavailable;
- human approval UX for autonomy elevation and later publication;
- accepted canonical sample set for style-profile bootstrapping.

## Completion definition

The roadmap is complete only when an explicitly bounded Art Director request can
be resumed across sessions, produce auditable Operator animation changes,
demonstrate visual and runtime correctness, publish solely through Workbench,
rollback exactly on failure, and leave zero missing/suspicious required coverage
inside its approved scope—without silently changing gameplay authority.
