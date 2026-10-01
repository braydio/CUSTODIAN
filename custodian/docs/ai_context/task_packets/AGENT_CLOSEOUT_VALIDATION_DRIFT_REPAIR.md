# AGENT CLOSEOUT VALIDATION DRIFT REPAIR

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-closeout-validation-drift-repair`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `agent-validation-drift`
- Kind: `implementation`
- Review: `none`
- Goal: Restore truthful repository workflow and ready-packet validation after expired procgen routing was removed and validation references drifted.
- Completion boundary: Existing agent workflow and review pairing closeout checks pass against the checked-out candidate tree, preserving all live claim/pairing and validation-reference enforcement.
- Current measured state: `agent_workflow_smoke.py` unconditionally requires `.github/workflows/expire-lfs-degraded-mode.yml` and expired primer markers removed from current main. `validate_review_pairing.py` reports invalid script references in six contract-world placement packets, `PROCGEN_RENDER_ATTRIBUTION_V1.md`, and `OPERATOR_ART_REGISTRATION_PROFILE.md`. Several paths omit the repository-root `custodian/` prefix; the Operator registration smoke is genuinely absent.
- Evidence: R1 changed-file validation reports 10 pass / 2 fail / 38 tier-skipped; failing tests are `agent_workflow_contract` and `review_pairing_contract`.
- Task-specific authority: `AGENTS.md`; `custodian/AGENTS.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/VALIDATION_RECIPES.md`.
- Work surface: `custodian/tools/validation/agent_workflow_smoke.py`; bounded validation fields of the named unclaimed active packets; existing packet-reference tests when needed. Re-check active claims before editing packets.
- Change: Replace the expired routing-presence assertion with truthful post-expiry coverage; correct exact script paths in unclaimed packets. For the absent Operator registration smoke, re-derive a real acceptance command or leave that packet explicitly blocked until its prerequisite exists. Preserve strict missing-reference rejection and review pairing. Do not weaken gates to hide missing tests.
- Preserve: Remote unique claims, scoped worktree lifecycle, terminal validation failure gating, packet pairing and existing unrelated packet goals/acceptance.
- Non-goals: No runtime changes, no Operator death implementation, no fabrication or art changes, no broad packet rewrite.
- Acceptance: Both failing checks pass; exact live validation paths resolve; genuinely unavailable acceptance remains blocked; no claimed packet is overwritten; expired routing cannot silently reappear; R1 can resume normal closeout.
- Validation: Run `custodian/tools/validation/agent_workflow_smoke.py`, `custodian/tools/agent/validate_review_pairing.py`, and `custodian/tools/agent/test_dispatch.py`, then changed-file closeout.
- Task overrides: `none`
- Deferred: R1 runtime landing resumes in `custodian-death-handoff-foundation` after this repair.

## Handoff

- Next action: Inspect current claims and exact failing references, repair bounded tooling/doc drift, land and resume R1.
