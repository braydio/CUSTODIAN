# CORRECTION: PAIRED REVIEW VALIDATOR RECERTIFICATION R0-01

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-validator-recertification-v1-review-corrections-1`
- Category: `agent-ops`
- Authoring handoff: `auto`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-agent-paired-review-validator-recertification-v1`
- Locks: `workstream-finish-sync-provenance`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-validator-recertification-v1-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `fc07bc2d8013737dbc59a9115065ead4156a4535`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae6efa3-7c70-83ea-aee6-bf0799e2eb65
- Visual review: `none`
- Parent implementation: `agent-paired-review-validator-recertification-v1`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_VALIDATOR_RECERTIFICATION_V1.md`
- Parent review: `review-agent-paired-review-validator-recertification-v1`; `custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_PAIRED_REVIEW_VALIDATOR_RECERTIFICATION_V1.md`
- Findings addressed: `R0-01`
- Affected acceptance: Parent implementation acceptance 2 and 3: exact lifecycle binding and rejection of malformed, reused, or unsupported merge-witness evidence before publication or landing.
- Current defect/evidence: The parent review (run `20261031T095210Z-2a66bdc76153`, reviewed implementation `0de885c5c6c482381cbcee0bbfa125fcaf26af7c`) found `workstream.py::_source_span_sync_merge_witness_error` accepts a changed-sync witness by matching `changed`, `head`, and `main_sha` without requiring the unique matching `checkpoint_completed` event. The guard checks only top-level schema/workstream/run identity; it does not require `schema_version == 1`, mapping-valued `data` on every relevant event, or exact claim event OID/parent/subject. The canonical `_verify_split_landing_sync_merges` consumer enforces stronger constraints, but the producer guard and its tests do not establish that same contract. The complete reviewer-authored evidence and stable `R0-01` are preserved in the archived parent review.
- Goal: Make the finish-time producer guard reject every malformed, incomplete, reused, or falsely bound source-span merge witness that the canonical consumer rejects, while preserving supported legitimate finish and resume behavior.
- Completion boundary: Correct the producer-side witness validation and focused real-Git regressions for `R0-01`; land the implementation through the normal lifecycle and leave acceptance to the fresh paired review. Do not accept or rewrite the parent review.
- Current measured state: At `origin/main@fc07bc2d8013737dbc59a9115065ead4156a4535`, the parent review is archived complete with authenticated `findings` and `R0-01`; no correction pair exists yet. The producer guard in `workstream.py` remains weaker than the canonical source-span consumer described in the finding.
- Evidence: Archived parent review `custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_PAIRED_REVIEW_VALIDATOR_RECERTIFICATION_V1.md`, section `Independent Review`, finding `R0-01`; archived implementation packet and its acceptance contract; `custodian/tools/agent/workstream.py::_source_span_sync_merge_witness_error`, `_verify_split_landing_sync_merges`, and focused tests.
- Task-specific authority: This correction packet; archived parent implementation and review; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; existing source-span consumer contract in `custodian/tools/agent/paired_review_host_validation.py`.
- Work surface: Primary: `custodian/tools/agent/workstream.py`. Tests: `custodian/tools/agent/test_workstream.py` and relevant lifecycle coverage in `custodian/tools/agent/test_paired_review_runner.py`. `workflow_control.py` may change only if a demonstrated missing genuine lifecycle event requires an authentic producer change. Do not rewrite or weaken `paired_review_host_validation.py` to make the producer guard pass.
- Publication inputs: `.github/workflows/packet-authoring-handoff.yml`; `custodian/tools/agent/packet_authoring_handoff.py`; `custodian/tools/agent/test_packet_authoring_handoff.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/test_workstream.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/tools/agent/workflow_control.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/task_packet_index.py`; `custodian/tools/agent/validate_task_packet_authoring.py`; `custodian/tools/agent/check_packet_categories.py`; `custodian/tools/agent/check_ai_context.py`; `custodian/tools/agent/validate_review_pairing.py`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_CORRECTION_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/TASK_PACKET_CATEGORIES.json`; `custodian/docs/ai_context/TASK_PACKET_CATEGORY_AUTHORING.md`; `custodian/docs/ai_context/prompts/review_runtime_change.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_VALIDATOR_RECERTIFICATION_V1.md`; `custodian/docs/ai_context/task_packets/archived/REVIEW_AGENT_PAIRED_REVIEW_VALIDATOR_RECERTIFICATION_V1.md`
- Required correction:
  1. First reproduce `R0-01` with failing disposable real-Git tests against the pre-correction implementation.
  2. Require unique checkpoint evidence and ordered merge witnesses consistent with `_verify_split_landing_sync_merges`.
  3. Validate the full relevant event shape: supported schema version; mapping-valued `data`; exact workstream, run, packet, branch, and worktree identity; and exact claim OID, parent, and subject.
  4. Reject missing, duplicated, reordered, reused, contradictory, or falsely bound changed-sync, checkpoint, resume, and no-op events, including conflicting event combinations.
  5. Verify exact merge parent order, branch/worktree association, main ancestry, and deterministic tree identities before publication or landing.
  6. Preserve actual supported in-place finish and checkpoint/resume behavior. If a genuine producer event is missing, emit it only through its existing lifecycle authority; never synthesize historical evidence.
  7. Add negative tests proving invalid source history is rejected before publication or landing, and positive end-to-end tests proving legitimate branch publication and finish/resume still work.
