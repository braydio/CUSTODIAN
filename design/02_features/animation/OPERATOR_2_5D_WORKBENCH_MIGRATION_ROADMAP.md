# OPERATOR 2.5D WORKBENCH MIGRATION + PRODUCTION PIPELINE

**Program ID:** operator-2-5d-workbench-migration-cockpit  
**Status:** WB25-1 through WB25-5 complete/reviewed; idle source intake and R0-01 timing correction complete/reviewed; WB25-6 real release held, closure audit ready
**Priority:** P1  
**Reviewed main:** `eff74f4164e46fac2abb5dc91fdbfee6b601d429`  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38  
**Last updated:** 2026-10-10

## Goal

Make Operator 2.5D animation production a target-driven, family-oriented pipeline where external or generated pixels enter as untrusted source-work, are deterministically normalized against the accepted Operator profile, polished in Aseprite, objectively QA'd and human-reviewed in Operator Workbench, sandbox-verified in Godot, and only then promoted into production as a coherent runtime generation.

The Workbench is the conductor. Aseprite is the pixel editor. Image generation and external art produce source-work only. Workbench/Source Session owns deterministic normalization and publication. The generated Operator runtime database remains the only production animation database.

## Locked animation-harness decisions and change authority

These are **existing approved choices**, not new values or a parallel configuration. Each remains owned by its cited source. Automation, import packages, pixel measurements, QA results, generation briefs and saved Aseprite documents may **observe** these choices but may not silently amend them. Proposed revisions require a separate recorded human decision, the owning spec/profile update, regenerated source/hash evidence, and relevant focused regression tests.

| Locked decision | Existing owning authority | Non-negotiable guard |
| --- | --- | --- |
| Operator 2.5D visual identity, material/projection and N/NE/E/SE/S/SW/W/NW order | Canonical visual contract, accepted design-reference PNG SHA `41782240...`, target plan | Wrong source/reference/hash, swapped directions or invented mirrored directions are not accepted canonical art. |
| Body canvas/registration | Active `operator_2_5d_128` profile SHA `05e92192...`, canonical visual contract; 128×128 cells, center x=64, projected root [64,106], shadow [64,107], shared visual scale 0.225 | Reject unapproved per-direction re-scaling, alpha-bbox recentering or changes to accepted coordinates. Exceptional action envelopes are separately reviewed. |
| First accepted canonical source | 8×15 ×128px `idle_relaxed_01/full_body` source SHA `d4a6a5f5...`, v2 plan | Eight physical editable directions are not eight review-verified directions. Pixels and target/source-binding hashes require live evidence. |
| Animation clock | v2 plan `fps=null` until explicit approved authoring, physical Workbench timeline for edit/preview, source `.animation.json` only after guarded publication | The editor 8 FPS/125 ms fallback is **not** an authored clock; `timing_authority=true` alone is not proof of the human timing decision. Require exact current approval provenance before effective 2.5D review eligibility. |
| Art authority states | Asset Pipeline V2, Source Sessions, Workbench and guarded publication, WB25-6 policy | Source-work, editable Workbench, QA-verified art and materialized runtime are distinct; neither a saved document nor a generated brief is publication. |
| Review ownership | Art Agent `operator_art_qa.v2`, Workbench `Operator2DReview.current_receipt`, human explicit QA approval, separate Godot sandbox | Do not collapse objective QA, subjective human disposition, approved timing and real sandbox presentation into one Boolean or cached success. |
| Cohort/runtime authority | 2.5D Workbench migration roadmap, WB25-6 packet, one `OperatorAnimationSelector`, one generated manifest/catalog/SpriteFrames database | A target family closes only with required directions/layers and current effective receipts; a complete family is not automatically a gameplay-coherent cutover. Legacy remains selected until a dependency-closed, explicitly human-chosen cohort passes a reversible release transaction. |

