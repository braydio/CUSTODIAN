# PROCESSION P1: PRESERVED REVIEW SCOPE ATTESTATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-procession-doc-scope-recovery-v1`
- Status: `complete`
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
- Goal: Recover the ALREADY CLAIMED Procession P1 independent review from the exact historical eight-file source payload omitted by its archived Work surface; preserve its original review claim and all generic provenance defenses.
- Completion boundary: After THIS repair's independent PASS, exactly the eight P1 source-bearing paths pinned by archive commit `68cef17f59c6d5e04026b56025451b901bd08185` become admissible for P1's pinned host-validation recovery. Every path must match its exact Git blob and regular-file mode. Before PASS or on any mismatch, keep rejecting.
- Current measured state: P1 landed on main after source-bearing archive commit `68cef17f59c6d5e04026b56025451b901bd08185`; the archive included three runtime scripts, two validation files, two `.gd.uid` sidecars and the validation recipe document, none enumerated as exact paths in the original `Work surface`. P1's review `review-hub-road-empty-procession-sequence-v1` has an existing claimed worktree and `host_validation_recovery`, no independent verdict. The recovery plan reads immutable reviewed-main packet bytes, so post-hoc editing its current archive Work surface cannot fix that pinned history.
- Evidence: P1 source archive `68cef17f59c6d5e04026b56025451b901bd08185`, original archived packet blob `9ad75ac27b88508647b6257245242272f49b21aa`, and the exact eight archive tree paths/blobs/modes listed in the attestation JSON. The host gate is `custodian/tools/agent/paired_review_host_validation.py`; the preserved reviewer-run interface is `custodian/tools/agent/paired_review_runner.py`.
- Task-specific authority: `custodian/tools/agent/paired_review_host_validation.py` and existing Grunt post-hoc exact-scope attestation example; `custodian/tools/agent/review_outcome.py` and `custodian/tools/agent/review_receipt_delta.py` own accepted-independent-review proof. Preserve existing P1 review's pinned SHA, worktree and evidence.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/test_paired_review_runner.py`, `custodian/docs/ai_context/review_scope_attestations/road_procession_p1_recipe_scope_v1.json`, and `custodian/tools/validation/validation_manifest.json` only as needed for focused validation manifest ownership. No P1 runtime, original archived P1 packet, P1 claim, or original review branch mutations.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/test_paired_review_runner.py`, `custodian/tools/agent/review_outcome.py`, `custodian/tools/agent/review_receipt_delta.py`, `custodian/tools/agent/paired_review_runner.py`, `custodian/docs/ai_context/review_scope_attestations/grunt_candidate_raster_v1.json` (existing tracked inputs).
- Change: Author one exact-match JSON attestation naming P1 workstream, canonical archived packet path and blob, source archive SHA `68cef17f59c6d5e04026b56025451b901bd08185`, and exactly these eight regular files with their exact archive Git blob SHAs and `100644` modes: `custodian/game/state/persistent/hub_state.gd`, `custodian/game/world/hub/events/road_procession/road_procession_sequence.gd`, its `.uid` sidecar, `custodian/game/world/hub/first_set/hub_first_set_map.gd`, `custodian/tools/validation/hub_road_empty_procession_smoke.gd`, its `.uid` sidecar, `custodian/tools/validation/validation_manifest.json`, and `custodian/docs/ai_context/VALIDATION_RECIPES.md`. Extend host validator narrowly: require the archive's complete extra-source path set to equal this eight-file set and every immutable tree entry to match; require ancestry and canonical independent PASS receipt for THIS repair's paired review. For preserved P1 runs whose immutable reviewed-main predates approval, allow fetched `origin/main` only as authenticated post-hoc approval evidence after validating pinned reviewed-main ancestry; do NOT repin that review's implementation or worktree. Never self-authorize from JSON alone, never accept a filename-only match, and never relax ordinary undeclared-path checks.
- Preserve: No second P1 claim; no broad Markdown exception; original source provenance, review and correction receipts, developer-owned Git history, tests, archive or review claimant bytes unchanged. The new repair's own paired review must complete before exception activates.
- Non-goals: No gameplay changes, no replay of P1 implementation, no P2 claim, no generic host-validation bypass, no overwrite/delete of review evidence or claim.
- Acceptance: P1 source-span validation against the actual immutable archive fails before independent approval and succeeds after this recovery earns an independently verified PASS, while admitting exactly the eight pinned source paths and no others. The attestation binds the original P1 workstream, archived packet path/blob, archive commit, every source path/blob/mode, and accepted recovery review provenance. Missing, forged, extra, or altered paths; wrong packet/path/commit/blob/mode; forked/stale approval; bad review receipt; or mutated original claimed checkout fail closed. Do not claim P1 has passed its own independent review.
- Validation: Add a real disposable-Git historical regression against P1 archive `68cef17f59c6d5e04026b56025451b901bd08185`; require full source-span success only after authenticated approval. Test absent approval plus forged, missing, altered, extra, and mode-mismatched paths. Target with `PYTHONPATH=custodian/tools/agent:custodian/tools python3 -m unittest custodian.tools.agent.test_paired_review_runner` (focused cases first); run changed-file validation and `git diff --check` after focused tests pass. Ensure manifest coverage of new JSON.
- Task overrides: `none`
- Deferred: Only after this repair's independent review PASS, re-plan and recover the pre-existing P1 review with `--continue-run ... --recover-host-validation --plan` then exact fresh hash `--apply`; do not try in this implementation.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Evidence: Actual P1 archive source-span regression passes after authenticated paired-review approval and rejects before approval; exact eight source paths/blobs/modes are pinned. Paired-review runner unit suite: 166 tests passed. Changed-file validation: `paired_review_runner_unit` passed with complete coverage. Packet authoring preflight and `git diff --check` passed.
- Remaining gate: This authorization remains inactive until the recovery implementation's independent paired review passes.

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: Original recovery acceptance scoped only the omitted Markdown recipe, while P1's immutable source archive included seven additional implementation and validation paths.
- Root cause / contributing factors: The original P1 packet described responsibilities but lacked exact filenames; the recovery correction was based on the initially reported Markdown-only validator failure rather than the full P1 archive diff.
- Prevention / pipeline improvement: Historical source-scope regressions now derive and assert the complete source payload from the immutable archive and bind every admitted path to its exact blob and mode.
- Tooling / docs drift discovered: Recovery packet and paired review had a one-document acceptance boundary inconsistent with the actual P1 archive; both now enumerate the exact eight-file scope.
- Follow-up: none
- What worked: Disposable Git history exercises pre-approval rejection and post-approval acceptance against P1's real archive commit.

## Original P1 claim preservation
Review `review-hub-road-empty-procession-sequence-v1` already holds an exact claim. Never rerun its initial paired-review runner or reset its branch/worktree. Its host-private proof stays on the original machine, to be verified through the recovery commands; no chat-only artifact is a claim-time input.

## Handoff
- Next action: Land this exact eight-file historical attestation gate; launch `review-agent-paired-review-procession-doc-scope-recovery-v1` as a fresh independent review. Only when accepted, resume original P1 host-validation run.
- Blockers or open questions: Implementation authority and exact original source evidence are pinned. Normal claim locks apply.

## Next Handoff
- Next workstream: review-agent-paired-review-procession-doc-scope-recovery-v1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Run the existing paired review in a fresh reviewer context. On accepted PASS, resume the preserved original P1 host-validation run using a fresh plan and its exact digest.
- Blockers or open questions: none
