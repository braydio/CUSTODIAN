# VAULTWING WORLD SPAWN INTEGRITY RECOVERY V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vaultwing-world-spawn-integrity-recovery-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `vaultwing-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime`
- Paired review workstream: `review-vaultwing-world-spawn-integrity-recovery-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `focused production spawn/reset contract correction with runtime ownership consequences`
- Reviewed main: `80bb91444`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery/closeout summary and final `## Next Handoff`; do not shorten or replace it.
- Goal: Make production Vaultwing spawning track active instances and recover cleanly after removals, while accurately validating the existing production spawner node.
- Completion boundary: Replace unsafe untyped pruning in `VaultwingSpawner`, correct the brittle scene-header assertion, and prove production node presence, one-time marker spawning, parent placement, reset, and clean replacement through focused runtime validation and a green changed-file closeout.
- Current measured state: On `origin/main@80bb91444`, `vaultwing_world_spawn` fails with five assertions. `vaultwing_spawner.gd::_prune_spawned` assigns `Array.filter()` output to `Array[Node]`, producing a runtime typed-array error. The scene contains the production `VaultwingSpawner`; the smoke's exact header assertion rejects its additional `unique_id` attribute. The suggested patch is `/home/braydenchaffee/Downloads/H5_vaultwing_owner_lane_suggested.patch` (SHA-256 `4baaf85a5f49aef965f592fbc01d378c134a3e0630998c6a7cb31156dd63a35a`) and passes `git apply --check` against the reviewed main.
- Evidence: `custodian/game/systems/spawning/vaultwing_spawner.gd`; `custodian/scenes/game.tscn`; `custodian/tools/validation/vaultwing_world_spawn_smoke.gd`; H5 recovery report `/tmp/h5-20261010-vaultwing-world-spawn.json`; archived baseline history of `vaultwing_world_spawn` failures.
- Task-specific authority: `design/02_features/ambient/VAULTWING_SYSTEM.md` owns wild Vaultwing lifecycle and spawn behavior; `custodian/game/systems/spawning/` owns ambient instance tracking; the production scene and focused smoke define exact runtime wiring.
- Work surface: `vaultwing_spawner.gd`; `vaultwing_world_spawn_smoke.gd`; only directly required manifest ownership and closeout documentation.
- Change: Use an explicit typed `Array[Node]` retention loop in `_prune_spawned`, dropping invalid and queued-for-deletion instances and logging queued runtime removals. Make the scene assertion accept the production node header with additional Godot attributes. Diagnose any spawn/reset assertion that remains after this patch; do not assume all are downstream of pruning.
- Preserve: Existing spawn caps, marker de-duplication, family identity, lifecycle telemetry, world parent (`World/Ambient`), reset semantics, deterministic selection, and all Vaultwing behavior/bond/relationship rules.
- Non-goals: No second spawner; no Vaultwing actor/controller/bond changes; no Asset V2 or import changes; no H5 edits; no timeout changes; no ambient ProcGen generation or loader work.
- Acceptance: (1) `vaultwing_world_spawn` passes production node detection despite extra serialized attributes; (2) one marker creates exactly one Vaultwing and duplicate marker processing creates no additional actor; (3) actor parent is `World/Ambient`; (4) reset removes/deactivates tracked actors and permits one clean replacement; (5) invalid/freed and queued actors are pruned without typed-array errors; (6) `vaultwing_runtime`, `vaultwing_bond`, and `actor_relationship_contract` remain green; (7) complete changed-file validation has complete coverage and all selected checks pass.
- Validation: Apply/compare the supplied patch against latest `origin/main`; run `vaultwing_world_spawn` first; run `vaultwing_runtime`, `vaultwing_bond`, and `actor_relationship_contract`; inspect logs for duplicate/invalid-instance controls; run complete `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json` and `git diff --check`. Do not alter a test timeout or suppress errors.
- Task overrides: `none`
- Deferred: H5 closeout and review; ambient real-world spawn diagnosis; Vaultwing runtime/bond hardening; broader spawner queue redesign.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: no
- Completion boundary satisfied: no
- Acceptance satisfied: no
- Superseded/legacy production path disposition: `n/a`
- Evidence: Pending execution.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: blocked
- Friction severity: none
- What went wrong: none
- Root cause / contributing factors: none
- Prevention / pipeline improvement: none
- Tooling / docs drift discovered: none
- Follow-up: none

## Next Handoff

- Next workstream: `review-vaultwing-world-spawn-integrity-recovery-v1`
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: none
- Next action: After implementation lands and archives complete, run the paired review from fresh reviewer context.
- Blockers or open questions: none
