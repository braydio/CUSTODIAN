# PROCESSION P1: PRESERVED REVIEW SCOPE ATTESTATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-procession-doc-scope-recovery-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `paired-review-source-provenance`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-procession-doc-scope-recovery-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `security-sensitive exact post-hoc source authorization`
- Reviewed main: `dd7282d9cb96827a8b54060aae993eb994a1882e`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Recover the ALREADY CLAIMED Procession P1 independent review from one historical unlisted validation-document change; preserve its original review claim and all generic provenance defenses.
- Completion boundary: After THIS repair's independent PASS, the one exact historical `custodian/docs/ai_context/VALIDATION_RECIPES.md` modification is authenticated for P1's pinned host-validation recovery. Before PASS or on any mismatch, keep rejecting.
- Current measured state: P1 landed on main after source-bearing archive commit `68cef17f59c6d5e04026b56025451b901bd08185`; the archive included the validation recipe document but the original `Work surface` omitted its exact Markdown path. P1's review `review-hub-road-empty-procession-sequence-v1` has an existing claimed worktree and `host_validation_recovery`, no independent verdict. The recovery plan reads immutable reviewed-main packet bytes, so post-hoc editing its current archive Work surface cannot fix that pinned history.
- Evidence: P1 source archive `68cef17f59c6d5e04026b56025451b901bd08185`, original archived packet blob `9ad75ac27b88508647b6257245242272f49b21aa`, validation document blob `bf1595c7a554bd307e9c77f241fe94817affe58a`. The source diff adds the Hub Road Empty Procession validation commands to the recipe guide. The host gate is `custodian/tools/agent/paired_review_host_validation.py`; the preserved reviewer-run interface is `custodian/tools/agent/paired_review_runner.py`.
- Task-specific authority: `custodian/tools/agent/paired_review_host_validation.py` and existing Grunt post-hoc exact-scope attestation example; `custodian/tools/agent/review_outcome.py` and `custodian/tools/agent/review_receipt_delta.py` own accepted-independent-review proof. Preserve existing P1 review's pinned SHA, worktree and evidence.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/test_paired_review_runner.py`, `custodian/docs/ai_context/review_scope_attestations/road_procession_p1_recipe_scope_v1.json`, and `custodian/tools/validation/validation_manifest.json` only as needed for focused validation manifest ownership. No P1 runtime, original archived P1 packet, P1 claim, or original review branch mutations.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/test_paired_review_runner.py`, `custodian/tools/agent/review_outcome.py`, `custodian/tools/agent/review_receipt_delta.py`, `custodian/tools/agent/paired_review_runner.py`, `custodian/docs/ai_context/review_scope_attestations/grunt_candidate_raster_v1.json` (existing tracked inputs).
- Change: Author one exact-match JSON attestation naming P1 workstream, canonical archived packet path, source archive SHA `68cef17f59c6d5e04026b56025451b901bd08185`, source packet blob `9ad75ac27b88508647b6257245242272f49b21aa`, and exactly one additional regular-file Markdown path `custodian/docs/ai_context/VALIDATION_RECIPES.md` with blob `bf1595c7a554bd307e9c77f241fe94817affe58a`. Extend host validator narrowly: require exact immutable Git tree entries, ancestry and canonical independent PASS receipt for THIS repair's paired review. For preserved P1 runs whose immutable reviewed-main predates this approval, allow freshly fetched `origin/main` only as authenticated *post-hoc approval evidence* after validating pinned reviewed-main ancestry; do NOT repin that review's implementation or worktree. Never self-authorize from a JSON file alone, never accept a filename-only match, and never relax ordinary undeclared-document checks.
- Preserve: No second P1 claim; no broad Markdown exception; original source provenance, review and correction receipts, developer-owned Git history, tests, archive or review claimant bytes unchanged. The new repair's own paired review must complete before exception activates.
- Non-goals: No gameplay changes, no replay of P1 implementation, no P2 claim, no generic host-validation bypass, no overwrite/delete of review evidence or claim.
- Acceptance: P1 host validation denies absent/unreviewed/forged attestation; after this repair earns an independently verified PASS, accepts ONLY the pinned doc and archive exact blobs. Wrong packet/path/commit/blob/mode, forked/stale approval, bad review receipt, other extra documents, or mutated original claimed checkout fail closed. Do not claim P1 has passed its own independent review.
- Validation: Add real disposable-Git focused positive/negative tests to `custodian/tools/agent/test_paired_review_runner.py`; target with `python3 -m unittest custodian.tools.agent.test_paired_review_runner` (focused cases first); run changed-file validation and `git diff --check` only after focused tests pass. Ensure manifest coverage of new JSON if necessary.
- Task overrides: `none`
- Deferred: Only after this repair's independent review PASS, re-plan and recover the pre-existing P1 review with `--continue-run ... --recover-host-validation --plan` then exact fresh hash `--apply`; do not try in this implementation.

## Original P1 claim preservation
Review `review-hub-road-empty-procession-sequence-v1` already holds an exact claim. Never rerun its initial paired-review runner or reset its branch/worktree. Its host-private proof stays on the original machine, to be verified through the recovery commands; no chat-only artifact is a claim-time input.

## Handoff
- Next action: Land this minimal historical attestation gate; launch `review-agent-paired-review-procession-doc-scope-recovery-v1` as a fresh independent review. Only when accepted, resume original P1 host-validation run.
- Blockers or open questions: Implementation authority and exact original source evidence are pinned. Normal claim locks apply.
