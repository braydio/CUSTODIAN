# Review Owner Review Exception Lane V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-owner-review-exception-lane-v1`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `owner-review-exception-lane-v1`
- Locks: `agent-workflow`
- Kind: `review`
- Review: `none`
- Review modes: `code, architecture, workflow`
- Review target workstream: `owner-review-exception-lane-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OWNER_REVIEW_EXCEPTION_LANE_V1.md`
- Reviewed main: `8ef7e4e0b82a865552c47b4f1dc9e48a8e74480d`
- Authoring chat: `not-recorded`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Visual review: `none`
- Goal: Independently falsify the project-owner review exception, especially self-approval, fabricated PASS, missing tests, unsafe claim release and broad eligibility expansion.
- Completion boundary: Publish a fresh-context findings-first receipt and canonical PASS only when the exception is non-forgeable, commit-pinned, separately audited and cannot affect review truth or repository safety. Do not exercise an override against a live claimed review.
- Current measured state: Target implementation is unpublished at authoring; `review_outcome.review_acceptance` must remain truthful and no exception approval is recorded. A low-risk review-economy policy workstream is separately active.
- Evidence: New exact owner-decision code/fixtures; current `dispatch.py` dependency and claim checks; immutable negative fixtures for findings, frozen review runs, wrong approval actor and staleness.
- Task-specific authority: Archived implementation packet, `custodian/tools/agent/dispatch.py`, `review_outcome.py`, `paired_review_runner.py`, `AGENT_WORKSTREAM_LIFECYCLE.md`, exact owner-authentication contract.
- Work surface: Read-only code and test inspection; review receipt, required closing summary and bounded lifecycle/archive metadata only. No implementation or historical run edits.
- Publication inputs: `custodian/tools/agent/dispatch.py`, `custodian/tools/agent/review_outcome.py`, `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/task_packet_contract.py`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Change: Independently reconstruct exact state and test non-owner forgery, self-approved decision, missing or stale code/validation SHA, conflicting decisions, misleading review report, wrong dependency, active claim/lock, changed original branch and report bytes, review findings, human_required and original PASS. Prove no bypass of source/provenance/validation protections or owner-only visual/canon approval. Positive disposable case must unblock exactly one eligible successor with a distinct owner_exception disposition.
- Preserve: Genuine review judgments, original receipts, clean/main synchronization and no fork of reviewer status. Only synthetic Git fixtures may simulate approvals and hostile conditions.
- Non-goals: No fixes in implementation files, no authoring extra bypasses, no cleanup of protected Procession runs, no semantic gameplay changes.
- Acceptance: Zero blocking defects, zero material gaps; owner authentication and narrow scope are independently demonstrated; original reviewer evidence and held claims remain byte-identical; separate owner-exception outcome is visible in audit and never accepted as canonical `passed` review.
- Validation: Focused owner-exception and dispatcher negative controls; paired-review runner and dispatch tests, changed-file validation and coverage, context/index/pairing checks, `git diff --check`; run all relevant approved code before final receipt.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Next action: After independent PASS, allow per-case owner decisions through the new tool; original review reports and preserved claims remain authoritative.
- Blockers or open questions: No user-approved review exception is implied by this packet's existence.
