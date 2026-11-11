# Operator Workbench Publish Readiness Review Corrections 1

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

Workstream: `review-operator-workbench-publish-readiness-recovery-review-corrections-1` (finding `R0-01`).

## Finding

R0-01 remains unresolved. Correction 1 removes the direct `operator anim publish` bypass and passes the ordinary checkout/readiness controls. The shared publication service still trusts the selected Workbench manifest's mutable binding paths as both candidate targets and authorization input. A manifest rebound to another existing Operator source path can expand `canonical_paths`; `publication_allowlist()` then includes that path and its sidecars. The backend writes those paths before the publisher checks the changed-path set. The final pre-mutation check reloads readiness but does not verify that the binding paths still match the selected animation's trusted plan/source index.

Relevant source: `ui/service.py` lines 695–745; `animation_workbench.py` lines 413–424 and 463–469; `operator_art_worktree.py` lines 801–811 and 920–933.

The CLI regression's success fixture checks the normal selected path and exact staged set, while its negative controls cover coordination main, stale override, detached checkout, and dirty art checkout. It does not cover manifest path retargeting or mutation between selection and final readiness revalidation.

## Validation

- `operator_cli_publish_boundary_smoke.py`: PASS
- `operator_art_worktree_smoke.py`: PASS
- `operator_workbench_mirror_publish_smoke.py`: PASS
- `operator_workbench_ui_smoke.py`: PASS; optional Textual pilot skipped because the dependency is not installed
- `operator_animation_workbench_smoke.py`: PASS
- `git diff --check`: PASS

No reviewed implementation files were modified. I created bounded cycle-2 correction and paired review packets; any unresolved correction-worthy result at that cycle's review requires a human decision, with no cycle 3.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: low
- What went wrong: Existing negative controls did not cover mutable binding-path retargeting. The first closeout attempt used the implementation summary's filename; the lifecycle gate rejected it, so I restored that file and used the canonical review-workstream summary name. After syncing to latest main, three already-deleted archive/dev assets remained hydrated as untracked files in this worktree and were removed to match main.
- Root cause / contributing factors: Publication candidate paths and allowlist scope both come from manifest paths; final revalidation does not bind those paths to the selected animation. Summary naming followed the correction packet's task name instead of the review workstream ID. The latest main commit deleted the three files while this worktree retained their prior checkout bytes.
- Prevention / pipeline improvement: Add negative controls for a tampered manifest and for path changes between initial selection and pre-mutation validation. Name review summaries from the claimed review workstream ID and check tracked state after syncing latest main.
- Tooling / docs drift discovered: none
- Follow-up: operator-workbench-publish-readiness-recovery-review-corrections-1-review-corrections-2
- What worked: Fixture-backed CLI and Workbench smokes validate the ordinary readiness and landing contract.

## Next Handoff

- Next workstream: `operator-workbench-publish-readiness-recovery-review-corrections-1-review-corrections-2`
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: none
- Next action: Bind publication paths to the selected animation's trusted path set and reject manifest retargeting before canonical mutation.
- Blockers or open questions: R0-01 remains unresolved pending cycle-2 correction and review.
