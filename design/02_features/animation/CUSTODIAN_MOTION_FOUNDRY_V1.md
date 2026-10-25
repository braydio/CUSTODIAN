# CUSTODIAN Motion Foundry V1: Deterministic Offline Animation Authoring

- Status: approved architecture and bounded MF1/MF2 implementation plan; **not implemented**
- Reviewed main: `9bbe905a1ffcca2afca273ccc48a7ed2f794d0c8`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- Owning domain: Operator animation authoring tools, not gameplay or runtime animation selection
- First release: pure-Python deterministic part motion, candidate rendering/QA, and a separately reviewed Operator Source Session bridge
- Explicit later gate: real Operator layered-source authoring and subjective art approval

## 1. Problem and evidence

CUSTODIAN can already inspect, edit and publish canonical Operator animation, but cannot synthesize a new coherent multi-frame motion from a rig definition and pose timeline. The currently implemented Art Agent V2 handles bounded pixel/mask/landmark mutations and a local MCP facade; the Workbench handles editable Aseprite composition and guarded publication. Neither claims general pose synthesis. The accepted 128px 2.5D Operator idle is a **flattened, already-authored** 15-frame-per-direction source. It is not an approved segmented rig. Do not infer editable limbs from the flattening.

Existing complementary work:
- `design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md`: accepted full-body reference, independent direction identity, [64,106] projected root and [64,107] shadow/ground, 128x128 frame contract, no independently scaled/rotated/sheared whole directions or frames.
- `design/02_features/animation/OPERATOR_ART_AGENT_SYSTEM.md`: semantic Art Agent, source sessions, QA, drafts, guarded local MCP adapter; `publish_authorized=false`.
- `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`: canonical PNGs, saved-document/timing authority, transactional guarded publish, dedicated art worktree, generated catalog/SpriteFrames.
- `design/02_features/animation/OPERATOR_2_5D_WORKBENCH_MIGRATION_ROADMAP.md`: explicit 2.5D generation and review gates, approved 15f x 8-direction idle and unknown/null FPS; full-body-first with selectively modular gameplay presentation.
- `design/02_features/enemy_visuals/HUMANOID_CUTOUT_RIG_SYSTEM.md`: existing **96x96** enemy runtime paper-doll rig with 20-part 5x4 atlas and its own pivot/profile authoring. This is a valuable donor/reference, **not** an authority to replace.
- `custodian/tools/operator/animation_transition.py`, `art_agent/qa.py`, `operator_2_5d_ingress.py`, `operator_generation_brief.py`, `operator_animation_workbench.py`, and `custodian/tools/validation/operator_2_5d_canonical_visual_contract_smoke.py`: existing reporting, identity, ingress and validation seams.

Documentation-drift rule: the older humanoid packet says `implementation / in-progress` but has a running/validated runtime rig; do not treat its status as permission to rewrite enemy architecture. The 2.5D migration roadmap retains older snapshot SHAs; use live profile and contract content/hashes at execution. Any mismatch must be reported before writes; this document does not silently supersede an accepted decision.

## 2. Boundaries and decision ownership

**Motion Foundry owns only offline authoring candidates**: a reproducible rig/part input contract, integer motion timeline, pure rasterization, QA, candidate receipts, and read-only inspect/plan operations. It never owns Operator animation selection, gameplay timing/hit windows, actor transforms, movement, weapons, hit boxes, asset registration, review approval or canonical publication.

Authority chain:

```text
accepted design/profile + authored part source (immutable hashes)
   -> Motion Foundry plan + deterministic keyframe interpolation
   -> ignored .ai candidate frames/strip/report (not approved art)
   -> optional MF2 explicitly selected, hash-locked export into source_work
   -> existing Operator2DIngress / SourceArtService normalization & review
   -> saved Aseprite Workbench + human art/timing decision
   -> existing guarded Workbench / Asset Pipeline V2 / runtime authority
```

No new runtime node, no second animation database, no custom Godot animation importer, and no competing `publish` implementation. Motion Foundry is not allowed to write canonical PNGs, sidecars, generated runtime resources, review approvals, Aseprite documents, or Git refs. Explicit source-work export is the only allowed non-ignored write in MF2. The existing `operator art` MCP adapter may gain a **read-only plan/status/candidate discovery** facade later; it must not gain arbitrary shell/file/write/publish tools.

