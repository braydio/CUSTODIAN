# AGENT PAIRED REVIEW HOST VALIDATION RECOVERY V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-host-validation-recovery-v1`
- Kind: `implementation`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `review-agent-paired-review-host-godot-validation-v1, review-agent-paired-review-same-run-continuation-v1`
- Locks: `paired-review-host-validation, paired-review-same-run-continuation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-host-validation-recovery-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `immutable reviewed source-span provenance, protected pre-launch recovery and independent reviewer launch/receipt semantics require adversarial review`
- Reviewed main: `a5309e8a17792f0042bba73299a79b56e9687c8f`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62`
- Visual review: `none`
- Goal: Validate the actual source/test implementation of a split source-and-archive landing without redefining its canonical archive commit, and safely continue a pre-review `host_validation_recovery` run under its original protected claim.
- Completion boundary: Keep archive/receipt reviewed implementation identity pinned to the canonical archive-introduction commit. Separately derive and validate a verified source-bearing commit span; expose an explicitly authorized, read-only-plan-first prelaunch recovery for the same original run/claim using new exclusive evidence in a child directory. Only a fresh independent reviewer authors a disposition.
- Current measured state: `review-worktree-backlog-census-and-safety-ledger-v1-review-corrections-1` has original run `20261017T200919Z-e0b32b5c1a3b` in `host_validation_recovery`, preserved clean claim branch at `b5b85ca47a1eacad9879c6abf55257d378ae0c91`; source/tests landed at its direct parent `1b586174fa7fbd9c1c94e6adbc36ee85bf809f4f`. Current `resolve_target_implementation_commit` returns the correct archive-introduction SHA, but `run_coordinator_validation` evaluates the archive-only immediate-parent diff, so it fails with `host validation does not cover changed implementation source/test files` before Codex launch. The accepted same-run continuation only permits `post_exit_recovery`. Root checkout is reportedly 1 local commit ahead and 13 behind origin/main, so do not use it as an implicit sync/write surface.
- Evidence: `custodian/tools/agent/review_receipt_delta.py`::`resolve_target_implementation_commit`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/paired_review_runner.py`::`continue_run`; original private run `.git/custodian-review-runs/review-worktree-backlog-census-and-safety-ledger-v1-review-corrections-1/20261017T200919Z-e0b32b5c1a3b`; archived W1 correction packet `custodian/docs/ai_context/task_packets/archived/WORKTREE_BACKLOG_CENSUS_AND_SAFETY_LEDGER_V1_REVIEW_CORRECTIONS_1.md`.
- Task-specific authority: Existing `paired_review_host_validation.py` owns host validation and immutable evidence, `review_receipt_delta.py` owns implementation/receipt identity, `paired_review_runner.py` owns recovery/reviewer launch, `dispatch.py` owns claims, `workstream.py` owns closeout; reuse independently accepted `agent-paired-review-same-run-continuation-v1` code rather than create another runner.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/review_receipt_delta.py` (only if necessary for a separate source-span API), `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/test_paired_review_runner.py`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md` (bounded new behavior only). No game/art/runtime source changes.
- Change:
  1. Introduce a *separate* exact validation source span, never replace the pinned canonical reviewed implementation commit, archive-introduction identity or receipt field. For adjacent split landings, prove the source-bearing commit(s) are ancestors of the archive commit, belong to the exact target implementation workstream by durable Git/packet/run provenance, and are within a unique, bounded, contiguous implementation range. Reject no source/test diff, multiple ambiguous source spans, unrelated commits and unverifiable provenance; do not hardcode the W1 SHA or use current main as an implicit substitute.
  2. Have trusted host validation select and pin all source/test paths from that verified span, prove nonvacuous selected test ownership and full changed-file coverage, store span base/head, source-path list and SHA-256 digests in immutable coordinator provenance, and verify again after reviewer exit and before publication. Preserve ordinary single-commit behavior. Do not allow an archive-only diff or unrelated package files to satisfy source coverage.
  3. Extend the existing accepted `continue-run` mechanism with an *explicit*, separately authorized `host_validation_recovery` prelaunch route and a side-effect-free `--plan` projection. Verify the original run ID/schema/phase, exact claim receipt and remote claim, worktree/branch/common Git directory, pinned reviewed main, target archive and source-span identity, absence of active supervisor, and clean coordinator checkout. Never run dispatcher claim a second time, never reset/rebase/stash/clean the original review or divergent project-root checkout, and never reinterpret the original failed host report as green.
  4. Preserve original `validation.json`, `coordinator-validation.json` and `metadata.json` byte-for-byte, alongside diagnostics and recovery text. Create a new exclusive/journaled `continuation-NN` child for corrected host validation and a distinct genuinely fresh Codex reviewer invocation; reconcile interruption through exact IDs and verified immutable hashes. Fail closed on malformed/duplicate child state, changed original bytes, mismatched report coverage, ambiguity, foreign claim or unsupported phase. Preserve historic failed attempts.
  5. Reviewer receives actual original implementation source diff, real host evidence and original W1 R0-01; reviewer alone decides `passed|findings|human_required`. Reuse standard canonical closing-summary path, exact receipt delta, reviewer provenance, bounded coordinator closeout, accepted-review semantics and landing verification. Do not treat successful host validation as reviewer PASS.
  6. Regression fixtures: split W1-style source commit followed by archive-only commit; single-commit baseline; ambiguous/missing source span; unrelated intervening code; mispinned implementation SHA; mismatched selected/covered tests; stale source/manifest fingerprint; original failed create-only evidence; exact claimant missing/moved/foreign; concurrent continuation; interrupted stages; repeated completed operation; denied authorization/dirty root without fallback; authentic reviewer findings and PASS.
- Preserve: Original W1 run `20261017T200919Z-e0b32b5c1a3b` and `b5b85ca4` review branch, existing private evidence and original W1 findings R0-01, all dirty/unique user worktrees, accepted standalone post-exit continuation behavior, one immutable canonical reviewed-commit identity, status gate and true reviewer independence.
- Non-goals: No second claim, no fabricated PASS, no manual edits to the protected W1 worktree, no direct deletion/replacement of create-only evidence, no casual Git reset/rebase of root checkout, no new independent dispatcher or recovery mechanism, no W2/W5 dependency waiver.
- Acceptance: (A1) Exact split-landing source/test diff selected and validated with full coverage while canonical reviewed implementation SHA stays `b5b85ca47a1eacad9879c6abf55257d378ae0c91` for the W1 fixture. (A2) Ambiguous/stale/empty source provenance blocks. (A3) Original run recovery can plan and explicitly apply under its existing claim with byte-identical parent evidence, unique child evidence and fresh independent reviewer. (A4) Normal `post_exit_recovery` and receipt invariants regress green. (A5) W1/W2 gates remain blocked until genuine accepted W1 correction review; no future cleanup automatically authorized.
- Validation: First run `python3 custodian/tools/agent/test_paired_review_runner.py` with new focused fixtures, then `python3 custodian/tools/agent/test_dispatch.py`, `python3 custodian/tools/agent/test_workstream.py`, `python3 custodian/tools/agent/test_review_outcome.py`, `python3 custodian/tools/agent/test_task_packet_contract.py`, and `python3 custodian/tools/validation/run_validation.py --changed --json`. Require complete selected tests/coverage and `git diff --check` before finish.
- Task overrides: `none`
- Deferred: If exact existing run/source provenance is impossible to prove without rewriting historical bytes, leave the claim protected and surface a specific evidence blocker instead of attempting manual cleanup or a new review claim.

## Handoff

- Next workstream: `review-agent-paired-review-host-validation-recovery-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62`
- Next action: Claim through dispatcher only after live audit permits. Implement and finish reviewed tooling; then use the accepted continuation route on the preserved W1 run without reclaiming it.
- Blockers or open questions: Publication preflight and accepted predecessor dependencies must pass. Original W1 claim, immutable evidence and diverged root checkout remain protected.