**Implementation-facing rule:** Where code accepts editable Workbench JSON, separate *descriptive state* from *permission*. Missing, inconsistent, copied or stale decision evidence must fail closed. Revalidate against the saved physical document and the current profile/target/reference, not merely self-asserted manifest fields. This is an operator-art workflow integrity guard, **not a claim that local files are cryptographically tamperproof**.

Executable decision regression ownership is the existing `custodian/tools/validation/operator_animation_timing_smoke.py`, `operator_2_5d_review_smoke.py`, `operator_2_5d_ingress_smoke.py`, `operator_animation_targets_smoke.py`, and production queue/runtime authority smokes. New timing-intent provenance tests are authored by `operator-animation-decision-authority-hardening-v1`; they do not authorize an actual FPS choice or WB25-6 activation.

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

## Composition policy (human-approved, 2026-10-11)

**Full-body-first, selectively modular** is now the production *design
choice*, not a runtime-generation switch. The owning contract is
`design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md` under
"Operator presentation composition doctrine". This clarifies that the
existing **69 families / 552 directional slots** are baseline
`full_body` *art-authoring targets*: their proposed 128px generations
should retain cohesive full-body neutral idle, ordinary locomotion and
committed whole-body actions. No already-accepted idle pixel or source
target is modified by this decision.

Where the gameplay *legally* permits locomotion simultaneously with an
independently facing upper-body aim/fire/guard/parry or weapon-ready phase,
preserve and **purposefully extend** the existing split-body presentation
capability. Such 2.5D split art requires separately approved canonical
128px lower+upper directional/source contracts with exact shared root,
cadence, weapon/socket and state ownership. **Do not** auto-split the 15f
accepted 2.5D idle, mirror missing views, duplicate generic ready-walk
variants, or demand 552× multiple layers merely for completeness.

The source-grounded and independently reviewed
`custodian/docs/reports/operator_presentation/OPERATOR_2_5D_COHORT_DEPENDENCY_CLOSURE.md`
reports all relevant state edges OPEN for 2.5D live migration; no
`operator_2_5d_128` split runtime contract has been approved. The new
`operator-2-5d-composition-mode-guard-v1` fixture-only packet plus fresh
review covers full-body/split/exclusive plan preflight, body-owner/clock,
same-generation registration, independent aiming vs travel, and fail-closed
partial/mixed parts. It leaves the active 96px presentation unchanged.
Existing `operator-guard-parry-composition-polish` still owns actual
moving guard/parry gameplay composition, and the existing 96px modular
directional coverage closeout remains a later visual-gap assessment.
No workstream may independently create a second presentation owner or
new source-to-runtime database.

WB25-6 must consume this design lock and its reviewed guard. It remains
`draft/manual`, requiring an explicit human-chosen dependency-closed
cohort, exact 2.5D art and timing approvals, physical QA/sandbox receipts,
and safe rollback before any 128px runtime activation.

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
| WB25-4 | operator-2-5d-workbench-review-automation | **complete / accepted after cycle-1 correction** | canonical QA, family/sequence review, sandbox runtime proof |
| WB25-4R | review-operator-2-5d-workbench-review-automation | **complete / R0-01 corrected and re-reviewed clean** | anti-drift/sequence/sandbox review |
| WB25-5 | operator-2-5d-workbench-production-queue | **complete / accepted** | live queue/dashboard + deterministic generation briefs |
| WB25-5R | review-operator-2-5d-workbench-production-queue | **complete / passed, zero findings** | queue math, real family and brief review |
| WB25-6 preparation | operator-2-5d-cohort-dependency-closure + paired review | **ready / auto, read-only** | current consumer/transition/body-composition dependency closure with no policy/art/runtime writes |
| WB25-6 decision guard | operator-animation-decision-authority-hardening-v1 + paired review | **ready / auto, no art authorization** | explicit human timing intent, current physical proof and executable invariants for accepted 2.5D locks |
| WB25-6 composition guard | operator-2-5d-composition-mode-guard-v1 + paired review | **ready / auto, fixture-only** | prove full-body/default, intentionally split concurrent actions, generation/clock/owner preflight without activating new art |
| WB25-6 | operator-2-5d-runtime-promotion | **draft / refreshed after idle R0-01; real cohort held** | guarded generation switch + rollback |
| WB25-6R | review-operator-2-5d-runtime-promotion | dependency-gated | no-mix/runtime/rollback review |

