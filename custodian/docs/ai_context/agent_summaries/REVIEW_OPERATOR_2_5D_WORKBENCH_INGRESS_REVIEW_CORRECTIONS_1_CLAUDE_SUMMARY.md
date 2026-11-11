# WB25-2 Ingress Correction Cycle 1 Independent Review

Review verdict: findings — one confirmed blocking defect remains. R0-01, R0-03 and R0-04 are fixed; R0-02 is unresolved for the physical saved-document contract, recorded as R1-01. Cycle 2 is the final automatic bounded correction.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb

- Reviewed implementation: d56c34d562e76f2e512fa309a708bb92d0299c94 (plus committed correction completion receipt).
- Reviewed main: 667370e3443818253112980497e2ee0d71f21d68
- Reviewer context: fresh
- Reviewer provenance: same-agent-fresh-context
- Reconstruction: archived correction and parent packets, original R0 findings and summary, correction summary, WB25-1 correction/re-review receipts, active migration/visual/Workbench/Source Session authorities, live landed diff, graph, focused smokes and disposable independent probes. This new Codex context received the named review assignment and no transient implementation reasoning.

## Findings

### R1-01 — Terminal and READY proof trust manifest contracts while accepting the wrong physical Aseprite document

- Class: blocking_defect
- Domain: implementation
- Affected acceptance: R0-02 requires absent/wrong-target/wrong-contract Workbench refusal before completed reuse and package closure; R0-01 READY recovery must prove an exact editable target Workbench.
- Evidence: `custodian/tools/operator/operator_2_5d_ingress.py:196` checks only nonempty document existence; lines 202–230 validate JSON manifest identity/frame/canvas/layer fields. A real reviewed/staged 15f/128px NE Source Session and valid target manifest were retained. A second real Aseprite Workbench was created with 12 frames at 128px; only its saved document bytes were copied over the disposable target's document. The physical Aseprite header reports 12 frames, while the untouched manifest reports 15. `process_cell(single_package, "ne")` returned EDITABLE_WORKBENCH and `validate_package(single_package)` returned complete=true. The existing `animation_workbench.reconcile_saved_document_contract(...)` rejected exactly the same bytes with SAVED ASEPRITE FRAME CONTRACT MISMATCH: physical 12, manifest/source/workspace/binding 15. Restoring the valid target document restored the passing control.
- Disposition: correction
- Rationale: package and manifest hints cannot prove that the saved editable document carries its required contract. Reuse the existing saved-document inspection authority in a read-only manner; preserve valid artist pixels and fail before conversion, handoff, opening or package completion on physical mismatch. Do not compare edited pixels to the original candidate.

## Original finding dispositions

| Finding | Disposition | Independent evidence |
| --- | --- | --- |
| R0-01 | fixed | Reset real READY NE cell to SOURCE_STAGED and remove terminal receipts; resume restored EDITABLE_WORKBENCH while production_command was forbidden. Document and handoff SHA/mtime were unchanged. Reviewed candidate/handoff/document mismatch refusals remain covered. |
| R0-02 | unresolved | Changed original source, reviewed candidate, staged handoff, Source Session identity, missing document and wrong manifest target all refused; unchanged completed cell closed. Real physical 12f document under a 15f manifest still passed, as R1-01 proves. |
| R0-03 | fixed | Actual WorkbenchService invocation over completed NE, blocked N and six pending valid directions produced 7 editable / 1 blocked / 0 pending; restart kept the same counts, N reason and all seven document hashes. Selected N never resolved or opened an editor. |
| R0-04 | fixed | Independent 12f/128px semantic counterpart caused COLLISION for requested 15f across source-parent, actual default source/animations, generation animations and generation parent roots. Legacy-96-only controls were READY across all roots and retained exact bytes. |

## Validation and evidence

