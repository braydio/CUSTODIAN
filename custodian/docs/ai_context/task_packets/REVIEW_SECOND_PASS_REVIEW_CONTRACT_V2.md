# REVIEW: SECOND PASS REVIEW CONTRACT V2

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-second-pass-review-contract-v2`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `second-pass-review-contract-v2`
- Locks: `agent-workflow`
- Kind: `review`
- Review: `none`
- Reviewed main: `b32a10d`
- Review target workstream: `second-pass-review-contract-v2`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/SECOND_PASS_REVIEW_CONTRACT_V2.md`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the V2 second-pass review/correction contract is acceptance-driven, bounded, structurally enforceable, and does not turn optional improvements into an endless correction queue.
- Completion boundary: Review the landed review/correction templates, lifecycle/prompt guidance, structural validation, and representative fixtures against the implementation packet. Record a durable receipt and create a narrow correction pair only for confirmed blocking defects.
- Current measured state: This packet is dependency-gated and must not run until `second-pass-review-contract-v2` is complete/archived. The target contract replaces ad hoc second-pass correction authoring while preserving the existing independent post-land architecture.
- Evidence: Archived implementation packet and closing summary; live `AGENT_REVIEW_PACKET_TEMPLATE.md`, `AGENT_CORRECTION_PACKET_TEMPLATE.md`, `task_packets/README.md`, `review_runtime_change.md`, relevant validator/tests, and current dispatcher review-pairing behavior.
- Task-specific authority: Archived `SECOND_PASS_REVIEW_CONTRACT_V2.md`, `AGENT_TASK_PACKET_TEMPLATE.md`, `AGENT_REVIEW_PACKET_TEMPLATE.md`, `task_packets/README.md`, live review validator/dispatcher tests, and `AGENT_WORKSTREAM_LIFECYCLE.md`.
- Work surface: Review-only inspection of workflow docs/templates/validators/tests plus durable review receipt/follow-up packet authoring. Do not modify the reviewed implementation's workflow code/docs in this review workstream.
- Change: Review only. Verify stable finding identity, class/domain/disposition rules, correction threshold, delta correction template, manual-second-pass alignment, pipeline-feedback separation, V2 structural validation, legacy compatibility, and finite review-cycle behavior.
- Preserve: Reviewer independence, no implementation fixes in the review workstream, human decision gates, post-land review, finite correction cycles, generic dispatcher scheduling, and legacy compatibility.
- Non-goals: Do not redesign the review architecture, create new features, add scoring/ranking, auto-approve subjective decisions, or fix reviewed implementation directly.
- Acceptance: Confirm representative findings route correctly: blocking correctness defect to correction; material proof gap to correction; non-blocking issue to next-slice/deferred; optional improvement to deferred/no-action; subjective unresolved choice to human_required. Confirm correction packets reference finding IDs and remain delta-only. Confirm process findings use task feedback rather than polluting implementation corrections. Confirm structural validation and existing pairing tests remain green. If any blocking contract defect remains, scaffold the bounded correction pair.
- Validation: Run focused review-pairing/dispatcher tests, V2 packet validator tests available on live main, prompt/template contract checks, and changed-file validation. Inspect at least one synthetic or fixture review/correction lineage proving the disposition model.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`
- Deferred: Feedback analytics/dashboarding, review scoring, pre-land review, and subjective baseline automation.

## Review Focus

Prioritize:

1. acceptance remains the review anchor rather than style/taste;
2. stable finding IDs survive correction/re-review without ambiguity;
3. correction threshold avoids both under-correcting real defects and manufacturing work from improvements;
4. delta correction packets preserve original authority instead of duplicating it;
5. implementation findings and pipeline/process findings remain separate;
6. validation enforces structure without attempting subjective prose scoring;
7. manual second-pass use and automatic paired review converge on one classification/disposition model.

## Handoff

- Next action: Claim after `second-pass-review-contract-v2` lands and archives.
- Best starting files: archived implementation packet + closing summary, live review/correction templates, README lifecycle, review prompt, validator/tests.
- Blockers or open questions: none.
