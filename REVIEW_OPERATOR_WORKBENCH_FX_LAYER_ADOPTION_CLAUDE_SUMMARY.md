# Operator Workbench FX Layer Adoption — Independent Review

## Result

The paired fresh-context review found one blocking publication defect and one deferred validation-harness issue. The implementation safely handles explicit saved-layer adoption, CREATE collisions, mirroring defaults, preview projection, and existing rollback fixtures, but REPLACE publication has a time-of-check/time-of-use gap: source freshness is checked before export/transaction setup, while the later source swap uses `os.replace` without verifying that the live canonical source still matches the adopted `file_sha256`. An external update in that interval can be overwritten, and current rollback preimages may capture that changed file.

Correction `R0-01` is packeted in `operator-workbench-fx-layer-adoption-review-corrections-1`; its paired review is `review-operator-workbench-fx-layer-adoption-review-corrections-1`. No reviewed implementation code was changed in this review workstream.

## Findings

- `R0-01` — `blocking_defect`, implementation, disposition `correction`: revalidate and protect the exact REPLACE preimage at the source-swap boundary, and ensure rollback never overwrites an external concurrent replacement. The archived review receipt records source locations and affected acceptance.
- `R0-02` — `non_blocking_issue`, pipeline, disposition `deferred`: the modular-defense smoke exits 0 and prints PASS while also emitting missing class/resource errors and an invalid helper call. This Workbench change does not alter gameplay code, and focused Workbench/UI/publish smokes plus import preflight pass; preserve the caveat for a separate harness reliability task.

## Independent Validation

- `operator_animation_workbench_smoke.py`: PASS.
- `operator_workbench_mirror_publish_smoke.py`: PASS, including FX CREATE/REPLACE, mirror transactions, collision refusal, metadata restoration, and rollback.
- `operator_workbench_ui_smoke.py`: PASS; optional Textual pilot skipped because the optional dependency is not installed.
- `godot_import_preflight_smoke.py`: PASS.
- `operator_modular_defense_ranged_smoke.gd`: process exit 0 and PASS marker, but emitted diagnostics including `ControllableActor` / `WorldSimulationRuntime` load failures, missing imported texture resources, animation errors, and `Invalid call. Nonexistent function '_exit_ranged_ready (via call)'`. Treated as a non-blocking evidence caveat because gameplay was not changed and the focused tooling checks passed.
- Graph index was empty in this fresh worktree; targeted source reads were used after confirming the graph had no indexed nodes.
- The review packet's original `Reviewed main` pointed to an earlier predecessor (`0c2a646ccd`). This review recorded the actual live reviewed HEAD `1e62ce7e2ff5dec8e1c76cff1850715f5a1e89dd`.
- The repository-wide `validate_review_pairing.py` remains red on an unrelated existing `contract-world-operator-void-spawn-failsafe-correction` pair (paired review not ready and bounded override malformed). The new correction pair validates when isolated; the unrelated packet was left untouched. Dispatch eligibility should be rechecked after this review lands.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `low`
- What went wrong: The modular-defense smoke reports PASS despite script/resource diagnostics; the review packet's inherited reviewed-main SHA was stale.
- Root cause / contributing factors: The smoke does not fail on all script diagnostics; planning metadata recorded a predecessor main SHA.
- Prevention / pipeline improvement: Keep smoke exit status and diagnostic caveats together; record the actual reviewed HEAD in the durable review receipt.
- Tooling / docs drift discovered: The graph database had no indexed nodes in this fresh worktree; review packet `Reviewed main` was stale and corrected in the archived receipt.
- Follow-up: `operator-workbench-fx-layer-adoption-review-corrections-1`
- What worked: The exact independent review smokes covered the new adoption path without recapturing visual evidence.

## Next Handoff

- Next workstream: `operator-workbench-fx-layer-adoption-review-corrections-1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d
- Refresh reason: `none`
- Next action: Claim the bounded source-conflict correction once this review is archived and dependency eligibility updates.
- Blockers or open questions: `R0-01` must be corrected and independently re-reviewed; the current repository-wide review-pairing guard also fails on unrelated `contract-world-operator-void-spawn-failsafe-correction` metadata.
