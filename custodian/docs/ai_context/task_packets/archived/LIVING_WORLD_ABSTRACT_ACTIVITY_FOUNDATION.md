# Living-World Abstract Activity Foundation · F14-B

- Packet schema: `custodian.task_packet.v2`
- Workstream: `living-world-abstract-activity-foundation`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `world-simulation-runtime, living-world-abstract-activity`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-living-world-abstract-activity-foundation`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `dbe29e53bc4b5c304ba9bae54102a0cd5c2ad45b`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Visual review: `none`
- Goal: Establish deterministic bounded offscreen group activity in one Campaign World using existing simulation time, so a named group in a genuinely uninstantiated geographic location changes objective/route progress and produces inspectable causal evidence without a second scene or clock.
- Completion boundary: One serializable abstract-activity state owner, deterministic fixed-tick invocation and a focused two-synthetic-location proof. A group exists in abstract state without a physical actor, advances via an approved nonlethal state change and survives macro snapshot/restore and replay. Does **not** instantiate/reify/teardown physical actors; F14-C owns that.
- Current measured state: The baseline audit reported six focused Godot runs passing. This slice adds deterministic state-only synthetic location activity every 60 fixed ticks and upgrades macro snapshots to schema v5 with v4 migration. The focused smoke proves causal route progress without a physical B actor, deterministic map-order behavior, pause, snapshot continuation, invalid-input rejection and legacy v4 restore. No actual geographic map binding, actor handoff/reification, or disk persistence is implemented; F15 geography and REMAP-3 remain deferred.
- Evidence: `design/04_architecture/codebase_systems_audit/F14_LIVING_WORLD_SIMULATION.md` local audit receipt; `design/04_architecture/codebase_systems_audit/F15_CAMPAIGN_WORLD_GEOGRAPHY.md` continuous-world user lock; `custodian/game/systems/simulation/simulation_kernel.gd`; `custodian/game/state/world/world_simulation_state.gd`; `custodian/game/systems/simulation/world_simulation_runtime.gd`; `design/04_architecture/PYTHON_SIM_REMAP_TRACKER.md`.
- Task-specific authority: F14 V1 bounded-world simulation decision lock and F15 stable-geographic-identity seam; `design/04_architecture/PYTHON_SIM_TO_GODOT_MIGRATION.md`; `design/01_systems/INTEREST_MANAGEMENT_SYSTEM.md`. Preserve `WorldSimulationState` schema migration and `SimulationSnapshot` canonical fingerprint semantics.
- Work surface: Primary owner `custodian/game/systems/simulation/` as a focused abstract-activity domain model/coordinator; small `SimulationKernel` stage integration and `WorldSimulationState` snapshot serialization/migration only where necessary. Target focused new Godot validation under `custodian/tools/validation/` and update `custodian/tools/validation/validation_manifest.json` only for changed owner selection. Do not embed stateful offscreen behavior in `enemy.gd`, `ProcGenTilemap`, HUD or the interest-manager autoload.
- Change: (1) Represent a domain-scoped stable `group_id` independently of a `campaign_visit_id`, with a stable `domain_id`, synthetic `location_id`, objective/route progress, last-advanced authoritative tick, bounded condition/pressure projection and serialization-safe causal event records. (2) Preserve location identity independently of loaded scenes, facility macro sector IDs and visual chunk coordinates; avoid premature world-graph APIs. (3) Invoke the offscreen-activity step through **existing `SimulationKernel` every 60 fixed ticks**; no `_process(delta)`, wall clock, independent RNG, hidden SceneTree or duplicated resource ledger. (4) Use deterministic stable ordering and `WorldSimulationState`'s serialized RNG stream (or a documented derived deterministic stream whose state is serialized) so replay is independent of dictionary insertion order. (5) Make B's synthetic patrol update a nonlethal objective/route-progress milestone and a causal change event, while no physical actor/node from B exists. Do not relocate an abstract group into a live physical A without handoff. (6) Serialize the authority through the existing macro snapshot/versioning mechanism, respecting backwards compatibility for pre-feature snapshots and accurate snapshot fingerprinting. (7) Fail closed for unknown/duplicate group identities, invalid location references, negative elapsed ticks and inconsistent schema state. (8) Keep the model small, bounded in work and event history; choose minimal practical tunable constants in the appropriate policy/resource instead of hardcoding future balance into the kernel.
- Preserve: Single `WorldSimulationRuntime` 60Hz fixed-step owner and macro stage ordering; deterministic `SimulationSnapshot` validity/fingerprint; previously supported snapshot schema reads; active physical enemies/Director/vehicle behavior; F02 procgen ownership, F06 campaign exactly-once resolution, REMAP-3 disk-save ownership and the existing interest-tier manager. If a new macro-stage order or snapshot version affects old fixtures, explicitly migrate and test instead of silently changing current results.
- Non-goals: No full geographic generation, endless chunks, Archive Resolve rendering, scripted cutscene/travel, vehicular movement, actor instantiate/serialize/reify, autonomous offscreen combat, casualties/irreversible story deaths, faction AI overhaul, cross-domain travel, new HUD, `WorldHistory` becoming persistence, full REMAP-3 disk save/restart, or artwork.
- Acceptance: (1) Exactly one authoritative abstract group with same stable ID exists before/after advancement and snapshot restore. (2) With location A considered active and B uninstantiated, B's group deterministically advances a patrol objective through one causal event after the configured fixed-tick threshold; no B `Node2D` is instantiated. (3) Identical seed + input order + fixed ticks yield identical canonical snapshots and event sequence even when initial map insertion order differs. (4) Save snapshot at an accepted fixed-step boundary, restore, advance equal ticks and compare canonical state/fingerprint/event IDs against an uninterrupted run. (5) Paused clock does not advance activity. (6) Duplicate IDs / invalid location ownership fail closed, no silent replacement or double consequences. (7) Legacy v4 snapshot loads with safe default activity state. (8) Existing world simulation macro, live-scene, telemetry and snapshot smokes remain green. (9) Focused new smoke genuinely fails if activity stepping, stable IDs or serialization are disabled; no fabricated physical reification pass claimed.
- Validation: Add/run one focused headless abstract-activity Godot smoke (new file path becomes exact once created). Re-run existing `res://tools/validation/world_simulation_kernel_smoke.gd`, `res://tools/validation/world_simulation_macro_state_smoke.gd`, `res://tools/validation/world_simulation_snapshot_roundtrip_smoke.gd`, and `res://tools/validation/world_simulation_live_scene_smoke.gd`. Run `python3 custodian/tools/agent/validate_task_packet_authoring.py` against the implementation and its paired review as an authoring gate **before promoting either from draft to ready**. Run changed-file validation once at closeout and `git diff --check`. No full renderer benchmark or all-repo headless sweep by default.
- Task overrides: `none`
- Deferred: F14-C owns actual physical↔abstract handoff and exactly-once reification; F14-D integrates durable Domain activity through REMAP-3; F14-E integrates the two-location playable proof and perf/soak. F15 owns world-scale topology, pedestrian/vehicle continuous streaming, passes and Archive Resolve presentation integration. Revisit 1Hz and activity budgets after a representative performance benchmark.

## Authoring / promotion receipt

The user approved the bounded offscreen activity decision on October 9, 2026. The targeted repository authoring preflight passed for this packet and its paired review before both were promoted to `ready/auto` and dispatched.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Superseded/legacy production path disposition: n/a
- Evidence: Focused abstract activity smoke; kernel, macro-state, snapshot-roundtrip, telemetry and live-scene smokes; changed-file validation (17 selected, 17 passed); authoring preflight passed. Independent post-land review remains the required next workstream.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: Godot first-import generated nine unrelated reference-art `.import` sidecars; removed these exact generated files after validation.
- Root cause / contributing factors: Fresh worktree required Godot editor import before headless validation.
- Prevention / pipeline improvement: none
- Tooling / docs drift discovered: F14 architecture and roadmap still described B as draft/unimplemented; updated to distinguish implementation from pending independent review.
- Follow-up: none
- What worked: Focused smoke and changed-file owner coverage exercised schema migration and deterministic continuation.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Refresh instruction: At claim time compare live `WorldSimulationState` serialization, `SimulationKernel` ordering and REMAP-3 current state. If source surfaces changed, preserve these explicit B behaviors without introducing another clock, save authority, or new global geography. Return architecture ambiguity to this chat rather than silently relaxing bounds.
