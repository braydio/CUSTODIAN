# Workstream Finish: Verified Managed-Index Conflict Recovery V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `workstream-finish-index-conflict-recovery-v1`
- Status: `complete`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `none`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-workstream-finish-index-conflict-recovery-v1`
- Review cycle: `0`
- Max automatic review cycles: `1`
- Review rationale: `Protected lifecycle enforcement change: accepting malformed or unbound Git history could land work whose archive, review, or validation evidence is not trustworthy; a fresh independent review must verify the narrow allowlist and adversarial controls.`
- Reviewed main: `dd3041b773959b50b38c7a5c2391ff0b7e120914`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae03e16-cd34-83e9-ba0e-82b8f95f7690
- Visual review: `none`
- Goal: Let the existing finish lifecycle recover the verified P0 managed Ready/Auto index conflict-and-repair history without bypassing archive, commit-provenance, scope, validation, completion-truth, or review gates.
- Completion boundary: Extend the existing post-archive main-sync recovery and its disposable-Git tests to recognize only a real two-parent sync merge whose sole conflict is in the generated managed Ready/Auto block, followed immediately by the exact bounded index repair and verified allowed follow-ups. Correctly parse bare repository paths in the archived packet's Work surface without treating prose as authorization. Preserve all other fail-closed history and completion checks. Land this Protected implementation through `workstream.py finish` with focused validation. Its fresh paired review and the original `workflow-governance-simplification-v1` closeout are required downstream handoffs, not prerequisites for archiving this implementation packet.
- Current measured state: `workstream.py` already accepts clean archive-first syncs and authenticated managed-index additions/removals, and `test_archive_guard_recovers_resolved_current_main_sync_without_erasing_conflict_evidence` covers a clean merge plus a scoped follow-up but does not create a conflict. The preserved original branch is `agent/workflow-governance-simplification-v1` at `871b673b6356b88f7e8e702ba786bf777018b6c7`, exactly seven first-parent commits ahead of `origin/main@dd3041b773959b50b38c7a5c2391ff0b7e120914`. Its exact sequence is archive `6040cb725b4ee16f602c2848ffd263b0bf4cf006`; interrupted two-parent merge `b80b23bdd54044019023945d9df188230489ab67`; managed-index conflict repair `9685d09e725121f15e25908f56a26278e9a69c83`; bounded closeout/index commits `39f5ab5b427c17c0f899597945b1d64fbc34ca9b`, `7a5b91f85dab3c3e2996a7c37d399bf8dec959a4`, `2179eae76437b7309f0e7d03986c34fd12ce7985`, and `871b673b6356b88f7e8e702ba786bf777018b6c7`. The merge parents are the archive commit and the recorded main SHA. The conflict markers are in the managed block; the repair removes only that conflict hunk. The original archived packet's Work surface lists repository paths without backticks, while the current guard extracts only backtick-quoted strings.
- Evidence: `custodian/tools/agent/workstream.py` (`_archive_transition_tip_error`, `_authenticated_managed_index_reconciliation`, artifact and completion-truth preflights); `custodian/tools/agent/test_workstream.py` (`test_archive_guard_recovers_resolved_current_main_sync_without_erasing_conflict_evidence`); `custodian/tools/agent/paired_review_host_validation.py` (managed-index reconciliation); `custodian/tools/agent/task_packet_index.py` (canonical generated index); original branch/trace refs and the exact commits listed above.
- Task-specific authority: Root `AGENTS.md`; `custodian/AGENTS.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; the exact original archived packet and its root summary on `agent/workflow-governance-simplification-v1`.
- Work surface: `custodian/tools/agent/workstream.py`; `custodian/tools/agent/test_workstream.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`. Existing helper code may be changed only when directly required by the acceptance tests; do not modify dispatcher, paired-review outcome, land-main, or general packet-authority behavior.
- Publication inputs: `custodian/tools/agent/workstream.py`; `custodian/tools/agent/test_workstream.py`; `custodian/tools/agent/task_packet_contract.py`; `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/task_packet_index.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/validation/run_validation.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md` (all must be verified tracked on `origin/main` at claim time; no external or unpublished fixture is required).
- Change: Reuse and narrowly extend the current post-archive sync sequence. Authenticate that the merge is the actual two-parent Git merge from the canonical archive transition to an ancestor of current `origin/main`, that Git's conflict tree differs only by the standard conflict-label text, and that its only conflict is the exact generated Ready/Auto entry for this now-archived packet inside the single managed block. Require the immediately following first-parent commit to modify only the regular README, remove that exact conflict hunk, preserve all other bytes, and leave no conflict markers. Authenticate each later first-parent commit and permit only exact declared Work-surface paths plus the exact archived packet, expected root summary, and managed-index administrative artifacts; validate final packet completion truth, backlinks, and generated-index state through existing finish checks. Parse explicit bare and backtick path tokens safely; ignore prose and reject traversal/absolute paths. Document this accepted history precisely. Do not add a CLI bypass or a generic conflict-recovery exception.
- Preserve: Canonical archive transition identity; real merge ancestry and current-main freshness; immutable diagnostic trace and claim provenance; generated-index ownership; regular-file/mode checks; exact Work-surface limits; completion-truth, artifact, summary-backlink, validation and independent-review gates; the original branch, claim, evidence, and packet `Review: none` decision.
- Non-goals: No rewrite/reset/rebase/force-push of the original branch; no direct GitHub merge; no bypass flags; no acceptance of conflicts outside the managed block; no acceptance of uncorrected markers, fabricated parents, extra merge descendants, unrelated path changes, executable/symlink extras, or false completion evidence; no generic recovery framework; no edits to `OWNER_REVIEW_EXCEPTION_LANE_V1` or other workstreams; no Pass B/C.
- Acceptance: (1) Extend the existing resolved-main-sync test with a real disposable Git archive → conflicting main update → two-parent merge containing only the authentic managed-block conflict → immediate exact README repair → bounded closeout chain, and prove the complete chain is accepted. (2) Compare the intermediate merge against Git's merge-tree result, normalizing only conflict labels; prove all non-README paths and stages match and the conflict hunk names the exact archived packet row. (3) Prove the repair is the immediate child, edits only the managed block hunk in a regular README, removes all markers, preserves all surrounding content, and leaves the final generated Ready/Auto block exactly current. (4) Prove subsequent commits are individually first-parent-bound and limited to parsed explicit Work-surface files or exact lifecycle packet/summary/index artifacts; bare paths in the original packet are recognized while prose, traversal, absolute paths, unrelated files, executable files, and symlinks are not authorized. (5) Reject uncorrected markers, a modified or delayed repair, another conflicted file, a forged/non-ancestor second parent, altered merge tree, unauthorized post-archive edits, missing/duplicate/ambiguous index markers, and a final stale index. (6) Demonstrate that false/missing Completion Truth, blocked packet status, bad summary backlink, or absent validation report still blocks normal finish; success of the history guard alone cannot land the original work. (7) Preserve existing archive-at-tip, authenticated sync, clean sync, scope rejection, and finish-before-push tests. (8) Land this implementation through the normal lifecycle with focused validation; fresh paired review and the original workstream closeout remain separate downstream stages. The original work remains `Review: none` and receives no retrospective review.
- Validation: Targeted authoring preflight on both packets before publication and after automatic promotion; `python3 custodian/tools/agent/test_workstream.py`; `python3 custodian/tools/agent/test_workstream_artifacts.py`; `python3 custodian/tools/agent/test_task_packet_contract.py`; `python3 custodian/tools/agent/test_dispatch.py`; `python3 custodian/tools/agent/task_packet_index.py`; `python3 custodian/tools/agent/check_ai_context.py`; `git diff --check`; and `python3 custodian/tools/validation/run_validation.py --changed --json` for implementation and final sync. The paired review runs only after the implementation is landed, through `paired_review_runner.py` in a fresh reviewer context. Resume the original branch only after a passing review, then run its changed-file validation and normal completion preflights before `workstream.py finish`.
- Task overrides: `TASK OVERRIDE: User-authorized Protected lifecycle correction for the exact preserved managed-index conflict-and-repair history in this packet. Do not weaken any unrelated guard or alter the original workstream's Review:none decision.`
- Deferred: Any other conflict topology, missing/ambiguous trace recovery, general post-archive source-span API, unrelated lifecycle hardening, and all Pass B/C work.

