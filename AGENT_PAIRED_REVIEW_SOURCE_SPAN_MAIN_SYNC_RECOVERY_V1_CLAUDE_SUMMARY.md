# Agent Paired Review Source-Span Main-Sync Recovery V1

Workstream: `agent-paired-review-source-span-main-sync-recovery-v1`

## Result

Repaired split-landing source provenance in `paired_review_host_validation.py` and added regression coverage in `test_paired_review_runner.py`.

For the historical W1 correction review, the canonical archived implementation remains `1fa679c33f49bf3ee7d08072c82f747809b00b35`. The resolver separately accepts the trace-pinned two-parent main-sync landing `f12717e61213d7d30ae6b3e670d45e71507cd784` only when its first parent is that archive commit, its second parent matches exactly one `main_sync(changed=true, head=merge, main_sha=...)` trace event, all event identities match the same workstream/packet/run, and the trace landing is an ancestor of the pinned reviewed main. The trace's later `main_sync(changed=false)` event does not substitute for that source event.

The recovered validation source range remains `06cbe9521dfa8efe82fb5820709646ca6d1486e7..48a0bfc4836fbc88cd4406cc814959dcfc6e453b`, with the two Python source/test files selected from the full source range. The merge SHA is recorded separately in validation provenance and is never used as the source-span head. The resolver also validates the canonical archive commit's closeout paths, requires active-packet deletion plus canonical archived-packet creation, rejects executable/non-regular closeout paths, and verifies that the trace merge leaves the archived target and every source-span path unchanged from the archive-first-parent tree.

## Validation

- `test_paired_review_runner.py`: 69 tests passed, including historical refs, W1 regression, and temporary Git merge positives/negative controls.
- `test_dispatch.py`: 86 tests passed.
- `test_workstream.py`: 39 tests passed.
- `test_review_outcome.py`: 13 tests passed.
- `test_task_packet_contract.py`: 27 tests passed.
- `run_validation.py --changed --json`: passed; 4 selected checks, both changed Python files covered by the two relevant owners, 3 documentation/summary paths explicitly excluded, 0 failures.
- `py_compile` for the changed Python files and `git diff --check`: passed.

The first changed-file validation was run before packet/summary archival and covered both Python files. The final report is regenerated after lifecycle closeout so its changed-file set also includes the packet and root summary. No protected review evidence was written, and the original run `20261018T014101Z-f4fd619029aa` remains in `host_validation_recovery`. The original W1 recovery plan was not applied.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: An initial resolver path could classify code accidentally included in an archive transition as ordinary implementation source. Archive-transition detection now routes through the strict archive allowlist first. The real W1 archive commit also showed that a summary or index need not change in the archive commit if it was already present or current.
- Root cause / contributing factors: Archive identity, final trace landing identity and source-validation range are distinct; ordinary rename detection hid the active packet deletion in an archive diff.
- Prevention / pipeline improvement: Keep the three identities separate, enumerate archive paths with rename detection disabled, and validate protected tree content across a main-sync merge.
- Tooling / docs drift discovered: none
- Follow-up: review-agent-paired-review-source-span-main-sync-recovery-v1
- What worked: The historical remote trace and synthetic real-Git two-parent fixtures exercised the exact lineage and failure boundaries.

## Next Handoff

- Next workstream: review-agent-paired-review-source-span-main-sync-recovery-v1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Refresh reason: none
- Next action: Run the paired post-land review in a fresh independent reviewer context. Recover the preserved correction-review run only after this review passes.
- Blockers or open questions: The existing correction-review run has no verdict and must remain protected; W2/W5 stay blocked.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