MF1 shall not use a generative service, GPU, network, 3D rig, image-to-image model, automatic body segmentation, geometric antialiasing, or arbitrary pose transfer. A later optional model adapter may offer suggestions but never silently replace the deterministic engine or accept artwork.

## 3. V1 rig and motion contracts (new schemas)

Schemas are **proposed**; implement versioned validation exactly and keep runtime assets independent. Store their validators in the new `custodian/tools/operator/motion_foundry/` package; avoid introducing a second global registry. Required model fields:

```json
{
  "schema": "custodian.motion_foundry.rig.v1",
  "rig_id": "operator_south_fixture",
  "owner": "operator",
  "art_generation": "operator_2_5d_128",
  "direction": "s",
  "frame_size": [128, 128],
  "root": [64, 106],
  "ground": [64, 107],
  "reference_profile_sha256": "<64-lowercase-hex-from-live-authority>",
  "parts": [
    {
      "id": "torso",
      "source": "<confined-PNG-path>",
      "sha256": "<64-lowercase-hex>",
      "pivot": [64, 73],
      "parent": null,
      "draw_order": 20,
      "movable": false
    },
    {
      "id": "arm_near",
      "source": "<confined-PNG-path>",
      "sha256": "<64-lowercase-hex>",
      "pivot": [59, 62],
      "parent": "torso",
      "draw_order": 40,
      "movable": true
    }
  ]
}
```

Each source part is a transparent RGBA PNG of exact rig frame dimensions in *absolute assembled coordinates*, not a cropped opaque limb. All inputs reside beneath a declared immutable/sandbox fixture root, inside `.ai/operator_motion_foundry/`, or another specifically authorized **read-only** art source root selected by the caller. Resolve every path and symlink before containment; no network URLs or arbitrary shell. Detect missing/duplicate IDs, missing parents, parent cycles, wrong RGBA/grid, bad hashes, unsupported generation, direction mismatch, duplicate draw order, out-of-grid pivots and invalid roots. Never mutate source files.

```json
{
  "schema": "custodian.motion_foundry.motion.v1",
  "motion_id": "neutral_idle_south_fixture",
  "rig_id": "operator_south_fixture",
  "profile": "unarmed",
  "group": "posture",
  "action": "idle_relaxed_01",
  "direction": "s",
  "frame_count": 15,
  "fps": null,
  "loop": true,
  "interpolation": "linear_integer_half_away_from_zero",
  "tracks": [
    {"part": "arm_near", "keys": [
      {"frame": 0, "offset": [0, 0]},
      {"frame": 7, "offset": [0, -2]},
      {"frame": 14, "offset": [0, 0]}
    ]}
  ],
  "contacts": [
    {"part": "foot_near", "frames": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "point": [61, 106]}
  ]
}
```

Other required fields/defaults: the complete exact list of rig part IDs must be covered (untracked parts stay at explicit [0,0]); strictly increasing keyframe numbers in [0, frame_count-1], with endpoints at first and last frame, and integer offsets only. Frame indices are zero-based. `fps:null` explicitly means no authored animation timing; preview fps is ephemeral and cannot become canonical timing. Reject unknown interpolation modes, malformed contact frames, moved non-movable root parts, frame count outside 1..120, and layer offsets that crop any visible pixel.

Interpolation is piecewise linear in **rational integer arithmetic**; after interpolating a segment use signed half-away-from-zero rounding and integer-only full-canvas translations. No RGB conversion, resampling, scaling, shear, frame rotation, image-model inpainting or new palette colors. Render back-to-front in stable `draw_order` order with straight alpha compositing. Never derive a missing direction by mirroring; the 96px enemy runtime's conditional mirror does not override 2.5D Operator authority.

For Phase 1, treat `pivot`/`parent` as explicit semantic metadata and QA context. **Do not silently implement hierarchical rotations or bone deformation.** Advanced rig transforms are a separately reviewed extension. Multiple-part motion can be authored by multiple tracks; no cutout promises smooth limb bending.

## 4. Output and provenance contract

Plan: side-effect-free `plan` reports resolved inputs/SHAs, target identity, 128px or 96px profile, fixture/art status, frame count and expected output geometry; does not create files.

Render is explicit and confined to ignored
`.ai/operator_motion_foundry/runs/<content-addressed-job-id>/`:
- `candidate/<owner>__<layer>__<profile>__<group>__<action>__<direction>__<N>f__<SIZE>.png` (RGBA, horizontal strip, `width = N * frame_width`, `height = frame_height`)
- `preview/contact_sheet.png` (non-canonical)
- `report.json` (`custodian.motion_foundry.report.v1`)
- `receipt.json` (`custodian.motion_foundry.candidate.v1`)

