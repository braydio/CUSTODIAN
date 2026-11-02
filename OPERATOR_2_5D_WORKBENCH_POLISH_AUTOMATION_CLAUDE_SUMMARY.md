# Operator 2.5D Workbench Polish Automation (WB25-3)

## Result

Implemented publication-free polish tooling for exact accepted 2.5D Workbenches. Art Agent can attach a session to the exact existing manifest/document after ingress identity, candidate, frame, canvas, timing, and physical Aseprite checks; it does not recreate or reconcile that Workbench. Session projections retain backward-compatible legacy defaults and fail if their generation disagrees with the manifest. Registration profile/report/overlay and QA now derive the 128 profile from the bound generation.

Art Agent metrics add deterministic connected opaque components, adjacent/loop silhouette and boundary deltas, semantic-region color/luminance changes, and exact frame/reference comparisons. QA reports localized temporal findings. The Workbench UI adds a POLISH mode for attach/analyze, refresh, opening the exact document in Aseprite, registration guide overlays, manual Center X proposals, opt-in planted registration, tiny detached island proposals, bounded apply, and undo. Proposal generation is non-mutating. Apply sets a frame/layer/operation scope, delegates to the existing Art Agent transaction/journal, then checks the physical Workbench contract and restores through undo if it fails. POLISH exposes no publication action.

The active authoring-surface contract and sprite pipeline cheatsheet now include the sixth numbered POLISH mode. The focused `operator_2_5d_polish` validation is in the manifest and covers synthetic 15-frame jitter, opt-in/evidence/locomotion gates, detached component protection, temporal/reference diagnostics, pixel non-mutation, profile compatibility, and scoped move/undo delegation.

## Evidence

- Focused validation: `operator_2_5d_polish`, `operator_2_5d_ingress`, `operator_art_agent_service`, `operator_art_agent_aseprite`, `operator_art_registration_profile`, `operator_animation_workbench`, and `operator_workbench_ui` passed.
- `python3 custodian/tools/validation/run_validation.py --changed --json`: 29 selected, 29 passed, 0 failed, 0 skipped. This run included the integration/moment tier and emitted only known expected fixture diagnostics/deprecation warnings. A separate UI smoke reports its optional interactive Textual pilot skipped because Textual is not installed.
- After `workstream.py finish` merged newer `origin/main`, `run_validation.py --changed --base origin/main --json` passed all 30 selected checks (0 failed, 0 skipped) against the merged implementation tree.
- Python compile checks passed for the affected operator, Art Agent, UI, and focused validation modules.
- `git diff --check` passed.
- The 2.5D ingress smoke covers fail-closed physical frame/canvas/timing refusal and byte preservation; the polish attach/analyze/apply path reuses that exact validator without repair.
- No canonical source/runtime/publisher files were changed. Godot-generated `.import` sidecars and a transient Art Agent pilot report from validation were removed after inspection.

## Friction and Limits

The first changed-file sweep found a legacy profile smoke fixture with no session projection and an active-mode contract that needed the newly added POLISH mode documented. Both were fixed and the complete changed-file sweep passed. During UI wiring, static review found and fixed a misspelled import path before landing. The interactive Textual pilot could not run because the optional dependency is absent; the service/UI smoke and Python compile checks passed. The regression smoke tests transaction scope and undo delegation with a fake service; the existing Aseprite bridge smoke separately passed its real Aseprite coverage.

The smoke does not make a subjective art-direction decision. It tests objective proposal safety and keeps the human choice explicit where the packet requires it. No conditional visual handoff was needed because no unresolved subjective question was raised by the implemented acceptance checks.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: New mode wiring crossed legacy profile and active authoring documentation contracts; the first changed-file validation found those seams and an import typo.
- Root cause / contributing factors: Cross-layer UI changes also require updating the mode contract and user-facing shortcut docs, while legacy tests may use lightweight session stubs.
- Prevention / pipeline improvement: Keep active mode registry/docs and compatibility fixtures in the change inventory; run changed-file validation after wiring and before closeout.
- Tooling / docs drift discovered: Optional Textual interaction smoke is skipped when the dependency is absent. A pre-existing paired-review runner `origin/main:<path>` source-path issue was observed in a prior workstream and was outside WB25-3 scope.
- Follow-up: review-operator-2-5d-workbench-polish-automation
- What worked: Targeted contract/smoke checks localized the compatibility failures quickly; the changed-file sweep completed with full coverage.

## Next Handoff

- Next workstream: review-operator-2-5d-workbench-polish-automation
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: none
- Next action: Claim the paired review from a fresh reviewer context after WB25-3 lands.
- Blockers or open questions: none.
