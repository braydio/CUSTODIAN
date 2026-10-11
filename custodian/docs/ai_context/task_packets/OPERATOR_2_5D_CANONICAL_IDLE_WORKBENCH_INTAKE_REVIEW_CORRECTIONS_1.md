# CORRECTION: OPERATOR 2.5D CANONICAL IDLE WORKBENCH INTAKE

- Packet schema: custodian.task_packet.v2
- Workstream: operator-2-5d-canonical-idle-workbench-intake-review-corrections-1
- Status: draft
- Dispatch: manual
- Priority: P1
- Depends on: review-operator-2-5d-canonical-idle-workbench-intake
- Locks: operator-art-agent, operator-source-normalization, operator-workbench-ui, operator-art-generation-schema
- Kind: correction
- Review: auto
- Review stage: post-land
- Review modes: code, asset-pipeline, workflow
- Paired review workstream: review-operator-2-5d-canonical-idle-workbench-intake-review-corrections-1
- Review cycle: 1
- Max automatic review cycles: 2
- Reviewed main: 26167ea659057192e12b71288e5a2be793454dd7
- Parent implementation: operator-2-5d-canonical-idle-workbench-intake; custodian/docs/ai_context/task_packets/archived/OPERATOR_2_5D_CANONICAL_IDLE_WORKBENCH_INTAKE.md
- Parent review: review-operator-2-5d-canonical-idle-workbench-intake; custodian/docs/ai_context/task_packets/archived/REVIEW_OPERATOR_2_5D_CANONICAL_IDLE_WORKBENCH_INTAKE.md
- Findings addressed: R0-01
- Affected acceptance: The accepted source timing remains fps=null/unknown; Workbench editor defaults do not become authored or human-approved timing and cannot authorize review or runtime promotion.
- Current defect/evidence: All eight imported workbench.json files record timeline.fps=8.0 and timing_authority=true. Ingress hardcodes fps=8.0, while timing_payload_from_timeline treats the authority bit as permission to emit a timing payload.
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Goal: Keep imported idle Workbench preview timing editable while ensuring the 8 FPS UI default is explicitly non-authoritative until an approved timing value exists.
- Completion boundary: Correct the timing-authority contract for specialized 2.5D import and prove no source pixels, target bindings, legacy/runtime outputs or publication status changed.
- Current measured state: Source report has plan_fps=null and UNKNOWN_NOT_APPROVED; physical manifests have fps=8.0 and timing_authority=true.
- Evidence: Review finding R0-01; archived intake packet and report; eight independently inspected Workbench manifests; animation_workbench.timing_payload_from_timeline and operator_2_5d_ingress.py import construction.
- Task-specific authority: Archived parent implementation packet acceptance and design/02_features/animation/OPERATOR_2_5D_WORKBENCH_MIGRATION_ROADMAP.md; retain WB25-2 editable-workbench behavior and fail-closed publication rules.
- Work surface: custodian/tools/operator/operator_2_5d_ingress.py; custodian/tools/operator/animation_workbench.py only if needed for explicit authority representation; focused operator 2.5D ingress/review smokes.
- Required correction: Represent fps=8.0, if retained for editor preview, as non-authoritative; ensure timing_payload_from_timeline returns no authoritative payload and publication/review paths do not mistake the default for approved timing. Explicitly authored timing must retain existing behavior.
- Preserve: Exact source/candidate pixels, all eight generation-aware target identities, saved editable Workbench documents, unknown/null source timing, current WB25-4 receipt ownership, no runtime mutation/publication.
- Non-goals: Selecting production FPS, authoring timing, approving any direction, changing animation art, modifying runtime or WB25-6 cohort scope.
- Acceptance: (1) Imported default preview remains editable and visibly 8 FPS if required, but timing_authority is false and no timing payload/approval is generated. (2) An explicit timing input still produces the existing authoritative timing contract. (3) All eight intake cells remain target-bound/editable and pixel-identical; runtime and publication remain untouched. (4) Negative regression proves the 8 FPS default cannot satisfy timing approval or produce an effective review receipt.
- Validation: Focused ingress, Workbench timing/model, target, queue and review smokes; explicit-authority positive control and unapproved-default negative control; compare protected runtime/catalog/SpriteFrames hashes; changed validation and git diff --check.
- Task overrides: none
- Deferred: Human timing selection and direction QA remain outside this correction.

## Refresh Planning Authority
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Refresh instruction: Confirm this narrow correction remains the desired authority boundary before promotion; no timing value is proposed.

## Execution Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: blocked
- Friction severity: none
- What went wrong: not started; packet is parked pending planning refresh.
- Root cause / contributing factors: correction changes whether downstream tools may treat default timing as authoritative.
- Prevention / pipeline improvement: none
- Tooling / docs drift discovered: none
- Follow-up: none
