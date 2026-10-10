# Stealth Perception Foundation — Recovery Checkpoint

## Outcome

The implementation is present on the existing `agent/stealth-perception-foundation` branch and remains unlanded. It types `NoiseEvent` through the factory, bus, Operator emission, and consumers; adds `PerceptionObservation` and `AcousticPerceptionSensor`; and routes Enemy and Vaultwing hearing through the shared receiver-side evaluation while leaving their behavior policy local.

The validation blocker is independently confirmed on clean, imported `origin/main@5e7c8e58a4b67dc8c29e85d4ab952e5f3fc07178`. The changed-file sweep selected 75 checks: 56 passed, 3 failed, and 16 higher-tier checks were skipped after actor-tier failures. These same three actor checks failed with the same assertions on the clean baseline:

- `operator_ranged_ready_input`: queued parry counter did not start after guard release.
- `operator_unarmed_fast_chain`: interruption/collision fixtures had no live carry.
- `operator_vigil_dagger`: impact probe did not resolve the actor's camera.

The failures are in unrelated Operator behavior and validation fixtures. No gameplay or test changes were made to those areas. `workstream.py finish` requires a green validation report, so this branch must remain active until the baseline failures are resolved by their owning workstream and the changed sweep is rerun.

## Evidence

- `perception_acoustic_contract`: passed.
- `actor_relationship_contract`: passed.
- `vaultwing_runtime`: passed.
- `cognitive_residue_enemy_objective`: passed.
- `ranged_combat_balance_smoke.gd`: passed.
- `combat_resource_feedback_smoke.gd`: passed (Godot reported existing object/resource leaks at exit).
- `git diff --check`: passed before checkpoint.
- Clean-main reproduction: all three changed-sweep failures reproduced after LFS preflight and Godot import.
- New test ownership covers the acoustic seam; changed-file coverage reported complete.

## Preserved boundaries

Relationship resolution remains outside the shared sensor. The observation carries source identity and emitted team facts; the Enemy/Vaultwing consumers retain their own response rules. Weapon-authored radius, loudness, threat, and suppression tuning are unchanged. NPA-8 remains unpublished and outside this work.

## Process Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: blocked
- Friction severity: medium
- What went wrong: Required changed-file validation failed on three unrelated Operator checks.
- Root cause / contributing factors: Editing `operator.gd` selects its broad existing validation ownership; the baseline tests fail on clean main too.
- Prevention / pipeline improvement: Keep stealth coverage scoped to the shared acoustic seam, and resolve the three baseline Operator failures in their owning workstream before retrying finish.
- Tooling / docs drift discovered: The paired review packet lacked required reviewer context/provenance fields; corrected and targeted authoring validation passed. NPA architecture documentation still marked the NPA-7 review pending; corrected here.
- Follow-up: manual-follow-up
- What worked: Focused acoustic, Enemy, Vaultwing, relationship, and ranged/noise checks passed.

## Next Handoff
- Next workstream: stealth-perception-foundation
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: none
- Next action: Resolve the three reproduced baseline Operator validation failures through their owning workstream, resume this preserved claim, rerun the changed-file sweep, then finish and launch the fresh-context paired review.
- Blockers or open questions: The baseline failures listed above block a green changed-file report; implementation landing and paired review remain gated.
