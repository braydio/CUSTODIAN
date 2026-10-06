# OPERATOR 2.5D CANONICAL VISUAL CONTRACT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-2-5d-canonical-visual-contract`
- Status: `ready`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `none`
- Claim gate: `do not claim while operator-2-5d-animation-viability-audit still owns operator-art-agent; claim after that workstream releases the shared lock`
- Locks: `operator-art-agent, operator-source-normalization, operator-aseprite-tooling`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline, workflow, visual-contract`
- Paired review workstream: `review-operator-2-5d-canonical-visual-contract`
- Reviewed main: `ca5e7d2acc5282f304a8d969343db127462326f1`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Goal: Turn the user's approved 8-direction Operator design reference into the single deterministic visual/registration authority for all future 2.5D Operator animation authoring: preserve the approved source bytes, measure and landmark every direction, define the new 128x128 authoring/runtime frame contract without breaking existing 96x96 assets, make Aseprite/Workbench/Art Agent show the canonical directional reference, and add structural/color/brightness/silhouette QA that prevents body/camera/material drift while preserving intentional pose motion.
- Completion boundary: Preserve the exact source under source_work; emit a canonical per-direction measurement/landmark record; migrate the art-profile authority so legacy 96 and canonical 128 profiles coexist; make Aseprite/Workbench consume the canonical reference and profile; add deterministic geometry/material/alpha QA; update active art/design docs; do not replace runtime animations in this slice.
- Current measured state:
  - The user has explicitly locked the attached 8-direction design and will save it as `OPERATOR_DESIGN_REFERENCE_480.png`.
  - The reviewed chat attachment is exactly 2048x256 RGBA: eight horizontal 256x256 cells ordered `N, NE, E, SE, S, SW, W, NW`. The filename token `480` is user naming, not measured geometry.
  - The reviewed attachment SHA-256 is `2d5de16d5d2eb3cde5ab36586a33414a613f214441c8b2ec2430e37d1af25323`.
  - Live `operator_art_profile.json` is schema v2 with one accepted 96x96 registration ruler at anchor `[48,84]` and ground `y=85`.
  - Live `registration_profile.py` supports v1/v2 and hard-requires accepted 96x96 geometry.
  - The style bible still says no canonical sample/pitch authority exists; that is now documentation drift.
  - The existing landmark vocabulary already covers hood/head, near/far shoulders/elbows/hands/hips/knees/ankles/toes, cloak tips, weapon grip and weapon tip.
- Evidence: `custodian/content/data/operator/authoring/operator_art_profile.json`; `operator_landmark_schema.json`; `custodian/tools/operator/art_agent/registration_profile.py`; `custodian/tools/aseprite/operator_anchor_guides.lua`; `custodian/tools/operator/README.md`; `design/02_features/animation/OPERATOR_ART_STYLE_BIBLE.md`; archived `OPERATOR_ART_REGISTRATION_PROFILE.md`; the approved source identity above.
- Task-specific authority: the exact approved source hash and user decision in this chat; current Operator registration/profile tooling; current specialized Operator authoring pipeline. This is an Operator-authoring reference asset, not a generic runtime prop. Do not create a parallel generic Asset V2 family if the live specialized Operator pipeline remains authoritative.
- Work surface: `custodian/asset_drop/source_work/operator/operator_2_5d_design_reference/`; Operator authoring profile/reference metadata; registration profile/QA/overlay services; Aseprite guide integration; style bible; focused validation; task index/roadmap.
- Preserve: existing canonical/runtime Operator PNGs and SpriteFrames; all current 96x96 production assets; animation timings; gameplay selectors; weapon sockets; old Source Sessions; existing v1/v2 normalization plans; the exact approved design-reference bytes.
- Non-goals: no new animation art; no runtime Operator replacement; no automatic limb warping; no per-frame scale correction; no 16-direction production requirement; no fabricated numeric camera angle; no melee/ranged behavior changes; no operator.gd decomposition work; no Forum implementation.
- Acceptance: source archive hash/dimensions/order are proven; all 8 directions have canonical landmark records and reproducible geometry/color/silhouette metrics; future 128-profile authoring can show direction-specific ghost/floor/body guides; legacy 96 stays usable; intentional scale/anchor/palette drift fixtures are caught; active docs reflect the approved sample; no production runtime art changes.
- Validation: new focused canonical-visual-contract smoke + existing registration-profile focused coverage + Aseprite clean-render guide-leak check + `git diff --check`. No broad gameplay/Godot suites unless runtime files are unexpectedly touched.
- Task overrides: `none`
- Deferred: actual animation regeneration, production rollout packets, and Forum refresh.

## Identity

```text
workstream: operator-2-5d-canonical-visual-contract
branch: agent/operator-2-5d-canonical-visual-contract
closing summary: OPERATOR_2_5D_CANONICAL_VISUAL_CONTRACT_CLAUDE_SUMMARY.md
```

## 1. Preserve the approved source exactly

Expected local source:

```text
~/Downloads/OPERATOR_DESIGN_REFERENCE_480.png
```

Verify before copying:

```text
dimensions: 2048x256
layout: 8x1
cell: 256x256
order: N, NE, E, SE, S, SW, W, NW
sha256: 2d5de16d5d2eb3cde5ab36586a33414a613f214441c8b2ec2430e37d1af25323
```

If absent, stop. If hash/dimensions differ, report actual values and stop for user confirmation. Do not fetch/regenerate/substitute.

Preserve exact bytes at:

```text
custodian/asset_drop/source_work/operator/operator_2_5d_design_reference/
    OPERATOR_DESIGN_REFERENCE_480.png
    operator_2_5d_design_reference_manifest.json
