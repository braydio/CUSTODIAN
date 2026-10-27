# Workflow Governance Simplification V1: Risk-Proportionate Review Defaults

- Packet schema: `custodian.task_packet.v2`
- Workstream: `workflow-governance-simplification-v1`
- Status: `blocked`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `none`
- Kind: `implementation`
- Review: `none`
- Review modes: `none`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `0`
- Review rationale: `low-risk exemption: user-authorized, documentation/template-only change to future review selection; existing dispatcher, review, validation, and safety enforcement are not modified; focused contract checks provide direct proof`
- Reviewed main: `5992bd9d8f28cb568b3b8e655474ce51bfbac5f8`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae03e16-cd34-83e9-ba0e-82b8f95f7690
- Visual review: `none`
- Goal: Make ordinary new CUSTODIAN work default to proportional, evidence-driven review, so routine Standard changes do not require an independent paired review without a concrete risk justification.
- Completion boundary: Update active repository review-selection policy and new-packet authoring defaults for Express, Standard, and Protected work; prove new ordinary packets can use Review:none without creating a paired packet, while published and protected work keeps its existing gates. This workstream completes with normal validated landing and no paired review.
- Current measured state: On reviewed main, custodian/AGENTS.md already permits skipping packets for narrow low-risk fixes and a compact packet for ordinary work; task_packet_contract.py and dispatch.py already accept Review:none. But AGENT_TASK_PACKET_TEMPLATE.md and the task_packets/README.md policy still broadly default packeted engineering to Review:auto; CONTEXT.md repeats that blanket presumption. This is policy/documentation drift, not a demonstrated defect in dispatcher safety enforcement.
- Evidence: custodian/AGENTS.md (Agent Task Packets and Instruction Inheritance); custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md (Review Policy); custodian/docs/ai_context/CONTEXT.md (Agent Execution Workflow); custodian/docs/ai_context/task_packets/README.md (Paired Review); custodian/tools/agent/task_packet_contract.py (review none and pairing logic); custodian/tools/agent/dispatch.py (existing eligibility).
- Task-specific authority: Root AGENTS.md; custodian/AGENTS.md; AGENT_TASK_PACKET_TEMPLATE.md; existing task_packet_contract.py/dispatch.py behavior and focused authoring-validation tests.
- Work surface: custodian/AGENTS.md; custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md; custodian/docs/ai_context/CONTEXT.md; custodian/docs/ai_context/task_packets/README.md policy prose (do not hand-edit its managed index); directly stale governance text only. Existing validation tools are test-only, not proposed production-code edit targets.
- Publication inputs: `none` (all required tools and sources already tracked on main; no external scripts, files, fixtures, or assets).
- Change: Establish explicit three-lane guidance without adding a classifier or execution subsystem. Express: narrow reversible low-risk work may skip packet and independent review, retaining focused tests and Git safety. Standard: ordinary bounded engineering may use a compact packet; default Review:none when correctness and scope can be proven with focused tests, with a concise risk rationale but no special exemption ceremony. Protected: consequential persistence/save/load, concurrency, irreversible operations, authority cutovers, dispatch/review/validation enforcement changes, dangerous asset-pipeline writes, or material evidence uncertainty retain Review:auto and fresh independent acceptance. Change the template's default selection and risk rationale prose to match. Clarify that risk, reversibility, verification quality, and blast radius decide review rather than mere file count or the label runtime. Preserve human-owned visual/canon decisions. Do not change Review:auto metadata or review dependencies of already-published work. Keep this implementation itself documentation/template only. If an actual runtime/dispatch/review/validation-enforcement code change is required, STOP and report the precise invariant and proposed separately risk-reviewed follow-up rather than silently expanding this workstream.
- Preserve: Canonical dispatcher/workstream/RunTrace owners; remote claim and lock safety; provenance; immutable review dispositions; current packet pairing for Review:auto; existing dependencies; human gates; required validation; root checkout and user-file preservation; Asset Pipeline V2; current branch and review evidence.
- Non-goals: No changes to dispatch.py, workstream.py, paired_review_runner.py, task_packet_contract.py or enforcement/tests unless specifically needed to address a directly demonstrated failure (such changes require a new risk decision before proceeding). No new orchestrator, risk engine, telemetry subsystem, queue-wide reclassification, mass archive, review deletion, historical claim recovery, asset creation, runtime change, or future Pass B/C implementation.
- Acceptance: (1) New template and active guidance agree on three proportional paths with Standard Review:none as the ordinary default. (2) A representative ready/auto Standard V2 packet with Review:none and Paired review workstream:none parses, passes targeted authoring/pairing checks and needs no review packet. (3) A representative Protected Review:auto packet without its matching valid review remains rejected; existing accepted-review dependencies and safety instructions stay unchanged. (4) Original ready/auto review workstreams and historical packets are untouched. (5) Documentation drift introduced by this contract is reconciled without broad edits. (6) This packet has no paired review and completes with normal focused verification and safe workstream.py finish.
- Validation: Run `python3 custodian/tools/agent/validate_task_packet_authoring.py custodian/docs/ai_context/task_packets/WORKFLOW_GOVERNANCE_SIMPLIFICATION_V1.md`, `python3 custodian/tools/agent/task_packet_index.py`, `python3 custodian/tools/agent/test_task_packet_contract.py`, `python3 custodian/tools/agent/test_validate_task_packet_authoring.py`, and `python3 custodian/tools/agent/check_ai_context.py`; use relevant existing review-pairing tests and repository changed-file validation only as prescribed by the current validation recipe. Exercise Standard-no-review and missing-Protected-review fixtures without altering live claims. Do not silently waive red checks.
- Task overrides: `TASK OVERRIDE: user-authorized Review:none for this documentation/template-only governance correction; no paired review or retrospective waiver; stop and re-scope if changes to safety enforcement are necessary.`
- Deferred: Pass B (automatic administrative projections/evidence reuse), Pass C (legacy recovery containment), any changes to existing packet decisions, and implementation of new execution machinery.

