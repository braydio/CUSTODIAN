# Paired Review Findings Artifact Recovery V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-findings-artifact-recovery-v1`
- Category: `agent-ops`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `agent-workflow`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-findings-artifact-recovery-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `The recovery bridges host-private reviewer artifacts into a durable findings closeout; exact claim, raw session, target immutability, and retry behavior require fresh independent falsification.`
- Reviewed main: `6189e1ec2e2101be8c788efcbdea487bf80603bf`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af253c2-3c40-83ea-bd81-7ba163d4602e
- Visual review: `none`
- Goal: Durably record the authentic findings from one preserved paired-review run whose reviewer-authored archive and summary exist only as untracked files in its protected worktree.
- Completion boundary: Add a digest-bound, read-only-plan/apply recovery for the exact run `20261110T082919Z-283d4ae71a0c` of `review-agent-owner-review-exception-direct-pr-provenance-recovery-v1`. Authenticate the original structured V2 claim, acquisition, run metadata, raw fresh reviewer session, host-validation report, archived findings packet, summary, target baseline, branch/worktree identities, and artifact inventory. Apply only through a separate recovery checkout, journaled and idempotent, using the existing nonpassing closeout verifier and integrity report. The original review worktree and run directory remain byte-preserved; the target implementation receives no receipt or other edit.
- Current measured state: The review runner recorded phase `post_exit_recovery` after the reviewer authored findings and the coordinator treated the unchanged target as a missing PASS receipt. The reviewer-authored archived packet and root summary remain untracked at the exact claimed checkout; their SHA-256 values are `9c7409c4c9173a6a6f1e146e425630a0f634ef7cf34eaf7b0f25df42b979b6f3` and `3c93fdc845466518a5d02424fa45c32f61f73391455a15f03bbfcb16bfceb28c`. The original branch and checkout HEAD remain `6189e1ec2e2101be8c788efcbdea487bf80603bf`. Existing `recover-closeout --plan` cannot authenticate this run because its claim.stdout is truncated before the JSON sentinel completes, while the separate `claim-receipt.json` is complete. `paired_review_runner.py:_host_validation_claim_receipt()` already strictly authenticates the separate receipt and its V2 acquisition and is the required claim verifier.
- Evidence: `.git/custodian-review-runs/review-agent-owner-review-exception-direct-pr-provenance-recovery-v1/20261110T082919Z-283d4ae71a0c/{metadata.json,claim.stdout,claim-receipt.json,validation.json,coordinator-validation.json,codex.jsonl,last-message.txt,RECOVERY.md}`; the protected claimed review checkout; current `origin/main` and `origin/agent/review-agent-owner-review-exception-direct-pr-provenance-recovery-v1` refs.
- Task-specific authority: `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_FINDINGS_CLOSEOUT_V1.md`; `custodian/tools/agent/paired_review_runner.py` functions `_host_validation_claim_receipt`, `_parse_redacted_final_session`, `recover_closeout`, `coordinator_finish_nonpassing_review`, `nonpassing_review_reasons`, and `landed_nonpassing_review_state`; `custodian/tools/agent/review_outcome.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Work surface: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/test_paired_review_runner.py`.
- Publication inputs: `none`
- Change:
  1. Add a read-only recovery plan bound only to the exact review workstream/run/turn. Authenticate the original claim using `_host_validation_claim_receipt()` and its structured claim receipt; verify the original private V2 acquisition, run metadata and phase, raw `codex.jsonl`/`last-message.txt` session using the existing session verifier, host-validation report/coordinator metadata hashes, exact target/implementation identity, original branch tip, and zero live process ownership.
  2. Authenticate the two preserved untracked artifacts by exact path and the packet-pinned SHA-256 values. Require the archive to contain exactly one canonical `findings` Review Outcome for IDs `R0-01,R0-02`, bound to this run, review workstream, target, `origin/main@6189e1ec2e2101be8c788efcbdea487bf80603bf`, implementation `f6ced9e60ceb6b6b57ee04b5bbd5dc0392140d7b`, and truthful fresh reviewer provenance. Cross-check the exact findings and both artifact hashes against the raw reviewer session. If the preserved artifact or session is ambiguous, stop.
  3. Return a SHA-256 plan digest binding metadata/receipt/session/report bytes, artifact bytes, original checkout status including every untracked file, refs, target baseline, outcome/finding IDs, recovery checkout path, and bounded changed-path list. Planning must not write to the original checkout or run directory, create a branch/worktree, stage files, or alter refs except the documented read-only planner's remote-tracking refresh.
  4. Apply only with the exact fresh plan digest. Recheck all source evidence and refs before writing; preserve source artifacts byte-for-byte in the original checkout; create/reuse only the named separate recovery checkout/branch; copy the verified reviewer artifacts there; make only bounded administrative status/summary/managed-index edits needed for canonical findings closeout; reuse `nonpassing_review_reasons()` and `coordinator_finish_nonpassing_review()` semantics plus the integrity report; journal before each mutation and converge on retries. Preserve the reviewed target packet byte-for-byte and publish no PASS receipt.
  5. Use `_host_validation_claim_receipt()` for the structured claim. Do not change `_claim_identity()` globally, accept truncated JSON, synthesize claim evidence, weaken acquisition validation, launch a reviewer, or recover another run.
