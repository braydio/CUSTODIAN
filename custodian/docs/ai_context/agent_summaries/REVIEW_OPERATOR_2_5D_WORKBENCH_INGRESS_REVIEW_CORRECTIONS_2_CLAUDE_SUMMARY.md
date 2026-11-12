# WB25-2 Ingress Review Corrections 2

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb

Review verdict: passed. R1-01 and the remaining R0-02 physical saved-document gap are fixed. Retained R0-01, R0-03, and R0-04 behavior remains green. No implementation files were changed in this review workstream.

## Findings

None. The cycle-2 acceptance passed with zero blocking defects and zero material evidence gaps.

## Independent physical-document evidence

- The correction smoke created real Aseprite documents at 12f/128x128 and 15f/127x128, plus a nonempty unreadable file, while retaining a valid 15f/128x128 target manifest.
- For every invalid document, completed reuse, `validate_package()`, and READY recovery refused with the saved Workbench Aseprite contract error. The physical document, reviewed candidate, and staged handoff bytes remained unchanged.
- The positive control saved a real pixel edit through Aseprite, resumed the READY Source Session without conversion, and kept the edited document byte-for-byte unchanged.
- A separate disposable probe changed the Source Session to `REVIEWED`, supplied a real 12f/128x128 document under the unchanged 15f target manifest, and called the existing `process_cell()` handoff path. It refused before `SourceArtService.handoff()` was invoked; the invalid saved document remained unchanged. The probe restored fixture state before continuing the smoke.
- Physical inspection is reached in `_validate_workbench()` before the reviewed handoff in `_process_cell()`. It checks actual frame count, canvas dimensions, and per-frame duration against target/manifest timing without invoking reconciliation.

## Retained acceptance and regression evidence

- `python3 custodian/tools/validation/operator_2_5d_ingress_smoke.py`: PASS, including legacy-96 compatibility, 2.5D publish refusal, READY recovery without conversion, package closure and completed reuse physical controls, eight-direction progress despite blocked N, and the original semantic alternate-frame collisions.
- Independent REVIEWED-state physical mismatch probe: PASS; refusal preceded the handoff call.
- `python3 custodian/tools/validation/run_validation.py --test operator_asset_schema --json`: PASS.
- `python3 custodian/tools/validation/run_validation.py --test operator_art_source --json`: PASS.
- `python3 custodian/tools/validation/run_validation.py --test operator_art_registration_profile --json`: PASS.
- `python3 custodian/tools/validation/run_validation.py --test operator_animation_workbench --json`: PASS.
- `/tmp/custodian-wb25-venv/bin/python custodian/tools/validation/run_validation.py --test operator_workbench_ui --json`: PASS, Textual pilot enabled; browser/live/preview controls and 2.5D matrix remained green.
- `python3 custodian/tools/validation/operator_animation_targets_smoke.py`: PASS, direction/readiness/read-only behavior.
- `git diff --check`: PASS.

## Review method and provenance

Claimed and reviewed on landed main `b59eeb3c526b8661944bce08922e6a66edf30f89` in a fresh Codex workstream. Provenance is `different-agent` relative to the implementation session, whose durable correction summary was authored by Claude. Reconstruction used the active review packet, archived cycle-2 correction and cycle-1 review/implementation packets, cycle summaries, active Workbench and 2.5D design authority, current state, live source, and fresh tests/probes.

The coordination-root CRG was available at the same main SHA. Its `detect_changes` orientation prioritized `_validate_workbench`, `inspect_saved_document_contract`, and `_apply_one`; its static test-gap counts were not treated as acceptance failures. Focused smokes and real saved-document probes supplied behavioral evidence.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The initial claim command produced no visible receipt text even though it created the claimed worktree; worktree and branch evidence recovered the assignment. Parallel focused validation runners serialized behind the shared Godot project lock.
- Root cause / contributing factors: Dispatcher output capture did not expose the claim receipt, and validation runners use a shared project lock.
- Prevention / pipeline improvement: Confirm claimed worktree state from `git worktree list` when output is absent; let runners serialize instead of treating lock waits as test failures.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: A disposable real-Aseprite probe independently covered the existing REVIEWED handoff boundary and verified refusal before handoff.

## Next Handoff

- Next workstream: operator-2-5d-workbench-polish-automation
- Next packet state: refresh-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: WB25-3 must consume the accepted landed Source Session/Workbench handoff and exact Art Agent seams after cycle-2 correction re-review.
- Next action: Return the landed implementation, correction, and passed review evidence to the authoring chat and refresh WB25-3 before dispatch.
- Blockers or open questions: none for this review; WB25-3 remains draft until the recorded planning refresh.
