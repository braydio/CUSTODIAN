# VISUAL REVIEW DROPBOX LIFECYCLE HARDENING

- Packet schema: `custodian.task_packet.v2`
- Workstream: `visual-review-dropbox-lifecycle-hardening`
- Status: `in_progress`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `agent-workflow, visual-review-transport`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-visual-review-dropbox-lifecycle-hardening`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial agent-workflow and external-evidence lifecycle change`
- Reviewed main: `7a8ad89c84263043d2fb127576ba0aba47789f06`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6a8afb3b-5934-83ea-a84a-4c7a4b7778fb`
- Visual review: `none`
- Goal: Make subjective visual review a complete authoring-chat round trip: autonomous agents receive the exact authoring chat and canonical Dropbox review root at claim time, publish compact evidence with the authoring chat embedded in its manifest, stop for ChatGPT/user judgment, then programmatically delete reviewed remote evidence by default unless retention was explicitly requested.
- Completion boundary: Update shared agent instructions/templates, packet parsing/claim receipts, workstream summary-backlink enforcement, visual-review publisher/cleanup tooling and focused tests/docs. Preserve the new ready/auto dependency-driven dispatch policy. Do not change Dropbox implementation-input semantics or allow autonomous agents to self-approve subjective aesthetics.
- Current measured state: Latest main already defaults executable packets to ready/auto with dependencies as claim gates and requires authoring-chat backlinks by prose convention. The visual-review publisher writes compact bundles and LATEST.json but its manifest does not carry authoring-chat/retention metadata and it has no reviewed-evidence cleanup command. Dispatch receipts do not surface the packet's authoring chat or visual-review root, and workstream finish proves a committed summary exists but does not programmatically prove the required authoring-chat backlink is present.
- Evidence: `AGENTS.md`; `custodian/AGENTS.md`; `.agents/skills/custodian-next/SKILL.md`; `custodian/tools/agent/{task_packet_contract.py,dispatch.py,workstream.py}`; packet/review/correction templates; `VISUAL_REVIEW_HANDOFF.md`; `publish_review_artifacts.py`; focused tests and validation ownership.
- Task-specific authority: Root/local AGENTS own agent behavior; shared packet parser/dispatcher/workstream own autonomous assignment and finish gates; `VISUAL_REVIEW_HANDOFF.md` + `publish_review_artifacts.py` own outbound review evidence; Dropbox connector/rclone credentials remain external.
- Work surface: Root/local agent guidance; task/review/correction templates and packet README/lifecycle/tooling docs; `.agents/skills/custodian-next/SKILL.md`; `task_packet_contract.py`, `dispatch.py`, `workstream.py` and focused tests; `publish_review_artifacts.py` + focused tests; validation manifest; CURRENT_STATE/FILE_INDEX/AGENT_TOOLING_BY_ASK and Moment Forge visual-review wording where directly stale.
- Change: Add authoring-chat and visual-review metadata to the shared packet/claim projection without invalidating legacy packets; include authoring chat + canonical `/CUSTODIAN/visual_review/<workstream>/` in autonomous claim receipts; fail workstream finish when a packet that records an authoring chat has a committed closing summary missing that exact backlink; embed authoring chat and delete-after-review retention policy in new visual-review manifests; add an idempotent exact-run `--cleanup-reviewed` path that purges only a validated v2 run and clears LATEST only when it points to that run; teach agents/ChatGPT authoring conversations to review the Dropbox manifest directly and return a structured verdict; after the verdict reaches the execution agent, delete reviewed evidence automatically unless the user/packet explicitly requested retention.
- Preserve: Ready/auto dependency gating and lock semantics; paired-review fresh-context rules; deterministic validation-first visual economy; Dropbox credential boundaries; immutable inbound `implementation_inputs`; Git as durable implementation/evidence-summary authority.
- Non-goals: No general Dropbox garbage collector; no time-based deletion of unreviewed evidence; no ChatGPT-side destructive deletion dependency; no automatic subjective verdict; no repository mirroring in Dropbox; no change to Asset Pipeline V2.
- Acceptance: Claim receipt exposes exact authoring chat and canonical visual-review root; new packet templates record Authoring chat; finish rejects a committed closing summary missing a recorded authoring-chat backlink and accepts the exact backlink; v2 visual-review upload manifest/payload records authoring chat and default delete-after-review policy; explicit retain overrides deletion policy; cleanup validates workstream/run/schema/policy before purging exactly one run, is idempotent after successful cleanup, clears matching LATEST but not a newer pointer, and refuses v1/retained/identity-mismatched evidence; agent docs route subjective review to the exact authoring chat with Dropbox manifest path and require execution-agent cleanup after review; focused unit/AI-context validation ownership covers the changed tooling.
- Validation: `python3 -m unittest custodian.tools.iteration.test_publish_review_artifacts`; focused agent workflow tests for packet parsing/dispatch receipt/workstream summary backlink; `python3 custodian/tools/agent/check_ai_context.py`; `python3 custodian/tools/agent/validate_review_pairing.py`; `python3 custodian/tools/validation/run_validation.py --changed --json`; `git diff --check`.
- Task overrides: `TASK OVERRIDE: this workflow task may modify shared agent-control-plane instructions, claim receipt metadata, finish gates, and the outbound Dropbox visual-review transport/cleanup lifecycle; it must not delete any existing user Dropbox evidence during implementation/testing except unique sacrificial fixture paths created by focused tests.`
- Deferred: Time/TTL-based orphan cleanup for never-reviewed bundles remains separate; inbound implementation handoff retention remains unchanged.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `none`
- What went wrong: `pending execution`
- Root cause / contributing factors: `pending execution`
- Prevention / pipeline improvement: `pending execution`
- Tooling / docs drift discovered: `pending execution`
- Follow-up: `pending execution`
- What worked: `pending execution`

## Completion Truth

- Schema: `custodian.task_completion.v1`
- Goal satisfied: `no`
- Completion boundary satisfied: `no`
- Acceptance satisfied: `no`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `implementation in progress`

## Next Handoff

- Next workstream: `review-visual-review-dropbox-lifecycle-hardening`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6a8afb3b-5934-83ea-a84a-4c7a4b7778fb`
- Refresh reason: `none`
- Next action: `Run fresh-context post-land review of the claim/finish and Dropbox cleanup safety boundaries.`
- Blockers or open questions: `none`
