# World Transition Baseline Recheck

## Result

On clean `origin/main` at `afc4282d4de0f48647c755cee4f1b61289e7425a`, after the Vaultwing importer-sidecar repair had landed, the specified clean-checkout preflight/import sequence completed and both baseline checks passed:

- `godot_import_preflight.py --project-dir custodian`: PASS, no checked-out LFS pointers.
- `godot --headless --path custodian --import --quit`: exit 0.
- `run_validation.py --test actor_relationship_contract --json`: 1 passed, 0 failed.
- `run_validation.py --test world_transition_handoff --json`: 1 passed, 0 failed.

An earlier imported worktree had intermittently returned `TARGET_SCENE_UNAVAILABLE` for `awakening-hub-0002` while switching from the deliberately missing Hub host to the production host. The same smoke passed on the fresh current-main worktree without a source change. Direct execution with the validation runner's project path, working directory, and isolated `HOME` also passed. The failure is therefore not currently reproducible on landed main; no world-transition runtime or smoke code was changed here.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: one earlier worktree produced an intermittent `TARGET_SCENE_UNAVAILABLE` result; it did not reproduce after the import correction landed and the check was rerun from a clean current-main worktree.
- Root cause / contributing factors: undetermined; current-main reproduction is green and the prior failure may have been transient.
- Prevention / pipeline improvement: keep the clean import and both focused checks together as the baseline gate before NPA-7 closeout.
- Tooling / docs drift discovered: none.
- Follow-up: none
- What worked: fresh current-main import plus separate runner invocations established green baseline evidence without modifying transition behavior.

## Next Handoff
- Next workstream: npa-7-commanded-ally-contracts
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: none
- Next action: Resume the existing NPA-7 claim, synchronize it with current main, rerun focused and changed-file validation, then complete the packet truth and workstream finish lifecycle.
- Blockers or open questions: none for the two reproduced baseline checks.
