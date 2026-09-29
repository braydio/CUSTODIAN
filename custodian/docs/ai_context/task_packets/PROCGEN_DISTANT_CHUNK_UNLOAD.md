# PROCGEN DISTANT CHUNK UNLOAD

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-distant-chunk-unload`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-chunk-payload-cache`
- Locks: `procgen-streaming`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Enable bounded distant chunk unload/reload using the proven lifecycle/cache without losing authoritative world mutations or causing visible traversal churn.
- Completion boundary: Done when a conservative production unload radius/policy is active, chunk unload frees eligible presentation/runtime-derived nodes, re-entry restores deterministic presentation from cache plus live mutation overlays, and gameplay-authoritative semantics remain resident.
- Current measured state: enable_distant_chunk_unload is false by default; lifecycle/cache now provide a safe basis for unload but no production policy is active.
- Evidence: S1 memory/node metrics; lifecycle/cache smokes; existing _unload_chunk and wall collision sync behavior.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; chunk lifecycle/cache; current interest/reveal radii and mutation authority.
- Work surface: Streaming policy/config, unload/reload commit paths, node/collision/nav presentation cleanup tests.
- Change: Define conservative unload hysteresis beyond active radius, unload only disposable presentation/derived runtime state, retain authoritative semantic/mutation state, and rebuild derived state through scheduler on re-entry. Avoid thrash by separating dormant from unload thresholds.
- Preserve: Player-visible continuity, world mutation persistence, ingress/road/terrain semantics, collision/nav correctness near active area.
- Non-goals: No semantic world-data eviction, no save-system changes, no render batching.
- Acceptance: Scripted out-and-back traversal unloads eligible distant chunks, lowers node/presentation load, restores identical visible result on return, and preserves destroyed/blocked state; no oscillation at threshold.
- Validation: Unload/reload smoke + mutation persistence + road/macro/wall/ingress streaming regressions + S1 runtime benchmark; changed-file closeout.
- Task overrides: `none`
- Deferred: Runtime streaming lane then converges with generation lane for coordinator extraction.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` and the matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Runtime lane closes. ProcGenTilemap extraction dependents unlock once generation lane demolition is also complete.
- Best starting files: chunk lifecycle/cache; _unload_chunk; mutation scheduler; S1 runtime metrics.
- Blockers or open questions: None known at authoring time.
