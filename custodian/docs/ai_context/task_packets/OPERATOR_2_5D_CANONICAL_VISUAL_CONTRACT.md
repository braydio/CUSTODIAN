# OPERATOR 2.5D CANONICAL VISUAL CONTRACT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-2-5d-canonical-visual-contract`
- Status: `ready`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `none`
- Claim gate: `do not claim while operator-2-5d-animation-viability-audit still owns operator-art-agent; after that workstream releases the shared lock, implementation may begin but the canonical 128 anchor/floor/profile must still pause at the PRE-LOCK CALIBRATION GATE for human approval before acceptance`
- Locks: `operator-art-agent, operator-source-normalization, operator-aseprite-tooling`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline, workflow, visual-contract`
- Paired review workstream: `review-operator-2-5d-canonical-visual-contract`
- Reviewed main: `2e375923edf450a64b4b9fb4b41ce02ca3fa1ff1`
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

## PRE-LOCK CALIBRATION GATE

Do **not** freeze the canonical 128 registration merely from the 2048x256 design-reference cell bounds. Two distinct artifacts exist and have different jobs:

### High-resolution design authority

The user-approved final design sheet supplied in the authoring chat measures:

```text
2048 x 256 RGBA
8 x 256x256 cells
order: N, NE, E, SE, S, SW, W, NW
sha256: 2d5de16d5d2eb3cde5ab36586a33414a613f214441c8b2ec2430e37d1af25323
```

This file owns anatomy, armor/cloak topology, projection, palette/material language and directional identity. It is **not** itself proof of runtime centering/floor registration.

### Runtime-registration candidate

The user's earlier crisp resize/canvas pass in this same chat measures:

```text
1024 x 128 RGBA
8 x 128x128 cells
sha256: 31bfc4fc40cbb1d2738037070b962d8e68b1f3ca87414b8f8c5f2ae1e60493c7
alpha: binary only (0/255)
```

Measured alpha bounds:

| Dir | bbox width | bbox height | bbox center x | top y | bottom y |
| --- | ---: | ---: | ---: | ---: | ---: |
| N | 49 | 87 | 63.0 | 20 | 106 |
| NE | 42 | 86 | 62.5 | 20 | 105 |
| E | 32 | 88 | 60.5 | 20 | 107 |
| SE | 43 | 87 | 63.0 | 20 | 106 |
| S | 49 | 85 | 64.0 | 20 | 104 |
| SW | 39 | 86 | 64.0 | 20 | 105 |
| W | 31 | 87 | 65.0 | 20 | 106 |
| NW | 42 | 84 | 64.5 | 20 | 103 |

The body is therefore already correctly sized for the intended "roughly old 96px body inside a 128px action canvas" strategy: apparent height is 84-88px with all directions beginning at y=20. Do not enlarge the body simply to fill the 128px cell.

### Candidate canonical root/floor

The accepted legacy profile uses `anchor_y=84`, `ground_y=85`; the viability audit found normal legacy sprite baselines at roughly y=84. Preserve that semantic relationship in the new profile.

Candidate new registration:

```text
frame: 128x128
center_x: 64
support/body baseline: y=106
root anchor: [64, 106]
ground_y: 107
bottom safety margin below ground: 20px
```

If bottommost opaque support contact is used as the initial normalization evidence, the candidate whole-sprite integer Y translations are:

```text
N   +0
NE  +1
E   -1
SE  +0
S   +2
SW  +1
W   +0
NW  +3
```

These translations are **calibration candidates, not permission to finalize blindly**.

Before final profile write:

1. landmark semantic `hip_center` and both visible/inferable toe/support contacts on all 8 directions;
2. verify that x=64 represents the projected body/root axis from semantic landmarks, not alpha-bbox centering;
3. verify y=106 against support-contact landmarks and the existing anchor-vs-ground semantics;
4. create one deterministic 8-direction calibration overlay showing cell bounds, x=64, candidate anchor y=106, ground y=107, support contacts, hip centers and applied integer translations;
5. publish that single overlay through the visual-review handoff and **pause for human/ChatGPT approval before the v3 profile/reference is declared accepted**;
6. if the user changes anchor/floor/body scale, update the profile measurements and this report from that decision. Do not reinterpret the visual design itself.

No direction may be independently rescaled to make its feet/bbox match. Whole-sprite integer translation is the only allowed pre-lock geometric adjustment after the one shared crisp body scale is established.

If the exact 1024x128 candidate is available locally, preserve it as additional source-work evidence under a name such as `OPERATOR_DESIGN_REFERENCE_128.png` and verify the SHA above. If it is not available, deterministically reproduce the 128 candidate from the approved source through the existing pixelart/normalization tooling and require the calibration overlay/human gate before accepting the result.

## AAA TECHNICAL-ART PRE-FREEZE ADDENDUM

This addendum supersedes any earlier implication that the lowest opaque pixel should be normalized to one common Y. The approved 2.5D art is now visually lockable; registration remains a semantic technical-art calibration.

### Audit disposition

Treat the current approved 8-direction character design as:

- **visual identity / anatomy / armor / cloak:** LOCK;
- **camera / projection:** LOCK;
- **runtime neutral body scale:** PASS;
- **frame center X:** LOCK at `64` for the 128 profile;
- **root/floor Y:** PROVISIONAL;
- **128x128 as a universal body-animation canvas:** PROVISIONAL until action-envelope proof;
- **mass animation production:** HOLD until the semantic-root and action-envelope gates below pass.

Measured neutral 128 reference evidence remains:

```text
cell: 128x128
apparent body height: 84-88 px
top alpha row: y=20 for all current neutral reference cells
bottom alpha row: y=103..107 depending on direction
binary alpha only
detached alpha islands: none
```

Do not enlarge the neutral body merely to fill the frame.

### Critical floor/root correction

**Do not normalize direction registration by alpha bottom.**

In a fixed elevated 2.5D projection, two feet can both contact the same physical ground plane while appearing at different screen-space Y coordinates. Therefore:

- lowest opaque Y is clipping/silhouette evidence only;
- equal alpha bottoms are not a registration invariant;
- equal head-top Y is not a registration invariant;
- the earlier candidate whole-sprite Y shifts derived from bottommost opaque pixels are diagnostic only and must not be applied merely to equalize bottoms.

Before accepting the canonical 128 registration, landmark for every direction:

```text
hip_center
left_foot_contact
right_foot_contact
projected_world_root
shadow_origin
```

Reuse existing near/far toe landmarks where they map cleanly, but add an explicit projected-root/shadow-origin concept if the current schema cannot represent the distinction without ambiguity.

The intended model is:

```text
world/root authority: fixed gameplay point
projected root: fixed screen-space registration point for the profile
foot contacts: direction-specific positions around that root
shadow origin: grounded presentation point
```

Candidate registration remains:

```text
frame: 128x128
center_x: 64
candidate root: [64, 106]
candidate ground_y: 107
```

but Y=106/107 is **not accepted merely because it is near the current lowest pixels**.

Prove or revise it from the semantic landmarks.

### Required human calibration proof

Before writing the new 128 profile as accepted, generate one deterministic eight-direction technical overlay showing, for every cell:

- 128x128 cell boundary;
- x=64 root axis;
- candidate/final projected root;
- ground reference;
- hip center;
- left/right foot contacts;
- shadow origin;
- alpha bbox;
- no geometric scaling difference between directions.

Publish that single overlay and pause at the existing human calibration gate.

The human decision is about root/floor/scale registration only. Do not reopen the approved character design/camera unless the overlay exposes an actual contradiction.

### 128 universal action-envelope proof

The neutral turnaround proves that the standing Operator fits comfortably inside 128x128. It does **not** by itself prove that 128x128 is a universal canvas for every future body animation.

Before declaring the 128 profile universal for new Operator body art, prove a bounded maximum-action envelope using representative worst extents from current/planned production semantics:

- deepest dodge/crouch;
- maximum fast-chain body extension;
- widest block-hit/reaction;
- raised/overhead melee pose;
- longest 1H attack body reach;
- ranged aim extension;
- large hit-reaction recoil;
- downed/death body extremity where relevant.

The proof may use existing art, canonicalized temporary poses, or measured legacy/reference envelopes. It does not require authoring a finished new animation family.

Acceptance:

- body anatomy fits the 128 body canvas with a deliberate safety margin;
- no body scale reduction is used to make an extreme pose fit;
- root remains stable under pose motion;
- intentional root-driving motion is represented explicitly rather than recentering the frame;
- if weapon/FX extents exceed the body canvas, solve that with the appropriate weapon/FX presentation envelope or layer contract, **never by shrinking the Operator body**.

If the body itself cannot fit a representative production pose safely at 128, stop and return that evidence for human/ChatGPT profile-size review before mass production.

### Runtime-pixel cleanup gate

The reviewed 128 candidate has correct binary alpha and connected silhouettes but contains a small number of embedded cool/green/blue palette contaminants.

Cleanup is allowed only on the normalized 128 authoring reference, not the immutable high-resolution design source.

Allowed cleanup:

- replace isolated non-warm contaminant pixels with locally appropriate graphite or warm-gold values;
- preserve perceptual brightness hierarchy;
- preserve exact alpha mask;
- preserve dimensions, silhouette, root, floor, scale, pose and topology.

Required proof:

- before/after hashes;
- exact changed-pixel list;
- alpha-mask equality;
- identical connected-component topology;
- 4x or greater diff/marked preview for human inspection.

Do not perform broad palette reduction or recolor.

The immutable high-resolution design-source hash remains the visual provenance authority even if the normalized 128 reference receives approved pixel cleanup and therefore has its own new reference hash.

### Final pre-freeze rule

The 128 profile may become accepted only after all three conditions are true:

1. semantic root/floor overlay is human-approved;
2. 128 body action-envelope proof passes or a revised frame size is human-approved;
3. normalized 128 pixel cleanup is reviewed and its final hash is recorded.

Until then, the implementation may build measurement/report/tooling support but must keep the new profile explicitly provisional.

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


## Handoff

- Next workstream: `review-operator-2-5d-canonical-visual-contract`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Summary backlink: include the exact Authoring chat URL in the closing summary and final Next Handoff
- Refresh reason: `none`
- Next action: `paired fresh-context review, then WB25-1 may proceed when its other dependencies are complete`
- Blockers or open questions: `none beyond declared dependencies`