## Concurrency scope decision

`Locks: none` is intentional for this correction because it edits only the
declared lifecycle guard, focused tests, and lifecycle documentation. The
dispatcher verified this workstream's unique claim at `main@bb5a1b16`; the
unrelated preserved review claim and its checkout remain untouched. Packet-level
lock removal does not waive unique workstream claims, local lifecycle mutexes,
serialized landing, or any actual shared-resource budget lock.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: The exact original seven-commit history passes `_archive_transition_tip_error` in an isolated clone pinned to `main@dd3041b773959b50b38c7a5c2391ff0b7e120914`. Focused adversarial disposable-Git cases and the required Python lifecycle, artifact, packet-contract, dispatch, index, context, and changed-file validation checks pass. This workstream commits the correction and evidence, then uses `workstream.py finish` as the landing authority. Its separate paired review is the next required workstream. The original governance task has not yet been closed out and remains an explicit downstream handoff.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: The first disposable-Git fixture produced an empty-index conflict shape instead of the preserved one-row conflict and initially exercised a temporary-repository import path. The fixtures were corrected to retain a neighboring generated entry and use the implementation checkout's validation modules. The initial packet boundary also combined implementation completion with the later independent-review and original-closeout stages; it is now aligned with the repository's implementation-then-review lifecycle.
- Root cause / contributing factors: The prior clean-sync test did not exercise a real generated-index conflict, and the packet boundary spanned stages that cannot complete before the implementation packet archives and unlocks its paired review dependency.
- Prevention / pipeline improvement: Keep the real conflict-and-repair topology, parent/tree tampering controls, and stage ordering in the focused disposable-Git suite; keep implementation and fresh-context review completion boundaries distinct.
- Tooling / docs drift discovered: The previous Work-surface scope parser required backtick-quoted paths despite the original packet listing bare paths; the recovery contract also needed the exact immediate-repair ordering documented.
- Follow-up: `review-workstream-finish-index-conflict-recovery-v1`
- What worked: The preserved original commit sequence, including its exact Git merge-tree conflict and README correction, passes the new guard without rewriting its branch or trace evidence.

## Handoff

- Next workstream: `review-workstream-finish-index-conflict-recovery-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae03e16-cd34-83e9-ba0e-82b8f95f7690
- Refresh reason: `none`
- Next action: After this Protected implementation lands and archives complete, invoke `paired_review_runner.py review-workstream-finish-index-conflict-recovery-v1` in fresh reviewer context; after a passing disposition, resume and finish the original preserved workstream.
- Blockers or open questions: None for this implementation. The original closeout remains gated on the paired review's fresh disposition and its own validation.
