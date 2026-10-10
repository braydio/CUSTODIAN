# OPERATOR 2.5D WORKBENCH MIGRATION + PRODUCTION PIPELINE

**Program ID:** operator-2-5d-workbench-migration-cockpit  
**Status:** active implementation / WB25-4 review found R0-01 / correction cycle 1 ready-auto
**Priority:** P1  
**Reviewed main:** `5f4762ab06a4b3d45608ef9d43b5e8bce92d1e44`  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb  
**Last updated:** 2026-10-10

## Goal

Make Operator 2.5D animation production a target-driven, family-oriented pipeline where external or generated pixels enter as untrusted source-work, are deterministically normalized against the accepted Operator profile, polished in Aseprite, objectively QA'd and human-reviewed in Operator Workbench, sandbox-verified in Godot, and only then promoted into production as a coherent runtime generation.

The Workbench is the conductor. Aseprite is the pixel editor. Image generation and external art produce source-work only. Workbench/Source Session owns deterministic normalization and publication. The generated Operator runtime database remains the only production animation database.

## Locked production doctrine

Three pixel states are intentionally distinct:

~~~text
SOURCE-WORK
  raw image-generator / artist output
  may be oversized, antialiased, arbitrary grid

        ↓ deterministic Source Session normalization

CANONICAL AUTHORING ART
  exact semantic identity
  exact frame/grid contract
  profile/reference provenance
  editable in Aseprite

        ↓ guarded Workbench publication

RUNTIME ART
  generated/synchronized runtime PNGs
  generated runtime manifest
  one operator_runtime_frames.tres
  consumed through OperatorAnimationSelector
~~~

No source-work file becomes runtime truth merely because its dimensions happen to look correct.

## Locked authority inputs

The migration is no longer starting from an empty target set.

- **Design lock:** `/CUSTODIAN/implementation_inputs/operator_2_5d_design_lock_v1_8dir_1f_256.png` — 2048x256 RGBA, 8x1 directions at 256x256, N/NE/E/SE/S/SW/W/NW, SHA-256 `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`. This owns visual identity, anatomy, armor/cloak topology, fixed top-down 2.5D projection, palette/material language and directional identity for all future Operator animation authoring.
- **First canonical production family:** `/CUSTODIAN/implementation_inputs/operator_2_5d_unarmed_posture_idle_relaxed_01_full_body_v1_8dir_15f_128.png` — 1920x1024 RGBA, 15 columns x 8 direction rows, 128x128 cells, semantic identity `unarmed/posture/idle_relaxed_01/full_body`, SHA-256 `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`. This is the first and currently only fully authored animation the user considers aligned with the migration target.
- Existing pre-migration runtime art remains legacy/fallback/donor material until migrated. Runtime reachability alone does not make it canonical 2.5D art.

The canonical visual-contract workstream is complete/reviewed. WB25-1 consumed its accepted profile/reference hashes and seeded this already-authored idle as canonical rather than pretending every 2.5D target is missing.
## Canonical 2.5D body contract

The human decision from this authoring chat is:

- art generation: operator_2_5d_128
- canonical body frame: 128x128
- shared visual scale target: 0.225
- neutral apparent body height target: approximately 84-88 px
- center axis: x = 64
- neutral support/contact presentation row: approximately y = 106
- projected_world_root, shadow_origin, and visible support-foot row remain distinct semantic concepts
- body remains 128x128; weapon, FX, and exceptional cape motion may use separate larger presentation envelopes
- no body shrink is allowed merely to fit weapon/FX overflow

The canonical visual-contract workstream incorporated these human decisions; WB25-1 preserved them in the live target/profile authority.

## Family is the production unit

A target family owns required directions/layers and completion.

First family is already authored and is the production seed:

~~~json
{
  "art_generation": "operator_2_5d_128",
  "profile": "unarmed",
  "group": "posture",
  "action": "idle_relaxed_01",
  "required_directions": ["n","ne","e","se","s","sw","w","nw"],
  "required_layers": ["full_body"],
  "frame_count": 15,
  "frame_size": [128,128],
  "loop": true,
  "source_sha256": "d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3",
  "design_reference_sha256": "41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b",
  "status": "authored"
}
~~~

