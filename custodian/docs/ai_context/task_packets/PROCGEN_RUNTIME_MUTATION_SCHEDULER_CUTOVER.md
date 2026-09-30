# PROCGEN RUNTIME MUTATION SCHEDULER CUTOVER

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-runtime-mutation-scheduler-cutover`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-derived-rebuild-scheduler-foundation, procgen-semantic-candidate-generation-correction-1`
- Locks: `procgen-runtime-mutation`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Route runtime topology mutation producers through the rebuild scheduler so one logical batch commits each expensive derived system at most once.
- Completion boundary: Done when streaming reveal, wall destruction, runtime blockers, connector commits, and other live topology producers mark dirty state instead of independently forcing full collision/boundary/navigation/shadow rebuilds.
- Current measured state: Scheduler foundation exists but legacy producers still own direct commit calls; current ProcGenTilemap contains many rebuild and flush call sites.
- Evidence: S1 runtime timings; scheduler request/commit telemetry; mutation functions damage_wall_tile, runtime blocker registration, streaming reveal and connector commit paths.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; derived rebuild scheduler; current collision/navigation/shadow contracts.
- Work surface: ProcGenTilemap mutation call sites, scheduler adapters, focused wall/connector/blocker/streaming tests.
- Change: Migrate producers to scheduler requests, define logical transaction boundaries, and commit in deterministic dependency order. Navigation must not rebuild once per revealed tile or producer when a single batch can cover the dirty region. Preserve explicit immediate flush only where a caller requires synchronous postcondition and test it.
- Preserve: Contacted-tile destruction, runtime walkability queries after synchronous mutations, connector correctness, streaming visibility, navigation path safety.
- Non-goals: No pause-aware background processing yet, no chunk-state rewrite, no navigation algorithm replacement.
- Acceptance: Focused mutation scenarios perform at most one required expensive rebuild per derived system per batch; S1 metrics show request>commit coalescing and no correctness regression.
- Validation: Scheduler cutover smoke + wall/connector/stuck-pocket/runtime-health/navigation tests + S1 runtime comparison; changed-file closeout.
- Task overrides: `none`
- Deferred: Pause-aware prepare/commit policy follows this cutover.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` and the matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Land cutover; procgen-pause-aware-streaming becomes eligible.
- Best starting files: ProcGenTilemap runtime mutation/reveal methods; scheduler; runtime blocker and connector tests.
- Blockers or open questions: None known at authoring time.
