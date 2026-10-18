# Paired Review Source-Bearing Archive Gate V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-source-bearing-archive-gate-v1`
- Kind: `implementation`
- Status: `ready`
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
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: `Allow one trace-pinned source-bearing archive transition to validate without weakening the existing archive-only and main-sync-merge provenance gates.`
- Completion boundary: `One narrowly extended source-span resolver and real-Git regression tests, landed with a SEPARATE code/test implementation commit followed by archive-only closeout, then an independent paired review. The two earlier preserved review runs are not resumed or altered by this implementation.`
- Current measured state: `The already-landed source-span implementation 6519a2b2db0bad5f14d7a6993e17c92aca58d081 directly descends from 7119b4c385266e8928070b8e534ea3a5844a5f9f and simultaneously changes paired_review_host_validation.py, test_paired_review_runner.py, its active packet deletion, archived packet creation, root summary and task index. Trace agent-diagnostics/agent-paired-review-source-span-main-sync-recovery-v1/20261018T064130Z-f6559c757a1f pins 7119b4c3 and landing 6519a2b2 with main_sync(changed=false). The review run 20261018T065436Z-f77aa52cf7a1 is preserved in host_validation_recovery because resolve_validation_source_span detects the packet archive transition, chooses the archive-only resolver, then rejects the two real Python source/test paths as unrelated. No reviewer verdict exists.`
- Evidence: `custodian/tools/agent/paired_review_host_validation.py::{resolve_validation_source_span,_split_landing_source_span}; custodian/tools/agent/test_paired_review_runner.py::PairedReviewHostValidationTests; commit 6519a2b2; exact immutable lifecycle trace ref above; preserved review run .git/custodian-review-runs/review-agent-paired-review-source-span-main-sync-recovery-v1/20261018T065436Z-f77aa52cf7a1/; historical archive-only/merge test 1fa679c3/f12717e6 and W1 b5b85ca4.`
- Task-specific authority: `Live paired_review_host_validation.py, task_packet_contract.py and canonical run_validation.py changed-file/coverage evidence; immutable workflow trace and post-land review runner contracts.`
- Work surface: `custodian/tools/agent/paired_review_host_validation.py; custodian/tools/agent/test_paired_review_runner.py. No runtime scenes, Git worktree mutation, or reviewed implementation source in preserved review checkout.`
- Change: `For an active-packet deletion plus canonical archived-packet creation, distinguish archive-only from source-bearing archive transitions only after exact unique trace, same workstream/packet/run and SHA ancestry verification. Existing archive-only path must stay strictly limited to active packet, archived packet, exact root closing summary and packet index. Permit the source-bearing variant only when the same linear single-parent canonical archive landing also changes nonempty documented implementation source/test paths; require ALL additional paths beyond the four closeout paths to be exact source/test file paths documented by the archived work surface, without unrelated files, nonregular/executable file modes or untracked fallback. Resolve the validation span from the trace's claim main_sha to the canonical source-bearing landing itself; preserve source code hashes, changed-file coverage, one-test-owner requirements, exact historical landing/trace provenance and source span identity in verification metadata. A later main-sync merge remains independently bound to its verified ordered parents and immutable main_sync event, and must not change archived target or recovered source bytes. Retain direct non-archive source path behavior. Reject trace ambiguity, forged metadata, undocumented changed files, missing source, unowned tests, merge ancestry within the source span, and missing/incorrect closeout paths. Avoid a second source/identity resolver.`
- Preserve: `Existing 1fa679c3 archive-only + f12717e6 main-sync historical result, W1 b5b85ca4 source span, missing/ambiguous trace and unrelated code negative controls; exact protected 20261018T065436Z-f77aa52cf7a1 original review run and 20261018T014101Z-f4fd619029aa prior correction run; claimed review branch/worktree, W1 six run-file hashes, backup refs, untouched root .gitignore and independent carrow claim.`
- Non-goals: `No blanket acceptance of arbitrary code in archive commits, no weakening of provenance, no bypass of source/tests coverage, no review verdict fabrication, no review launch, no W1 plan application, no W2/W5 release, no coordination-root reset/fast-forward, no changes to Carrow.`
- Acceptance: `A1: historical 6519a2b2 resolver with its exact trace, reviewed_main=6519a2b2 and archived target returns base 7119b4c3 and head 6519a2b2, identifying exactly paired_review_host_validation.py and test_paired_review_runner.py as code/test paths, with trace-pinned source-bearing archive provenance. A2: historical 1fa679c3/f12717e6 and W1 b5b85ca4 keep their existing distinct exact source ranges and provenance. A3: real temporary Git fixtures reject absent/duplicate/forged traces, incorrect workstream/packet/run/base SHA, bad archive transition, no source, unrelated code, unrelated noncode, executable/nonregular paths, merge in source chain, source/target mutation in later main-sync merge. A4: coordinator validation writes new exclusive source/coverage evidence and post-review verification re-resolves it byte-identically, with no mutation of earlier original run artifacts. A5: closeout for THIS fix must be two commits: code/tests implemented and validated first; a subsequent archive-only packet/summary/index commit modifies no source or test files, preventing another same-run host-validation deadlock. A6: independent review passes before either preserved review is resumed.`
- Validation: `python3 -m unittest custodian.tools.agent.test_paired_review_runner -v; python3 -m unittest custodian.tools.agent.test_dispatch custodian.tools.agent.test_workstream custodian.tools.agent.test_review_outcome custodian.tools.agent.test_task_packet_contract -v; python3 -m py_compile custodian/tools/agent/paired_review_host_validation.py custodian/tools/agent/test_paired_review_runner.py; python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json; git diff --check. In a clean source checkout, exercise exact historical trace-pinned 6519 commit read-only. Stop on any failed changed-file coverage or unknown mutation. Before finish, explicitly commit the Python source/test changes, verify worktree clean, then perform a SECOND closeout-only commit; reject co-committed source and packet archival.`
- Task overrides: `none`
- Deferred: `Recovery of the currently blocked review 20261018T065436Z-f77aa52cf7a1, then of 20261018T014101Z-f4fd619029aa, then new W1 plan generation/application, and W2/W5, all gated on independently accepted review. No new review claim or fresh run replacing either preserved original.`

## Next Handoff

- Next workstream: `review-agent-paired-review-source-bearing-archive-gate-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: `Fresh independent review of the actual source-bearing-archive case, historical archive-only/main-sync behavior and negative controls. After acceptance, attempt read-only same-run recovery plan for preserved 20261018T065436Z-f77aa52cf7a1, never a new claim.`
- Blockers or open questions: `The existing source-span review holds a separate source-span-provenance claim; no reviewer launched. A narrowly distinct maintenance lock is used only to avoid modifying that preserved review identity; no parallel reviewer launch is authorized.`
