# REVIEW: AGENT VALIDATION GATE DRIFT REPAIR

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-validation-gate-drift-repair`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `agent-validation-gate-drift-repair`
- Locks: `agent-workflow, task-packet-validation`
- Review: `none`
- Review target workstream: `agent-validation-gate-drift-repair`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_VALIDATION_GATE_DRIFT_REPAIR.md`
- Reviewed main: `440dccbb274707869eb0a9eebf109e6588a4f26c`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the two global landing-gate failures were repaired at their real shared authorities without weakening fail-closed packet validation, restoring expired temporary workflow state, or modifying unrelated game/runtime work.
- Reviewed implementation acceptance: Exact implementation acceptance from archived `AGENT_VALIDATION_GATE_DRIFT_REPAIR.md`: post-expiry workflow smoke passes with the temporary workflow absent; validation references preserve/resolve repo-root, Godot `res://tools`, and project-root `tools` forms; genuine missing scripts still fail; the Operator profile forward reference is removed while future-smoke authoring remains required; the prior eight false-positive workstreams are clear; both manifest-backed gates and focused agent tests are green; no gameplay/runtime files changed.
- Review evidence: Reuse implementation unit results, before/after `review_pairing_contract` output, manifest-backed gate JSON, exact diff for `agent_workflow_smoke.py` / `task_packet_contract.py` / manifest / Operator packet, and temporary-repository path-resolution fixtures. Gather no game/runtime evidence unless the diff unexpectedly crosses those boundaries.
- Correction threshold: Any regression that permits a genuinely missing ready-packet validation script, incorrectly maps arbitrary `res://` paths, restores/depends on the deleted expiry workflow, or leaves either global gate failing is correction-worthy. Stylistic helper naming and optional documentation refinements are non-blocking.
- Focused validation: Run `python3 custodian/tools/agent/test_task_packet_contract.py`, `python3 custodian/tools/agent/test_dispatch.py`, `python3 custodian/tools/agent/test_review_contract.py`, `python3 custodian/tools/agent/validate_review_pairing.py`, `python3 custodian/tools/validation/agent_workflow_smoke.py`, plus manifest-backed `agent_workflow_contract` and `review_pairing_contract`. Inspect that the exact eight previous workstreams no longer appear and one synthetic missing path still fails.
- Review focus: (1) path mapping is explicit and bounded; (2) original reference strings survive for diagnostics; (3) root `tools/` is not accidentally forced into `custodian/tools/` when a real root file exists; (4) deleted expiry state remains deleted; (5) Operator future-smoke rule is fixed without disabling future existence checks; (6) no game/runtime diff.
- Acceptance: Produce a findings-first independent review of live `main`. Record a `passed` receipt or concrete findings with stable `R0-NN` IDs, class/domain/affected acceptance/evidence/disposition/rationale. Blocking defects/material proof gaps create `agent-validation-gate-drift-repair-review-corrections-1` and its paired review. Do not patch reviewed implementation code.
- Non-goals: Do not fix Marine/Operator/procgen feature branches, broaden packet syntax beyond validation script path resolution, redesign dispatch, or reintroduce temporary LFS routing.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after `agent-validation-gate-drift-repair` completes and archives.
2. Compare live main against the implementation packet's exact completion boundary.
3. Re-run focused workflow/packet tests before any broad gate.
4. Verify one positive case for each supported path form and one negative missing-path case.
5. Confirm the expired workflow/markers remain absent and no runtime/game files changed.
6. Record the review receipt and use the ordinary correction lifecycle only for blocking defects/evidence gaps.

## Handoff

- Next action: Auto-dispatch immediately after the P0 implementation packet completes.
- Blockers or open questions: none.
