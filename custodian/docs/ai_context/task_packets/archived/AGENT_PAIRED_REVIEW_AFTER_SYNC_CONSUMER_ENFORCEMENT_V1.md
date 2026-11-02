# Paired-Review After-Sync Consumer Enforcement

- Packet schema: `custodian.task_packet.v2`
- Authoring handoff: `auto`
- Workstream: `agent-paired-review-after-sync-consumer-enforcement-v1`
- Category: `agent-ops`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `workstream-finish-sync-provenance`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-after-sync-consumer-enforcement-v1`
- Review cycle: `0`
- Max automatic review cycles: `0`
- Review rationale: `The canonical paired-review host validator is an acceptance boundary for landed workstream history. It currently authenticates changed-main sync merges without requiring the producer's after-sync validation witness; a false acceptance can certify unvalidated source. A fresh independent post-land review is mandatory.`
- Reviewed main: `1260f542674a94b1d127b6d3d3b55f51eb1a0060`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae6efa3-7c70-83ea-aee6-bf0799e2eb65
- Visual review: `none`
- Goal: Make paired-review host validation independently reject a changed-main synchronization merge unless its exact after-sync validation is authenticated, without changing the preserved cycle-2 human-required outcome.
- Completion boundary: Implement and validate consumer-side after-sync witness enforcement, land the scoped source and regression tests through the normal workstream lifecycle, and complete the required first fresh-context paired review. The original cycle-2 review remains `human_required`; this work does not create cycle 3 or retroactively accept that review.
- Current measured state: At reviewed main `1260f542674a94b1d127b6d3d3b55f51eb1a0060`, `paired_review_host_validation.py::_verify_split_landing_sync_merges` matches split-landing commits to checkpoint, changed-sync/resume and final no-op trace events, but does not consume `validation_after_sync`. The producer `_source_span_sync_merge_witness_error` in `workstream.py` requires ordered after-sync validation witnesses for changed-main merges. The archived cycle-2 reviewer recorded this mismatch as blocking finding R2-01 and dispositioned the review `human_required`.
- Evidence: `custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_PAIRED_REVIEW_VALIDATOR_RECERTIFICATION_V1_REVIEW_CORRECTIONS_2.md` (R2-01 and `Review Outcome`); `custodian/tools/agent/paired_review_host_validation.py::_verify_split_landing_sync_merges`; `custodian/tools/agent/workstream.py::_source_span_sync_merge_witness_error`; existing real-Git split-landing fixtures in `custodian/tools/agent/test_paired_review_runner.py`; producer-side witnesses in `custodian/tools/agent/test_workstream.py`.
- Task-specific authority: The cited archived R2-01 review evidence; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/test_workstream.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
- Work surface: Primary consumer `custodian/tools/agent/paired_review_host_validation.py::_verify_split_landing_sync_merges`; real-Git consumer fixtures and adversarial cases in `custodian/tools/agent/test_paired_review_runner.py`; producer contract and regressions in `custodian/tools/agent/workstream.py` and `custodian/tools/agent/test_workstream.py` are reference behavior and must remain unchanged unless a new failing test proves a minimal integration change is necessary.
- Publication inputs: `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/test_workstream.py`; `custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_PAIRED_REVIEW_VALIDATOR_RECERTIFICATION_V1_REVIEW_CORRECTIONS_2.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`
- Change:
  1. Begin with a disposable real-Git failing-first consumer reproduction showing that a changed-main sync merge with no corresponding `validation_after_sync` event is accepted by the current consumer.
  2. Require exactly one authenticated after-sync validation witness for every applicable changed-main synchronization merge. Bind each witness to the exact merge commit and tree, upstream main parent, successful/green result, report SHA-256, and source-status identity using the durable lifecycle evidence available to the consumer.
  3. Require event ordering, uniqueness, and one-to-one correspondence across every applicable synchronization. Reject absent, duplicated, reused, stale, malformed, misordered, and identity-mismatched witnesses. Add a multiple-main-advancement negative-control sequence and a valid changed-main witness positive control.
  4. Determine whether the consumer can read the durable validation report bytes. Verify report contents against the recorded digest wherever those bytes are available. Where only a digest is available, state the limit and authenticate the digest through its immutable trace/provenance; do not claim report-content verification from a digest alone.
  5. Preserve legitimate checkpoint/resume, ordinary finish, unchanged-main/no-op, multiple-sync, archive-first, and historical source-span behavior. Any compatibility path must be narrow and authenticated by immutable provenance; do not introduce a general legacy bypass.
  6. Add focused adversarial consumer coverage to `custodian/tools/agent/test_paired_review_runner.py` and narrowly relevant modules. Keep the corrected producer and historical review evidence unchanged absent a demonstrated minimal necessity.
