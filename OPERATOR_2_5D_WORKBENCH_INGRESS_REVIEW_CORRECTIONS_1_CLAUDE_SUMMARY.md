# WB25-2 Ingress Review Corrections 1

Resolved the four blocking findings from the fresh WB25-2 paired review. The correction changes only ingress recovery/package truth, direction-set reporting, and the generation-specific creation source scan.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb

## Corrections

- **R0-01, READY handoff recovery:** A nonterminal package cell whose Source Session is already READY now verifies the existing reviewed candidate, handoff destination, and target Workbench and restores the package receipt. It does not repeat production conversion or overwrite the Workbench. A READY session missing its handoff or Workbench fails closed.
- **R0-02, completion proof:** Terminal EDITABLE_WORKBENCH reuse and `validate_package()` recheck the current package plan/source and projected target authority, session target binding/state, reviewed candidate digest, existing handoff identity, and Workbench target identity/frame manifest/document. An artist-edited Aseprite file is not compared to the original candidate or rewritten.
- **R0-03, direction progress:** `process_package()` handles and persists each direction independently. One BLOCKED cell no longer prevents later directions from progressing. The UI returns aggregate/selected-cell status and opens Aseprite only when the selected cell has a validated Workbench.
- **R0-04, NEW collisions:** Added generation scan root resolution for source-parent, default `source/animations`, and already generation-scoped roots. The default OPUI root now sees alternate-frame same-generation semantic counterparts while legacy behavior remains unchanged.

## Validation

- `operator_2_5d_ingress`: passed, including READY crash recovery, edited-document preservation, stale source/candidate/plan checks, missing and mismatched Workbench rejection, per-direction continuation, no-open behavior, and 12f-vs-15f collision controls across three root shapes.
- `operator_asset_schema`, `operator_art_source`, `operator_art_registration_profile`, `operator_animation_workbench`, `operator_workbench_ui`: all passed (6/6 official runner invocations).
- `operator_animation_targets_smoke.py`: passed.
- `run_validation.py --changed --json`: 12 selected, 12 passed, 0 failed/timeouts/infrastructure errors; coverage complete. Report: `/tmp/wb25-2-r0-correction-changed-final.json`.
- `python3 -m compileall -q custodian/tools/operator custodian/tools/validation`: passed.
- `git diff --check`: passed.
- Graph review covered five changed code/test files. The graph's symbol-level gaps prompted verification against the new focused end-to-end smoke rather than treating aggregate gap counts as acceptance evidence.

## Limits and friction

The initial implementation tests missed crash recovery after handoff and stale completed-cell evidence. The correction uses disposable SourceArtService fixtures; it did not write production art/resources/selectors. Visual review was not applicable. The checkout graph was missing at claim time and was initialized before code review.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: Four real restart/collision gaps escaped the parent happy-path tests; the UI previously expected direction-set processing to return one process handle.
- Root cause / contributing factors: Package terminal strings bypassed live proof, direction processing stopped at first error, and the default source root was normalized incorrectly for the 2.5D generation.
- Prevention / pipeline improvement: Added the four independent regressions, including persistence-boundary recovery and all supported source-root forms; run the focused ingress smoke on future changes to this service.
- Tooling / docs drift discovered: none
- Follow-up: review-operator-2-5d-workbench-ingress-review-corrections-1
- What worked: Real Aseprite/SourceArtService smoke recovered a READY session without conversion and preserved edited Workbench bytes.

## Next Handoff
- Next workstream: review-operator-2-5d-workbench-ingress-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: none
- Next action: Claim the paired fresh-context re-review.
- Blockers or open questions: none
