# Review Carrow Claimed Review Worktree Recovery V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-paired-review-carrow-claimed-worktree-recovery-v1`
- Authoring handoff: `auto`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `paired-review-carrow-claimed-worktree-recovery-v1`
- Locks: `paired-review-run-recovery`
- Kind: `review`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review target workstream: `paired-review-carrow-claimed-worktree-recovery-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PAIRED_REVIEW_CARROW_CLAIMED_WORKTREE_RECOVERY_V1.md`
- Reviewed main: `6e75b57ea828f5d90679ae737052a4acdefce361`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Independently falsify any path that reconstructs a missing claimed checkout without exact identity, ownership/evidence proof, immutable original reports, bounded recovery, and a genuinely green new validation.
- Current measured state: The exact Carrow run failed `world_transition_handoff` and was never reviewed. The recorded checkout and Git worktree metadata are missing; branch head remains the pinned baseline and the reviewer was not launched. Thirteen canonical focused reproductions at that pinned implementation passed only after a complete import, each preserving exact equality at `(-6, 162)`; this is diagnostic evidence, not a replacement for the historical failed report or an independent PASS.
- Evidence: Inspect the exact implementation source span and tests; replay all recovery actions in temporary repositories; compare original report and metadata byte hashes before/after; verify the exact branch/claim, worktree path, lock and continuation manifests.
- Task-specific authority: The implementation packet and the current live `paired_review_runner.py`, `paired_review_host_validation.py`, `test_paired_review_runner.py`, and `AGENT_WORKSTREAM_LIFECYCLE.md`.
- Work surface: Review-only reads of the three paired-review source/test files plus recovery task/review packets and the exact protected Carrow run evidence. Only the canonical bounded review receipt, packet archive/index and root summary may be authored.
- Publication inputs: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/VALIDATION_RECIPES.md`; `custodian/docs/ai_context/task_packets/PAIRED_REVIEW_CARROW_CLAIMED_WORKTREE_RECOVERY_V1.md`
- Review focus: Challenge exact run/claim/branch/pinned SHA validation; original failed report and complete run manifest hashing; local and remote branch movement; missing Git worktree metadata; missing evidence and operator attestations; live supervisor detection; path traversal/symlink/occupied/foreign destinations; races between plan and apply; preservation of all original bytes; worktree reconstruction on the same branch; canonical full validation selection and coverage; append-only continuation identity; fail-closed partial recovery; one-shot reviewer launch; replay; and compatibility with existing import-recovery, findings-closeout, and ordinary review flows. Confirm no code/test touches Carrow implementation or source/runtime. Run all negative cases from the implementation packet independently; tests must falsify unsafe paths, not just assert helper presence.
- Acceptance: Findings-first fresh independent review. PASS only if every acceptance claim A1-A9 is supported by code-path inspection, negative test evidence, exact report/run/branch hash comparison, and canonical validations. Any uncertain owner/evidence state must remain blocked, never reconstructed by assumption. New validation success is not a reviewer PASS. Do not apply recovery to the protected Carrow claim as part of the review.
- Validation: `PYTHONPATH=custodian/tools/agent:custodian/tools python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; focused related test suites; canonical `run_validation.py --test paired_review_runner_unit --json` and applicable changed-file validation; `check_ai_context.py --json`; `task_packet_index.py`; `validate_review_pairing.py`; and `git diff --check`. Reuse durable structured evidence; do not run or mutate the protected Carrow claim.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Next Handoff

- Next workstream: `review-carrow-interior-layout-authoring-v1`
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc3bfd-cf88-83ea-9156-be4e5c2851c0`
- Refresh reason: none
- Next action: After independent PASS and a fresh recovery plan, resume the original Carrow claim only with the required operator attestations, validate, and complete the ordinary independent review.
- Blockers or open questions: Human attestation is required if current durable evidence cannot establish that no live owner or indispensable unique checkout data exists.
