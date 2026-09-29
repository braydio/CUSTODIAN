# PROCGEN PAUSE AWARE STREAMING

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-pause-aware-streaming`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-runtime-mutation-scheduler-cutover`
- Locks: `procgen-streaming`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Separate background procgen preparation from gameplay-authoritative commit so already-requested world preparation may continue during pause while simulation/discovery remains frozen.
- Completion boundary: Done when pause semantics are explicit, tested, and implemented through a dedicated scheduler/process owner rather than making the entire procgen subtree PROCESS_MODE_ALWAYS.
- Current measured state: PauseUI sets SceneTree.paused=true; ProcGenTilemap reveal work runs in ordinary _process and therefore stops while paused. No explicit contract separates prepare from commit.
- Evidence: S1 streaming metrics; mutation scheduler; PauseUI; _prepare/_update/_process_streaming_reveal_queue and visual flush paths.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; STREAMING_PROCGEN_REVEAL.md; pause/input lifecycle.
- Work surface: Streaming scheduler/worker seam, ProcGenTilemap reveal adapter, pause tests/docs.
- Change: Introduce explicit PREPARE and COMMIT phases. Pause-capable processing may perform pure deterministic chunk/visual/cache preparation for work already requested before pause. Player-driven discovery, enemy simulation, destructible/world interaction, and gameplay-authoritative topology commits remain frozen. Resume drains prepared commits under existing/bounded budgets.
- Preserve: SceneTree pause semantics for gameplay, deterministic reveal order, collision/nav authority, no hidden player movement/discovery.
- Non-goals: No chunk unload yet, no background gameplay simulation, no threading Node mutation, no generation redesign.
- Acceptance: During pause, gameplay/reveal frontier and authoritative topology do not advance; allowed preparation counters can advance; resume commits prepared work deterministically without burst duplication or missed collision/nav updates.
- Validation: New pause streaming smoke + pause UI regression + scheduler/runtime health/streaming tests + S1 runtime benchmark; changed-file closeout.
- Task overrides: `none`
- Deferred: Explicit chunk lifecycle/cache is next.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` and the matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Land pause contract; procgen-chunk-lifecycle-state-machine becomes eligible.
- Best starting files: pause_ui.gd; ProcGenTilemap streaming methods; mutation scheduler; STREAMING_PROCGEN_REVEAL.md.
- Blockers or open questions: None known at authoring time.
