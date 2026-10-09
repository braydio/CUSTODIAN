# WB25-1 R0-01 Direction Workflow Truth Correction

## Result

Corrected the workflow projection to read each direction's own
`operator_2_5d_128/<profile>/<group>/<action>/<direction>/workbench.json`.
The target projection now calls the existing read-only
`animation_workbench.state()` classifier for current document state. Saved
creation documents that differ from their blank baseline project
`READY_TO_PUBLISH`; absent or unchanged documents remain `EDITING`. Published,
validated workspaces project `RUNTIME_VERIFIED` at their exact direction.
Pending land/migration and backend state are preserved, and stale canonical
profile/reference authority retains precedence.

## Evidence

- `operator_animation_targets_smoke.py` passes direction-level publish state,
  missing-workspace state, sibling direction and legacy generation isolation,
  saved versus unchanged creation readiness, stale-reference precedence, and
  manifest/document byte-preservation checks.
- `operator_animation_plan_smoke.py` passed.
- `operator_asset_schema_smoke.py` passed.
- Textual-enabled `operator_workbench_ui_smoke.py` passed all cases, including
  browser stabilization and matrix/tree selection identity.
- `run_validation.py --changed --json` passed with complete changed-file
  coverage; `git diff --check` and Python compile checks passed.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The independent WB25-1 review caught direction path and stale readiness errors missed by broad implementation validation.
- Root cause / contributing factors: The target projection was not using the Workbench's direction-level workspace and authoritative readiness classifier.
- Prevention / pipeline improvement: The projector smoke now exercises actual workspace placement and saved-versus-baseline document hashes per direction.
- Tooling / docs drift discovered: none
- Follow-up: fixed-in-scope
- What worked: The correction delegates saved-document interpretation to the existing backend and remains read-only.

## Next Handoff
- Next workstream: review-operator-2-5d-workbench-cockpit-foundation-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: none
- Next action: claim the paired cycle-1 re-review in a fresh reviewer context.
- Blockers or open questions: none