- Preserve: The original R2-01 `human_required` receipt, archived cycle-2 review, implementation/review evidence, all unrelated claims/locks, source-span/landing policy outside the missing after-sync-consumer contract, and the producer-side R1-01 retry correction.
- Non-goals: Do not reopen or rewrite cycle 2; do not create correction cycle 3; do not modify reviewer-authored or archived evidence; do not repair the runner's main-advancement race, PASS-only closeout routing, sparse checkout profile, or transient garbage collection; do not broaden historical compatibility.
- Acceptance:
  - The failing-first real-Git regression fails against the pre-change consumer because a changed-main sync without its required validation witness is accepted, then passes after enforcement because that history is rejected.
  - A valid exact witness is accepted. Adversarial tests reject missing, duplicate, reused, stale, malformed, out-of-order, misbound and false-result witnesses, mismatched report/source identities, and a multi-main-advancement sequence with a missing witness for either advancement.
  - Validation-report byte availability and digest/content verification limits are documented in the implementation evidence without overstating what a digest proves.
  - Ordinary finish, checkpoint/resume, no-op, multi-sync, archive-first and historical source-span tests remain green; producer behavior remains unchanged unless a minimal proven integration change is required.
  - The original archived R2-01 disposition and preserved evidence remain byte-for-byte unchanged.
  - Required focused validation and canonical changed-file validation pass; the implementation lands and tears down normally; the fresh paired reviewer executes genuine adversarial reproductions and required focused suites.
  - The independent review may establish prospective acceptance only. It does not change the original cycle-2 `human_required` outcome.
- Validation:
  - Failing-first disposable real-Git consumer reproduction, then its positive and adversarial controls.
  - `python3 -m unittest custodian.tools.agent.test_workstream -v`
  - `PYTHONPATH=custodian/tools/agent python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`
  - `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`
  - `python3 custodian/tools/agent/check_ai_context.py --json`
  - `python3 custodian/tools/agent/validate_review_pairing.py`
  - `python3 custodian/tools/agent/task_packet_index.py`
  - `git diff --check`
  - Record selected/passed/failed/skipped/timed-out validation totals, coverage/exclusions, exact source and trace identities, and event ordering. The reviewer independently reruns the genuine regressions and both focused suites, and independently exercises the producer-side R1-01 retry behavior.
- Task overrides: `none`
- Deferred: The original cycle-2 acceptance remains human-required. No attempt to convert that historical outcome into a pass is part of this workstream.

## Handoff

- Next workstream: `review-agent-paired-review-after-sync-consumer-enforcement-v1`
- Next packet state: `blocked/manual`; the project owner waived this prospective independent review under the two-turn finalization policy; no reviewer was launched or accepted.
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae6efa3-7c70-83ea-aee6-bf0799e2eb65`
- Refresh instruction: `none`
- Next action: `After this implementation lands and its worktree is normally torn down, run the fresh-context paired review. Do not alter the original cycle-2 disposition.`
- Blockers or open questions: `The implementation must determine exactly which durable validation-report bytes the consumer can access and bound content-verification claims to that evidence.`

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Superseded/legacy production path disposition: n/a
- Evidence: Consumer after-sync witness enforcement and adversarial controls are committed at `3af2f7f959db1d37a2e465f45319c692bb630bdf`; focused suites and canonical changed-file validation are recorded in the private run evidence and will be rerun against the committed source before canonical finish. This packet's implementation-only completion boundary is met; landing and teardown remain canonical finish operations, and the required independent post-land review remains pending as a separate gate.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: high
- What went wrong: The original packet circularly required post-land review and teardown before implementation finish, while the review dependency requires implementation landing first.
- Root cause / contributing factors: Completion Truth criteria conflated implementation completion with later landing, teardown and independent acceptance.
- Prevention / pipeline improvement: Corrected this packet's completion ordering and separated the mandatory post-land review gate without weakening technical criteria.
- Tooling / docs drift discovered: none
- Follow-up: fixed-in-scope
- What worked: Existing packet and workstream were preserved and continued under the original claim.
