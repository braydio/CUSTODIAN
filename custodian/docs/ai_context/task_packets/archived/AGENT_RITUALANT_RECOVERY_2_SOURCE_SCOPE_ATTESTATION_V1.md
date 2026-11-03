# IMPLEMENTATION: RITUALANT RECOVERY 2 HISTORICAL SOURCE-SCOPE ATTESTATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-ritualant-recovery-2-source-scope-attestation-v1`
- Category: `agent-ops`
- Status: `complete`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `paired-review-source-provenance`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-ritualant-recovery-2-source-scope-attestation-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `a post-hoc historical source-scope exception activates independent review authority and must itself receive a fresh adversarial review`
- Reviewed main: `c1c4b0592c3447183bdd97549b7d5a6a5837c59f`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae7eb07-c554-83e9-911a-1335e640e4d0
- Visual review: `none`
- Goal: Permit the preserved Ritualant recovery-2 reviewer to validate exactly the two Markdown files that were included in its immutable source-bearing archive but omitted from the archived packet Work surface, without changing that historical packet or weakening ordinary source-scope validation.
- Completion boundary: Add one exact, post-hoc source-scope attestation for the immutable recovery-2 archive; authenticate its activation only after this correction's canonical independent PASS and target receipt are accepted on main; add focused real-Git regression tests. Preserve the original Ritualant review claim, worktree, run and evidence. Do not resume that original review until this correction has landed and its independent review is accepted.
- Current measured state: The implementation archive is `a45663a9b23d2e2818edd1531cbb5ac1aa231f58`, parent `a70a234e58f2f5b298a840c88b43566a4c4555bb`, tree `0cd4036479097394da9135d5cdd5b7d22289b7ef`. Its complete changed-path inventory is pinned below. The canonical summary and packet README are already allowed closeout paths. The only undeclared Markdown source paths are `custodian/docs/ai_context/BRANCH_ARCHIVE.md` and `design/02_features/enemy_objective/FORLORN_RITUALANT_SHADER_FX.md`. The original archived implementation packet is blob `4e85a3da641f1b5ef0704e8acf43b4d251f09e30`, mode `100644`; the two source blobs are respectively `da34a093b39756807e0e5fd2962e7c599fe7725d` and `63a57f87ad16b88fc09d5290f8ae505cff336585`, both mode `100644`. The original review run `20261103T022803Z-2fa8fee1b08c` is preserved in host-local `.git/custodian-review-runs/` and its claimed worktree is preserved; neither may be modified by this implementation.
- Evidence:
  - Exact immutable archive and path inventory: `a45663a9b23d2e2818edd1531cbb5ac1aa231f58` and its parent/tree above.
  - Archived implementation packet: `custodian/docs/ai_context/task_packets/archived/RITUALANT_NPC_SILHOUETTE_READABILITY_SHADER_V1_RECOVERY_2.md`.
  - Canonical rejection: `custodian/tools/agent/paired_review_host_validation.py` source-scope gate rejects extra archive Markdown not declared by Work surface or an accepted exact attestation.
  - Preserved run: `20261103T022803Z-2fa8fee1b08c`; local evidence is owned by the host and is not a publication input. Do not rewrite it.
  - Existing architectural references: `custodian/tools/agent/paired_review_host_validation.py` Procession/Grunt attestation verifiers and their focused cases in `custodian/tools/agent/test_paired_review_runner.py`.
