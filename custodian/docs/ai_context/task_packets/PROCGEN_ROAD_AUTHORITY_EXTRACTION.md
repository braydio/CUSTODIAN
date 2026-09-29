# PROCGEN ROAD AUTHORITY EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-road-authority-extraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-candidate-runtime-path-demolition, procgen-distant-chunk-unload`
- Locks: `procgen-runtime`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Extract coherent road generation/repair/surface-state ownership from ProcGenTilemap after generation and streaming seams are stable.
- Completion boundary: Done when main/soft/ruined road topology state, repair/component logic, road visual descriptors/decals, and road debug summary are owned behind one road authority with a narrow ProcGenTilemap façade.
- Current measured state: ProcGenTilemap still contains main-road carving, connectivity repair/pruning, road authority clearing, road semantics, road piece/surface decals, connected-road queries and debug helpers across a very large file.
- Evidence: Road Semantics V2 smokes; archived main-road opt-in behavior; S1 baseline; canonical generation/materialization and chunk cache.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; Road Semantics V2/current road surface contracts.
- Work surface: game/world/procgen/roads/ authority/service plus ProcGenTilemap façade/delegation and road/streaming tests.
- Change: Move road-owned state and methods as one stateful subsystem. Preserve disabled-by-default archived wide-road generation, active narrow route/ruined-road semantics, deterministic component/repair ordering, surface-role decals, and streaming hooks. ProcGenTilemap exposes only required queries/requests.
- Preserve: All road topology/fingerprints, walkability, parking/service apron behavior, decals/material roles, streaming visibility.
- Non-goals: No road redesign, no enabling archived wide roads, no art changes, no claim/export extraction in this packet.
- Acceptance: Road semantic/role/streaming fixed-seed tests match; road state has one owner; ProcGenTilemap no longer contains road-domain algorithms except façade glue.
- Validation: road semantics v2 + road surface roles + placeholder/compound road where applicable + S1 quick + changed-file closeout.
- Task overrides: `none`
- Deferred: Authored claims and generation-state extraction proceed as sibling dependents; façade contraction waits on all.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Finish normally; ProcGenTilemap facade contraction waits for all three extraction siblings.
- Best starting files: ProcGenTilemap road methods; procgen/surfaces road resolvers; road smokes.
- Blockers or open questions: None known at authoring time.
