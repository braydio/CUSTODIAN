# NPA Showcase Existing Drone Hardening — Implementation Summary

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

## Delivered

Registered the existing real-world coverage as three explicit manifest IDs: `drone_follower_commands`, `main_scene_allied_droid`, and `debug_collector_combat_drone`. Strengthened the manager integration smoke to assert the two-droid active cap, stable `DRONE_01`/`DRONE_02` slot identities, and slot identity reuse after replacement. The real manager test continues to cover fire/follow orders, guard marker/reticle, target commands, recall, free-roam/guard leash behavior, prune/replacement and inheritance. NPA-7 auto-versus-explicit passive targeting remains solely in `commanded_ally_targeting_contract`. Updated FILE_INDEX and NPA program state. No production runtime changes were needed because focused runtime evidence did not reproduce a defect.

## Validation

- LFS/import preflight passed.
- `drone_follower_commands`, `main_scene_allied_droid`, `debug_collector_combat_drone`, `commanded_ally_targeting_contract`, `actor_relationship_contract`, and `allied_drone_navigation_walkability` passed.
- Changed-file sweep selected 35 checks; all 35 passed, coverage complete, no uncovered files.
- Some existing checks reported known exit resource/ObjectDB warnings; `actor_relationship_contract` also emitted a missing-navigation warning, but all assertions passed.
- Review pairing, task packet index, JSON parse and `git diff --check` passed.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: existing validation warnings listed above; no runtime bug reproduced.
- Root cause / contributing factors: test teardown warnings and the existing relationship fixture's missing navigation owner.
- Prevention / pipeline improvement: no production changes without a reproduced runtime defect; register direct evidence with exact owners.
- Tooling / docs drift discovered: three real direct smokes lacked manifest IDs and FILE_INDEX listed them as unregistered.
- Follow-up: none
- What worked: the existing real-scene command test covered most of the acceptance contract; adding precise cap/identity checks closed its remaining gap.

## Next Handoff
- Next workstream: review-npa-showcase-existing-drone-hardening
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: none
- Next action: land the validated implementation and run the fresh-context paired review.
- Blockers or open questions: none.