- Preserve: Original review claim/branch/worktree and all bytes; the two raw findings artifacts and reviewer session; host-validation report and digest; both older held review runs, all acquisition receipts, divergent project-root checkout, and Slice G; target implementation bytes and unresolved review status.
- Non-goals: Correcting findings R0-01/R0-02; modifying the reviewed implementation or target packet; authoring a PASS receipt; relaunching any reviewer; recovering the older held correction or original owner-exception review; changing global dispatch/claim fallback behavior; deleting/releasing the original review claim outside the authenticated recovery lifecycle; touching Operator runtime or G.
- Acceptance:
  - Read-only plan authenticates the complete separate structured claim receipt and acquisition while rejecting modified/malformed receipt, metadata, session, report, artifacts, target, refs, or worktree state.
  - The exact recorded `findings` outcome and IDs match the canonical archived packet, final reviewer message, raw JSONL final message, summary, run/workstream/target/main/implementation pins, and reviewer provenance.
  - Apply refuses a stale or altered plan digest and all changed source evidence, preserves the original checkout and run evidence byte-for-byte, and writes only the bounded closeout artifacts in an isolated recovery checkout.
  - The resulting archived review is a canonical complete `findings` disposition with a valid closeout-integrity report and required `Next Handoff`; the reviewed implementation packet remains byte-identical and receives no receipt.
  - Interrupted apply and same-plan retry are idempotent, journaled, and cannot create a second claim, reviewer session, branch, outcome, or release of unrelated refs.
  - Tests reject PASS/human-required substitution, wrong IDs, mismatched source/raw reviewer text, session truncation/contradiction, missing or modified artifact, malformed structured claim, bad acquisition identity, active process ownership, changed branch tip, dirty/out-of-scope checkout, stale plan digest, target mutation, and recovery-branch scope violations.
- Validation: Focused `test_paired_review_runner` and `test_workstream_artifacts`; deterministic isolated Git fixture for exact run metadata, a valid and truncated claim.stdout with the separately preserved strict claim receipt, raw completed reviewer session, exact findings artifacts, original-worktree preservation, stale digest, changed artifact/session/receipt, target immutability, and interrupted retry. Run changed-file routed validation with complete coverage, `check_ai_context.py --json`, packet category/authoring/pairing/index checks, and `git diff --check`. Keep recovery apply itself unauthorized until this implementation receives fresh independent acceptance.
- Task overrides: `none`
- Deferred: The generic `coordinator_finish_review()` findings path still treats a missing PASS receipt on an unchanged target as a post-exit recovery error; this exact-run bridge does not repair that broader findings-routing defect. Track that separately. After this bridge lands and receives independent fresh-context acceptance, re-run the exact findings recovery plan and apply only with its printed digest and a separate orchestration authorization. Then author/execute `agent-owner-review-exception-direct-pr-provenance-recovery-v1-review-corrections-1` for R0-01/R0-02; do not mix source corrections into this recovery implementation.

## Publication hold

This pair is `draft/manual` only for atomic authoring validation and the push-triggered auto handoff. Do not claim until the handoff promotes both packets and the live dispatcher audit reports eligible. The original findings claim remains protected throughout.