Individual directions may be authored independently, but fallback/projected/legacy art never closes a canonical 2.5D family.

## End-to-end stages

| Stage | Owner | Closure |
| --- | --- | --- |
| Target | Workbench target projection | exact generation/profile/group/action/direction/layer leaf exists even when missing |
| Brief | Workbench generation brief | immutable target/reference/timing/profile hashes exported |
| Source | artist/image generation | source-work only; no canonical/runtime mutation |
| Ingress | Workbench + SourceArtService | identity-bound Source Session/package manifest |
| Normalize | SourceArtService + registration profile | shared scale, integer registration, exact target canvas, proof receipt |
| Polish | Aseprite through existing Art Agent/Workbench bridge | local pixel edits only; no semantic authority changes |
| QA | canonical QA + temporal QA | dimensions, alpha, components, registration, F01 fidelity, palette, silhouette, temporal shimmer, loop seam |
| Human review | Workbench Review/Sequence | subjective motion/readability approval after objective gates |
| Sandbox | bounded Godot/Motion preview | real in-game scale/presentation proof without production selector mutation |
| Publish | Workbench transaction | canonical source → runtime sync/import/build/validation/landing |
| Promote | runtime generation policy | coherent cohort flips generation atomically; rollback available |

## Aseprite role

Keep Aseprite. Move plumbing out of it.

Aseprite owns:
- onion-skin animation polish;
- local silhouette/outline corrections;
- deliberate frame edits;
- shoulder/highlight temporal stabilization;
- cloth/secondary-motion polish;
- timing preview.

Workbench/tooling owns:
- source slicing and grid identity;
- registration proposals;
- profile guides/ghosts;
- detached-component detection;
- temporal outline/highlight diagnostics;
- loop-seam metrics;
- naming and canonical paths;
- stale-profile/reference guards;
- publication/runtime rebuild.

The standalone Lua helpers created during the first idle family are prototypes, not new authorities. WB25-3 folds the useful behavior into the existing Workbench/Art Agent bridge rather than keeping a parallel pile of scripts.

## Objective review taxonomy

The live objective QA authority is `custodian.operator_art_qa.v2` from
`custodian/tools/operator/art_agent/qa.py`. Findings carry severity
`critical`, `major`, or `advisory` plus their existing finding class.
The aggregate QA status is `RED`, `NEEDS_HUMAN_REVIEW`, `YELLOW`, or
`GREEN`. WB25 review/queue surfaces consume that schema directly and must not
reintroduce historical planning labels such as `HARD_FAIL` or
`STRUCTURAL_WARN` as a parallel taxonomy.

Minimum family QA:
- exact frame dimensions/count;
- allowed alpha contract;
- connected-component/island scan;
- alpha bbox and clipping;
- apparent body size;
- semantic root/support residual;
- center drift;
- F01 reference difference;
- palette/material drift;
- silhouette/outline drift;
- frame-to-frame temporal delta;
- F15→F01 loop seam;
- stale profile/reference SHA;
- direction-family continuity.

Automated tools may propose a bounded repair. They do not silently redesign anatomy, camera pitch, pose, root semantics, or costume topology.

## Runtime generation policy

Authoring generations coexist. Production must not silently mix them.

Recommended authoring source layout:

~~~text
legacy_96
  existing canonical source paths remain unchanged

operator_2_5d_128
  content/sprites/operator/source/generations/operator_2_5d_128/animations/...
~~~

Runtime semantic identity remains profile/group/action/direction/layer. WB25-6 selects which authoring generation feeds the unchanged runtime identity.

Promotion is by coherent cohort, not whichever individual PNG happens to exist. Example cohorts:

1. unarmed core: relaxed idle, ready idle, walk, run, relaxed↔ready transitions
2. defensive mobility: dodge, block, hit reactions
3. melee 1H posture/locomotion
4. melee 1H attack/guard
5. ranged 2H
6. sidearm
7. specials/reactions/death

A cohort cannot promote while any required family is missing, stale, fallback/projected, unreviewed, or not runtime-verified.

## Source intake convention

External/generated unprocessed art belongs under:

