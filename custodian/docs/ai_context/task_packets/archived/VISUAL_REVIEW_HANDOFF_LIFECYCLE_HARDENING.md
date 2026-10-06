# VISUAL REVIEW HANDOFF LIFECYCLE HARDENING

- Packet schema: `custodian.task_packet.v2`
- Workstream: `visual-review-handoff-lifecycle-hardening`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `agent-workflow, visual-review-handoff`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-visual-review-handoff-lifecycle-hardening`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `agent control-plane, Dropbox retention, and finish-gate change`
- Reviewed main: `4811bffc9e0ff66e2be1c07be632c8abaeb203db`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6a8afb3b-5934-83ea-a84a-4c7a4b7778fb`
- Visual review: `none`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery/closeout summary and final `## Next Handoff`.
- Goal: Make the CUSTODIAN visual-review lane an end-to-end autonomous handoff lifecycle: claims carry the authoring-chat/Dropbox route, visually gated agents return compact evidence to that exact ChatGPT conversation, reviewed Dropbox media is deleted by default, and durable closing summaries cannot silently drop authoring-chat provenance.
- Completion boundary: Update shared packet grammar, dispatcher receipts, `$custodian-next`, workstream finish gates, outbound review transport/cleanup, templates, agent instructions, indexes/current-state docs, and focused validation. Do not change runtime/gameplay or inbound implementation-input semantics.
- Current measured state:
  - Visual review already publishes compact evidence to `/CUSTODIAN/visual_review/<workstream>/<run-id>/` with `LATEST.json`, but it has no reviewed-evidence cleanup mode.
  - The connected Dropbox currently exposes `/CUSTODIAN/visual_review`.
  - Packet guidance requires authoring-chat backlinks, but `workstream.py finish` does not enforce the exact URL in closing summaries.
  - Dispatcher claim receipts do not project authoring-chat or visual-review routing metadata.
  - `$custodian-next` does not explicitly treat required subjective review as a same-workstream pause.
- Evidence: `publish_review_artifacts.py`; `VISUAL_REVIEW_HANDOFF.md`; `task_packet_contract.py`; `dispatch.py`; `workstream.py`; `.agents/skills/custodian-next/SKILL.md`; task/review templates; focused unit suites.
- Task-specific authority: root/local `AGENTS.md`; `VISUAL_REVIEW_HANDOFF.md`; `AGENT_TASK_PACKET_TEMPLATE.md`; `AGENT_REVIEW_PACKET_TEMPLATE.md`; `AGENT_WORKSTREAM_LIFECYCLE.md`; `task_packet_contract.py`; `dispatch.py`; `workstream.py`.
- Work surface: agent control-plane Python/docs, visual-review publisher/tests, validation manifest, current-state/index docs.
- Change:
  - Parse `Authoring chat`, `Refresh planning chat`, and `Visual review: none|conditional|required` through the shared packet contract.
  - Put authoring-chat, visual-review mode/root, and default retention in claim receipts and human claim output.
  - Fail finish when a packet with a recorded chat URL has a closing summary without the exact `Authoring chat: <url>` line.
  - Add `--authoring-chat`, `--retain-after-review`, `--reviewed-manifest`, and `--reviewed-by` to the visual-review publisher. Default manifests to `delete-after-review`; path-confine cleanup to one exact manifest run and remove `LATEST.json` only when it points there.
  - Treat a required subjective review as a pause in the current workstream. Return the exact authoring-chat URL + Dropbox manifest to ChatGPT web, then resume the same workstream after decision and run the emitted cleanup command unless retention was explicit.
  - Update all shared agent guidance/templates/indexes and register focused validation owners.
- Preserve:
  - Objective checks remain first; coding agents do not self-approve subjective art/game feel.
  - Dropbox credentials remain outside Git.
  - Existing compact evidence budgets and inbound `implementation_inputs` lane remain separate.
  - No automatic cloud cleanup occurs until review is explicitly recorded/resumed by the workflow.
- Non-goals: No runtime changes; no Dropbox credential management; no blanket deletion of historical review folders; no forced retention migration for old manifests; no automatic aesthetic decisions.
- Acceptance:
  - Claim JSON/human output exposes exact authoring chat, visual-review mode, canonical root, and delete-after-review default.
  - Shared packet parser accepts/validates visual-review metadata.
  - A packeted closing summary omitting a recorded chat URL fails the finish artifact gate.
  - Upload manifests carry authoring chat + retention policy + cleanup command.
  - Reviewed cleanup deletes only the exact validated run and matching latest pointer; explicit retain performs no deletion.
  - Agent docs/templates and `$custodian-next` route required review back to the same authoring conversation and do not claim unrelated work.
  - Focused tests and changed-file validation are green.
- Validation:
  - `python3 custodian/tools/agent/test_task_packet_contract.py`
  - `python3 custodian/tools/agent/test_dispatch.py`
  - `python3 custodian/tools/agent/test_workstream_artifacts.py`
  - `python3 custodian/tools/iteration/test_publish_review_artifacts.py`
  - `python3 custodian/tools/agent/validate_review_pairing.py`
  - `python3 custodian/tools/agent/check_ai_context.py --json`
  - `python3 custodian/tools/validation/run_validation.py --changed --json`
  - `git diff --check`
- Task overrides: `TASK OVERRIDE: this ChatGPT authoring session is implementing the control-plane/doc changes directly on its isolated agent branch; normal autonomous claim behavior is the output being changed, not the mechanism used to author this packet.`
- Deferred: Any provider-wide retention/TTL sweeper beyond exact reviewed-run cleanup.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: Focused tests and repository validation recorded in `VISUAL_REVIEW_HANDOFF_LIFECYCLE_HARDENING_CLAUDE_SUMMARY.md`; existing historical review runs are not bulk-deleted.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `Main was stable during the final authoring pass; no material workflow failure encountered.`
- Root cause / contributing factors: `n/a`
- Prevention / pipeline improvement: `The new parser/claim/finish/cleanup contracts make review routing and cleanup machine-visible rather than prose-only.`
- Tooling / docs drift discovered: `Task packet template prose required Authoring chat even though the copyable header omitted it; corrected.`
- Follow-up: `paired review`
- What worked: `Existing Dropbox publisher and shared task-packet grammar provided clean extension seams.`

## Handoff

- Next workstream: `review-visual-review-handoff-lifecycle-hardening`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6a8afb3b-5934-83ea-a84a-4c7a4b7778fb`
- Refresh reason: `none`
- Next action: `Run the fresh-context paired review against landed main.`
- Blockers or open questions: `none`