```

Manifest records filename, SHA-256, bytes, dimensions, cell geometry, order, approval date, authoring chat and provenance `user_approved_visual_lock`.

Do not recompress/threshold/edit the master.

## 2. Split immutable measurement cells

Exact-boundary split only:

```text
source_cells/
    n_source.png
    ne_source.png
    e_source.png
    se_source.png
    s_source.png
    sw_source.png
    w_source.png
    nw_source.png
```

Each remains 256x256 and must reconstruct the master pixel-for-pixel. Record every cell hash.

## 3. Introduce canonical 128 without breaking legacy 96

The future Operator frame/canvas is 128x128 with approximately the current gameplay body scale inside the larger canvas. Existing 96 art remains valid during migration.

Upgrade the profile authority to a backward-readable registry, recommended `custodian.operator_art_profile.v3`:

```json
{
  "schema": "custodian.operator_art_profile.v3",
  "active_authoring_profile": "operator_2_5d_128",
  "profiles": {
    "legacy_96": { "...existing v2 registration unchanged..." },
    "operator_2_5d_128": { "...new canonical contract..." }
  },
  "canonical_visual_reference": {
    "path": "...OPERATOR_DESIGN_REFERENCE_480.png",
    "sha256": "...",
    "measurements_path": "...operator_2_5d_design_reference.json"
  }
}
```

Exact private shape may follow live code, but invariants are mandatory:

- v1/v2 remain readable;
- legacy 96 remains selectable;
- old Source Sessions/plans do not silently migrate;
- new authoring defaults to `operator_2_5d_128`;
- profile identity/hash is carried through normalization/review receipts;
- consumers do not retype geometry constants.

Update `registration_profile.py` to select an explicit profile instead of hard-requiring one top-level 96 registration.

## 4. Derive 128 registration from the approved pixels

Create the canonical 128 directional reference with existing crisp Operator conversion/normalization, using one shared body scale across all directions. The design target is the approved body at roughly the former 96px gameplay scale inside a roomier 128px cell, not a body stretched to 128.

Rules:

- X authority = semantic `hip_center`, not alpha-bbox center.
- Y authority = semantic support contact from `toe_near/toe_far`; alpha bottom is fallback evidence only.
- One shared scale for all eight directions.
- Direction-specific adjustment is integer translation only.
- Never independently scale directions to equalize apparent height.
- Never rotate/shear.
- Preserve crisp output and true alpha.
- Frame center X is 64.
- Derive final 128 anchor Y / ground Y from approved support contacts; do not guess them in advance.

Recommended durable normalized references:

```text
custodian/content/sprites/operator/reference/operator_2_5d/
    operator_2_5d_rotation_lock_128.png
    directions/n.png
    directions/ne.png
    directions/e.png
    directions/se.png
    directions/s.png
    directions/sw.png
    directions/w.png
    directions/nw.png
