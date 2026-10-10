# NPA-7 Commanded Ally Contracts — Recovery Summary

## Status

Implementation is present on the existing claimed workstream branch `agent/npa-7-commanded-ally-contracts` in worktree `/home/braydenchaffee/Projects/.custodian-worktrees/npa-7-commanded-ally-contracts-20261010T140547Z-13c3e29f6113`. The work is not landed. The paired review has not started. Closeout is blocked because the required changed-file validation is red on two unrelated checks.

The implementation composes `ActorAllegianceComponent` on `CombatDrone` as `operator_allied`, centralizes autonomous versus explicit command qualification in `DroneTargeting`, prunes stale manager orders, and revalidates at target refresh, weapon update, and every projectile commit. Allegiance, targetability, death, freed instances, and changed orders cancel queued burst rounds. `AlliedInfantryDroid` retains inherited behavior and presentation; existing squad command and slot ownership remain in `DroneManager` and `DroneSquadState`.

The registered `commanded_ally_targeting_contract` smoke exercises actual projectile emission and damage, passive Shrumb explicit targeting, opted-in neutral explicit targeting, autonomous exclusion, allegiance changes before first fire and mid-burst, untargetable/dead/freed targets, direct setter rejection, changed orders, and destroyed/replaced squad slots.

## Validation Evidence

- `commanded_ally_targeting_contract`: passed.
- `allied_drone_navigation_walkability`: passed.
- `drone_follower_commands_smoke`: passed.
- `main_scene_allied_droid_smoke`: passed.
- `debug_collector_combat_drone_smoke`: passed.
- `check_ai_context.py --json`: passed with 0 findings.
- `validate_review_pairing.py`: passed; 62 review packets paired.
- Targeted NPA-7 packet authoring preflight: passed.
- `git diff --check` and validation manifest JSON parse: passed.
- Final `run_validation.py --changed --json`: coverage complete; 21 passed, 2 failed, 1 skipped. `actor_relationship_contract` failed and blocked `awakening_late_seams_v1`; the changed sweep also failed `world_transition_handoff`.

The `actor_relationship_contract` failure was reproduced from clean project-root `main@1da9c970f27ff37298abb190ce8d3075d4837f0b`. It fails its legacy Enemy allegiance fallback and player-targeting assertions and reports unavailable Vaultwing animation imports. The changed-sweep `world_transition_handoff` failure reports `Qualified Awakening completion did not enter Hub`; the same check is also red on clean main, where the local environment reports missing GDExtension and resource imports. Neither failing check touches NPA-7's source surface.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: Required changed-file validation remains red on unrelated baseline contracts.
- Root cause / contributing factors: The shared relationship smoke has failing legacy fallback assertions and unavailable Vaultwing imports on main; the world transition smoke also fails on main in this checkout environment.
- Prevention / pipeline improvement: Keep clean-main reproductions with downstream workstream evidence and resolve shared validation failures in their owning workstreams.
- Tooling / docs drift discovered: The manifest's source ownership correctly selects shared relationship checks for drone changes, while changes to the manifest select additional broad integration coverage.
- Follow-up: npa-7-commanded-ally-contracts
- What worked: The focused actor-to-projectile contract test proves both allowed explicit passive commands and fail-closed target changes before subsequent shots.

## Next Handoff

- Next workstream: npa-7-commanded-ally-contracts
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: none
- Next action: Resume the existing claimed implementation after the unrelated baseline validation failures are corrected; rerun the required changed-file sweep, finish through the normal lifecycle, and launch review-npa-7-commanded-ally-contracts in a fresh context.
- Blockers or open questions: Do not land or start paired review while the required changed-file validation is red.
