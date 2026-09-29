# PROCGEN CHUNK PAYLOAD CACHE

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-chunk-payload-cache`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-chunk-lifecycle-state-machine`
- Locks: `procgen-streaming`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Cache immutable/reusable per-chunk derived payloads so reveal and future unload/re-reveal do not recompute stable chunk semantics.
- Completion boundary: Done when chunk lifecycle records own or reference deterministic cached payloads for structural tiles, prop/foliage plans, collision descriptors, presentation descriptors, and dirty bounds where those are currently recomputed.
- Current measured state: Chunk lifecycle is explicit, but _get_chunk_tiles and downstream reveal paths still reconstruct/scan stable information repeatedly.
- Evidence: S1 streaming metrics; lifecycle transitions; current reveal/foliage/road/macro/wall payload paths.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; chunk lifecycle authority; immutable accepted-world semantics.
- Work surface: Streaming chunk payload/cache types and adapters to existing foliage/road/macro/collision reveal consumers.
- Change: Build payloads once from accepted authoritative world state at/after PREPARED transition, with deterministic invalidation only for genuinely mutable topology. Separate immutable payload cache from live mutation overlays so destroyed walls/runtime blockers cannot be resurrected by cache reuse.
- Preserve: Visible output, mutation persistence, exact wall destruction, road/macro/foliage determinism, memory safety.
- Non-goals: Do not enable unload yet; no generic global cache; no renderer batching.
- Acceptance: Reveal->dormant->prepare test reuses immutable payloads, mutation overlays remain authoritative, cache hit/miss metrics appear in S1 schema, and repeated reveal results are identical.
- Validation: Cache/lifecycle smoke + wall destruction persistence + foliage/road/macro streaming tests + S1 runtime comparison; changed-file closeout.
- Task overrides: `none`
- Deferred: Production distant unload follows after cache correctness.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` and the matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Land payload cache; procgen-distant-chunk-unload becomes eligible.
- Best starting files: chunk lifecycle authority; ProcGenTilemap reveal consumers; runtime mutation state.
- Blockers or open questions: None known at authoring time.
