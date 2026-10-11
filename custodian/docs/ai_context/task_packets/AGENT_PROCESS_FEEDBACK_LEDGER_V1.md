# AGENT PROCESS FEEDBACK LEDGER V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-process-feedback-ledger-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `agent-workflow`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-process-feedback-ledger-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Independent provenance and deterministic inventory audit required`
- Reviewed main: `4b5ba4c4f88f25cbde281ca6f148da58cd5648b2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Visual review: `none`
- Summary backlink: Include the exact Authoring chat URL in every closing, review, recovery summary and Next Handoff.
- Goal: Create a read-only, source-linked, deterministic ledger of CUSTODIAN process feedback and unresolved follow-ups without modifying task state.
- Completion boundary: Deliver a CLI scanning root *_CLAUDE_SUMMARY.md and active/archived packet feedback receipts, a real-corpus inventory, deterministic JSON/Markdown, focused tests, validation ownership and scoped automation-backlog reconciliation.
- Current measured state: AGENTS.md prescribes custodian.task_feedback.v1 closing feedback and mirrored V2 Execution Feedback. check_ai_context.py checks only active complete V2 packets, not historical feedback; the existing automation backlog still says managed Ready/Auto markers are uninitialized despite the live README markers.
- Evidence: AGENTS.md Process Feedback/Next Handoff; custodian/tools/agent/check_ai_context.py; task_packet_contract.py; task_packet_index.py; AGENT_AUTOMATION_BACKLOG.md; existing root closing summaries.
- Task-specific authority: AGENTS.md feedback schema; existing task_packet_contract.py for packet grammar; dispatch.py and task_packet_index.py remain queue authorities.
- Work surface: Create custodian/tools/agent/process_feedback.py and focused tests; update validation_manifest.json and scoped workflow docs only.
- Change: Provide read-only scan --json and report --markdown. Parse actual heading sections, not fenced examples; support backticked values and legacy omissions. Link each result to source file, schema, workstream, outcome, friction, follow-up and provenance. Deduplicate only identity-proven packet/summary mirrors, preserve uncertainty as unclassified, and report missing/unparsed source metrics. fixed-in-scope stays author-reported; manual-follow-up stays unowned until explicit linked owner.
- Preserve: No historical rewrite, no task-state mutation, stable ordering/format, no inferred closure from claimed fixes; full-corpus denominator must be reproducible.
- Non-goals: No duplicate packet parser, LLM classification authority, automatic task claims, auto-fixes, web dashboard or retroactive legacy failure gating.
- Acceptance: 1) Each parsed source has path+identity+receipt provenance; 2) explicit mirror pairs count once; 3) missing/ambiguous feedback is labeled, not guessed; 4) unowned medium/high follow-ups are visible; 5) byte-stable repeated JSON and Markdown; 6) fenced fake sections/legacy omissions/duplicate mirrors/unknown owners fail anti-vacuity fixtures; 7) automation backlog reflects actual existing tools.
- Validation: Focused Python parser/corpus-fixture tests first, then twice-run real repository report equality; python3 custodian/tools/agent/check_ai_context.py --json; python3 custodian/tools/agent/validate_review_pairing.py; python3 custodian/tools/agent/task_packet_index.py; python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json; git diff --check.
- Deferred: Automated classification, auto-authoring corrections and external feedback connectors.

- Task overrides: `none`

## Handoff

- Next workstream: `review-agent-process-feedback-ledger-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Refresh reason: `none`
- Next action: `After implementation lands and archives, run the fresh-context paired review.`
- Blockers or open questions: `none`
