# Paired Review Source-Bearing Archive Gate V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-source-bearing-archive-gate-v1`
- Kind: `implementation`
- Status: `complete`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-source-span-main-sync-recovery-v1`
- Locks: `paired-review-source-bearing-archive-gate`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-source-bearing-archive-gate-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `security-sensitive archive/source provenance and same-run reviewer recovery require a fresh independent negative-control review`
- Reviewed main: `099c44353dfd258c233016b88cc50ba2dd502ef1`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad41ae1-c654-83ea-ba9f-2b4dc4dde401`
- Visual review: `none`
- Goal: `Allow one trace-pinned source-bearing archive transition to validate without weakening the existing archive-only and main-sync-merge provenance gates.`
- Completion boundary: `One narrowly extended source-span resolver and real-Git regression tests, landed with a SEPARATE code/test implementation commit followed by archive-only closeout, then an independent paired review. The two earlier preserved review runs are not resumed or altered by this implementation.`
- Current measured state: `The bounded repair is implemented in source/test commit `5b5de5717ae10aa5bbacbd53433571aae016c555`. It pairs separately verified claim/publication and landing/teardown traces by exact worktree, branch, ancestry and canonical landing; validates the historical source-bearing `6519a2b2` and queue `aa9ddfc61` archives; and preserves archive-only, main-sync and W1 ranges. All 239 repository agent workflow, runner, dispatch, workstream, review-outcome and packet-contract tests pass; changed-file validation selects two suites with complete coverage. The original review run `20261018T065436Z-f77aa52cf7a1` and prior correction run `20261018T014101Z-f4fd619029aa` remain untouched and unresumed pending this packet’s fresh paired review.`
- Evidence: `custodian/tools/agent/paired_review_host_validation.py::{resolve_validation_source_span,_split_landing_source_span}; custodian/tools/agent/test_paired_review_runner.py::PairedReviewHostValidationTests; commit 6519a2b2; exact immutable lifecycle trace ref above; preserved review run .git/custodian-review-runs/review-agent-paired-review-source-span-main-sync-recovery-v1/20261018T065436Z-f77aa52cf7a1/; historical archive-only/merge test 1fa679c3/f12717e6 and W1 b5b85ca4.`
- Task-specific authority: `Live paired_review_host_validation.py, task_packet_contract.py and canonical run_validation.py changed-file/coverage evidence; immutable workflow trace and post-land review runner contracts.`
- Work surface: `custodian/tools/agent/paired_review_host_validation.py; custodian/tools/agent/test_paired_review_runner.py. No runtime scenes, Git worktree mutation, or reviewed implementation source in preserved review checkout.`
- Change: `For an active-packet deletion plus canonical archived-packet creation, distinguish archive-only from source-bearing archive transitions only after exact unique trace-role verification. For split traces, each immutable trace must independently match the target workstream and active packet; the pair must share the exact published worktree and branch, bind the claim base as a descendant of Reviewed main, and bind the landing trace to the canonical landing or verified main-sync merge. Any failed claim event in the landing trace must name that same claim base. Existing archive-only path must stay strictly limited to active packet, archived packet, exact root closing summary and packet index. Permit the source-bearing variant only when the same linear single-parent canonical archive landing also changes nonempty documented implementation source/test paths; require ALL additional paths beyond the four closeout paths to be exact source/test file paths documented by the archived work surface, without unrelated files, nonregular/executable file modes or untracked fallback. Resolve the validation span from the trace's claim main_sha to the canonical source-bearing landing itself; preserve source code hashes, changed-file coverage, one-test-owner requirements, exact historical landing/trace provenance and source span identity in verification metadata. A later main-sync merge remains independently bound to its verified ordered parents and immutable main_sync event, and must not change archived target or recovered source bytes. Retain direct non-archive source path behavior. Reject trace ambiguity, forged metadata, undocumented changed files, missing source, unowned tests, merge ancestry within the source span, and missing/incorrect closeout paths. Avoid a second source/identity resolver.`
- Preserve: `Existing 1fa679c3 archive-only + f12717e6 main-sync historical result, W1 b5b85ca4 source span, missing/ambiguous trace and unrelated code negative controls; exact protected 20261018T065436Z-f77aa52cf7a1 original review run and 20261018T014101Z-f4fd619029aa prior correction run; claimed review branch/worktree, W1 six run-file hashes, backup refs, untouched root .gitignore and independent carrow claim.`
- Non-goals: `No blanket acceptance of arbitrary code in archive commits, no weakening of provenance, no bypass of source/tests coverage, no review verdict fabrication, no review launch, no W1 plan application, no W2/W5 release, no coordination-root reset/fast-forward, no changes to Carrow.`
- Acceptance: `A1: historical 6519a2b2 resolver with its exact trace, reviewed_main=6519a2b2 and archived target returns base 7119b4c3 and head 6519a2b2, identifying exactly paired_review_host_validation.py and test_paired_review_runner.py as code/test paths, with trace-pinned source-bearing archive provenance. A2: historical 1fa679c3/f12717e6 and W1 b5b85ca4 keep their existing distinct exact source ranges and provenance. A3: real temporary Git fixtures reject absent/duplicate/forged traces, incorrect workstream/packet/run/base SHA, bad archive transition, no source, unrelated code, unrelated noncode, executable/nonregular paths, merge in source chain, source/target mutation in later main-sync merge. A4: coordinator validation writes new exclusive source/coverage evidence and post-review verification re-resolves it byte-identically, with no mutation of earlier original run artifacts. A5: closeout for THIS fix must be two commits: code/tests implemented and validated first; a subsequent archive-only packet/summary/index commit modifies no source or test files, preventing another same-run host-validation deadlock. A6: independent review passes before either preserved review is resumed.`
- Validation: `python3 -m unittest custodian.tools.agent.test_paired_review_runner -v; python3 -m unittest custodian.tools.agent.test_dispatch custodian.tools.agent.test_workstream custodian.tools.agent.test_review_outcome custodian.tools.agent.test_task_packet_contract -v; python3 -m py_compile custodian/tools/agent/paired_review_host_validation.py custodian/tools/agent/test_paired_review_runner.py; python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json; git diff --check. In a clean source checkout, exercise exact historical trace-pinned 6519 commit read-only. Stop on any failed changed-file coverage or unknown mutation. Before finish, explicitly commit the Python source/test changes, verify worktree clean, then perform a SECOND closeout-only commit; reject co-committed source and packet archival.`
- Task overrides: `none`
- Deferred: `Recovery of the currently blocked review 20261018T065436Z-f77aa52cf7a1, then of 20261018T014101Z-f4fd619029aa, then new W1 plan generation/application, and W2/W5, all gated on independently accepted review. No new review claim or fresh run replacing either preserved original.`


## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: A1: read-only historical resolution of `6519a2b2db0bad5f14d7a6993e17c92aca58d081` returns base `7119b4c385266e8928070b8e534ea3a5844a5f9f`, head `6519a2b2db0bad5f14d7a6993e17c92aca58d081`, and exactly the paired-review host validator plus its test file. A2: historical 1fa679c3/f12717e6, W1 b5b85ca4, and queue aa9ddfc61 provenance resolve with their existing exact ranges. A3: temporary Git negative controls cover mismatched/ambiguous traces, undocumented and unrelated paths, executable/symlink modes, invalid sync ancestry, and source/packet mutation. A4: coordinator evidence is written, re-resolved, checked against report and metadata digests, and detects later source mutation. A5: source/test commit `5b5de5717ae10aa5bbacbd53433571aae016c555` precedes the separate packet/summary/index closeout commit. A6: no preserved reviewer run was resumed; the immediate paired review is required to pass before any preserved run may resume.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: Initial synthetic Git fixtures inherited ignored paths and prior negative-case history, causing misleading no-op commits and mode controls.
- Root cause / contributing factors: The fixtures used a shared temporary repository across subcases and inherited host Git ignore/filemode configuration.
- Prevention / pipeline improvement: Isolate negative fixture histories, set `core.filemode=true`, and force-stage fixture-owned files.
- Tooling / docs drift discovered: The packet's bare unittest commands need `PYTHONPATH=custodian/tools/agent:custodian/tools` in this checkout to import runner modules.
- Follow-up: `none`
- What worked: Historical queue and source-bearing archive evidence reproduced the exact split-trace case without changing either protected review run.

## Next Handoff

- Next workstream: `review-agent-paired-review-source-bearing-archive-gate-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad41ae1-c654-83ea-ba9f-2b4dc4dde401`
- Refresh reason: `none`
- Next action: `Fresh independent review of the actual source-bearing-archive case, historical archive-only/main-sync behavior and negative controls. After acceptance, attempt read-only same-run recovery plan for preserved 20261018T065436Z-f77aa52cf7a1, never a new claim.`
- Blockers or open questions: `The existing source-span review holds a separate source-span-provenance claim; no reviewer launched. A narrowly distinct maintenance lock is used only to avoid modifying that preserved review identity; no parallel reviewer launch is authorized.`
