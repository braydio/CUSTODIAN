# Carrow Claimed Review Worktree Recovery V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `paired-review-carrow-claimed-worktree-recovery-v1`
- Authoring handoff: `auto`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `paired-review-run-recovery`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-paired-review-carrow-claimed-worktree-recovery-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `6e75b57ea828f5d90679ae737052a4acdefce361`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Add an exact, one-shot continuation for the existing Carrow paired review after host validation failed and its recorded claim worktree disappeared.
- Completion boundary: The original claim remains the sole claim; a verified fresh full host-validation continuation is appended without changing any original run evidence, and a fresh reviewer may launch only after that validation is genuinely green.
- Current measured state: At `origin/main@6e75b57ea828f5d90679ae737052a4acdefce361`, Carrow run `20261018T072047Z-83514d0c54fd` is in `host_validation_recovery`. Its immutable report records 38/40 passed, one `world_transition_handoff` failure and one skip. Original implementation is `9b15c2c4aa3f5c56584cd45ac96913ea1c81d9c6`; reviewed main and remote review-branch head are `099c44353dfd258c233016b88cc50ba2dd502ef1`. The recorded checkout path and Git worktree metadata are absent. The reviewer was not launched. Existing recovery rejects this non-import failure and cannot authenticate a missing checkout.
- Evidence: Exact run metadata, claim receipt, `validation.json`, `coordinator-validation.json`, recovery note, their SHA-256 values in the original run directory, current remote branch head, dispatcher audit, reproduction reports under `/tmp/custodian-carrow-world-transition-repro/`, and the preserved historical failure.
- Task-specific authority: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Work surface: `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/test_paired_review_runner.py`. No edits to the original Carrow run, original claim branch, Carrow implementation, other claims, or generic quarantine/parking paths.
- Publication inputs: `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/VALIDATION_RECIPES.md`; `custodian/docs/ai_context/task_packets/REVIEW_CARROW_INTERIOR_LAYOUT_AUTHORING_V1.md`; `custodian/docs/ai_context/task_packets/archived/CARROW_INTERIOR_LAYOUT_AUTHORING_V1.md`
- Change: Add a narrowly scoped recovery plan/apply path bound to exactly review `review-carrow-interior-layout-authoring-v1`, run `20261018T072047Z-83514d0c54fd`, branch `agent/review-carrow-interior-layout-authoring-v1`, reviewed main `099c44353dfd258c233016b88cc50ba2dd502ef1`, and implementation `9b15c2c4aa3f5c56584cd45ac96913ea1c81d9c6`. The plan must authenticate the original claim/run/report pair, reject held supervisor locks and any occupied/foreign destination, require explicit operator attestations when cross-host ownership and lost untracked/ignored bytes cannot be established from recorded evidence, prove local and remote branch identity and absence of unique commits, and bind the exact known failed report and whole run manifest. Apply must recheck the fresh plan digest and every bound identity, reconstruct only the exact recorded checkout on the original claim branch, create no duplicate claim, preserve all original run bytes, then append a SHA-verified continuation with a new full canonical host-validation record. A failed or interrupted validation remains preserved and cannot launch a reviewer; only a fresh verified green continuation may authorize one fresh independent reviewer.
- Preserve: Original reports, run metadata, claim receipt, branch identity and head, current dispatcher claim/lock state, all existing review artifacts, the exact `Spawn_SouthReach` assertion, source authority, and ordinary findings/PASS lifecycle. Keep the Carrow review outcome unresolved until a real reviewer completes it.
- Non-goals: Generic lost-worktree recovery; changing other failed-host-validation routes; claim parking/quarantine; branch or lock deletion; editing original reports; treating reruns or green validation as reviewer acceptance; changing the world-transition test or runtime; repairing Awakening; executing mapper M1-M7.
- Acceptance: (A1) Only the exact Carrow workstream/run/pinned SHAs/branch/report digests can enter this recovery path. (A2) A read-only plan does not alter original report bytes, metadata, claim refs, worktree state or run inventory. (A3) Apply refuses forged/mismatched claims, any SHA/ref movement, altered/incomplete report pair, altered original run manifest, active supervisor, unapproved missing-owner/evidence attestations, occupied destination, foreign checkout, existing continuation or replay. (A4) Reconstruction preserves original branch and claim without a second dispatch claim and is allowed only when no unique commits exist and all required local-data/owner proofs or explicit attestations are present. (A5) Original evidence remains byte-identical; new validation is append-only, SHA-bound and distinct from the historical failed report. (A6) A failed, skipped, incomplete or partial new validation remains nonpassing, is never overwritten or retried implicitly, and launches no reviewer. (A7) Only exact complete green canonical host validation allows one fresh reviewer launch; it does not create PASS. (A8) Negative tests cover forged claim; mismatch in run/branch/pinned SHAs; occupied destination; foreign worktree; unique/missing evidence; changed remote branch; active local supervisor; missing attestations; altered failed report; partial recovery; and replayed continuation. (A9) Existing host-validation import recovery and ordinary paired-review continuation behavior stay unchanged.
- Validation: `PYTHONPATH=custodian/tools/agent:custodian/tools python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`; focused related `test_workstream`, `test_review_outcome`, and `test_dispatch`; canonical `run_validation.py --test paired_review_runner_unit --json` and changed-file validation against the current main base with complete coverage; `check_ai_context.py --json`; `task_packet_index.py`; `validate_review_pairing.py`; and `git diff --check`. Recovery fixtures must use isolated temporary Git repositories, never the protected Carrow claim.
- Task overrides: `TASK OVERRIDE: implementation may change only the three listed paired-review runner/host-validation source and test files; the future paired post-land review may stage, commit, and push only its durable review receipt, review-packet lifecycle/archive metadata, required closing summary, and bounded correction/re-review packets; it must not edit reviewed implementation or unrelated work.`
- Deferred: Applying the reviewed recovery path to the protected Carrow run until independent review acceptance and the required operator attestations are present.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `161 paired-review runner tests pass; changed-file suites agent_workflow_contract, paired_review_runner_unit, review_pairing_contract, and visual_review_handoff pass with complete coverage; related workstream/review_outcome/dispatch tests, check_ai_context.py, task_packet_index.py, validate_review_pairing.py, and git diff --check pass; live read-only plan SHA 51341b4fc532ee6596b39ce080aac9ed1471b5eccec3f7dab12bf198b27896ad was verified against coordinator main 195ae53e9d21e6affac5da4fcbd563f6c17f882d.`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: `The host-recovery planner rejected this exact non-import failure and required the missing original checkout. The current source-span resolver also disagreed with the immutable report because it did not reproduce the original rename-aware path set.`
- Root cause / contributing factors: `The recovery planner only supported pre-validation interruption and a narrow import failure; the historical validation used Git rename detection for the implementation packet move.`
- Prevention / pipeline improvement: `Added a one-run, report-hash-pinned recovery path and exact verifier for its historical direct-commit source span; no other claims use this exception.`
- Tooling / docs drift discovered: `A reconstructed checkout must validate using the authenticated source-span evidence from the original run when current archive-follow-up resolution differs.`
- Follow-up: `review-paired-review-carrow-claimed-worktree-recovery-v1`

## Next Handoff

- Next workstream: `review-paired-review-carrow-claimed-worktree-recovery-v1`
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Independently review the landed recovery implementation. After review acceptance and explicit operator attestations, apply the exact recovery to the preserved Carrow claim and complete its original review.
- Blockers or open questions: The original checkout's untracked/ignored inventory is not recoverable from Git; apply must require and record an explicit operator attestation if durable evidence cannot establish absence of unique work or a live owner.
