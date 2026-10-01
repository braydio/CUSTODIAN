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
- Reviewed main: `9d21d27c24a3c043bca25167c556cc0566da2618`
- Goal: Allow deterministic preparation for already-requested procgen reveal work to continue while the game is paused without advancing discovery, gameplay-authoritative topology, or simulation, then commit that prepared work once and under bounded budgets after resume.
- Completion boundary: Done when one focused streaming prepare/commit authority owns the pause-aware lifecycle for existing reveal work; `ProcGenTilemap` is reduced to narrow streaming integration/delegation for this behavior; paused processing may advance only non-authoritative preparation for work requested before pause; authoritative reveal/frontier, collision/navigation/topology publication, and gameplay simulation remain frozen; and resume drains prepared work deterministically through the landed M2 mutation/rebuild scheduler without duplicate commits or an unbounded one-frame burst. M4 chunk lifecycle, M5 payload caching, and M6 unload remain untouched.
- Current measured state: M2 landed on main at `0ca95441d` and made runtime walkable-boundary and shadow rebuilds actually batch through dirty-flag + `call_deferred` flushes; navigation already used that pattern. M2 preserved an explicit synchronous exception via `_rebuild_runtime_walkable_boundary(..., flush_now=true)` for `_claim_isolated_world_overlook_pocket`, whose caller requires same-call walkability, while generation/connector boundary callers remain deferred. Full wall-collision rebuild still has one generation call site and topology commits already represent one logical mutation, so M2 deliberately left both unchanged. `custodian/game/ui/hud/pause_ui.gd` still owns `SceneTree.paused`; M2 explicitly deferred pause-aware background processing to this workstream. Streaming reveal remains integrated in `ProcGenTilemap`, and the live `custodian/game/world/procgen/` tree has no focused streaming lifecycle owner yet.
- Evidence: `PROCGEN_RUNTIME_MUTATION_SCHEDULER_CUTOVER_CLAUDE_SUMMARY.md`; `custodian/docs/ai_context/task_packets/archived/PROCGEN_RUNTIME_MUTATION_SCHEDULER_CUTOVER.md`; `custodian/game/world/procgen/derived_rebuild_scheduler.gd`; `custodian/game/world/procgen/proc_gen_tilemap.gd`; `custodian/game/ui/hud/pause_ui.gd`; `design/02_features/procgen/STREAMING_PROCGEN_REVEAL.md`; `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`; M2 validation evidence in `procgen_derived_rebuild_scheduler_smoke.gd`, `procgen_walkable_boundary_smoke.gd`, `procgen_runtime_health_smoke.gd`, and `ash_bell_threadway_causeway_smoke.gd`.
- Task-specific authority: `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`; `design/02_features/procgen/STREAMING_PROCGEN_REVEAL.md`; the landed M2 scheduler/coalescing contract and its explicit `flush_now` synchronous-postcondition exception; `custodian/game/ui/hud/pause_ui.gd` for game pause semantics.
- Work surface: Primary ownership should be one focused procgen streaming prepare/commit authority under `custodian/game/world/procgen/streaming/` unless live inspection proves an existing focused owner is a cleaner seam. Integrate it through the minimum `custodian/game/world/procgen/proc_gen_tilemap.gd` adapter/orchestration changes and the existing `derived_rebuild_scheduler.gd`; add `custodian/tools/validation/procgen_pause_aware_streaming_smoke.gd` and update `custodian/tools/validation/validation_manifest.json` so the new owner selects focused coverage. Treat `pause_ui.gd` as the pause authority/trigger and edit it only if the implementation requires a narrow integration seam rather than duplicating pause state elsewhere.
- Change: Introduce explicit PREPARE and COMMIT phases for existing streaming-reveal work. PREPARE may run while paused only for reveal work already requested before pause and only as deterministic, non-authoritative computation/state that does not mutate live TileMap/Node collision, navigation, reveal frontier, player discovery, destructibles, runtime blockers, connector topology, enemies, or other gameplay state. Pausing must not enqueue new reveal work from player movement/discovery. COMMIT remains frozen while `SceneTree.paused` is true. On resume, drain prepared work in deterministic existing reveal order and under the existing or a narrowly bounded per-frame budget; all derived rebuild publication must continue through M2's scheduler/coalescing seam. Preserve M2's explicit immediate-flush contract for callers with same-call postconditions instead of globally converting synchronous paths to deferred behavior. Prefer immutable/plain prepared records over a second mutable world-state authority; do not introduce M4 chunk-state or M5 cache semantics early. Add transition-level observability for requested/prepared/deferred/resumed/committed counts or events where the existing Observatory/scheduler snapshot can own it, without per-frame log spam.
- Preserve: Existing seeded/full-map generation; current reveal ordering and visible-world semantics; `SceneTree.paused` gameplay freeze; M2 request>commit coalescing and scheduler ownership; `_claim_isolated_world_overlook_pocket` same-call walkability through its explicit `flush_now` path; collision/navigation correctness; connector and stuck-pocket behavior; destructible/runtime-blocker semantics; S1 deterministic fingerprints and normal unpaused streaming behavior.
- Non-goals: No chunk lifecycle state machine (M4), payload cache (M5), distant unload/reload (M6), GenerationGrid/generation rewrite, D1/D2/D3 extraction, placement-lane work, world-generation retuning, new art/presentation redesign, background gameplay simulation, threading of Godot Node/TileMap mutation, or blanket `PROCESS_MODE_ALWAYS` on the procgen subtree.
- Acceptance: A focused pause-aware streaming scenario with reveal work requested before pause proves all of the following: (1) across multiple pause-capable ticks, authoritative reveal frontier/visible topology and collision/navigation publication do not advance; (2) allowed PREPARE state/counters can advance deterministically for the already-requested work, without accepting new player-driven discovery or duplicating prepared items; (3) resume commits the prepared work exactly once, in the same deterministic order as the unpaused path, under the normal/bounded reveal budget rather than one unbounded burst; (4) derived rebuild request/commit telemetry still demonstrates M2 coalescing and no duplicate boundary/navigation/shadow publication from the prepared batch; (5) the explicit synchronous `flush_now` caller still satisfies its same-call postcondition; (6) normal unpaused streaming and the S1 fixed-seed fingerprint remain unchanged. The implementation must have one pause-aware streaming owner rather than parallel prepare/commit state split across `ProcGenTilemap`, PauseUI, and a new service.
- Validation: Add/run `custodian/tools/validation/procgen_pause_aware_streaming_smoke.gd` first, covering request -> pause -> preparation -> frozen authority -> resume -> single bounded commit. Then run the directly affected M2/streaming regressions: `custodian/tools/validation/procgen_derived_rebuild_scheduler_smoke.gd`, `custodian/tools/validation/procgen_walkable_boundary_smoke.gd`, `custodian/tools/validation/procgen_runtime_health_smoke.gd`, and `custodian/tools/validation/ash_bell_threadway_causeway_smoke.gd`. Run the S1 quick `custodian/tools/validation/procgen_performance_baseline_bench.gd` determinism/runtime comparison at closeout, then the repository's changed-file closeout once. Do not use `procgen_candidate_promotion_smoke.gd` as a required acceptance gate for this slice unless its documented pre-existing streaming assertion has been independently repaired; do not absorb that unrelated defect into M3.
- Task overrides: `none`
- Deferred: M4 `procgen-chunk-lifecycle-state-machine` owns canonical chunk states/transitions; M5 owns reusable payload caching; M6 owns distant unload/reload. Do not pre-implement those authorities here. Any M2 seam contradiction discovered from live code must be recorded explicitly rather than solved by creating a second mutation/rebuild path.