```

These are authoring references/ghosts, not gameplay animation states.

## 5. Landmark every direction

Create:

```text
custodian/content/data/operator/authoring/operator_2_5d_design_reference.json
```

For each direction record source-256 and normalized-128 coordinates for every visible/inferable existing semantic landmark:

```text
hood_top
head_center
shoulder_near / shoulder_far
elbow_near / elbow_far
hand_near / hand_far
hip_center / hip_near / hip_far
knee_near / knee_far
ankle_near / ankle_far
toe_near / toe_far
cloak_tip_near / cloak_tip_far
```

Every point has confidence and provenance. Do not fabricate occluded points at high confidence.

## 6. Deterministic geometry/proportion measurements

Persist per direction:

### Registration and silhouette
- alpha bbox and centroid;
- silhouette area and occupancy ratio;
- top/bottom/left/right margins;
- support-contact y;
- hip-center x offset;
- apparent height/width;
- widths at standard vertical percentages (20/35/50/65/80%);
- reproducible perimeter/edge density if stable.

### Anatomy
Using landmarks:
- hood-top to head-center;
- head-center to hip-center;
- shoulder span;
- hip span;
- shoulder to elbow;
- elbow to hand;
- hip to knee;
- knee to ankle;
- ankle to toe;
- torso length;
- apparent leg length;
- cloak-tip displacement from hip/root.

Store raw px and ratios normalized to head-center-to-hip and/or apparent height.

Foreshortening is direction-specific. Future N compares to canonical N, E to E, etc. Never force screen-space segment lengths to be equal across bearings.

### Rotational continuity
Report N -> NE -> E -> SE -> S -> SW -> W -> NW -> N discontinuities in body height, head scale, shoulder span, hip placement, cloak mass and overall scale. Report only; do not warp art.

## 7. Deterministic color / brightness / material measurements

Do not pretend the rendered source is a tiny exact palette.

Record:
- source and normalized alpha histograms;
- dominant sRGB clusters;
- perceptual lightness statistics (OKLab or equivalent);
- luminance p05/p50/p95/p99;
- chroma/saturation distribution;
- darkest silhouette/outline band;
- graphite/cloth dark-mid-light bands;
- gold dark-mid-highlight bands;
- visor core/glow band where present;
- highlight occupancy percentages;
- gold-to-graphite contrast;
- visor-to-gold and visor-to-body contrast;
- per-direction lightness/chroma deltas.

Preserve this hierarchy:

```text
visor/core focal highlight
> selected gold/plate speculars
> gold trim
> graphite plate highlights
> cloth mids
> deep outline/shadow
```

Gross material/palette deviation can be structural QA; small action-lighting variation remains warning-level until separately hardened.

## 8. Outline / alpha / artifact measurements

For normalized directions report:

- alpha-perimeter pixels;
- dark-outline perimeter coverage;
- outline lightness distribution;
- outlier hue/color contaminants;
- detached 1-2 px alpha islands;
- semitransparent fringe pixels after crisp normalization;
- excessive 2+ px outline thickening as warning evidence.

Do not enforce a uniform sticker outline. Require continuous silhouette separation and coherent internal value edges.

## 9. Lock visual identity/topology

Create human-readable hard authority for:

- faceless hood: never expose skin/eyes/nose/mouth;
- hood crown readable under the fixed elevated camera;
- visor strongest S, partial SE/SW, narrow/profile E/W, minimal NE/NW, absent/near-absent N;
- lean athletic proportions;
- angular shoulder plates;
- graphite/black plate + cloth;
- restrained antique-gold/amber trim;
- layered split cloak/tabard;
- fixed belt-ring language;
- stable shoulder/forearm/knee/greave plate segmentation;
- one screen-space lighting language;
- exactly eight authored directions;
- no direction collapses into a side-on camera.

Do not invent a numeric pitch from flattened pixels. The approved turnaround is projection authority.

## 10. Create the design authority

Create:

```text
design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md
```

Document:
- identity and direction order;
- projection authority;
- source-vs-128 reference distinction;
- frame/canvas strategy;
- root/floor semantics;
- invariant geometry vs pose-authoring freedom;
- direction-relative measurement rules;
- material/palette/brightness hierarchy;
- visor behavior;
- outline/alpha rules;
- weapon/FX clipping rules;
- mirroring policy;
- human-review triggers.

Update `OPERATOR_ART_STYLE_BIBLE.md` to point here and remove stale claims that no approved canonical sample exists.

## 11. Animation anti-drift rules

Hard:
- profile/frame size;
- one animation-wide global scale;
- no per-frame rescale;
- canonical direction/projection;
- body/costume topology;
- root/ground coordinate system;
- canonical profile/reference hash;
- no clipping;
- alpha/layer contract.

Direction-relative structural checks for neutral/locomotion baseline frames:
- head scale;
- head-to-hip ratio;
- shoulder span;
- hip span;
- limb ratios;
- apparent body height;
- hip-center offset;
- support-foot registration.

Derive tolerances from the approved reference and reproducible existing noise; do not invent arbitrary percentages when measurements can supply them.

Intentional pose motion remains free: crouch, recoil, lean, anticipation, follow-through, airborne pose, dodge extension and cloak swing may move joints. Joint position may change; anatomy/scale cannot silently change.

## 12. Centering / floor / weapon rules

Canonical 128:
- center x = 64;
- hip/root centering for neutral references;
- support-foot contact for floor alignment;
- alpha bbox only for clipping/sanity.

Never recenter a frame around alpha bbox, weapon, FX, cloak tip or extended fist.

Weapons/FX may trigger clipping refusal; they may never shrink the body.

## 13. Aseprite canonical ghost guides

Extend the existing Operator guide script. A selected direction should expose locked non-exporting guides equivalent to:

```text
__ART_GUIDE_OPERATOR_FLOOR
__ART_GUIDE_OPERATOR_CENTER
__ART_GUIDE_OPERATOR_BODY
__ART_GUIDE_OPERATOR_CANONICAL_REFERENCE
```

The canonical-reference guide is the approved normalized direction ghost at low opacity.

Requirements:
- load through profile/reference authority;
- direction-correct;
- locked and toggleable;
- never included in clean render/publish;
- idempotent replacement;
- legacy-96 and canonical-128 modes;
- no permanent duplication of guide pixels when on-demand rendering is cleaner.

## 14. Workbench / Art Agent QA

Shared services should expose/report:
- effective canonical profile;
- canonical direction reference;
- landmark/registration overlay;
- geometry/proportion report;
- palette/brightness report;
- silhouette/outline report.

Classify findings:

```text
HARD_FAIL
STRUCTURAL_WARN
ART_DIRECTION_WARN
INFO
```

Examples:
- wrong frame/profile or per-frame scale -> HARD_FAIL;
- support-root or limb-ratio drift -> STRUCTURAL_WARN according to profile;
- gold/visor lightness/hue drift -> ART_DIRECTION_WARN;
- action pose head-y differs from neutral with stable anatomy -> INFO.

No automatic anatomy warping.

## 15. Durable evidence

Create:

```text
reports/operator_presentation/canonical_visual_contract/
    operator_2_5d_reference_turnaround.png
    operator_2_5d_landmark_overlay.png
    operator_2_5d_measurement_summary.json
    operator_2_5d_palette_summary.json
    OPERATOR_2_5D_CANONICAL_VISUAL_CONTRACT_REPORT.md