- Task-specific authority: `custodian/tools/agent/paired_review_host_validation.py`; canonical review outcomes in `custodian/tools/agent/review_outcome.py`; canonical target receipt verification in `custodian/tools/agent/review_receipt_delta.py`; the archived recovery-2 implementation packet; and the exact immutable archive identities in this packet.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/docs/ai_context/review_scope_attestations/ritualant_npc_silhouette_readability_shader_v1_recovery_2.json`.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/review_receipt_delta.py`; `custodian/docs/ai_context/review_scope_attestations/grunt_candidate_raster_v1.json`; `custodian/docs/ai_context/review_scope_attestations/road_procession_p1_source_scope_v1.json`; `custodian/docs/ai_context/task_packets/archived/RITUALANT_NPC_SILHOUETTE_READABILITY_SHADER_V1_RECOVERY_2.md`; `custodian/docs/ai_context/task_packets/REVIEW_RITUALANT_NPC_SILHOUETTE_READABILITY_SHADER_V1_RECOVERY_2.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_G2_SOURCE_SCOPE_ATTESTATION_V1.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_PROCESSION_DOC_SCOPE_RECOVERY_V1.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_GRUNT_RASTER_REVIEW_SCOPE_ATTESTATION_V1.md`.
- Change:
  1. Pin the exact landing commit, parent, tree, archived packet path/blob/mode, and complete changed-path inventory below. Pin exact source blobs and modes for only the two admitted Markdown files.
  2. Add the attestation at the declared `review_scope_attestations/` path. Its canonical bytes must identify the source workstream, commit, parent, tree, archived packet, complete archive path inventory, and exactly the two source file entries.
  3. Add one target-specific verifier in the existing source-scope mechanism. Require exact archive identity and complete path set; verify the archived packet blob/mode and each admitted source blob/mode from Git objects. Reject any extra/missing path or identity drift.
  4. Treat the attestation as non-authorizing until fetched `origin/main` proves this correction's archived implementation and paired review are its ancestors and the review has a canonical accepted independent PASS plus a valid matching target receipt. Reuse `review_outcome` and `review_receipt_delta`; reject missing, malformed, nonpassing, forged, stale or mismatched evidence.
  5. Apply the exception only when the source target and landing commit exactly match this archived recovery-2 implementation. Leave all ordinary Work surface, Procession, Grunt and other source-scope rules unchanged.
  6. Add actual-Git positive/negative regressions proving the two exact Markdown paths are rejected before approval and admitted only after authentic correction review acceptance; wrong commit, parent, tree, packet blob/mode, full path inventory, source path/blob/mode, extra paths, malformed attestation, or forged/missing review approval all fail closed.

- Immutable archive path inventory (exact `git diff-tree --no-commit-id --name-only -r a45663a9b23d2e2818edd1531cbb5ac1aa231f58` result):
  - `RITUALANT_NPC_SILHOUETTE_READABILITY_SHADER_V1_RECOVERY_2_CLAUDE_SUMMARY.md`
  - `custodian/docs/ai_context/BRANCH_ARCHIVE.md`
  - `custodian/docs/ai_context/task_packets/README.md`
  - `custodian/docs/ai_context/task_packets/RITUALANT_NPC_SILHOUETTE_READABILITY_SHADER_V1_RECOVERY_2.md`
  - `custodian/docs/ai_context/task_packets/archived/RITUALANT_NPC_SILHOUETTE_READABILITY_SHADER_V1_RECOVERY_2.md`
  - `custodian/game/world/events/ash_bell/forlorn_ritualant_site.tscn`
  - `custodian/game/world/events/ash_bell/materials/ritualant_silhouette_readability_material.tres`
  - `custodian/game/world/events/ash_bell/shaders/ritualant_silhouette_readability.gdshader`
  - `custodian/game/world/events/ash_bell/shaders/ritualant_silhouette_readability.gdshader.uid`
  - `custodian/tools/validation/forlorn_ritualant_presentation_smoke.gd`
  - `custodian/tools/validation/forlorn_ritualant_presentation_smoke.gd.uid`
  - `custodian/tools/validation/levels/forlorn_ritualant_underground_smoke.gd`
  - `custodian/tools/validation/validation_manifest.json`
  - `design/02_features/enemy_objective/FORLORN_RITUALANT_SHADER_FX.md`

