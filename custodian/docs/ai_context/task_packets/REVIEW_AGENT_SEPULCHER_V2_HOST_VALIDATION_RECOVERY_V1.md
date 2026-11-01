# REVIEW: Sepulcher V2 Held Host-Validation Recovery

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-sepulcher-v2-host-validation-recovery-v1`
- Category: `agent-ops`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `agent-sepulcher-v2-host-validation-recovery-v1`
- Locks: `sepulcher-v2-host-validation-recovery`
- Review: `none`
- Review target workstream: `agent-sepulcher-v2-host-validation-recovery-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_SEPULCHER_V2_HOST_VALIDATION_RECOVERY_V1.md`
- Reviewed main: `58f52ac2b8f7e5ea60b48a00a3af57f55ee32c79`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, runtime, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: `Independently falsify any false green caused by relaxing V2 spawn validation or by authenticating an actually failed host report as a PASS. Verify original review claim and byte evidence remain untouched.`
- Reviewed implementation acceptance: `A1-A6 of archived agent-sepulcher-v2-host-validation-recovery-v1 packet; every source/motion and failed-report invariant must pass.`
- Review evidence: `Exact original unchanged failed report SHA/claim identity and frozen run; corrected smoke same Operator/scene; cold-run Godot pass and falsifying cases; runner tests with valid failed reports and tampered reports; full changed-file coverage.`
- Correction threshold: `Fail if test drops genuine spawn/movement regression coverage; if real Operator/camera/scene changes were made to pass smoke; if original pinned review is mutated, a failed suite is called PASS or accepted as green, source identities/claim IDs mismatch, broad runner constraints are removed, or no independent reproducible evidence is provided.`
- Focused validation: `Repeat new focused V2 smoke 3 times on fresh cold headless Godot imports, test deliberately wrong spawn/movement and V1 smoke; adversarial paired_review_runner failed-report evidence tests; changed-file validation; source-scope proof; git diff --check. Preserve original run.`
- Review focus: `Separate valid failed host-report authentication from a successful reviewer verdict; distinguish corrected test source in a new landed commit from prior immutable original review's pinned source. Technical independent acceptance is separate from human visual/art acceptance.`
- Acceptance: `Fresh findings-first R0-NN report and canonical independent PASS only if smoke correctness and provenance fail-closed controls hold. Only then may the coordination owner plan authorized original-run disposition and a new independent V2 review against corrected source. No original review auto-PASS.`
- Non-goals: `No original run recovery apply, no modifying an old claim, no review approval for production 128px Operator or floor, no artwork regeneration or duplicate scene.`
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Next Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Summary backlink: `not-recorded`
- Refresh reason: `none; accepted correction is only a prerequisite to authorizing source-consistent V2 review`
- Next action: `Return host evidence and the exact next permissible original-review disposition/fresh V2 technical-review action, preserving the original claim until explicit supported reconciliation.`
- Blockers or open questions: `Original report's exact run ID/failed-report traceback must be authenticated on the Codex host; no forged outcome permitted.`