## Series Contract

This packet belongs to the pre-authored `procgen-runtime-optimization-v1` dependency DAG. Do not author its ordinary V1 successor during implementation: downstream packets already exist on `main` with `Dispatch: auto`. Update `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md` and the matching master-roadmap row at closeout, record landed evidence, then finish normally so declared dependents can become eligible. If live evidence invalidates a downstream contract, record the contradiction and leave that dependent blocked rather than silently broadening this workstream.

## Completion Truth

Required before completion.

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: `<fill with exact owner/integration files, pause/resume smoke results, M2 scheduler telemetry, synchronous-exception regression, and S1 fingerprint/runtime evidence>`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: `none` or concrete failures/near-misses
- Root cause / contributing factors: `none` or concise cause
- Prevention / pipeline improvement: `none` or smallest repeatable fix
- Tooling / docs drift discovered: `none` or exact stale/missing authority
- Follow-up: `none | fixed-in-scope | <workstream-id> | manual-follow-up`
- What worked: optional, one short line at most

## Handoff

- Next action: Claim `procgen-pause-aware-streaming` from current `origin/main`; implement the focused PREPARE/COMMIT owner against the landed M2 scheduler contract. On successful finish, `procgen-chunk-lifecycle-state-machine` becomes eligible.
- Best starting files: `PROCGEN_RUNTIME_MUTATION_SCHEDULER_CUTOVER_CLAUDE_SUMMARY.md`; `custodian/game/world/procgen/proc_gen_tilemap.gd`; `custodian/game/world/procgen/derived_rebuild_scheduler.gd`; `custodian/game/ui/hud/pause_ui.gd`; `design/02_features/procgen/STREAMING_PROCGEN_REVEAL.md`; the four M2 regression smokes named in Validation.
- Blockers or open questions: None. M2 is complete on main; M3 is now dependency-eligible. Preserve the M2 `flush_now` exception and do not pull M4/M5/M6 semantics forward.