# REVIEW: OPERATOR 2.5D WORKBENCH GUIDED INGRESS

- Packet schema: custodian.task_packet.v2
- Workstream: review-operator-2-5d-workbench-ingress
- Kind: review
- Status: ready
- Dispatch: auto
- Priority: P1
- Depends on: operator-2-5d-workbench-ingress
- Locks: operator-workbench-ui, operator-workbench-publish, operator-source-normalization, operator-art-generation-schema
- Review: none
- Review target workstream: operator-2-5d-workbench-ingress
- Review target packet: custodian/docs/ai_context/task_packets/archived/OPERATOR_2_5D_WORKBENCH_INGRESS.md
- Reviewed main: d6c94d38c99e58c96e5f5c7e46db8d290bfeb10f
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Visual review: none
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Review modes: code, architecture, asset-pipeline, workflow
- Review cycle: 0
- Max automatic review cycles: 2
- Goal: Independently verify the landed implementation against its archived packet and live behavior.
- Reviewed implementation acceptance: The archived implementation packet Acceptance section is the exact contract.
- Review evidence: Reuse implementation receipts/fixtures first; gather fresh evidence only where acceptance is not established.
- Correction threshold: Correct confirmed correctness/authority defects or material proof gaps through bounded correction + re-review; route polish to the next slice.
- Focused validation: Rerun the ingress smoke plus the archived packet's generation/path, SourceArtService, registration-profile, Workbench creation and Textual UI checks; independently exercise one legacy-96 creation/source session, one 128px 2.5D import, one same-semantic legacy counterpart, one stale-reference failure and one attempted 2.5D publish refusal; then `git diff --check`.
- Review focus: Guided intake must reuse WB25-1 target/workspace truth, reviewed New Animation and SourceArtService; prove generation-aware 128px creation/import, durable target/profile/reference provenance, safe resumability, explicit direction mapping, generation-scoped collision semantics, R0-01 workflow truth preservation, legacy compatibility and a fail-closed 2.5D publication boundary.
- Acceptance: Findings-first receipt with stable IDs; zero blocking defects/material proof gaps for pass; do not patch reviewed implementation.
- Non-goals: No redesign, implementation fixes, production art mutation, or successor implementation.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.

## Agent Handoff / Planning Decisions — 2026-10-08

Review against the refreshed WB25-2 contract and the **landed** WB25-1/R0-01 authorities, not the pre-WB25 assumptions.

Required review anchors:
- exact `AnimationSelection.art_generation` / `authoring_identity` identity is preserved end-to-end;
- direction workspace path comes from the landed `WorkbenchService.workspace(selection)`;
- New Animation generation support is additive and default-legacy compatible;
- SourceArtService 128px conversion/verification is real, while legacy 96 remains unchanged;
- target binding is durable in Source Session evidence and backward-readable;
- canonical collision inspection is scoped to the requested authoring generation;
- package manifests reference Source Session truth rather than duplicating normalization/review authority;
- explicit direction mapping is mandatory for combined packages/grids;
- same-semantic legacy fallback/runtime art does not block 2.5D authoring;
- no WB25-2 code path can publish/promote 2.5D art into production runtime.

## Procedure

Follow custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md from fresh context.

## Handoff

- Next workstream: operator-2-5d-workbench-polish-automation
- Next packet state: refresh-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Summary backlink: include exact Authoring chat URL
- Refresh reason: WB25-3 must consume the actual landed Source Session→Workbench handoff/session metadata and exact Art Agent seams.
- Next action: Return implementation/review evidence to the authoring chat and refresh the successor before claim.
- Blockers or open questions: successor intentionally draft until refresh
