# AGENT WORKSTREAM CLOSEOUT PREFLIGHT V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-workstream-closeout-preflight-v1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `agent-workflow`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-workstream-closeout-preflight-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Read-only lifecycle preflight requires independent no-side-effects review`
- Reviewed main: `4b5ba4c4f88f25cbde281ca6f148da58cd5648b2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Visual review: `none`
- Summary backlink: Repeat exact Authoring chat URL in durable implementation/review/recovery/closeout summaries and Next Handoff.
- Goal: Expose an accurate, nonmutating workstream-finish readiness report before expensive synchronization and landing while keeping workstream.py finish authoritative.
- Completion boundary: Add an optional read-only preflight subcommand and focused temporary-repository tests that reuse existing artifact, packet, summary and validation checks; no change to finish's landing semantics.
- Current measured state: `workstream.py finish` remains authoritative. The new read-only preflight reports packet/archive state, literal completion truth, summary backlink, managed-index residue, classified untracked artifacts, review receipt/provenance and scope, branch state, and supplied validation report. It marks latest-main synchronization, post-sync validation and race-safe landing unknown until finish runs.
- Evidence: custodian/tools/agent/workstream.py; task_packet_contract.py; check_ai_context.py; task_packet_index.py; NPA_7_REVIEW_CLOSEOUT_CORRECTION_CLAUDE_SUMMARY.md and H5 recovery checkpoint.
- Task-specific authority: workstream.py finish remains the only workstream landing gate; shared task_packet_contract.py, task_packet_index.py and validation_green() own input semantics.
- Work surface: `custodian/tools/agent/workstream.py`; temporary-repository tests in `custodian/tools/agent/test_workstream_artifacts.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Change: Expose preflight <workstream-id> [--validation-report path] --json. Report active/archive packet state, literal Completion Truth yes fields, exact summary Authoring chat backlink, stale managed index, unrelated untracked artifacts, review receipt/provenance, branch drift and validation report integrity. Explicitly label predicates knowable only after final sync. Pure inspection must not create traces, fetch, lock, sync, stage, commit or mutate refs; leave all actual acceptance to finish.
- Preserve: Existing finish fail-closed gates and race-safe sync/landing, dirty root user files and other claimed worktrees; no report can claim landed before finish.
- Non-goals: No new finisher, automatic completion rewrite, packet archive, forced merge, baseline fail waiver or external dashboard.
- Acceptance: 1) Temporary-repo H5/NPA-type incomplete truth/backlink/index/artifact cases diagnosed before finish; 2) preview categories agree with final finish's checks; 3) stable --json output and explicit unknown-post-sync status; 4) test proves no Git refs/worktrees/files modified; 5) invalid/non-green report never yields fully ready.
- Validation: Focused test_workstream.py and isolated fixture matrix with byte-preserving negative controls; check_ai_context.py --json, validate_review_pairing.py, task_packet_index.py, run_validation.py --changed --base origin/main --json; git diff --check.
- Deferred: Any automatic repair/synchronization helper or change to finish acceptance policy.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Superseded/legacy production path disposition: `n/a`
- Evidence: `test_workstream_artifacts.py` passed 13/13 and `test_workstream.py` passed 38/38. The fixture matrix proves ready and blocked cases, invalid and failing validation reports, exact backlinks, stale index entries, untracked artifact classification, review receipts/provenance, JSON schema, explicit post-sync unknown, and byte/ref/worktree preservation. Repository-wide context, pairing, index, and changed-file gates are recorded in the closing summary.

## Execution Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The first fixture run had an incorrect blocker count and a green Completion Truth example without its required Evidence field.
- Root cause / contributing factors: The fixture initially modeled packet count rather than distinct active-packet and completion-truth gates, and did not copy the shared receipt's full required shape.
- Prevention / pipeline improvement: Build preflight fixtures from complete shared-contract examples, then assert each gate independently.
- Tooling / docs drift discovered: none
- Follow-up: fixed-in-scope
- What worked: Existing finish validators and temporary-Git fixtures provided a direct baseline for the preflight report.

- Task overrides: `none`

## Next Handoff

- Next workstream: review-agent-workstream-closeout-preflight-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1
- Refresh reason: none
- Next action: Launch the paired reviewer in a fresh context after this implementation lands and archives.
- Blockers or open questions: none

## Independent Review

- Status: `findings`
- Review target workstream: `agent-workstream-closeout-preflight-v1`
- Reviewed commit: `f742c79a53244f62ae1720bddac921413ff46fa4`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, workflow`
- Verdict: `findings`

### Findings

- **R0-01 — Incomplete-coverage validation report can produce READY.** The temporary-repository probe supplied a schema-valid report with `passed: true`, one passing test, and `coverage.complete: false` with an uncovered file. `closeout_preflight` returned `ready_before_sync: true`, `validation.green: true`, and no blockers. The repository validation runner defines overall pass as complete coverage and all selected tests passing (`custodian/tools/validation/run_validation.py`, lines 346-348), while `_validation_report_status` only records coverage and `_validation_data_green` trusts the top-level flag and test statuses. This violates acceptance item 5 and the review packet's false-ready correction threshold. A correction must define how the shared finish validator handles this inconsistent report without weakening finish authority.

### Review Evidence

- `python3 -m unittest -q custodian.tools.agent.test_workstream_artifacts custodian.tools.agent.test_workstream` — passed, 51 tests.
- Isolated temporary Git fixture — reproduced R0-01; no repository files, refs, or worktrees were changed by the probe.
- `python3 -m py_compile custodian/tools/agent/workstream.py custodian/tools/agent/test_workstream_artifacts.py` — passed.
- `python3 custodian/tools/agent/check_ai_context.py --json` — passed, zero findings.
- `python3 custodian/tools/agent/task_packet_index.py` — passed.
- `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json` — passed, but the landed tree had no changed files selected (zero tests); the focused unit suite above is the substantive test evidence.
- `git diff --check` — passed before review receipt changes.
- `python3 custodian/tools/agent/validate_review_pairing.py` — passed (66 auto packets); the first sandboxed attempt could not write shared Git `FETCH_HEAD`, then the exact check passed when rerun with the repository-authorized Git metadata access.
- Post-sync/landing behavior — remains finish-owned and is labeled `unknown` by preflight as designed; no sync or landing was attempted during this read-only review.
