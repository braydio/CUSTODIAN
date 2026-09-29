# PROCGEN DERIVED REBUILD SCHEDULER FOUNDATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-derived-rebuild-scheduler-foundation`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `procgen-performance-baseline-v1`
- Locks: `procgen-runtime-mutation`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `6a11a14ef42eef4b0eeecae0bc669594b7adb4ee`
- Goal: Introduce one dirty-region/rebuild scheduling authority for expensive procgen derived state without changing when current producers ultimately commit.
- Completion boundary: Done when topology/collision/boundary/navigation/shadow/presentation dirtiness can be recorded and coalesced through one scheduler with metrics, while legacy producers still preserve current behavior through adapters.
- Current measured state: ProcGenTilemap owns multiple rebuild/flush helpers and producers can independently request wall collision, walkable boundary, navigation, shadow, and visual rebuild work; S1 captures a ~258 ms navigation outlier.
- Evidence: S1 runtime metrics; _rebuild_runtime_wall_collision, _rebuild_runtime_walkable_boundary, _queue/_flush_navigation_rebuild, _refresh_shadows, streaming visual flushes.
- Task-specific authority: PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md; RUNTIME_STUTTER_PERFORMANCE_PASS.md; runtime collision/navigation ownership.
- Work surface: Focused runtime scheduler under procgen/streaming or runtime-mutation namespace; minimal ProcGenTilemap adapters; runtime-health gauges/tests.
- Change: Define deterministic dirty reasons/regions and a scheduler snapshot. Route requests through it without yet changing all commit timing. Coalesce duplicate requests within a logical batch and expose counts/durations into the S1 metrics contract. Keep actual rebuild implementations owned by their existing systems.
- Preserve: Exact wall destruction, navigation correctness, boundary/shadow behavior, streaming visuals, and current gameplay timing.
- Non-goals: No pause processing, no chunk lifecycle, no semantic generation work, no forced thread use.
- Acceptance: Equivalent mutation sequences produce identical world state, duplicate same-batch requests coalesce deterministically, scheduler metrics account for requested/committed work, and no producer directly invents a second dirty-state authority.
- Validation: New scheduler smoke + runtime wall collision compaction/destruction + runtime health + navigation representative smoke + S1 quick; changed-file closeout.
- Task overrides: `none`
- Deferred: Full producer cutover and commit batching follow.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` and the matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Handoff

- Next action: Land scheduler foundation; procgen-runtime-mutation-scheduler-cutover becomes eligible.
- Best starting files: proc_gen_tilemap.gd rebuild/queue/flush helpers; runtime-health snapshot; prior stutter pass.
- Blockers or open questions: None known at authoring time.
