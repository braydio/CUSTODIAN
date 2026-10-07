# OPERATOR 2.5D WORKBENCH MIGRATION + PRODUCTION PIPELINE

**Program ID:** operator-2-5d-workbench-migration-cockpit  
**Status:** active planning / all implementation slices pre-authored and refresh-gated  
**Priority:** P1  
**Reviewed main:** e56a75cfb76cdb5a3a430b21be267b1b4e20ed6e  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac60342-02a4-83e9-b402-577faeed63ff  
**Last updated:** 2026-10-07

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

The canonical visual-contract workstream must incorporate these human decisions before WB25-1 is refreshed to ready.

## Family is the production unit

A target family owns required directions/layers and completion.

Example first family:

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
  "loop": true
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

All automated findings use the canonical visual-contract categories:

~~~text
HARD_FAIL
STRUCTURAL_WARN
ART_DIRECTION_WARN
INFO
~~~

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

## Implementation series

| Slice | Workstream | Initial state | Primary closure |
| --- | --- | --- | --- |
| WB25-1 | operator-2-5d-workbench-cockpit-foundation | draft / prerequisite refresh | generation namespace, plan v2, target-first tree/matrix |
| WB25-1R | review-operator-2-5d-workbench-cockpit-foundation | dependency-gated | independent target/namespace truth review |
| WB25-2 | operator-2-5d-workbench-ingress | draft / refresh-required | guided New/Import + directional package intake |
| WB25-2R | review-operator-2-5d-workbench-ingress | dependency-gated | provenance/rollback/import review |
| WB25-3 | operator-2-5d-workbench-polish-automation | draft / refresh-required | profile-guided Aseprite polish + temporal diagnostics |
| WB25-3R | review-operator-2-5d-workbench-polish-automation | dependency-gated | mutation/QA boundary review |
| WB25-4 | operator-2-5d-workbench-review-automation | draft / refresh-required | canonical QA, family/sequence review, sandbox runtime proof |
| WB25-4R | review-operator-2-5d-workbench-review-automation | dependency-gated | anti-drift/sequence/sandbox review |
| WB25-5 | operator-2-5d-workbench-production-queue | draft / refresh-required | queue/dashboard + deterministic generation briefs |
| WB25-5R | review-operator-2-5d-workbench-production-queue | dependency-gated | queue math/brief review |
| WB25-6 | operator-2-5d-runtime-promotion | draft / refresh-required | cohort-based 2.5D production cutover + rollback |
| WB25-6R | review-operator-2-5d-runtime-promotion | dependency-gated | no-mix/runtime/rollback review |

Expected implementation packets: **6**.

## Mandatory refresh cadence

Every substantial dependent is intentionally pre-authored but cannot be claimed from stale predecessor assumptions.

- WB25-1: refresh after the viability audit is formally completed and the corrected canonical visual contract + paired review land.
- WB25-2: refresh after WB25-1 + review.
- WB25-3: refresh after WB25-2 + review.
- WB25-4: refresh after WB25-3 + review.
- WB25-5: refresh after WB25-4 + review.
- WB25-6: refresh after WB25-5 + review and real queue/verification counts exist.

Each refresh re-derives current public APIs, exact files, locks, profile/reference hashes, validation paths, and any changed completion boundary.

## Current repository drift / prerequisites

At authoring time:
- operator-2-5d-animation-viability-audit is implemented on agent/operator-2-5d-animation-viability-audit at 0fd497c43 but remains unmerged/paused for human completion; main still advertises its packet as ready.
- operator-2-5d-canonical-visual-contract is implemented/corrected on agent/operator-2-5d-canonical-visual-contract at 914d9d2d9 but remains unmerged/provisional and still needs the human scale/root decisions above incorporated, then paired review.
- OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json is v1 and not generation-aware.
- Workbench browser discovery begins from existing source, so truly missing target art is invisible.
- operator_asset_schema.py has no art_generation dimension and current operator canonical source paths would collide if legacy and 2.5D authoring generations coexist.
- OPERATOR_ART_AGENT_SYSTEM.md still describes the legacy accepted 96px registration path as its concrete profile-mode example. Preserve that legacy behavior, but new 2.5D work must consume the accepted generation-specific profile rather than retyping 96px assumptions.
- OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md remains correct that one generated runtime database + OperatorAnimationSelector own production selection; WB25-6 changes which authoring generation feeds that runtime identity, not the runtime database architecture.

## Exit condition

The program is complete when a missing 2.5D target can be selected, briefed, imported/authored, normalized, polished, objectively reviewed, human-approved, sandbox-verified, published, tracked in the queue, and safely promoted as part of a coherent runtime cohort without overwriting legacy source or creating a second runtime animation authority.