## Execution Instructions

1. Inspect current origin/main and current repository AGENTS. Do a read-only dispatcher audit and verify this exact packet is the one to claim. The user has explicitly prioritized this P0 workstream. Do not use generic claim-next or pick another task.
2. Claim through `python3 custodian/tools/agent/dispatch.py claim workflow-governance-simplification-v1 --agent codex` and work in its returned isolated checkout. The repository's claimed branch/worktree and its current files, not the authoring SHA, are implementation truth.
3. Limit work to policy/template/doc changes and focused evidence. Use existing Review:none mechanics; do not add a new review control plane. If another live worker is editing the same policy files or a real claim/owner gate forbids safe action, report the actual conflict and preserve all existing work.
4. Validate focused checks, update only truly stale related prose, fill truthful Completion Truth / Execution Feedback / Handoff fields, commit the current workstream's root closing summary with the exact Authoring chat URL, and safely land through `workstream.py finish`. Do not run `land_main.py` directly. Root sync is fast-forward only if safe.
5. At completion, report the verified origin/main SHA, exact files changed, passing checks, old-versus-new review requirement for Standard and Protected examples, and any uncovered risk. No independent paired review or next workstream claim is required.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `no`
- Acceptance satisfied: `no`
- Superseded/legacy production path disposition: `n/a`
- Evidence: The three-path guidance and Standard/Protected pairing behavior are implemented and focused validation is green. Normal validated landing is not complete: `workstream.py finish` stopped on an origin/main merge conflict, and after the conflict was resolved it rejected the branch because the canonical archive transition commit `6040cb725b4ee16f602c2848ffd263b0bf4cf006` is no longer the current tip `9685d09e725121f15e25908f56a26278e9a69c83`. The supported conflict reconciliation only accepts generated managed-index changes; this conflict was in the active packet catalog outside that region. After recording the blocked status, `check_ai_context.py` also correctly reports that the newly published `OWNER_REVIEW_EXCEPTION_LANE_V1.md` dependency is not complete. That successor remains untouched. No landing or final main SHA is claimed.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `blocked`
- Friction severity: `high`
- What went wrong: A concurrent main update conflicted with this packet's removal from the active packet catalog. After preserving the upstream additions and resolving the conflict, `workstream.py finish` rejected the now-non-tip archive transition.
- Root cause / contributing factors: Finish recognizes only a tightly scoped managed-index conflict reconciliation, while this README conflict was in the active packet catalog outside the generated block. The task packet explicitly forbids expanding into lifecycle enforcement code. The newly published owner-review exception packet now depends on this task completing, so its dependency remains blocked.
- Prevention / pipeline improvement: Add an explicitly authorized, separately reviewed lifecycle path for this documented archive/catalog conflict shape, or ensure packet catalog updates serialize before archive transitions.
- Tooling / docs drift discovered: `workstream.py finish` cannot safely close this documentation task after a concurrent main update conflicts on the active packet catalog; it requires the canonical archive transition to remain the branch tip unless a supported source-span reconciliation applies.
- Follow-up: `manual-follow-up`
- What worked: Focused checks proved the review defaults and the workstream remains preserved on its claimed branch with no forced landing.

## Handoff

- Next workstream: `none`
- Next packet state: `human-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae03e16-cd34-83e9-ba0e-82b8f95f7690
- Summary backlink: Include this exact Authoring chat URL in the root closing summary.
- Refresh reason: A new, separately risk-reviewed lifecycle follow-up is needed to reconcile this active packet catalog conflict while preserving the archive transition and current main history.
- Next action: Review the exact finish invariant and authorize a bounded lifecycle follow-up; then resume this preserved workstream through a supported recovery path.
- Blockers or open questions: `workstream.py finish` rejects archive transition `6040cb725b4ee16f602c2848ffd263b0bf4cf006` because current tip is `9685d09e725121f15e25908f56a26278e9a69c83` after the main-sync conflict merge.
