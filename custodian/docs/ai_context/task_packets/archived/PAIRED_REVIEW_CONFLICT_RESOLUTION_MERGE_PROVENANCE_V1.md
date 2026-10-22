# Paired Review Conflict-Resolution Merge Provenance V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-conflict-resolution-merge-provenance-v1`
- Authoring handoff: `auto`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-failed-host-validation-import-recovery-v1`
- Locks: `paired-review-conflict-merge-provenance-v1`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-conflict-resolution-merge-provenance-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `host-validation merge provenance is a protected independent-review trust boundary`
- Reviewed main: `3e68c0b1b6b19d618f18c57b97bb1c111b2b5891`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Allow the preserved host-import recovery review to reach a reviewer only after its two historical conflict-resolution merges are authenticated from existing Git and lifecycle evidence.
- Completion boundary: Add a narrowly exact validator path for `dbcf8aec4eb09264b60bea9d26c99f235022efb5` and `d83319a3a9c211fe3947e4951bfaa06f1684bf05`, with real-Git positive and adversarial coverage, update lifecycle documentation and the dated status clarification, and pass the fresh independent review. The original held review remains unresolved until its own same-run plan and separately authorized apply.
- Current measured state: At `origin/main@3e68c0b1`, read-only recovery planning for `review-agent-paired-review-failed-host-validation-import-recovery-v1` run `20261022T052405Z-1ce687862e23` fails in `_verify_archive_sync_followup()` with `post-merge source merge lacks a unique exact main-sync witness`. Its immutable implementation trace is `20261020T200652Z-2fd156ce23d0`, SHA-256 `8d51464d6fe4852cc6154e71889bff250b32994a61f0551cb66b98da8b84a915`. The claim remains published and held; its worktree at `.../review-agent-paired-review-failed-host-validation-import-recovery-v1-20261022T052415Z-57e5cf803c6e` is clean at `6e75b57ea828f5d90679ae737052a4acdefce361`, and no reviewer launch occurred.
- Evidence: `custodian/tools/agent/paired_review_host_validation.py::_verify_archive_sync_followup`; `custodian/tools/agent/test_paired_review_runner.py`; archived implementation packet `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md`; held review packet `custodian/docs/ai_context/task_packets/REVIEW_AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md`; local immutable lifecycle trace and review metadata named above; historical merge commits and full parent SHAs named in Change.
- Task-specific authority: The held review packet's exact archive-transition lineage and review focus; the archived implementation packet's source/test surface; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md` source-span rules; the original local trace, which is host-private and must be verified in place without alteration.
- Work surface: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1_CLAUDE_SUMMARY.md`; `AGENT_PAIRED_REVIEW_CONFLICT_RESOLUTION_MERGE_PROVENANCE_V1_CLAUDE_SUMMARY.md`.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md`; `custodian/docs/ai_context/task_packets/REVIEW_AGENT_PAIRED_REVIEW_FAILED_HOST_VALIDATION_IMPORT_RECOVERY_V1.md`.
- Change:
  1. Add a compatibility path limited to the exact target workstream, original claim/run identity, canonical archive, and two exact merges: `dbcf8aec4eb09264b60bea9d26c99f235022efb5` with parents `49772f31f4dfe28614b8be9c5c820f14e8872f6b` and `e9e69fc2178b1a96e02240f4b0a86cdaf30581e7`; `d83319a3a9c211fe3947e4951bfaa06f1684bf05` with parents `b7b245dbf113b7fc21a5c34a83aee0bd65d7ccc8` and `8e4bca145658b825bb6dedeed595a3c53497a138`.
  2. Bind the first two absent merge witnesses to the exact ordered `run_blocked` conflict events in the preserved trace, the subsequent `worktree_resumed` event at `d83319a3...`, the original claim/run/workstream, and ancestry. Do not synthesize `main_sync` events or treat Git ancestry alone as lifecycle evidence.
  3. Verify both full merge trees, conflict-resolution deltas, exact changed paths and blob/mode identities, including the `test_paired_review_runner.py` resolution and archived packet changes. Continue requiring the genuine ordered later `main_sync` events for `4b1af571...` and final `6e75b57...`; preserve exact source/test coverage, file modes, archive identity, and all existing ancestry/path checks.
  4. Add a real-Git historical positive using the exact commits and trace-derived event fixture. Add adversarial cases for substituted commits/parents, forged or changed trace rows, duplicate/reordered/missing conflict interruptions, unrelated merges, changed resolution paths or file modes, source/test mutations, changed archive identity, reversed ancestry, and absent later sync events. Keep existing reset, Blender, direct-tail, and adversarial multi-merge coverage green.
  5. Update lifecycle documentation to describe this exact evidence-backed exception without broadening ordinary merge witness requirements. Add a dated clarification to the existing implementation summary while retaining its original historical account.