~~~text
custodian/asset_drop/inbox/operator_2_5d/
~~~

Recommended human-readable filename:

~~~text
operator_2_5d_128__unarmed__posture__idle_relaxed_01__ne__full_body__15f.png
~~~

The filename is convenience only. Package/session metadata owns semantic identity, generation, canonical profile/reference SHA, source hash, frame contract, timing contract, and donor/reference provenance. Canonical destinations always come from operator_asset_schema.py.

### Durable Dropbox implementation inputs

```text
/CUSTODIAN/implementation_inputs/operator_2_5d_design_lock_v1_8dir_1f_256.png
/CUSTODIAN/implementation_inputs/operator_2_5d_unarmed_posture_idle_relaxed_01_full_body_v1_8dir_15f_128.png
```

These are immutable handoff inputs, not runtime paths. The canonical-contract packet must preserve exact source bytes under Operator source-work and use live specialized schema/tooling for canonical destinations.
## Implementation series

| Slice | Workstream | Initial state | Primary closure |
| --- | --- | --- | --- |
| WB25-1 | operator-2-5d-workbench-cockpit-foundation | **complete / reviewed after R0-01 correction** | generation namespace, plan v2, target-first tree/matrix |
| WB25-1R | review-operator-2-5d-workbench-cockpit-foundation | **complete / correction re-review passed** | independent target/namespace truth review |
| WB25-2 | operator-2-5d-workbench-ingress | **complete / reviewed through cycle-2 correction** | guided New/Import + directional package intake |
| WB25-2R | review-operator-2-5d-workbench-ingress | **complete / final correction re-review passed** | provenance/rollback/import review |
| WB25-3 | operator-2-5d-workbench-polish-automation | **complete / reviewed after R0-01 correction** | profile-guided Aseprite polish + temporal diagnostics |
| WB25-3R | review-operator-2-5d-workbench-polish-automation | **complete / correction re-review passed** | mutation/QA boundary review |
| WB25-4 | operator-2-5d-workbench-review-automation | **implementation complete / review finding R0-01** | canonical QA, family/sequence review, sandbox runtime proof |
| WB25-4R | review-operator-2-5d-workbench-review-automation | **complete / blocking R0-01** | anti-drift/sequence/sandbox review |
| WB25-5 | operator-2-5d-workbench-production-queue | draft / refresh-required | queue/dashboard + deterministic generation briefs |
| WB25-5R | review-operator-2-5d-workbench-production-queue | dependency-gated | queue math/brief review |
| WB25-6 | operator-2-5d-runtime-promotion | draft / refresh-required | cohort-based 2.5D production cutover + rollback |
| WB25-6R | review-operator-2-5d-runtime-promotion | dependency-gated | no-mix/runtime/rollback review |

Expected implementation packets: **6**.

## Mandatory refresh cadence

Every substantial dependent is intentionally pre-authored but cannot be claimed from stale predecessor assumptions.

- WB25-1: complete and independently reviewed after bounded correction R0-01. Direction workflow now reads the exact direction workspace and saved creation readiness uses the backend classifier. Final planning truth remains 69 live legacy semantic families, 1 authored canonical family, 68 remaining baseline canonical families, and 544 baseline direction-animation strips.
- WB25-2: complete and independently reviewed through cycle-2 correction. The final accepted ingress validates exact target-bound Source Sessions, generation-scoped handoff/workspaces, independent direction progress, legacy compatibility, no-runtime-promotion, and the physical saved Aseprite frame/canvas/timing contract before recovery/completion while preserving legitimate artist edits.
- WB25-3: complete and independently reviewed after bounded correction R0-01. Exact detached-island and registration proposals are re-derived from the current physical Workbench, render, masks and landmarks before mutation; forged/stale coordinates or deltas fail before Art Agent apply, while valid scoped apply/undo remains intact.
- WB25-4: implementation landed, but its fresh paired review found blocking R0-01: a caller-supplied `NOT_REQUIRED` human disposition can waive `NEEDS_HUMAN_REVIEW` and still reach effective `runtime_verified=true`. Planning now authorizes cycle-1 correction `operator-2-5d-workbench-review-automation-review-corrections-1`: derive human state from live QA, accept only backend-authored explicit Workbench approval for human-required evidence, bind approval to the exact current evidence hash, and revalidate that contract at `current_receipt()`. The correction and its paired re-review are `ready/auto`; no new Dropbox decision subsystem is introduced.
- WB25-5: refresh only after the WB25-4 correction + fresh re-review pass.
- WB25-6: refresh after WB25-5 + review and real queue/verification counts exist.

