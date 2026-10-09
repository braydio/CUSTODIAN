# Operator Workbench Publish Readiness and Recovery — Independent Review

Reviewed live `main` at `21ffccb775b24ed3d8c7e8d7651acdd438a18017` from a fresh context. The four required focused Workbench smokes passed. One blocking publication-boundary finding remains: the documented CLI entrypoint bypasses the UI service's readiness and dedicated-art-checkout landing contract.

## Finding

- **R0-01 — blocking correctness, publication boundary/workflow.** `custodian/tools/operator/operator_cli.py:58` calls `animation_workbench.publish(...)` directly for `operator anim publish`. That backend mutates canonical source PNGs (`animation_workbench.py:463-476`) without validating checkout identity or readiness. The UI path does validate readiness and routes through `operator_art_worktree.publish_to_main` (`ui/service.py:680-705`). A clean coordination-main CLI invocation can therefore replace canonical source/runtime files without the dedicated `workbench/operator-art` checkout, scoped staging, or approved landing handoff. The correction workstream and paired review are created as `operator-workbench-publish-readiness-recovery-review-corrections-1` and `review-operator-workbench-publish-readiness-recovery-review-corrections-1`.

## Verification

- `python3 custodian/tools/validation/operator_art_worktree_smoke.py` — PASS.
- `python3 custodian/tools/validation/operator_workbench_mirror_publish_smoke.py` — PASS.
- `python3 custodian/tools/validation/operator_workbench_ui_smoke.py` — PASS; optional Textual pilot skipped because Textual is not installed.
- `python3 custodian/tools/validation/operator_animation_workbench_smoke.py` — PASS.
- `python3 custodian/tools/pipelines/godot_import_preflight.py --project-dir custodian` — blocked in this full coordination checkout because Git LFS reported missing object `df9378d1c7b5ada8dc967939c275f6f2cb5abe94`. The implementation summary records a successful preflight after verified local hydration; I did not treat this checkout-specific failure as a product defect.
- No implementation code was changed. Durable finding receipt is recorded in the archived implementation packet and this review packet.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: UI-centered tests did not exercise the documented CLI publication dispatch. The full coordination checkout also lacks one Git LFS object needed by the import preflight.
- Root cause / contributing factors: CLI calls the transaction backend directly; smoke coverage focuses on UI service and fixture-level publication. LFS materialization differs across local checkouts.
- Prevention / pipeline improvement: Add CLI adversarial boundary coverage and route CLI publication through the shared readiness/allowlist/landing authority. Run import preflight in the sparse art checkout or rely on fresh exact-head materialization evidence.
- Tooling / docs drift discovered: `operator anim publish` is documented but bypasses the newly added service-owned readiness and landing boundary.
- Follow-up: operator-workbench-publish-readiness-recovery-review-corrections-1
- What worked: Graph caller tracing exposed the CLI path; all four packet-required focused smoke scripts passed.

## Next Handoff

- Next workstream: operator-workbench-publish-readiness-recovery-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: none
- Next action: Implement the bounded CLI publication-boundary correction; then complete its paired review before advancing Workbench browser/PREVIEW hardening.
- Blockers or open questions: none
