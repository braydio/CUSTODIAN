# Review Findings Bridge Closeout Recovery V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-findings-bridge-review-closeout-recovery-v1`
- Category: `agent-ops`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `agent-findings-bridge-review-closeout-recovery-v1`
- Locks: `none`
- Kind: `review`
- Review: `none`
- Review target workstream: `agent-findings-bridge-review-closeout-recovery-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_FINDINGS_BRIDGE_REVIEW_CLOSEOUT_RECOVERY_V1.md`
- Review modes: `code, architecture, workflow`
- Review rationale: `none`
- Reviewed main: `4d3b1978c09d51753cd63b2b8f416201284b4170`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af0b3b3-e168-83ea-a136-5047fc969fbe
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently determine whether the exact-run findings closeout recovery authenticates the preserved reviewer evidence without turning a failed session into PASS or disturbing protected state.
- Completion boundary: Review only the landed implementation for `agent-findings-bridge-review-closeout-recovery-v1`, exact protected run `20261110T113743Z-f5db7f631c66`, V2 claim `20261110T113805Z-ee5bb73efbaf`, acquisition turn `ee5bb73efbaf4e39af72b0c82836f0eb`, reviewed main `6ce61c8f8b101d88e8c05f0312cd1f4931873743`, branch `agent/review-agent-paired-review-findings-artifact-recovery-v1`, and target implementation `a4e9dbc8505bcde3eb20b5f40b32df838a4b550d`. Independently inspect the source, tests, exact-run read-only plan and synthetic adversarial cases. Do not execute apply or modify the held review checkout, run, claim, lock, reviewer artifacts, target implementation, or unrelated work.
- Current measured state: At authoring main `4d3b1978c09d51753cd63b2b8f416201284b4170`, the exact recovery pair and implementation are absent. The held review's pinned artifacts match their expected SHA-256 values, host validation is 2/2 PASS, and the run remains `post_exit_recovery` because the generic strict parser rejects its nonempty stderr. This is a findings-only state, not a review PASS.
- Evidence: Use the implementation packet's seven public-safe hash pins and exact identities. The raw run files and reviewer artifacts are host-private and must be resolved by the documented local verification route; do not commit, attach, or reproduce their raw contents. The existing implementation source and reviewer tests are tracked in the reviewed main and enumerated in the implementation packet's `Publication inputs:`.
- Task-specific authority: The implementation packet; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_FINDINGS_ARTIFACT_RECOVERY_V1.md`; `custodian/tools/agent/paired_review_findings_closeout_recovery.py`; `custodian/tools/agent/test_paired_review_findings_closeout_recovery.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/review_outcome.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Work surface: Review the new exact-run recovery module/tests, existing strict reviewer-session parser and canonical nonpassing closeout paths, and the immutable host-private evidence by hash and read-only plan.
- Publication inputs: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/turn_dispatcher_v2.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_FINDINGS_ARTIFACT_RECOVERY_V1.md`.
- Reviewed implementation acceptance: The implementation authenticates the exact claim and V2 acquisition, reviewer identity, run/host-report/session evidence, all seven pinned hashes, target commit/bytes and findings before producing a digest-bound plan. The scoped stderr compatibility does not weaken `_parse_redacted_final_session()`, synthesize a clean session, or admit any non-pinned stderr. Apply is separately authorized, revalidates evidence and ownership, changes only four allowed administrative closeout paths in an isolated checkout, preserves original evidence and target bytes, records one findings outcome without PASS, and never releases a claim or lock.
- Review evidence: Read the complete landed diff and focused tests. Independently recompute public-safe pinned hashes on the host without printing raw files; inspect the authenticated V2 claim/acquisition and exact run metadata; execute only the read-only exact-run plan; compare its identities, evidence hashes and target branch/commit to the packet; verify no source evidence or protected worktree mutation. Exercise the deterministic synthetic fixture suite and add reviewer-owned negative probes if a material gap remains.
- Review focus: Confirm the exact pinned stderr is matched by both digest and narrowly classified non-mutating failure shape; all other stderr and failed/contradictory/malformed sessions are rejected; no temporary or synthetic-clean session copy bypasses the strict parser; final reviewer message matches raw JSONL through the pinned redactor behavior; exactly one `findings / R0-01` is corroborated by archive and summary; claimed branch, review target, implementation commit and reviewed main all match; symlink inventories include link type and link target without following links; the plan digest covers evidence, refs, owners, filesystem inventory and bounded paths; apply requires authorization plus the fresh digest and refuses live/unknown owner, stale bytes or out-of-scope paths; retries cannot duplicate outcomes; target bytes, original checkout/run, claims, locks and unrelated files remain unchanged.
- Correction threshold: Findings are required for any acceptance of stderr without full digest and semantic reconciliation, a generic stderr relaxation, malformed or substituted evidence acceptance, wrong run/claim/target identity, target mutation, unauthorized apply, new PASS path, claim/lock release, or omitted changed path. Do not fix the implementation in this review workstream.
- Validation: Run `python3 -m unittest custodian.tools.agent.test_paired_review_runner -v` and the focused recovery test suite identified in the landed implementation handoff. Verify the exact-run read-only plan succeeds only on the pinned host evidence and that its plan digest binds every listed input; do not invoke apply. Check AI-context and packet lifecycle validation and inspect the exact main/implementation review span. If the host-private evidence is unavailable or any identity/hash differs, stop with a findings disposition; never substitute newly created evidence.
- Acceptance: A fresh different-agent reviewer records an evidence-backed `passed`, `findings`, or `human_required` disposition for this exact target and commit. `passed` requires all positive and adversarial checks, unchanged protected state and target bytes, and proof that neither the implementation nor review invoked recovery apply. A findings or human-required result must remain truthful and must not release protected state.
- Non-goals: Applying recovery to the held run; claiming, changing or releasing the held claim/lock; modifying protected checkout/run evidence; launching a replacement reviewer; modifying the target implementation; accepting a PASS from the original held run; fixing the symlink inventory bug; touching Weather V2, Operator Chassis, Operator runtime or tooling-library workstreams.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only its durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary and bounded correction/re-review packets. Never edit the reviewed implementation or unrelated work.`
- Deferred: Recovery application requires a separate explicit orchestration authorization after this fresh independent review is accepted. A later source correction to the reviewed symlink inventory remains a distinct workstream.

## Publication hold

This pair is `draft/manual` for atomic authoring validation and the push-triggered packet-authoring handoff only. Do not claim or execute the review until the implementation has landed, the paired handoff is promoted, and the dispatcher confirms the exact review is eligible.