- Preserve: Original parent review `R0-01`, reviewer-authored snapshot and hashes, archived implementation packet and acceptance, the separate historical multi-sync `R0-01`, coverage-correction and Procession claims/worktrees/locks, canonical source-span consumer authority, and unrelated workstreams.
- Non-goals: Historical review recovery; new bypasses or compatibility exceptions; source ownership expansion; release of another claim; generalized dispatcher redesign; broad review-runner refactoring; any edit to historical reviewer artifacts or verdicts.
- Acceptance:
  1. The first new disposable real-Git regression fails against the pre-correction producer guard and passes only after the correction.
  2. Producer preflight enforces the canonical consumer's complete lifecycle witness contract for every relevant source-span merge, including event uniqueness/order and exact identities.
  3. Negative tests cover absent, malformed, duplicate, reordered, reused, conflicting, wrong-run, wrong-claim, wrong-branch/worktree, wrong-parent/order, wrong-main, and wrong-tree evidence, and prove rejection before publication or landing.
  4. Positive real-Git tests prove supported ordinary finish, changed-main synchronization, checkpoint/resume, and no-op paths remain valid.
  5. The canonical validator and all relevant regressions pass without weakening `paired_review_host_validation.py` or fabricating lifecycle evidence.
  6. The archived parent review and its `R0-01`, reviewer evidence, protected claims, locks, and worktrees remain unchanged; correction completion does not itself accept the finding.
- Validation: Focused falsification first: `python3 -m unittest custodian.tools.agent.test_workstream -v`; `python3 -m unittest custodian.tools.agent.test_paired_review_runner -v`. Then `python3 custodian/tools/validation/run_validation.py --changed --json` with complete coverage; `python3 custodian/tools/agent/check_packet_categories.py <implementation packet> <paired review packet>`; `python3 custodian/tools/agent/validate_task_packet_authoring.py <implementation packet> <paired review packet>`; `python3 custodian/tools/agent/check_ai_context.py --json`; `python3 custodian/tools/agent/validate_review_pairing.py`; `python3 custodian/tools/agent/task_packet_index.py`; and `git diff --check`. Record actual counts, coverage, exclusions, failures, and timeouts.
- Task overrides: `none`
- Deferred: Any recovery or reclassification of historical review evidence; the separate runner behavior that can misroute a successful nonpassing disposition through PASS authentication; stale original-run `post_exit_recovery` metadata. These remain separate follow-ups and must not broaden this correction.

## Handoff

- Next workstream: `review-agent-paired-review-validator-recertification-v1-review-corrections-1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae6efa3-7c70-83ea-aee6-bf0799e2eb65
- Refresh reason: `none`
- Next action: `Implement and land the bounded R0-01 correction, then perform the fresh-context cycle-1 independent review.`
- Blockers or open questions: `The dependency review contains an unaccepted blocking R0-01; correction implementation and fresh independent re-review are required.`