- Preserve: Original trace bytes and SHA, held review claim/ref/worktree/run metadata, implementation commit `25229d8d3874608f7b8492df98bc3df4385a9d28`, landing `6e75b57ea828f5d90679ae737052a4acdefce361`, all later actual sync events, the original unresolved review disposition, and unrelated worktrees/claims.
- Non-goals: No claim parking or release; no changing the held review's packet, branch, worktree, run evidence, verdict, or lock; no reviewer launch; no synthetic lifecycle event; no broad acceptance of untraced merges or descendants; no direct-tail/receipt implementation; no historical reset/Blender plan; no changes to the original implementation source.
- Acceptance:
  - A1: Current `--recover-host-validation --plan` failure reproduces before the change and the same exact historical plan reaches all source-span checks after the change, without mutating any original evidence.
  - A2: Only the two exact conflict merges are accepted through a one-to-one ordered pairing with the original two interruption events and exact `worktree_resumed` record. Their parents, trees, path/mode sets, and content identities match the pinned history.
  - A3: Genuine later `main_sync(changed=true, head=4b1af571..., main_sha=b5b1e5f...)` and `main_sync(changed=false, head=6e75b57..., main_sha=b5b1e5f...)` remain uniquely ordered and required. No event is added to the original trace.
  - A4: Every adversarial case fails closed; existing reset, Blender, direct-tail, and multi-merge tests remain green.
  - A5: The dated implementation-summary clarification preserves its original historical text and states the landed SHA/current unresolved review disposition accurately.
  - A6: Only after a genuine independent PASS of this correction may the original review's read-only recovery plan be rerun. This packet does not authorize applying it, launching its reviewer, releasing its claim, or declaring its outcome accepted.
- Validation: First run the exact read-only original host-recovery plan as the historical failing control. Run `python3 -m unittest custodian.tools.agent.test_paired_review_runner -v` including the exact real-Git regression and all existing source-span cases; run `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json` with complete selected-check coverage; run `python3 -m py_compile custodian/tools/agent/paired_review_host_validation.py custodian/tools/agent/test_paired_review_runner.py`; `python3 custodian/tools/agent/task_packet_index.py`; and `git diff --check`. Re-run the original command with `--plan` only after the correction receives independent acceptance. Never use `--apply` in this workstream.
- Task overrides: `none`
- Deferred: The original review remains held and unresolved. Its fresh reviewer can be authorized only through a new exact read-only recovery plan and separate explicit apply authorization after this correction independently passes.

## Context Pack

- Repomix: `none`

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Evidence: The exact historical conflict-resolution path is bound to the immutable trace, exact merge parents/trees/path and mode changes, and later genuine synchronization events. The original held review and its read-only recovery plan remain untouched pending this correction's independent acceptance.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `the host-local lifecycle trace contains a final append-only push event beyond the published diagnostic trace; fixtures had to preserve its exact compact JSONL encoding`
- Root cause / contributing factors: `the immutable diagnostic ref was published before the final local push event`
- Prevention / pipeline improvement: `verify the published trace artifact and host-local continuation as separately pinned evidence`
- Tooling / docs drift discovered: `none`
- Follow-up: `none`
- What worked: `exact commit/tree/path/mode pins and trace ordering constrained compatibility to this one historical run`

## Next Handoff

- Next workstream: `review-agent-paired-review-conflict-resolution-merge-provenance-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: Complete the implementation through its declared isolated lock and ordinary lifecycle; the paired fresh-context review follows landing.
- Blockers or open questions: The pre-existing host-import review remains claimed under its original lock and must remain untouched. This correction owns only `paired-review-conflict-merge-provenance-v1`.
