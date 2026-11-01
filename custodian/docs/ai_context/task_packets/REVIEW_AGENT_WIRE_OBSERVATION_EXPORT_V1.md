# REVIEW CUSTODIAN WIRE OBSERVATION EXPORT V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-wire-observation-export-v1`
- Category: `agent-ops`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `agent-wire-observation-export-v1`
- Locks: `none`
- Review: `none`
- Review target workstream: `agent-wire-observation-export-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_WIRE_OBSERVATION_EXPORT_V1.md`
- Reviewed main: `f070b4ee7f46c16890469889886bc13126705387`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the landed WIRE observation exporter reports only complete, supported, sanitized evidence and cannot change canonical project state.
- Reviewed implementation acceptance: Verify all acceptance claims in the archived `AGENT_WIRE_OBSERVATION_EXPORT_V1.md`, especially input/source identity, source freshness and completeness, full-inventory count reconciliation, null-versus-zero behavior, strict redaction, deterministic evidence identity, schema rejection, and read-only operation.
- Review evidence: Reconstruct the contract from the archived implementation packet, live exporter/schema/tests, task-administrator snapshot, current dispatcher/recovery evidence contracts, and focused synthetic adversarial fixtures. Reuse durable implementation evidence when valid; do not run an overlapping/full live dispatcher audit merely for review.
- Correction threshold: A fabricated count/status, accepted or running inference, missing/partial inventory presented as complete, source revision/freshness mismatch, redaction leak, schema bypass, unstable digest for unchanged evidence, or any canonical-state mutation is blocking. Other confirmed acceptance defects or material evidence gaps require a bounded correction; non-blocking observations are recorded without changing the reviewed implementation.
- Focused validation: Independently run the focused exporter unit suite, schema checks, category/packet pairing checks, changed-file validation, and `git diff --check`; inspect tests and source for subprocess, Git, network, filesystem mutation, upload, or service-install paths.
- Review focus: Prove the exporter consumes supplied observations without invoking expensive collectors; falsify completeness/freshness/count claims with missing, failed, stale, mismatched, conflicting, duplicate, and unavailable evidence; inspect adversarial output strings for private path, credential, prompt, log, command-line, Dropbox-path, and host-identifier leakage; verify unknown evidence stays unknown and that no dispatcher/recovery/review authority is inferred or changed.
- Acceptance: Produce a findings-first fresh-context independent review of live `main`. Record a genuine passed receipt or concrete findings using stable cycle-scoped IDs and the repository review contract. Do not edit the reviewed exporter, schema, tests, or unrelated files. Any correction must identify the exact failed acceptance and use the normal correction/re-review lifecycle.
- Non-goals: Do not implement or patch the reviewed exporter; do not run or install a recurring service; do not upload telemetry; do not modify the public WIRE feed, publisher, hourly automation, dispatcher claims, review outcomes, Dropbox credentials/destinations, Render, or Quickshell.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after the implementation packet is complete and archived on `origin/main`.
2. Start from a fresh reviewer context and reconstruct the implementation contract from durable repository evidence.
3. Inspect the complete landed diff, exporter, strict schema, tests, validation registration, implementation summary, and task-administrator/dispatcher/recovery ownership seams.
4. Independently rerun the focused synthetic negative and positive fixtures. Do not launch a broad live audit unless a specific acceptance claim cannot be established from durable evidence; if required, use one bounded invocation and record any timeout as unknown evidence.
5. Verify the exact source revision and timestamps survive sanitization; recalculate counts from the complete inventory; attempt duplicate, missing, malformed, stale, future, conflicting, and privately identifying inputs.
6. Check that no operation writes Git refs, claims, worktrees, review receipts, service state, public feeds, Dropbox, or other canonical state.
7. Record objective findings first. Do not change implementation files. Create bounded correction work only for confirmed acceptance defects or material evidence gaps.
8. Complete and archive this review packet through the normal lifecycle; do not alter the implementation packet's completion truth or invent a PASS.

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: `none`
- Blockers or open questions: `none`