- Preserve: The source archive and archived packet byte-for-byte; the original Ritualant review run, claim ref, branch, lock, worktree and evidence; all unrelated active review ownership; the existing general source-scope rules and every prior review receipt/verdict.
- Non-goals: No shader, runtime, design or validation-source edits; no edits to the historical archived implementation packet or commit; no generic Markdown/suffix/glob exception; no fabricated review acceptance; no duplicate or replacement Ritualant review claim; no lock preemption or release; no original-review recovery before this correction's accepted PASS.
- Acceptance:
  1. The original source-scope replay remains rejected before this correction receives its own accepted independent PASS.
  2. After authentic accepted PASS and target receipt are reachable from `origin/main`, the exact pinned source archive is admissible and only the two named Markdown paths are admitted.
  3. Each commit/parent/tree/packet/path/source blob and mode mismatch, missing/extra archive path, malformed/ambiguous attestation origin, or missing/noncanonical/forged/mismatched approval fails closed.
  4. Existing generic, Procession and Grunt rules remain unchanged; the preserved Ritualant review run and its lack of reviewer verdict are unchanged.
  5. Focused actual-Git tests, Python compilation, packet-index check, `git diff --check`, and canonical changed-file validation pass with complete coverage and no skips.
- Validation: Run focused new historical attestation tests plus related `paired_review_runner` regression tests; run `python3 -m py_compile custodian/tools/agent/paired_review_host_validation.py`; run `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`; require complete coverage and zero failed/skipped/infrastructure-error tests. Avoid Godot import/runtime sweeps. After this correction's accepted review is on main, the coordinator may plan recovery of the preserved run; that later plan/apply is not part of this implementation's PASS.
- Task overrides: `none`
- Deferred: After this correction's own accepted independent PASS lands, the coordinator resumes only run `20261103T022803Z-2fa8fee1b08c` with `paired_review_runner.py review-ritualant-npc-silhouette-readability-shader-v1-recovery-2 --continue-run 20261103T022803Z-2fa8fee1b08c --recover-host-validation --plan`. Apply only the exact new plan digest using the tool's current documented `--apply --authorize-fresh-reviewer-context` controls. The original reviewer then reports its own PASS, findings or `human_required` outcome.


## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: The exact recovery-2 attestation and source-bound verifier are implemented; actual-Git positive/adversarial tests pass; the four existing administrator/Grunt history fixtures now pin synthetic provenance; `run_validation.py --changed --base origin/main --json` passed both selected groups with complete changed-file coverage, 0 failures, 0 skips, 0 timeouts and 0 infrastructure errors; Python compilation, packet-index check and `git diff --check` pass. Validation report: `/home/braydenchaffee/.cache/custodian/validation/ritualant-r2-final-20261103T091927Z.json`.

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: The new exact source-attestation route initially intercepted generic fixture histories, and four legacy administrator/Grunt approval tests failed because their synthetic histories depended on moving `origin/main` or ambiguous attestation-blob origin. The production verifier compatibility path was restored, then the authorized fixture builders were repaired with pinned implementation/history identities.
- Root cause / contributing factors: Historical test fixtures derived provenance from moving branch state and did not create a unique source-blob origin; test runs exposed the provenance ambiguity.
- Prevention / pipeline improvement: Pin synthetic review targets and baseline commit identities, and build a unique introduction history for attested blobs.
- Tooling / docs drift discovered: none
- Follow-up: fixed in-scope
- What worked: Real-Git historical acceptance and adversarial mutation tests exercised the unchanged fail-closed review predicates; canonical changed validation now passes all selected groups.

## Handoff
- Next workstream: `review-agent-ritualant-recovery-2-source-scope-attestation-v1`
- Next packet state: `ready/auto`; implementation archive and landing now unblock dispatcher eligibility.
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae7eb07-c554-83e9-911a-1335e640e4d0
- Refresh reason: `none`
- Next action: After implementation landing, re-audit dispatcher eligibility and launch the exact fresh paired reviewer through `paired_review_runner.py`; preserve original review run `20261103T022803Z-2fa8fee1b08c` until this correction receives canonical independent acceptance.
- Blockers or open questions: Independent paired review is pending; original Ritualant review remains preserved and unresolved.
