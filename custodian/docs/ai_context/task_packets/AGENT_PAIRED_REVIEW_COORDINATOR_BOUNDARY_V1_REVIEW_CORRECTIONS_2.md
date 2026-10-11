# CORRECTION: PF5 RECEIPT DELTA LIVE TARGET PATH (R1-01, R1-02)

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-coordinator-boundary-v1-review-corrections-2`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-coordinator-boundary-v1-review-corrections-1`
- Locks: `none`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-coordinator-boundary-v1-review-corrections-2`
- Review cycle: `2`
- Max automatic review cycles: `2`
- Review rationale: `The cycle-1 review found that its positive fixture did not exercise the real archived target or production pinned-blob read.`
- Reviewed main: `607c76aba831ed5fcc313f00489e10df75a8a375`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Visual review: `none`
- Parent implementation: `agent-paired-review-coordinator-boundary-v1-review-corrections-1`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_COORDINATOR_BOUNDARY_V1_REVIEW_CORRECTIONS_1.md`
- Parent review: `review-agent-paired-review-coordinator-boundary-v1-review-corrections-1`; active claim evidence is preserved on its claimed branch.
- Findings addressed: `R1-01, R1-02`
- Goal: Make the canonical receipt-delta flow work against real archived packets while preserving exact target bytes outside the permitted receipt.
- Completion boundary: One bounded correction to shared receipt identity derivation and pinned packet reads, with regression coverage through the production runner and `workstream.py finish`.
- Current measured state: At `origin/main@607c76aba831ed5fcc313f00489e10df75a8a375`, the actual archived cycle-1 packet has no `Implementation commit:` field, so `verify_review_receipt_delta` receives no implementation identity and rejects it. The packet's unique archive-completion commit is `16b9dfdd6ce09889b85c61372e02d0eccea5de76`. The exact target Git blob ends in `\n`, while `paired_review_runner.git()` strips that byte; a direct production-input probe therefore fails the receipt append check.
- Evidence: `custodian/tools/agent/review_receipt_delta.py`; `paired_review_runner.py` (`packet_at_main`, `validate_eligible_review`, `run`, `coordinator_finish_review`, `landed_review_state`); `workstream.py` (`_paired_review_artifact_preflight_error`); cycle-1 paired runner/workstream tests; exact archived cycle-1 packet history at `16b9dfdd6ce09889b85c61372e02d0eccea5de76`.
- Task-specific authority: This correction packet; the cycle-1 archived correction packet and its active cycle-1 review findings; `custodian/tools/agent/AGENT_WORKSTREAM_LIFECYCLE.md`; the shared receipt verifier and `workstream.py finish` artifact gate.
- Work surface: `custodian/tools/agent/review_receipt_delta.py`, `paired_review_runner.py`, `workstream.py`, and their existing paired-runner/workstream-artifact tests. Add a small shared identity helper only if required to keep both gates on one exact derivation.
- Required correction: Derive the target implementation identity fail-closed from the unique commit that introduced/archived the exact complete packet on the pinned history when the baseline packet lacks an explicit `Implementation commit:` field; verify its workstream, completion state, ancestry, and uniqueness. Read pinned packet blobs as exact UTF-8 bytes without whitespace stripping or newline translation in both runner and finish paths. Use the same derived identity and byte-preserving baseline for receipt validation before coordinator staging and after landing. Preserve existing exact section-delta checks and reject ambiguity.
- Preserve: The original PF5 implementation and historical review receipt; cycle-1 correction findings; byte identity outside the one authorized review receipt; reviewer/coordinator privilege boundaries; final `workstream.py finish` authority; all unrelated checkout changes.
- Non-goals: No broad text-diff allowlist; no editing unrelated archived packets; no loosening receipt fields or accepting a reviewer-supplied commit without history proof; no general dispatch/landing redesign; no correction beyond R1-01/R1-02.
- Acceptance: (A) The actual archived cycle-1 target resolves to exactly `16b9dfdd6ce09889b85c61372e02d0eccea5de76` from pinned history despite lacking the header field. (B) Runner, workstream preflight, and landed-state verification preserve and use the exact trailing newline. (C) A canonical receipt-only append to the actual target passes the shared verifier and normal temporary-remote coordinator plus `workstream.py finish` path. (D) No-receipt, ambiguous archive history, malformed/mismatched workstream, mismatched commit, unrelated header/body/Completion Truth/Execution Feedback/Next Handoff edits, duplicate sections/receipts, and prior-receipt tampering all fail closed. (E) Runner rejects invalid deltas before staging. (F) The cycle-1 pair's prior 73-test baseline remains green, with focused regressions covering actual packet bytes and metadata. (G) No duplicate claim, force push, or claim-state loss.
- Validation: Focused paired-runner/workstream/workstream-artifact unittest suites; actual target history and exact-byte regression; temporary bare-remote end-to-end receipt and `workstream.py finish` fixture with green complete-coverage report; negative delta fixtures; `check_ai_context.py --json`; `validate_review_pairing.py`; `task_packet_index.py`; changed-file validation with complete coverage; `git diff --check`.
- Task overrides: `none`
- Deferred: Any further receipt protocol changes after review cycle 2 require a new human-planned workstream; the downstream agent-next-execution-boundary remains gated on the cycle-1 review being independently accepted.

## Handoff

- Next workstream: `review-agent-paired-review-coordinator-boundary-v1-review-corrections-2`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Refresh reason: `none`
- Next action: `Run the exact fresh-context cycle-2 paired review, then resume the preserved cycle-1 review in a fresh context after the cycle-2 implementation lands.`
- Blockers or open questions: `none`
