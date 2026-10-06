# Operator Workbench browser / preview correction cycle 2

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab

Implemented and validated the final automatic correction for R1-01 and the remaining R0-04 ownership evidence gap.

- `_live_document_matches_selection` now requires the selected Workbench to match both the result/event document and the editor's currently active document. An absent active document fails closed.
- Async Live Bridge results recheck active document ownership after live-image, comparison, and transition-analysis awaits and immediately before applying preview state.
- Synchronous F5 export/load captures the document identity across both awaits. A document switch rejects the live image and uses the saved Workbench preview when the selection remains valid.
- Comparison and transition loaders now retain the captured examiner mode across awaits alongside selection, source, generation, target, and primary-preview ownership.
- The deterministic smoke covers the real app debounce → controller → real server send → command cause/result path with a fake transport; wrong result document, revision, output path, missing generation/identity/source; disconnect; active-document changes during live image, comparison, transition analysis, synchronous export, and synchronous live loading; valid same-document result; saved fallback; and selection/source/examiner-mode supersession with preview, comparison, transition, frame, and PreviewControls preservation.
- Updated the active Workbench design and current-state contract with the active-document requirement.

Validation:

- `/tmp/custodian-opui/bin/python custodian/tools/validation/operator_workbench_ui_smoke.py`: PASS, all expanded Textual Pilot controls executed.
- `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`: PASS, 15/15 selected, 0 failed/timed out/skipped/infrastructure errors, complete changed-file coverage. Report: `/tmp/operator-workbench-cycle2-validation-final.json`. The system-Python runner's UI entry reports its optional Textual Pilot as skipped; the pinned run above supplies the complete app-level evidence.
- `python3 -m py_compile custodian/tools/operator/ui/app.py custodian/tools/validation/operator_workbench_ui_smoke.py`: PASS.
- `git diff --check`: PASS.
- `python3 custodian/tools/agent/task_packet_index.py`: PASS after archive/index regeneration.
- One expanded Pilot invocation encountered a transient Textual shutdown timer error; immediate clean reruns passed, including the final pinned run.

No renderer or animation Workbench smoke was run: this correction changes UI result ownership and does not alter discovery projection, art, or runtime assets. No production-crash root cause is inferred; the historic traceback remains unavailable.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: The first synchronous-loader probe matched a replaced callable incorrectly; its barrier was moved into the service loader. One full Pilot invocation hit a transient shutdown timer error before clean reruns passed. System Python omits optional Textual coverage.
- Root cause / contributing factors: Active editor document identity had not been rechecked across asynchronous work. Generation-only fixtures also did not isolate examiner-mode ownership.
- Prevention / pipeline improvement: Barrier tests cover issue-to-result transport and each async acceptance boundary, including independent selection/source/examiner-mode controls and disconnect.
- Tooling / docs drift discovered: The changed-file runner's system-Python UI run skips the optional Textual Pilot; use the pinned `/tmp/custodian-opui` environment for complete UI evidence.
- Follow-up: review-operator-workbench-browser-preview-refresh-hardening-review-corrections-1-review-corrections-2
- What worked: Real server command-cause handling plus deterministic barriers proved the corrected ownership checks without renderer capture.

## Next Handoff

- Next workstream: review-operator-workbench-browser-preview-refresh-hardening-review-corrections-1-review-corrections-2
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab
- Refresh reason: none
- Next action: Run the fresh paired review for cycle 2; if clean, identify the FX-adoption lane's exact live dependency and refresh gate.
- Blockers or open questions: This is the final automatic correction cycle; any correction-worthy unresolved finding requires human decision. Historic production traceback remains unavailable.
