# P0: Authenticate excluded coverage evidence for preserved paired-review retries

- Packet schema: `custodian.task_packet.v2`
- Workstream: agent-paired-review-excluded-coverage-evidence-recovery-v1
- Category: `agent-ops`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `agent-paired-review-excluded-coverage-evidence`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: review-agent-paired-review-excluded-coverage-evidence-recovery-v1
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: Changes the integrity checks that authenticate stored failed host-validation evidence before any fresh independent reviewer may launch.
- Reviewed main: `14298756db4493ab6f52e0a886a911ed0e01c2c0`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae424b0-a48c-83ea-9c8e-68e3c48fa59d
- Visual review: `none`
- Goal: Repair one mismatch between the canonical changed-file coverage-exclusion policy and paired-review failed-host-report authentication. Unblock the *existing claimed*, unreviewed attestation correction `review-agent-persistent-task-administrator-review-scope-recovery-v1` without fabricating a pass, changing its immutable evidence, or re-claiming it.
- Completion boundary: A preserved failed host report with one canonical policy-excluded, source-hashed JSON under `custodian/docs/ai_context/review_scope_attestations/` can be authenticated and planned for same-run host-validation retry; ineligible excluded paths, missing covered source/tests, altered reports and mismatched pinned bytes remain rejected. Equivalent successful report validation must not contradict the same canonical coverage policy.
- Current measured state: Scope authorization implementation landed `origin/main@b9b76f86c404b955291097e5a37407e6559cb9dd` with 208 paired-review tests passing. Its fresh review is already claimed, no verdict, and preserved as `host_validation_recovery` in exact run `20261030T111515Z-d6cd006cd42d`. The host failure was reported at `paired_review_runner.py:3020`: `code_paths` contains a source-hashed attestation JSON excluded by the canonical manifest `custodian/docs/**`; `_failed_host_validation_report_pair()` incorrectly requires `code_paths` to be a subset of `coverage.covered_files`. `paired_review_host_validation._validate_report()` also has a duplicate unconditional covered-only check for `_source_code_paths()` including `.json`. Do not reinterpret the timed-out test as a successful review. Current authoring base is `main@14298756db4493ab6f52e0a886a911ed0e01c2c0`.
- Evidence: `custodian/tools/agent/paired_review_runner.py` `_failed_host_validation_report_pair`, `custodian/tools/agent/paired_review_host_validation.py` `_validate_report`, `custodian/tools/validation/run_validation.py` `changed_file_coverage()`, and `custodian/tools/validation/validation_manifest.json` `coverage_excludes`. Existing host-private original run reports and pinned review checkout are preservation evidence, not publication inputs.
- Task-specific authority: `AGENTS.md`, `custodian/AGENTS.md`, `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`, `custodian/tools/validation/run_validation.py`, `custodian/tools/validation/validation_manifest.json`, `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/paired_review_host_validation.py`.
- Work surface: `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/test_paired_review_runner.py` and narrowly necessary existing host validation regression tests; `custodian/tools/validation/validation_manifest.json` only for adding test ownership, never to weaken existing exclusions. Required completion summary/packet archive through normal lifecycle.
- Publication inputs: `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/paired_review_host_validation.py`, `custodian/tools/agent/test_paired_review_runner.py`, `custodian/tools/validation/run_validation.py`, `custodian/tools/validation/validation_manifest.json`, `custodian/docs/ai_context/task_packets/archived/AGENT_PERSISTENT_TASK_ADMINISTRATOR_REVIEW_SCOPE_RECOVERY_V1.md`, `custodian/docs/ai_context/task_packets/REVIEW_AGENT_PERSISTENT_TASK_ADMINISTRATOR_REVIEW_SCOPE_RECOVERY_V1.md` (already tracked on main).
- Change: Fix the failed-report predicate by authenticating `code_paths` in two independent dimensions: (1) every path is still source-hashed and bound to the exact pinned reviewed-main Git tree and actual preserved checkout bytes, and (2) the coverage classification is correct for the trusted canonical validation manifest at the pinned baseline. For each code path, require `covered_files` with a valid test owner OR `excluded_files` with an actual matching canonical `coverage_excludes` rule, never merely a claimed exclusion list in JSON. Maintain complete changed-file accounting, no overlaps/duplicates, complete selected test IDs/counts and positive failed-report integrity checks. Apply consistent classification to `paired_review_host_validation._validate_report()` so successful retries will not fail the same excluded JSON. Reuse existing policy/selection helpers where possible; do not create a second policy list, hardcode the administrator filename, bypass the check, or change the canonical exclusion policy.
- Preserve: `review-agent-persistent-task-administrator-review-scope-recovery-v1` original claim/worktree/host-private run `20261030T111515Z-d6cd006cd42d` and all report bytes; `review-agent-persistent-task-administrator-v1` earlier original claim and historical baseline; Procession claims; source authorization attestation JSON; existing independent verdict gates and unrelated root/host data.
- Non-goals: No review rerun in this implementation worktree, no general rearchitecture, no historical source-scope exemptions, no bypassing tests or review receipts, no edits to the claimed review packet, no blanket permission to treat arbitrary `.json` as excluded, no Phase B/C executor implementation.
- Acceptance: (1) A disposable fixture modeling the exact real attestation path, hashed in metadata and marked `excluded_files` by a trusted baseline `custodian/docs/**` policy, is accepted for genuine failed-host retry authentication while `code_paths` includes that JSON. (2) A changed Python source falsely marked excluded, a nonmatching JSON path, a duplicated/overlapping/extra excluded path, uncovered required source, malformed coverage, forged pinned hashes/report bytes or a false report success still fail closed. (3) `_validate_report` accepts green canonical coverage with that excluded JSON but rejects source/test gaps and forged/mismatched exclusions. (4) Original preserved report/run is not changed; a fresh independently approved correction review is required before this host repair is relied upon.
- Validation: Focused `test_paired_review_runner.py` tests of both validation paths and adversarial coverage exclusion controls, including `run_validation.py` policy behavior, plus full paired review unit suite, canonical changed-file validation and complete coverage for eligible changed files; `python3 custodian/tools/agent/validate_task_packet_authoring.py` for the pair, review pairing/category checks, `git diff --check`. Treat a timed-out test as a real failed attempt, not successful evidence.
- Task overrides: `none`
- Deferred: After this implementation and its genuine independent review PASS, on the original host resume the *existing* attestation review using the exact run `20261030T111515Z-d6cd006cd42d` with `paired_review_runner.py review-agent-persistent-task-administrator-review-scope-recovery-v1 --continue-run 20261030T111515Z-d6cd006cd42d --recover-host-validation --plan`, followed only by an authorized fresh hashed `--apply`. If its fresh review passes, continue the older administrator implementation review's separate original run. Never create duplicate review claims.

## Execution instructions
Claim this implementation with the normal dispatcher; implement in its isolated worktree. Keep the patch to the two existing validator/runner modules and targeted regression tests. Verify trusted coverage exclusions against pinned-manifest provenance, not an untrusted report field. Land/teardown via `workstream.py finish` after full green validation; launch only this packet's fresh independent review after landing. Do not touch either preserved administrator review worktree.

## Handoff
- Next workstream: review-agent-paired-review-excluded-coverage-evidence-recovery-v1
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae424b0-a48c-83ea-9c8e-68e3c48fa59d
- Refresh reason: none
- Next action: On independent PASS, recover the preserved attestation review by its exact run ID using read-only plan and SHA-pinned apply.
- Blockers or open questions: Fresh implementation/review and host-private same-run recovery remain outstanding.
