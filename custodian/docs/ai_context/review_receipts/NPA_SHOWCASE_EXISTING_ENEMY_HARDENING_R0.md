# NPA Showcase Existing Enemy Hardening — Review R0

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

## Result

**PASS — zero blocking findings and zero material evidence gaps.** Reviewed implementation commit `9dda45b0f41881bcdb117c7fed4aec9308b75fd1`; it is an ancestor of this checkout's stored `origin/main` ref (`4380293e6de9e7ed297144103f6e6975c29c9abc`). The current branch includes later main history and preserves the implementation files unchanged. A network fetch was unavailable because the linked worktree's common Git metadata is read-only; conclusions are checked against the available stored ref.

## Findings

No blocking findings. The initial R0-01 environment evidence gap is resolved: after importing the project and generating Godot's local class/import cache, the real-scene NPA showcase and the unchanged actor control both pass. No implementation changes were made during review.

## Structural review

The landed change introduces `directional_actor_lane` and routes only Marine Dash and Savage Pounce through it. Existing `directional_lane` callers retain their prior behavior. The helper adds projected collision support only when both actors have enabled root `CollisionShape2D` shapes. The fixture instantiates the real Grunt, Marine, Savage, and Operator scenes, exercises public ability requests and lifecycle states, and checks once-only corpse loot. Source ownership and test structure align with the archived acceptance; no shadow authority or test fake was found.

## Validation performed

- `git diff --check 9dda45b0f41881bcdb117c7fed4aec9308b75fd1^ 9dda45b0f41881bcdb117c7fed4aec9308b75fd1`: pass.
- `godot --headless --editor --path custodian --quit`: completed to populate this fresh review checkout's import/class cache.
- `python3 custodian/tools/validation/run_validation.py --test npa_showcase_existing_enemy --json`: pass, 1/1; real Grunt, Marine, Savage and Operator paths reached their expected semantic states. Known shutdown ObjectDB/resource leak warnings were classified by the runner and did not fail the test.
- `python3 custodian/tools/validation/run_validation.py --test enemy_reaction_posture --json`: pass, 1/1 unchanged control. It emitted navigation fallback warnings from the test's isolated actor setup; the runner reported no failures or infrastructure errors.
- Independently parsed `/tmp/npa-existing-enemy-changed-final-after-latest-main.json`: schema `custodian.validation.result.v1`, 35 selected, 35 passed, 0 failed, 0 timeouts, 0 skipped, 0 infrastructure errors, `passed: true`, and complete coverage with no uncovered files. Its covered source/test/manifest files match the implementation commit; documentation and packet-index changes are explicitly excluded. JSON SHA-256: `f5b38b115ce724f7f4d88e628da4bfafd6cfa16cdd466cb5a068dfc035b008c0`.
- Independently parsed `/tmp/npa-review-showcase.json`: schema valid, 1/1 passed, no failures or infrastructure errors. SHA-256: `3fb61bda7a0496f73546fda173db40a94b67f3b0f4f74891050975c509b179b8`.
- Independently parsed `/tmp/npa-review-enemy-reaction-control.json`: schema valid, 1/1 passed, no failures or infrastructure errors. SHA-256: `817f7635baf9881de00d0cc8d74d77a2fcc140f0d689e5ba5d0825da17468bb6`.
- `git diff --check origin/main...9dda45b0f41881bcdb117c7fed4aec9308b75fd1`: pass; no implementation changes are present between the reviewed commit and stored main.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The fresh review checkout initially lacked generated Godot import and global class-cache state, blocking runtime validation before actor execution.
- Root cause / contributing factors: Ephemeral worktree setup did not run the Godot editor import before actor tests.
- Prevention / pipeline improvement: Warm the Godot project import/class cache in fresh review worktrees before focused actor validation.
- Tooling / docs drift discovered: none
- Follow-up: fixed-in-scope
- What worked: The new showcase and unchanged actor control both passed after project import; the implementation-author changed sweep independently reports complete 35/35 coverage.

## Next Handoff
- Next workstream: npa-showcase-existing-drone-hardening
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: normal live-main API remeasurement
- Next action: Review is complete; do not claim or continue the successor in this workstream.
- Blockers or open questions: none
