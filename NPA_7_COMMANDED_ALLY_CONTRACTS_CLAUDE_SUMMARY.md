# NPA-7 Commanded Ally Contracts — Closeout Summary

## Status

NPA-7 implementation is complete in the preserved workstream `agent/npa-7-commanded-ally-contracts`, synchronized to current `origin/main@6176615a1`. The implementation stays within the existing relationship and squad authorities: `CombatDrone` composes `ActorAllegianceComponent`, `DroneTargeting` separates autonomous hostility from explicit command qualification, and manager/weapon boundaries revalidate eligibility through every projectile commit. `AlliedInfantryDroid` retains the inherited integration. No Enemy inheritance, universal NPC command system, squad-state duplication, or bonded Vaultwing command behavior was added.

The new `commanded_ally_targeting_contract` smoke exercises actual projectile emission and damage, explicit passive Shrumb/neutral targeting, autonomous exclusion, dead/freed/untargetable targets, direct setter rejection, allegiance changes before the first shot and mid-burst, changed orders, and destroyed/replaced squad slots.

## Validation

- LFS import preflight: PASS; no checked-out pointers.
- Godot import after sync: exit 0.
- `commanded_ally_targeting_contract`: 1/1 passed.
- `actor_relationship_contract`: 1/1 passed after the separate Vaultwing importer-sidecar repair landed.
- `allied_drone_navigation_walkability`: 1/1 passed.
- `drone_follower_commands_smoke.gd`, `main_scene_allied_droid_smoke.gd`, and `debug_collector_combat_drone_smoke.gd`: all exited 0. The first and third print Godot resource-leak shutdown diagnostics despite exit 0.
- Final changed-file validation: `run_validation.py --changed --base origin/main --json`; coverage complete, 26 selected, 26 passed, 0 failed, 0 skipped. The report saw 22 paths because Godot import generated nine untracked operator `.import` sidecars; those temporary artifacts were removed before closeout. The committed change set is covered.
- `check_ai_context.py --json`: PASS, 0 findings.
- `validate_review_pairing.py`: PASS, 63 pairs.
- Targeted implementation/review packet authoring check: PASS before completion/archive.
- `git diff --check`: PASS.

The first full post-sync sweep had one `world_transition_handoff` failure and skipped `awakening_late_seams_v1`. The focused transition test passed, the failure was not reproducible on a fresh current-main baseline after import, and the second complete sweep passed 26/26. No transition-runtime changes were included in NPA-7.

The baseline actor failure was isolated separately: 15 Vaultwing bonding `.png.import` sidecars had lost their `path`/`dest_files` records and were marked `valid=false`. Their correction landed at `afc4282d4`; it enabled clean import and both requested baseline checks passed.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: NPA-7 closeout was delayed by invalid baseline asset-import metadata and one intermittent world-transition failure in the first based sweep. Also, `--changed` without `--base` returned zero files for the already-committed implementation branch.
- Root cause / contributing factors: The Vaultwing sidecar issue was corrected in its own workstream. The world-transition failure was not reproduced on clean current main or the subsequent focused/full reruns. The validation router defaults to uncommitted/staged/untracked paths unless a base is supplied.
- Prevention / pipeline improvement: Run preflight/import before resource-dependent tests and use `--changed --base origin/main` after workstream changes have been committed. The implementation packet now records the based invocation.
- Tooling / docs drift discovered: The previous packet validation command omitted the base and could report an empty successful changed-file set for committed changes.
- Follow-up: none
- What worked: Focused actor-to-projectile evidence and the final 26/26 changed sweep verify both targeting policy and closeout coverage.

## Next Handoff
- Next workstream: review-npa-7-commanded-ally-contracts
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: none
- Next action: Land the implementation and archived completion packet, then run the paired review in a fresh reviewer context.
- Blockers or open questions: none