Use the **existing Operator V2 8-token filename grammar** via `custodian/tools/pipelines/operator_asset_schema.py` for Operator candidates. For fixture review, example south-facing 15f x 128 sheet: `operator__full_body__unarmed__posture__idle_relaxed_01__s__15f__128.png` at 1920x128 RGBA. This is a *synthetic candidate*, not an authorized reproduction or replacement of the accepted 15f idle. Record candidate hashes, resolved source hashes, keyframe/rig canonical-JSON hashes, profile hashes, versions, applied transforms and QA evidence. Do not use timestamps for identity. If an identical job already exists, verify byte hashes and return it; if mismatched, fail closed without overwrite or cleanup.

Candidate report fields: schema, status (`candidate` only), owner, rig/motion identities, source SHA map, profile/reference hashes, output geometry, frame_count, loop, `authored_fps:null`, preview-only fps when used, candidate file SHA, per-frame alpha bbox/centroid/palette, per-part integer translations and contact residuals, loop-boundary metrics, `hard_failures`, `warnings`, `publication_authorized:false`. The QA report is not an art-approval receipt.

## 5. Quality gates

Hard fail: wrong grid/frame count, changed profile/reference, source hash mismatch, malformed rig/pose, clipping, palette expansion, non-deterministic byte output, missing alpha, non-integer scale/transform, invalid direction/semantic name, forbidden path, incorrect contact lock or root movement. Proof must include **negative controls** for each category. Approved color palette must come from exact source part pixels/reference, not a guessed list. For sample fixtures with partial alpha, alpha-composite colors may be new mathematically; Phase 1 accepts only binary-alpha 0/255 part sources to guarantee palette-subset provenance and test it.

Advisory until calibrated: silhouette continuity, anatomy proportions, apparent center-of-mass jump, pose plausibility, unnatural overlapping cutouts, loop feel, and transition readiness. Reuse `animation_transition.py` and `art_agent/qa.py` measurements where their interfaces apply; do not create conflicting score authorities. An all-green synthetic QA report is **engineering proof only**, never human-approved Operator animation.

Frame contact semantics: contact-marked source-part point after integer translation must equal its declared fixed world-space point in each specified frame. Explicit noncontact frames may move. Root and ground are separate; alpha bounding-box bottom is not the root. Loop contract compares final-to-first pose/part transforms (with explicit loop seam rules); no hidden intermediate duration or inferred FPS.

## 6. Delivery slices and gates

| Slice | Deliverable | Dependency | Review/exit |
|---|---|---|---|
| MF1 `operator-motion-foundry-core-v1` | Pure Python rig/pose parser, integer interpolation, RGBA renderer, content-addressed candidate output, deterministic fixture and QA | none | fresh review and focused negative controls; no authored-art claim |
| MF2 `operator-motion-foundry-source-bridge-v1` | Exact Operator2DIngress identity binding, inspect/plan and **explicit** source-work export with immutable receipt and collision refusal | `review-operator-motion-foundry-core-v1` | fresh review; source remains untrusted and no publish |
| MF3 (future human-asset gate) | User-approved layered 128px Operator south source, source hashes, one actual 15-frame comparison and Workbench review | MF2 review + genuine source components | new planned packet after art-input decision, subjective user approval mandatory |
| MF4 (future research) | Bone rotations/IK, 3D directional render or model-assisted pixels behind candidate-only adapter | MF3 evidence | architecture review and quality comparison; no model training prerequisite |

MF1 files (new):
- `custodian/tools/operator/motion_foundry/__init__.py`
- `custodian/tools/operator/motion_foundry/schema.py`
- `custodian/tools/operator/motion_foundry/rig.py`
- `custodian/tools/operator/motion_foundry/motion.py`
- `custodian/tools/operator/motion_foundry/render.py`
- `custodian/tools/operator/motion_foundry/qa.py`
- `custodian/tools/operator/motion_foundry/cli.py`
- `custodian/tools/validation/operator_motion_foundry_core_smoke.py` (generated fixtures, no external images)

