# Review: Operator 2.5D Workbench Review Automation

## Findings

- **R0-01 — Blocking: caller-supplied human disposition can bypass the required-human gate.** In `custodian/tools/operator/operator_2_5d_review.py`, `inspect()` stores the supplied `human_disposition` mapping as-is at line 132. `current_receipt()` treats either `APPROVED` or `NOT_REQUIRED` as sufficient to set `runtime_verified=true` at lines 253-256. When live QA is `NEEDS_HUMAN_REVIEW`, passing `{"status":"NOT_REQUIRED"}` therefore produces a current effective verification without approval. That fails implementation acceptance (9), which requires the required-human gate to pass before effective verification. The UI’s own checkbox path supplies `APPROVED`, but the service/API boundary also accepts arbitrary caller statuses and does not enforce valid disposition or provenance.

No reviewed implementation/runtime code was changed. The review packet records the finding and is archived as a completed review activity; WB25-4 implementation acceptance remains failed pending a bounded correction and fresh re-review. The user explicitly limited durable edits to the receipt, summary, and authorized review packet, so no correction packet was created and no other workstream was claimed.

## Evidence and Validation

Reviewed implementation commit `23e88f377` (`operator 2.5d review, runtime sandbox`) in current `origin/main` ancestry and reconstructed the review from the archived implementation packet, its root summary, current main, and the paired review packet.

Passed focused checks: `operator_2_5d_review`, `operator_2_5d_polish`, `operator_2_5d_ingress`, `operator_animation_plan` (target projection), `operator_animation_preview_timeline`, `operator_workbench_ui`, and `operator_motion_preview`. The review smoke exercised a successful real-Operator sandbox, request/frame tamper refusal, and unchanged production runtime resources. Direct `operator_runtime_animation_authority_smoke.py` passed with its existing report of 188 legacy runtime residue files and one migration gate. `git diff --check 23e88f377^1 23e88f377` passed.

Two initially attempted test IDs (`operator_animation_targets`, `operator_runtime_animation_authority`) are not registered IDs in the validation manifest; their manifest-backed equivalents were run (`operator_animation_plan`, plus the runtime-authority smoke directly). Validation created nine untracked Godot `.import` sidecars; these generated files were removed after the checks.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: low
- What went wrong: the review found a required-human gate bypass; two descriptive smoke names in the packet were not registered runner IDs.
- Root cause / contributing factors: human-disposition values are accepted without a status/provenance gate; validation IDs differ from smoke filenames.
- Prevention / pipeline improvement: validate allowed human dispositions and approval evidence at the receipt authority boundary; map packet test descriptions to registered manifest IDs.
- Tooling / docs drift discovered: validation runner IDs are not obvious from smoke filenames.
- Follow-up: manual-follow-up
- What worked: focused runner evidence and the sandbox’s structured tamper/presentation assertions were reusable.

## Next Handoff
- Next workstream: none (planning must authorize/define bounded correction and re-review)
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: Blocking R0-01 prevents a clean WB25-4 review and must be addressed before WB25-5 treats WB25-4 as accepted.
- Next action: Bring the findings receipt to the exact authoring chat and define the bounded correction plus fresh re-review. Do not claim another packet until that planning gate is resolved.
- Blockers or open questions: decide the correction scope and the explicit approval provenance contract.
