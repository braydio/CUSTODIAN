# PROCGEN GENERATION STATE EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-generation-state-extraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-candidate-runtime-path-demolition, procgen-distant-chunk-unload`
- Locks: `procgen-runtime`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Extract accepted-world generation snapshot/level-data export ownership from ProcGenTilemap into a focused generation-state authority.
- Completion boundary: Done when capture of generated tile state, authoritative fingerprints, level-data assembly, terrain-builder export, and immutable accepted-world semantic snapshots live behind one generation-state owner.
- Current measured state: ProcGenTilemap still owns _capture_generated_tile_state, get_level_data, terrain-builder export and many debug/generated floor/wall fingerprint helpers while also serving runtime mutation/streaming.
- Evidence: S1 fingerprint schema; canonical semantic candidate/materializer; procgen spatial/determinism tests.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; S1 benchmark schema; current level-data consumers.
- Work surface: game/world/procgen/generation/ accepted-world state/export service, ProcGenTilemap façade, level-data/determinism tests.
- Change: Move immutable/base generated-state capture and level-data serialization into one owner. Runtime mutation overlays remain runtime-owned and are represented explicitly rather than mutating the immutable base snapshot invisibly. Preserve all externally consumed level-data keys unless a versioned migration is unavoidable and tested.
- Preserve: Fingerprints, level-data keys, terrain/road/region/intent data, ContractWorldLoader consumers, minimap/debug consumers.
- Non-goals: No save-system work, no loader placement extraction here, no semantic model redesign.
- Acceptance: S1 fixed fingerprints and all direct level-data consumers match; ProcGenTilemap delegates export/capture; immutable base state is clearly separated from runtime mutation overlays.
- Validation: Spatial normalization + candidate/materializer determinism + level-data consumer/loader representative tests + S1 quick + changed-file closeout.
- Task overrides: `none`
- Deferred: Facade contraction follows all ProcGenTilemap extraction siblings.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update the detailed procgen roadmap and matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Finish normally; ProcGenTilemap facade contraction waits for all three extraction siblings.
- Best starting files: _capture_generated_tile_state, get_level_data, debug fingerprint helpers, generation/ semantic types.
- Blockers or open questions: None known at authoring time.