Core WB25 implementation packets: **6**. An independent **read-only dependency-closure audit** and its paired review precede WB25-6; they are preparatory work, not a seventh release/promotion implementation.

## Mandatory refresh cadence

Every substantial dependent is intentionally pre-authored but cannot be claimed from stale predecessor assumptions.

- WB25-1: complete and independently reviewed after bounded correction R0-01. Direction workflow now reads the exact direction workspace and saved creation readiness uses the backend classifier. Final planning truth remains 69 live legacy semantic families, 1 authored canonical family, 68 remaining baseline canonical families, and 544 baseline direction-animation strips.
- WB25-2: complete and independently reviewed through cycle-2 correction. The final accepted ingress validates exact target-bound Source Sessions, generation-scoped handoff/workspaces, independent direction progress, legacy compatibility, no-runtime-promotion, and the physical saved Aseprite frame/canvas/timing contract before recovery/completion while preserving legitimate artist edits.
- WB25-3: complete and independently reviewed after bounded correction R0-01. Exact detached-island and registration proposals are re-derived from the current physical Workbench, render, masks and landmarks before mutation; forged/stale coordinates or deltas fail before Art Agent apply, while valid scoped apply/undo remains intact.
- WB25-4: complete and independently accepted after cycle-1 correction. R0-01 is fixed: caller-supplied human disposition was removed, `NEEDS_HUMAN_REVIEW` remains required until the explicit Workbench approval path authors canonical provenance with the backend-computed exact evidence hash, `current_receipt()` revalidates that evidence, RED remains non-overridable, and GREEN/YELLOW preserve their no-approval path. The fresh correction re-review passed with zero blocking defects/material proof gaps and no new findings.
- WB25-5: **implemented and accepted**. Implementation `69cdfdbf1`, landed as `d4efc0234`; independent paired review `cd72b90b1` passed with zero findings; 36/36 changed validation passed. The live 69 family/552 direction queue and local deterministic generation-brief/ingress architecture are implemented, including real-record family verification and rank-safe NEXT. The paired review measured **0 current receipt-verified 2.5D leaves / 0 verified families** in its default workspace. No live runtime promotion was performed.
- WB25-6 source-intake bridge (2026-10-11): `operator-2-5d-canonical-idle-workbench-intake` landed at `26167ea6`; all eight immutable 1920×128 source strips and 15×128px saved Workbenches were independently byte-checked. Fresh review discovered blocking R0-01: unknown FPS / 8 FPS preview incorrectly given timing authority. Correction implementation `fa955e5e7` and cycle-1 fresh review both **passed**; all eight manifests now have `timing_authority=false` while preview/physical document timing, artwork, candidate, Source Session and runtime hashes remain unchanged. 0 effective receipts, 0 verified families, 0 published directions. The original intake master absolute path is stale due to a retired worktree, but per-direction source/current physical evidence matched independently. **Release remains held**: no human FPS choice, no full candidate art/QA and no dependency-closed user-approved cohort. A new `ready/auto` read-only `operator-2-5d-cohort-dependency-closure` audit and fresh review will establish exact consumer/preemption/weapon/body-composition closure first; it will not activate generation policy.
- WB25-6: **planning refreshed 2026-10-11 after R0-01 correction; keep draft/manual.** Live runtime sync scans legacy source by default and WB25-5 does not own PUBLISHED. Release must follow a current verified, human-chosen dependency-closed cohort → staged transactional generation switch → confirmed runtime publication and rollback proof. The one accepted idle source family alone is not a coherent release cohort; 0 verified families means no candidate is eligible. See the active WB25-6 packet for full gates.

