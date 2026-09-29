# PROCGEN CHUNK LIFECYCLE STATE MACHINE

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-chunk-lifecycle-state-machine`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-pause-aware-streaming`
- Locks: `procgen-streaming`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Replace implicit reveal-set bookkeeping with one explicit deterministic chunk lifecycle authority.
- Completion boundary: Done when every streaming chunk is tracked as UNSEEN, QUEUED, PREPARED, VISIBLE, DORMANT, or UNLOADED with legal transitions, while current visible-world behavior remains unchanged and unload stays disabled.
- Current measured state: ProcGenTilemap tracks visible/revealed/queued chunks through multiple sets/queues and has _unload_chunk, but distant unload is disabled and no canonical lifecycle object owns state transitions.
- Evidence: Streaming methods _prepare_streaming_reveal, _prime/_update_streaming_chunks, _queue_chunk_for_reveal, _reveal_chunk_immediately, _unload_chunk; pause scheduler.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; STREAMING_PROCGEN_REVEAL.md; pause-aware streaming contract.
- Work surface: Focused chunk lifecycle authority under procgen/streaming plus ProcGenTilemap adapter and streaming tests.
- Change: Create deterministic chunk IDs/state records and legal transition API. Adapt reveal queue/priority/visibility bookkeeping to query/update this authority. Keep unload policy off, but make DORMANT/UNLOADED transitions testable through explicit debug/test seams.
- Preserve: Current reveal ordering/radii/tiles-per-frame, visible tile results, road/macro/foliage streaming behavior, collision/nav correctness.
- Non-goals: No payload cache yet; no production unload enablement; no render batching.
- Acceptance: Same traversal produces identical visible/revealed world and stable transition sequence; illegal transitions fail loudly in tests; no duplicate chunk queues or reveal commits.
- Validation: Chunk lifecycle smoke + road semantics streaming + macro presentation streaming + wall collision sync + S1 streaming case; changed-file closeout.
- Task overrides: `none`
- Deferred: Chunk payload caching and production unload remain next.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` and the matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Land lifecycle authority; procgen-chunk-payload-cache becomes eligible.
- Best starting files: ProcGenTilemap streaming sets/queues; road/macro streaming smokes; new streaming authority.
- Blockers or open questions: None known at authoring time.
