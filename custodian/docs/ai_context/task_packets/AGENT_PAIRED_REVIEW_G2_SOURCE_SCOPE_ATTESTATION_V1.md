# IMPLEMENTATION: G2 Historical Source-Scope Attestation

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-g2-source-scope-attestation-v1`
- Category: `agent-ops`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `hub-sepulcher-grave-resolution-v1`
- Locks: `paired-review-source-provenance`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-g2-source-scope-attestation-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `a post-hoc historical scope exception activates review authority and needs fresh adversarial review`
- Reviewed main: `c8e3957628e5d453a7ca10d49517ee71b78fd2bf`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae5d404-c86c-83ea-aec4-6cd3d75af933`
- Visual review: `none`
- Goal: Make the already-landed Sepulcher Grave G2 implementation reviewable by authorizing exactly one validation-recipe path omitted from its immutable archived Work surface, without editing the historical packet or weakening ordinary source-scope validation.
- Completion boundary: Add an exact G2-only historical source-scope attestation and host-validation proof that remains inactive until this correction receives an accepted canonical independent PASS on main. Preserve the original G2 review claim and run. Only after this correction review passes may its held original host-validation run be replanned and, if its fresh plan succeeds, applied.
- Current measured state: G2 landed at `c8e3957628e5d453a7ca10d49517ee71b78fd2bf`; its original paired-review run `20261031T123604Z-246a023a3750` is `host_validation_recovery`, with no reviewer verdict because host validation stopped before launch. The exact runner recovery plan fails at `archive-only landing contains unrelated paths` because the source-bearing archive changes `custodian/docs/ai_context/VALIDATION_RECIPES.md`, absent from the archived packet Work surface. The root filesystem has 2.16 GiB free and `/tmp` tmpfs has 9.16 GiB free; use `/tmp` only for disposable test scratch, keep run evidence and Git records durable.
- Evidence: Immutable archive commit `c8e3957628e5d453a7ca10d49517ee71b78fd2bf`, parent `b41c4d86b5bc40ec504b1e30fa3aadffd301cc9f`, tree `8321317bbd04aa3d67d8612c836d5ff742eb99dc`; archived target packet blob `626362d96ae1ef1041951d97880ed226a0f33c18`; omitted recipe blob `7d37cb4654f627808274df297e1b73e6c6a555f5` (mode `100644`). The recipe adds the three exact G2 smoke invocations and the acceptance behavior descriptions.
- Task-specific authority: `custodian/tools/agent/paired_review_host_validation.py::_split_landing_source_span`; its Procession and Grunt accepted-review-gated scope-attestation implementations; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/review_receipt_delta.py`; the archived G2 implementation and active G2 review packets.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; new `custodian/docs/ai_context/review_scope_attestations/hub_sepulcher_grave_resolution_v1.json`.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/test_paired_review_runner.py`, `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/review_outcome.py`, `custodian/tools/agent/review_receipt_delta.py`, `custodian/docs/ai_context/task_packets/archived/HUB_SEPULCHER_GRAVE_RESOLUTION_V1.md`, `custodian/docs/ai_context/task_packets/REVIEW_HUB_SEPULCHER_GRAVE_RESOLUTION_V1.md`, `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_PROCESSION_DOC_SCOPE_RECOVERY_V1.md`, `custodian/docs/ai_context/task_packets/archived/AGENT_GRUNT_RASTER_REVIEW_SCOPE_ATTESTATION_V1.md`, and existing attestation `custodian/docs/ai_context/review_scope_attestations/grunt_candidate_raster_v1.json`.
- Change: Pin the exact G2 archive identity (commit, parent, tree, archived packet blob, complete archive path inventory, and exact source path blobs/modes). Add one canonical post-hoc attestation whose `source_files` admits only `custodian/docs/ai_context/VALIDATION_RECIPES.md` at blob `7d37cb4654f627808274df297e1b73e6c6a555f5`, mode `100644`. The G2 verifier must reject any other workstream, target packet, landing SHA, archive path set, packet blob, source path, blob, mode, mutable/ambiguous attestation origin, missing or non-accepted correction review, forged PASS, or invalid target receipt. Authenticate approval from fetched `origin/main` only after proving the preserved G2 reviewed main and source archive are its ancestors. Reuse canonical review outcome and receipt-delta verification; bind the accepted attestation/approval provenance into coordinator validation evidence and its re-verification. Integrate the exception only for this exact G2 source archive. Keep all ordinary undeclared-path checks unchanged. Add real disposable-Git tests against the actual G2 commit proving rejection before approval, acceptance only after a canonical independent PASS, and fail-closed behavior for wrong/missing/extra paths, blobs, modes, archive identity, attestation bytes/origin, and forged or mismatched approval.
- Preserve: The archived G2 packet and source commit byte-for-byte; the exact original review run, branch, claim, execution lock, worktree and evidence; all unrelated review claims, locks, worktrees and user files. Do not edit or rerun the original G2 review before this correction's accepted PASS.
- Non-goals: No gameplay or validation-recipe change; no general-purpose source-scope bypass; no directory, glob, suffix, filename-only or mutable Work surface permission; no retroactive packet edits; no fabricated G2 verdict; no duplicate G2 reviewer or claim; no modification of F14-C2a or other protected workstreams.
- Acceptance: (1) The exact immutable G2 historical source-span replay rejects before correction approval and succeeds only after this correction's accepted independent PASS is present on main. (2) Only the single pinned recipe Markdown path is attested; the complete source-bearing extra path set and all commit/parent/tree/packet/source blob/mode identities match the original G2 landing. (3) Extra or mutated source files, any other Markdown, wrong target or source commit, malformed/changed attestation, ambiguous origin, missing correction packet/review, nonpassing or forged outcome, wrong reviewer receipt, stale/forked approval, and altered coordinator provenance all fail closed. (4) Historical G2 review evidence is unchanged and still has no verdict until its own reviewer runs. (5) No broad Godot validation is added; Python-only focused tests and complete changed-file coverage prove the correction.
- Validation: First run the new focused real-Git historical regression and related G2 attestation cases with `PYTHONPATH=custodian/tools/agent:custodian/tools python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; run `python3 -m py_compile custodian/tools/agent/paired_review_host_validation.py`; then `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json` with complete coverage and `git diff --check`. Keep disposable fixtures under `/tmp`; no Godot or broad runtime sweep.
- Task overrides: `none`
- Deferred: After this correction's own independent PASS lands, run a fresh exact-run `--recover-host-validation --plan` for original G2 run `20261031T123604Z-246a023a3750`. Apply only that newly emitted plan digest through the preserved claim and verify the resulting reviewer outcome and canonical landing. Never treat this attestation as a G2 reviewer PASS.

## Handoff
- Next workstream: `review-agent-paired-review-g2-source-scope-attestation-v1`
- Next action: Run the fresh independent paired review for this exact correction. Only an accepted PASS activates the G2 exception and permits original-run recovery.
- Blockers or open questions: The shared `paired-review-source-provenance` lock is currently held by a separate claimed review; dispatcher eligibility remains authoritative.

## Next Handoff
- Next workstream: `review-agent-paired-review-g2-source-scope-attestation-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae5d404-c86c-83ea-aec4-6cd3d75af933`
- Refresh reason: `none`
- Next action: Launch the existing paired review for this correction after its implementation archives complete.
- Blockers or open questions: The G2 source-scope exception remains inactive until the paired review passes.
