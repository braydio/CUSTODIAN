# WB25-2 Ingress Review Corrections 2

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb

Closed R1-01 and the remaining R0-02 saved-document proof gap. Ingress now
inspects the physical Aseprite document before READY recovery, completed-cell
reuse, or package closure. Inspection checks actual frame count, canvas size,
and uniform timing against the current target and manifest. It uses the
Workbench's existing Aseprite inspection mode through a new read-only helper;
the migration reconciliation path remains the only path that can repair
obsolete migration metadata.

The focused regression creates real 12-frame/128px and 15-frame/wrong-canvas
Aseprite documents, plus a nonempty unreadable file. It verifies refusal in
completed reuse, `validate_package()`, and READY recovery while preserving the
document, candidate, and handoff bytes. The positive control now performs a
real Aseprite pixel edit, resumes the READY session, and verifies the edited
document remains byte-for-byte unchanged.

## Validation

- `operator_2_5d_ingress`: passed with physical mismatch, unreadable document,
  READY recovery, and edited-document preservation controls.
- `operator_asset_schema`, `operator_art_source`,
  `operator_art_registration_profile`, `operator_animation_workbench`, and
  `operator_workbench_ui`: passed; the UI run used
  `/tmp/custodian-wb25-venv/bin/python` to enable the Textual pilot.
- `operator_animation_targets_smoke.py`: passed.
- Final `run_validation.py --changed --base origin/main --json`: 7 selected,
  7 passed, no failures/timeouts/infrastructure errors, complete coverage.
  Report: `/tmp/wb25-r1-correction-final-closed.json`.
- `python3 -m compileall -q custodian/tools/operator custodian/tools/validation`:
  passed.
- `git diff --check`: passed.
- Graph was initialized, updated for all three changed files, and used for
  impact/change review. Its static test-gap counts were not treated as
  acceptance evidence; the focused Aseprite smoke exercises the persisted
  contract directly.

## Limits and friction

No production art, runtime resources, or selectors changed. Visual review was
not applicable. The first focused test run exposed a fixture issue: the
multi-direction package still had an intentionally pending N cell when the
test attempted package closure. The fixture now closes its complete
one-direction package and separately exercises READY recovery in the
multi-direction package. A fresh graph database was missing in the isolated
worktree and required initialization before graph review.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The first expanded smoke run tried to close an intentionally incomplete eight-direction package; the validation correctly rejected its pending N cell.
- Root cause / contributing factors: The added READY-recovery control reused a package whose N session had been staged earlier for a separate resumability check.
- Prevention / pipeline improvement: Keep the physical-document package-closure control on its own complete one-direction fixture; retain the multi-direction package only for the READY recovery path.
- Tooling / docs drift discovered: The claimed worktree had no code-review graph database; initialized and updated it before review.
- Follow-up: review-operator-2-5d-workbench-ingress-review-corrections-2
- What worked: Real saved Aseprite fixtures prove the physical contract independently from manifest claims while checking document and handoff preservation.

## Next Handoff

- Next workstream: review-operator-2-5d-workbench-ingress-review-corrections-2
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: none
- Next action: Claim the paired cycle-2 review from fresh context and independently verify R1-01 plus retained WB25-2 corrections.
- Blockers or open questions: none for implementation; unresolved blocking findings at this final automatic review cycle require a human decision.