All six required official focused runner invocations passed: operator_2_5d_ingress, operator_asset_schema, operator_art_source, operator_art_registration_profile, operator_animation_workbench, operator_workbench_ui. UI was rerun using `/tmp/custodian-wb25-venv/bin/python` with the Textual pilot enabled; its 2.5D matrix and full browser/live/preview controls passed with no skipped pilot. Direct operator_animation_targets_smoke.py passed direction/readiness/read-only checks. Ingress focused smoke and independent probes use real Aseprite/128px SourceArtService fixtures and explicit legacy-96 compatibility / unconditional 2.5D publish refusal.

Fresh evidence: `/tmp/wb25-r1-focused.json`, `/tmp/wb25-r1-ui-textual.json`, `/tmp/wb25-r1-targets.log`, `/tmp/wb25-r1-independent-probes.json`, `/tmp/wb25-r1-collision-probe.json`. Independent executable probes are `/tmp/wb25-r1-probes.py` and `/tmp/wb25-r1-collision.py`; they derive temporary fixtures from the checked-in ingress smoke, perform real private/service calls and restore original fixture state before the smoke's remaining controls. Temporary source/session/art fixtures were deleted automatically; no reviewed implementation or production asset was edited.

Reused broader correction evidence `/tmp/wb25-2-r0-correction-changed-final.json`: 12 selected / 12 passed, complete owned-path coverage. It covers the normal implementation paths but does not settle R1-01. Review artifact validation `/tmp/wb25-r1-artifact-validation.json` passed 2/2 (review_pairing_contract, visual_review_handoff), complete owned-path coverage. Targeted authoring preflight passed both before and after ready/auto promotion; managed queue index regenerated and verified. Post-sync artifact report `/tmp/wb25-r1-artifact-validation-after-sync.json` also passed 2/2 with complete coverage. `git diff --check` passed.

Graph entry initially reported missing worktree graph. Built the graph at reviewed main (1,865 files, 20,665 nodes), then detect_changes prioritized _validate_workbench/_validate_ready_proof/validate_package. Caller traversal confirms _validate_workbench is used by READY proof and creation/resume; tests_for has no statically resolved direct coverage. Minimal postprocess produces no affected flows, so exact source and actual probes supply behavioral evidence.

Moment Forge: not run — tooling/workflow review, no runtime presentation change. Visual review: none; no subjective aesthetic decision was attempted.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Green focused regressions changed only manifest contracts, leaving physical saved-document mismatch untested. Default Python skipped the optional Textual pilot; the enabled environment was required. Fresh worktree graph initialization took several minutes. The initial focused-report aggregation used results instead of the runner's tests key; no test outcome was lost. First finish rejected historical nested correction naming; current lifecycle requires the flat lineage root plus cycle 2. Latest-main merge then conflicted only in the generated queue index; regeneration preserved both branches' packet truth.
- Root cause / contributing factors: Ingress proof validates the manifest while the actual saved Aseprite is only checked for nonempty existence; the tests mirror the manifest proof. Optional UI dependencies are installed in /tmp/custodian-wb25-venv rather than default Python.
- Prevention / pipeline improvement: Cycle 2 acceptance requires real readable wrong-frame/wrong-canvas documents and actual saved pixel edits, plus read-only refusal. Reused the installed UI environment and aggregated the unchanged official records with the correct schema.
- Tooling / docs drift discovered: Historical browser review summary describes nested cycle-2 naming; current paired-review artifact gate explicitly rejects nested lineages and requires root-series cycle numbering. Packet IDs/paths were corrected in-scope.
- Follow-up: operator-2-5d-workbench-ingress-review-corrections-2
- What worked: Real direction-set service probes progressed six pending siblings around blocked N, and restart preserved all seven editable document hashes.

## Next Handoff

- Next workstream: operator-2-5d-workbench-ingress-review-corrections-2
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: none
- Next action: Claim the final bounded automatic correction for R1-01 / remaining R0-02, validate and land it, then start its cycle-2 paired review from fresh context.
- Blockers or open questions: WB25-3 remains draft/refresh-required after successful correction re-review; unresolved blocking findings at cycle 2 require human_required rather than another automatic correction.
