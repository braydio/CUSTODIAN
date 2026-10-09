# CORRECTION: WB25-1 Direction Workflow Truth

- Packet schema: custodian.task_packet.v2
- Workstream: operator-2-5d-workbench-cockpit-foundation-review-corrections-1
- Status: ready
- Dispatch: auto
- Priority: P1
- Depends on: review-operator-2-5d-workbench-cockpit-foundation
- Locks: operator-workbench-ui, operator-art-generation-schema, operator-animation-plan
- Kind: correction
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, workflow
- Paired review workstream: review-operator-2-5d-workbench-cockpit-foundation-review-corrections-1
- Review cycle: 1
- Max automatic review cycles: 2
- Reviewed main: 3c23a493992cdf8c20724d7d9c25c3235211c263
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Visual review: none
- Parent implementation: operator-2-5d-workbench-cockpit-foundation; custodian/docs/ai_context/task_packets/archived/OPERATOR_2_5D_WORKBENCH_COCKPIT_FOUNDATION.md
- Parent review: review-operator-2-5d-workbench-cockpit-foundation; custodian/docs/ai_context/task_packets/archived/REVIEW_OPERATOR_2_5D_WORKBENCH_COCKPIT_FOUNDATION.md
- Findings addressed: R0-01
- Affected acceptance: One structured projection truthfully reports coverage/workflow state; generation-aware session/workspace identity consumes real Workbench workflow evidence.
- Current defect/evidence: Projector probes family-level workbench.json while Workbench owns direction-level manifests; classifier reads persisted NEW / UNSAVED creation hint rather than current saved document state. The review summary records both isolated reproductions.
- Goal: Project each target direction's actual workspace workflow and current saved creation readiness truthfully.
- Completion boundary: Correct only the workflow path/classifier and add focused regression evidence; preserve the single target projection, accepted coverage/count/hash state, and all legacy/runtime behavior.
- Current measured state: Passed-publish direction manifest projects NONE; a saved creation document projects EDITING although the existing backend derives NEW / READY TO PUBLISH.
- Evidence: REVIEW_OPERATOR_2_5D_WORKBENCH_COCKPIT_FOUNDATION_CLAUDE_SUMMARY.md, finding R0-01; operator_animation_targets.py lines 115-133/159/187/192; WorkbenchService.workspace; animation_workbench.state.
- Task-specific authority: Archived WB25-1 contract, operator_asset_schema.py authoring identity, existing Workbench direction workspace and current saved document state. Accepted canonical profile/reference and audit remain unchanged.
- Work surface: custodian/tools/operator/operator_animation_targets.py; minimal shared read-only workflow/path helper only if needed; custodian/tools/validation/operator_animation_targets_smoke.py; focused Workbench UI/model checks and normal owned-truth context updates only.
- Required correction: Read each direction workspace manifest rather than its family parent. Derive saved creation readiness from current manifest/document evidence using existing backend authority or a bounded equivalent read-only projection; do not trust persisted creation.state as live readiness. Preserve stale-reference precedence and keep siblings/generations isolated. No manifest upgrades or writes during projection.
- Preserve: All legacy source/workspace/runtime paths; 69/1/68 and 544 inventory; accepted hashes; fallback/projected non-completion; browser snapshots/races; New Animation behavior; production resources/selectors and art bytes.
- Non-goals: No ingress orchestration, new state database, runtime cutover, art mutation, UI redesign, or unrelated workflow redesign.
- Acceptance: R0-01: a direction manifest with passed publish evidence projects RUNTIME_VERIFIED at that exact direction; no manifest projects NONE (or existing accepted-source INTAKE); independent sibling/generation manifests cannot change its state. A saved creation document differing from its blank baseline projects READY_TO_PUBLISH while unchanged/absent saved creation remains EDITING; stale profile/reference still projects STALE_REFERENCE. Projection must remain read-only and existing focused/UI checks pass.
- Validation: Add focused regressions for both reproductions and sibling/generation isolation; run operator_animation_targets_smoke.py, operator_animation_plan_smoke.py, operator_asset_schema_smoke.py, Textual-enabled operator_workbench_ui_smoke.py, one run_validation.py --changed --json after focused checks, git diff --check.
- Task overrides: none
- Deferred: Guided ingress, canonical QA, production cutover, and subjective visual review remain outside this correction.

## Handoff
- Next workstream: review-operator-2-5d-workbench-cockpit-foundation-review-corrections-1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: none
- Next action: Land the bounded correction and claim its paired re-review from fresh context.
- Blockers or open questions: none

## Execution Feedback
Complete the standard custodian.task_feedback.v1 receipt before archive.