```

Turnaround shows all 8 normalized directions on the same floor/center guides. Landmark overlay makes anatomy/root placement inspectable.

Report exact source hash, profile hash, final 128 anchor/ground, ordering, hard/advisory tolerances, and any measurement that remains human-authority-only.

## 16. Documentation drift to resolve

Reconcile:
- style bible still says no canonical sample is approved;
- art profile still models a single 96 profile;
- registration parser hard-requires 96;
- 2.5D roadmap does not yet treat this approved body as the art authority.

Do not rewrite historical archived packets.

## 17. Focused validation

Add focused owner, recommended ID `operator_2_5d_canonical_visual_contract`.

Prove:
1. source hash/dimensions;
2. source-cell reconstruction;
3. v1/v2 profile readability;
4. legacy 96 still available;
5. canonical 128 is default for new art;
6. all 8 reference directions exist;
7. exact direction order;
8. landmark names valid;
9. measurement generation deterministic;
10. intentional scale/anchor drift caught;
11. intentional palette/brightness drift reported;
12. guide layers cannot leak through clean render/publish.

Run existing registration-profile focused smoke if present and `git diff --check`. No broad gameplay/Godot suite.

## 18. Completion / handoff

Publish turnaround, landmark overlay and concise report through the visual-review workflow.

If normalization changes appearance rather than integer placement/metadata, stop for human review rather than silently redefining the approved art.

After reviewed landing:
1. recompute the animation-art backlog against this contract;
2. author canonical unarmed locomotion/posture as the first production art tranche;
3. refresh the Forum 2.5D packet only after that art plan is accepted.