Each refresh re-derives current public APIs, exact files, locks, profile/reference hashes, validation paths, and any changed completion boundary.

## Current repository drift / prerequisites

- Presentation composition decision (2026-10-11): **full-body-first, selective modular upper/lower only for simultaneous legal movement+upper action**, with independent weapon/FX overlays. This is now approved in the runtime architecture and AGENTS. The 69 full-body target rows remain baseline art authority; do not infer 69 unconditionally full-body runtime behaviors or fabricate split outputs. The reviewed dependency audit remains NOT_RELEASE_ELIGIBLE with open preemption and legacy-vs-2.5D body seams. A separate fixture-only guard and paired review precede WB25-6. Both older roadmap entries saying cohort audit/decision hardening are still `ready` describe historical scheduling, not current queue states; use archived receipts and the actual active packet queue.


- Authoring decision trust audit (2026-10-11): `timing_authority=false` from R0-01 intake correction correctly blocks default 8 FPS, but an editable manifest may still assert `timing_authority=true` and supply a well-formed timeline without independent **user timing decision** provenance. The prepared `operator-animation-decision-authority-hardening-v1` pairs explicit-timing authoring intent with exact physical/workspace/plan/reference evidence, adds negative tests for forged/stale approvals, and records existing visual/runtime lock decisions in the canonical visual contract and agent rules. This is NOT human FPS approval or WB25-6 cutover.

- Current R0-01 closeout: `Operator2DReview.current_receipt()` rejects preview-only timing, but no user-facing authoritative idle timing selection has been made. Do not treat the physical 8 FPS value as approved or flip the boolean by hand.
- Cohort dependency closure audit (2026-10-11, investigated main `7d14aa7d`): `operator-2-5d-cohort-dependency-closure` generated a hash-bound, read-only report at `custodian/docs/reports/operator_presentation/OPERATOR_2_5D_COHORT_DEPENDENCY_CLOSURE.md` and `.json`. The proposed seven-family / 56-direction neutral-motion set remains **NOT_RELEASE_ELIGIBLE**: 8 editable relaxed-idle directions, 0 effective receipts/verified leaves/families, 0 published candidate directions. All twelve enumerated posture/movement/guard/parry/dodge/melee/ranged/equipment/action-completion edges remain OPEN for full-body generation closure. Current posture requires modular lower+upper layers with east/west projection; current locomotion prefers modular layers; the 2.5D plan calls for 8-way full_body. Six families have null frame/loop/FPS contracts, and idle timing remains preview-only with no approved FPS. The physical workspace's source, source-session, document and corrected-manifest hashes match R0-01 evidence; its checkout was 67 commits behind main with preserved untracked intake files. The audit did not modify art/runtime. WB25-6 remains held; return this evidence for human cohort/timing scope decisions before any refresh or switch.
- Latest independent review corrected only ignored art manifests and preserved protected runtime hashes; the old roadmap statements below are historical baseline evidence and must not be used to infer current 2.5D workspace emptiness.


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
- WB25-4 is accepted after correction. The cycle-1 fix removed free-form disposition authority, added backend-authored `workbench_explicit_user` approval provenance bound to `human_review_evidence_sha`, and made `current_receipt()` fail closed on missing/forged/stale approval evidence. Fresh re-review passed. `RUNTIME_VERIFIED` remains review evidence only and WB25-4 still does not own `PUBLISHED`.
- Production runtime remains one generated database + `OperatorAnimationSelector`; WB25-6 changes which authoring generation feeds that identity, not the runtime authority architecture.
## Exit condition

The program is complete when a missing 2.5D target can be selected, briefed, imported/authored, normalized, polished, objectively reviewed, human-approved, sandbox-verified, published, tracked in the queue, and safely promoted as part of a coherent runtime cohort without overwriting legacy source or creating a second runtime animation authority.
