# Paired-Review `codex_exited` Findings Continuation

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-codex-exited-findings-continuation-v1`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `agent-paired-review-procession-pass-closeout-recovery-v1`
- Locks: `paired-review-codex-exited-findings-continuation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture`
- Paired review workstream: `review-agent-paired-review-codex-exited-findings-continuation-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `f06dd8943efe168937a552418a66a5561b59dc84`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Complete the exact stranded Procession PASS-closeout recovery review as genuine findings without accepting its implementation or changing its original claim/worktree evidence.
- Completion boundary: Add one exact-run `codex_exited` findings continuation through `paired_review_runner.py` for review `review-agent-paired-review-procession-pass-closeout-recovery-v1`, run `20261024T232113Z-32d8a7c6bb9d`. A fresh independent reviewer must confirm the original read-only-plan finding and author a canonical findings disposition. The coordinator then closes the review through nonpassing serialized authority, with the target implementation packet unchanged and no acceptance receipt. No general `codex_exited` closeout capability is added.
- Current measured state: The review run is `codex_exited`, reviewer exit code is zero, host validation is green, and no canonical archived Review Outcome exists. The reviewer-authored last message reports one material gap: planning fetches and mutates Git refs/FETCH_HEAD. The original worktree remains at `f06dd8943efe168937a552418a66a5561b59dc84`, with a modified archived target packet containing a receipt inconsistent with the final `findings` verdict and an untracked review summary. Its published branch remains at the pinned reviewed main. The original run manifest is intact. The existing `continue_run` and findings `recover-closeout` reject this phase/state.
- Evidence: `.git/custodian-review-runs/review-agent-paired-review-procession-pass-closeout-recovery-v1/20261024T232113Z-32d8a7c6bb9d/{metadata.json,claim-receipt.json,validation.json,coordinator-validation.json,codex.jsonl,last-message.txt}`; preserved reviewer worktree at `/home/braydenchaffee/Projects/.custodian-worktrees/review-agent-paired-review-procession-pass-closeout-recovery-v1-20261024T232131Z-ee1fc433fb2e`; independent full runner suite reproduced green (177 tests) at coordination `main@f06dd894` while the original reviewer session reported historical host-import conflicts.
- Task-specific authority: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/review_receipt_delta.py`; `custodian/tools/agent/workstream.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Work surface: `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/test_paired_review_runner.py`, a narrowly scoped recovery implementation packet and paired review, plus this workstream's root summary. The exact original review worktree and run are protected inputs, never an editing surface.
- Publication inputs: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/review_receipt_delta.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/land_main.py`; `custodian/tools/agent/dispatch.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`.
- Change:
  1. Add a read-only exact-run plan for the protected `codex_exited` case. Authenticate the structured claim, pinned reviewed main and target, report pair and hashes, raw original reviewer session, final `findings` judgment, no canonical Review Outcome, absence of a running owner, exact branch/worktree and current file inventories. Reject every other workstream/run/phase/outcome.
  2. On separately authorized apply, append a create-only continuation/journal record binding the full original run manifest and original dirty/untracked worktree inventory. Preserve every original byte and commit. Never reset, clean, resume, edit, or delete the original checkout.
  3. Create a separate recovery checkout at the exact published tip. Launch one fresh reviewer context which independently checks the reported finding and writes a canonical findings disposition with stable finding IDs. Do not accept PASS for this exact continuation. Bind raw session, validation evidence, reviewer output, archived packet and summary; preserve the existing original reviewer result as separate historical evidence.
  4. Use coordinator-owned nonpassing closeout and serialized landing. The canonical findings outcome must be based on the fresh reviewer-authored disposition; coordinator code may render/validate it but may not invent IDs or reinterpret the verdict. Require the implementation target to equal its exact pinned baseline byte-for-byte and contain no Independent Review receipt.
  5. Make interruption recovery deterministic. Journal each stage with immutable hashes; if a fresh reviewer was already launched, verify its existing output and do not launch a replacement. A partial, ambiguous, changed, occupied, symlinked or replayed state fails closed.
- Preserve: Original claim, branch, worktree HEAD, index, tracked/untracked/ignored files, original raw session, run manifest, report pair, reviewer prose and run evidence. Preserve the inconsistent original review receipt as historical evidence; never treat it as accepted. Preserve existing nonpassing recovery behavior and avoid changing the original target implementation packet.
- Non-goals: General recovery for arbitrary `codex_exited` runs; recovering or applying the Procession PASS; implementing the read-only planning correction; mapper work; releasing the primary pre-validation recovery claim; modifying the original dirty review worktree.
- Acceptance:
  - Exact run plan authenticates every identity and is read-only across refs, `FETCH_HEAD`, index, worktrees, run evidence and target files; a complete inventory before/after proves this for successful and failed plans.
  - Apply preserves an exact inventory of original run/worktree bytes and creates a separate recovery checkout/branch without a duplicate claim.
  - Fresh reviewer authors canonical `findings` with stable IDs only after independently confirming the original defect. Missing or contradictory outcome, PASS, changed target, invalid reports, forged claim, active owner, changed refs, extra files, occupied/symlink checkout, altered report, partial journal and repeated/replayed invocation all fail closed.
  - The final archived review contains the authentic findings; the reviewed implementation target remains byte-identical to its pinned baseline and has no acceptance receipt.
  - Closeout lands through the existing serialized lifecycle, releases only the exact review lock after verified landing, and does not satisfy an accepted-review dependency.
  - Original run manifest and protected worktree inventory remain byte-identical after completion.
- Validation: Focused real-Git fixtures first; `python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; canonical `run_validation.py --test paired_review_runner_unit --json`; changed-file validation with complete coverage; AI-context, task-index, review-pairing, compile and `git diff --check` validations. Exercise the exact-run plan against the live host evidence only after the new implementation's independent review is accepted; do not apply until that review is accepted.
- Task overrides: `TASK OVERRIDE: This exact-run recovery may create only the continuation record and an isolated recovery checkout/branch required to close the named review as findings. It may not edit the original review checkout, reviewed target, original reports, original run manifest, or original reviewer session. It may not recover a PASS or release any unrelated claim.`
- Deferred: Close the original review as findings; then create the bounded correction pair for the read-only plan finding. Keep the Procession PASS recovery and mapper M1-M7 blocked until their genuine review dependencies are satisfied.

## Next Handoff
- Next workstream: `agent-paired-review-procession-pass-closeout-recovery-v1-review-corrections-1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: After the exact original review lands as findings, author and execute one correction pair addressing its actual finding IDs; preserve the protected PASS recovery run.
- Blockers or open questions: `The original review must first close with an authentic canonical findings outcome; its present codex_exited artifacts are incomplete and contradictory.`
