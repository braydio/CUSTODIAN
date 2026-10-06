# OPERATOR 2.5D WORKBENCH MIGRATION COCKPIT ROADMAP

**Program ID:** `operator-2-5d-workbench-migration-cockpit`  
**Status:** active planning / WB25-1 dependency-gated / WB25-2..4 pre-authored refresh-required  
**Priority:** P1  
**Reviewed main:** `f8ef4c84adf8f332713d4284a4c3aaa89ef51fb0`  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff  
**Last updated:** 2026-10-06

## Goal

Turn the existing Operator Workbench into the production cockpit for migrating from legacy 96px Operator art to the canonical 128px 2.5D model without deleting or overwriting legacy art, hiding missing coverage, or forcing artists through manual CLI choreography.

The program reuses existing Workbench publication, New Animation creation, Source Sessions, Art Agent QA, Preview/Timeline/Motion, and canonical-visual-contract authorities. It does not create a second publisher, a second normalizer, or a new runtime animation state machine.

## Core migration model

Two explicit art generations coexist during migration:

```text
legacy_96
operator_2_5d_128
```

`profile/group/action/direction` remains gameplay/semantic identity. `art_generation` is a separate authoring dimension and must never be overloaded into `profile`.

Legacy records remain discovery-driven. The canonical 2.5D tree is target-driven: required plan leaves exist even when art does not.

```text
2.5D target plan
    LEFT JOIN source/workbench/publish state
        -> MISSING / PARTIAL / ACTIVE / PUBLISHED / VERIFIED
```

Legacy fallback or projected direction coverage is always visible and never counts as canonical 2.5D completion.

## Planned slices

| Slice | Workstream | State | Primary closure |
| --- | --- | --- | --- |
| WB25-1 | `operator-2-5d-workbench-cockpit-foundation` | ready / dependency-gated | generation namespace, plan v2, dual trees, target-driven missing leaves, migration matrix |
| WB25-1R | `review-operator-2-5d-workbench-cockpit-foundation` | ready / auto behind WB25-1 | independent namespace/target-state review |
| WB25-2 | `operator-2-5d-workbench-ingress` | draft / refresh-required | one-click New/Import, generated-art Source Session orchestration, directional packages |
| WB25-2R | `review-operator-2-5d-workbench-ingress` | ready / auto behind WB25-2 | transaction/intake/rollback review |
| WB25-3 | `operator-2-5d-workbench-review-automation` | draft / refresh-required | canonical QA projection, stale-reference guards, sequence review, runtime sandbox proof |
| WB25-3R | `review-operator-2-5d-workbench-review-automation` | ready / auto behind WB25-3 | anti-drift/review/runtime-proof review |
| WB25-4 | `operator-2-5d-workbench-production-queue` | draft / refresh-required | throughput queue, progress dashboard, generation briefs, migration closeout |
| WB25-4R | `review-operator-2-5d-workbench-production-queue` | ready / auto behind WB25-4 | honest completion/priority/export review |

Expected implementation packets: **4**.

## Mandatory refresh cadence

The user explicitly requires each substantial dependent to be re-derived after its predecessor lands.

1. WB25-1 becomes claimable only through its declared dependencies.
2. WB25-2 remains `draft` until WB25-1 + review land and ChatGPT/user refresh it in the authoring chat.
3. WB25-3 remains `draft` until WB25-2 + review land and is refreshed the same way.
4. WB25-4 remains `draft` until WB25-3 + review land and is refreshed the same way.

Every refresh must re-check live public APIs, measured state, changed files, locks, validation paths, and whether predecessor evidence changed the completion boundary.

## Existing authorities consumed

- `operator-2-5d-animation-viability-audit`: production-reachable backlog and legacy/projection truth.
- `operator-2-5d-canonical-visual-contract`: canonical 128 profile, reference SHA, landmarks, material/geometry QA.
- `operator-workbench-animation-creation`: absent semantic animation CREATE/publication backend.
- Workbench V2: source/workspace/publish authority.
- Source Art Service: external/generated source normalization/review/handoff.
- `OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json`: human-authored implementation order/priority authority.
- Preview/Timeline/Motion: visual, sequence, and spatial review authority.

## Relationship to UX Hierarchy V1

The 2026-10-01 UX Hierarchy roadmap predates this migration program.

- UX4 Work Queue is superseded in substance by WB25-1/WB25-4 and must not be implemented as authored.
- UX1/UX2/UX3/UX5 may still be useful later as UI polish, but must be refreshed after this migration program so they consume its state rather than create competing projections.
- This program prioritizes migration throughput and correctness over general interface polish.

## Program non-goals

- No production gameplay selector cutover to 2.5D art.
- No Godot `AnimationTree` replacement.
- No deletion of legacy 96 art.
- No automatic image generation/network call.
- No automatic anatomy warping.
- No second source/runtime publisher.
- No silent mutation/reordering of human-authored animation priorities.
- No claim that projected/fallback art is canonical completion.

## Exit condition

The Workbench can truthfully answer, for every target 2.5D animation/direction: whether art is needed, exact workflow stage, canonical profile/reference provenance, guided ingress, canonical anti-drift status, sequence quality, runtime-sandbox proof, and next highest-value missing item.

Production runtime cutover is a later human/ChatGPT planning gate based on actual 2.5D coverage.