Each refresh re-derives current public APIs, exact files, locks, profile/reference hashes, validation paths, and any changed completion boundary.

## Current repository drift / prerequisites

Current live-main refresh (2026-10-10):
- New Animation backend is reviewed complete (`a26982b8d` correction; `0ebea7b6` cycle-1 re-review).
- Human art-direction ambiguity is resolved: the design lock and first authored relaxed-idle family are the exact Dropbox inputs/hashes above. Do not reopen whether legacy live art is the migration target.
- `operator-2-5d-animation-viability-audit` completed its current-main read-only closeout: 69 production-reachable families are legacy fallback, one supplied relaxed-idle source is canonical but not runtime-published, and 68 semantic families remain in the baseline atlas estimate. No new subjective visual decision was needed.
- `operator-2-5d-canonical-visual-contract` and its paired review are complete/passed. Accepted registration is center x=64/root [64,106]/shadow and ground [64,107]. The unchanged shared-scale 128px reference SHA-256 is `e529df0e0ceaeb941f67ed18ce93799755053b7c516a9f02a5b6929248e25fb9`; accepted `operator_2_5d_128` profile SHA-256 is `05e92192af68b2f4e7516f59a0938e536926f3525a31b42dd7695f61d77ca761`; first-family source SHA-256 is `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`; design lock SHA-256 is `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`. The first family is `unarmed/posture/idle_relaxed_01/full_body`, 8 directions x 15 frames. Universal action-envelope fit is explicitly not asserted; FPS is unknown/null and non-blocking. Fresh paired review passed with no findings and landed at `4aac9437`.
- WB25-1 and bounded correction R0-01 are landed/re-reviewed clean. The live v2 plan projects all 69 production-reachable targets, one canonical family and 68 missing canonical counterparts; direction workspaces and saved creation readiness are truthful.
- `OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json` is now backward-readable v2 and generation-aware through the WB25-1 target projection.
- `operator_asset_schema.py` now owns additive generation-aware canonical source paths while preserving legacy behavior.
- WB25-2 and its two bounded correction cycles are complete/reviewed. The final cycle-2 review passed with zero blocking defects/evidence gaps on exact saved-document proof, preserving target binding, independent direction progress, collision semantics, legacy-96 behavior and unconditional 2.5D publication refusal.
- WB25-3 and its bounded R0-01 correction are complete/reviewed. The accepted apply boundary re-inspects the physical Workbench, re-renders current frames, reloads masks/landmarks and re-derives erase/registration proposals before mutation; forged/stale proposal data cannot reach Art Agent operations. QA remains `custodian.operator_art_qa.v2` and publication/runtime bytes remain untouched.
- WB25-4 implementation binds each leaf receipt to exact Workbench/render/profile/reference/physical-timing and QA evidence; family/sequence/sandbox/runtime no-diff behavior passed focused review. The fresh paired review nevertheless found blocking R0-01 in the required-human gate: caller-supplied `NOT_REQUIRED` can waive `NEEDS_HUMAN_REVIEW`. Cycle-1 correction + re-review are now ready/auto with an explicit backend-authored Workbench approval provenance/evidence contract. `RUNTIME_VERIFIED` remains review evidence only and WB25-4 still does not own `PUBLISHED`.
- Production runtime remains one generated database + `OperatorAnimationSelector`; WB25-6 changes which authoring generation feeds that identity, not the runtime authority architecture.
## Exit condition

The program is complete when a missing 2.5D target can be selected, briefed, imported/authored, normalized, polished, objectively reviewed, human-approved, sandbox-verified, published, tracked in the queue, and safely promoted as part of a coherent runtime cohort without overwriting legacy source or creating a second runtime animation authority.
