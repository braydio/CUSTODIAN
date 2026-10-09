# Operator Workbench Publish Readiness Recovery Review Corrections 2

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d

Workstream: `operator-workbench-publish-readiness-recovery-review-corrections-1-review-corrections-2` (finding `R0-01`).

## What changed

- `WorkbenchService` now validates manifest selection identity, binding identity, source contract paths, and publish contract paths against the selected animation's trusted plan before readiness preparation.
- Candidate and allowlist paths now come from those validated paths. Horizontal mirror targets are derived from the validated publish identity and dimensions, with existing counterpart sources resolved through the source index.
- The final pre-mutation check reloads the manifest and revalidates the binding/path set before readiness inspection and before `animation_workbench.publish()` can run.
- CLI smoke coverage now rejects a fully path-retargeted manifest with coherent source freshness hashes and rejects a post-preparation path swap. Both preserve source/runtime hashes, HEAD, and Git status and prove the backend is not called. The eligible selected-path publication remains the positive control.
- The correction packet is complete and archived; the task packet index now points to the paired cycle-2 review as the immediate successor.

## Evidence

- `operator_cli_publish_boundary_smoke.py`: PASS; both manifest tamper controls blocked before backend mutation; selected-path positive control landed only the selected source on the fixture remote.
- `operator_art_worktree_smoke.py`: PASS. The fixture exercised origin-main advancement and retry behavior before completing.
- `operator_workbench_mirror_publish_smoke.py`: PASS.
- `operator_workbench_ui_smoke.py`: PASS; optional Textual pilot skipped because its dependency is not installed.
- `operator_animation_workbench_smoke.py`: PASS.
- `run_validation.py --test operator_cli_publish_boundary --json`: green focused report at `/tmp/custodian-operator-workbench-correction-2-validation.json`.
- `git diff --check` and Python compilation: PASS.
- No canonical art/gameplay changes.

## Awkward parts

- The first hostile fixture changed semantic identity as well as paths and therefore hit the identity guard before exercising the path-only defect. I revised it to retain the selected identity and provide a valid alternate Operator source with matching file/pixel hashes and frame dimensions.
- The code-review graph reported an empty index in this worktree. Exact symbol/path source search supplied the missing structure.
- The art-worktree smoke printed a remote-main advancement block during its race/retry scenario, then completed and reported PASS. This was fixture-only; no test data was sent to the project remote.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The initial retarget fixture combined semantic and path tampering; the graph index was empty.
- Root cause / contributing factors: The first negative control was not single-fault; the worktree graph had no indexed nodes.
- Prevention / pipeline improvement: Keep hostile controls single-fault and fall back to targeted source search when graph discovery reports empty.
- Tooling / docs drift discovered: Code-review graph index empty in this worktree; no code change needed.
- Follow-up: none
- What worked: Fixture remotes exercised actual checkout readiness and landing boundaries without touching the real remote.

## Next Handoff
- Next workstream: review-operator-workbench-publish-readiness-recovery-review-corrections-1-review-corrections-2
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d
- Refresh reason: none
- Next action: Complete the paired cycle-2 review from a fresh reviewer context after this correction lands and archives.
- Blockers or open questions: none