MF2 files (new):
- `custodian/tools/operator/motion_foundry/source_bridge.py`
- `custodian/tools/validation/operator_motion_foundry_source_bridge_smoke.py`
- Limited read-only integration in the existing `custodian/tools/operator/operator_2_5d_ingress.py` only if required; prefer calling existing public interfaces without modifying publication.
- Operator pipeline-specific generation-brief binding must reuse `operator_generation_brief.py` if it needs provenance, not invent a new approver.

MF2 explicit source-work handoff (not claim-time input):
`custodian/asset_drop/source_work/operator/motion_foundry/<job-id>/<canonical-operator-filename>.png`.
Provenance sidecar beside that source stays `candidate` and must be content-addressed. Use exact published Operator V2 filename grammar and *current* profile/target plan; refuse a selected target already occupied by accepted same-generation canonical art unless invoking an existing explicit replacement-review workflow. SourceArtService's authorized source roots already include `asset_drop/source_work`; only that existing service can normalize/review and pass to its specialized inbox. No direct `content/sprites/operator/source/` mutation.

Initial art example: **15 × 128 × 128 south-only**, 1920x128 horizontal. Eight-direction 15f full family would be 1920x1024 in N,NE,E,SE,S,SW,W,NW row order, but MF1 and MF2 do not assert eight available source rigs. No new image-generation output should be saved to Asset V2 inbox without current schema-validated source/owner and existing approval gates. Reference/placeholder pixels are not production-approved assets. The existing humanoid enemy 96x96 rig/source/atlas remains untouched.

## 7. Focused validation and threat model

MF1 test/negative-control matrix:
1. Known integer interpolation, including negative halves and exact endpoints.
2. Repeat execution in separate temp directories produces byte-identical PNGs and canonicalized receipts (except explicitly allowed absolute diagnostic paths, excluded from identity).
3. Fixture 15f x 128x128 -> 1920x128 RGBA; pixel-color alpha and z-order checks; correct contact/root.
4. Corrupt source hash, wrong part size/alpha, unknown IDs, duplicate draw order, hierarchy cycle, invalid timeline, direction mismatch, changed profile SHA, traversal/symlink escape, unsupported transform, clipping, source palette mutation all fail with zero writes to canonical paths.
5. A changed requested output at an existing job ID fails rather than overwriting.
6. Guard that `custodian/content/` and the authorized Operator design/reference have identical hashes before/after tests.

MF2 test/negative-control matrix:
1. Exact current target binding resolves from existing `Operator2DIngress`; reject stale/unapproved profile/reference hashes, wrong generation/direction/layer, missing plan target and forged job/receipt.
2. A hash-verified candidate can export once to isolated source-work; retry is idempotent when bytes match and fails for collisions.
3. Never auto-run `SourceArtService.handoff`, the Workbench Publish/land path, Asset V2 ingest or runtime build; canonical hash sets remain unchanged.
4. Output provenance still says candidate/unapproved; no self-asserted human art/timing approval, no default 8-FPS promotion.
5. Regression checks: `operator_2_5d_ingress_smoke.py`, `operator_art_agent_v2_pilot.py` where affordable, `operator_2_5d_canonical_visual_contract_smoke.py`, `operator_animation_workbench_smoke.py`; full `run_validation.py --changed --json` with normal Godot host locks, `git diff --check`.

Every implementation gets an independent fresh-context post-land review. The reviewer must attempt falsifications and report whether it proved only synthetic fixture correctness or an actual approved art candidate. Never claim MF3 art accepted from green MF1/MF2 tests.

## 8. Local hardware/cost and expansion

Use Python/Pillow and CPU for MF1/MF2. No CUDA, GPU VRAM, licensed SaaS, new persistent daemon, secrets or external network dependency. Later GPU-assisted synthesis must be pluggable, benchmarked on the user's actual GPU and compared against deterministic outputs for character continuity and cost. Do not promise PixelLab-equivalent image-model quality from MF1.

## 9. Publication and current next action

Publish this spec and both MF1/MF2 implementation-plus-fresh-review packet pairs atomically. If repository authoring automation is opted in, seed packets as `draft/manual` plus `Authoring handoff: auto`; the existing CI validator may promote them to `ready/auto` after targeted checks. Publication and authoring promotion do **not** imply dispatch eligibility, a local claim, implementation, reviewer acceptance or human art approval. Local Codex must inspect live main and `dispatch.py audit --json` before any claim. MF3 must remain unclaimed until real source art is available, with a separate reviewed packet or human-signed visual disposition. All durable summaries link back to: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
