# CORRECTION: WB25-2 Guided Ingress Resume and Collision Truth

- Packet schema: custodian.task_packet.v2
- Workstream: operator-2-5d-workbench-ingress-review-corrections-1
- Status: complete
- Dispatch: auto
- Priority: P1
- Depends on: review-operator-2-5d-workbench-ingress
- Locks: operator-workbench-ui, operator-workbench-publish, operator-source-normalization, operator-art-generation-schema
- Kind: correction
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, asset-pipeline, workflow
- Paired review workstream: review-operator-2-5d-workbench-ingress-review-corrections-1
- Review cycle: 1
- Max automatic review cycles: 2
- Reviewed main: 0d4612f52e064b48c2cf5a157a6c95aec4a553a8
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Visual review: none
- Parent implementation: operator-2-5d-workbench-ingress; custodian/docs/ai_context/task_packets/archived/OPERATOR_2_5D_WORKBENCH_INGRESS.md
- Parent review: review-operator-2-5d-workbench-ingress; custodian/docs/ai_context/task_packets/archived/REVIEW_OPERATOR_2_5D_WORKBENCH_INGRESS.md
- Findings addressed: R0-01, R0-02, R0-03, R0-04
- Affected acceptance: Idempotent restart/resume of verified Source Sessions and receipts; stale source/session/profile/reference failure before mutation; truthful editable Workbench/package completion; mixed-state eight-direction progress; same-generation semantic/frame-contract collision refusal.
- Current defect/evidence: The review summary contains real 15f/128px import probes: READY post-handoff state is rejected on restart; completed hints return after changed source/missing Workbench; service stops at first direction failure; OPUI default source/animations scan misses a 12f same-generation counterpart when creating 15f.
- Goal: Make the existing guided ingress resumable and truthful through all four confirmed review boundaries.
- Completion boundary: Correct only R0-01 through R0-04 in existing owners; add focused regressions; preserve the accepted generation/target/source authorities and publication refusal.
- Current measured state: Four confirmed blocking defects; all seven preexisting focused smokes pass and do not cover these regressions.
- Evidence: REVIEW_OPERATOR_2_5D_WORKBENCH_INGRESS_CLAUDE_SUMMARY.md; archived parent Independent Review receipt; operator_2_5d_ingress.py lines 178-214/240-257; ui/service.py lines 537-555; animation_workbench_model.py lines 113-123 and WorkbenchService default source root.
- Task-specific authority: Archived WB25-2 contract and landed WB25-1/R0-01 target/workspace truth; SourceArtService owns normalization/review/handoff proof; reviewed New Animation owns creation; operator_asset_schema owns generation canonical destinations; no runtime promotion in this correction.
- Work surface: custodian/tools/operator/operator_2_5d_ingress.py; custodian/tools/operator/ui/service.py; custodian/tools/operator/animation_workbench_model.py; minimal existing Source Session/Workbench helper only where required; custodian/tools/validation/operator_2_5d_ingress_smoke.py and directly affected focused UI/creation validation.
- Required correction: R0-01 validate and reuse READY handoff evidence after interruption before package receipt persistence without reconversion, rehandoff mutation or loss of valid artist edits. R0-02 validate current plan/profile/reference/source/session/candidate and target Workbench identity/frame/existence before terminal reuse and package completion; terminal strings never replace proof; preserve legitimate Workbench pixel edits. R0-03 process directions independently, retain durable BLOCKED reasons, progress eligible pending cells despite another failure, and report selected-cell/aggregate status without opening a missing Workbench. R0-04 derive the generation scan path correctly for source-parent, default source/animations, and already-generation-scoped roots; refuse alternate-frame semantic counterparts and preserve legacy behavior.
- Preserve: Default legacy-96 creation/source/edit/publish paths and bytes; exact AnimationSelection.authoring_identity; landed direction workspace/projector readiness; accepted profile/reference hashes; Source Session staleness/digest gates; explicit direction mapping; generation-scoped source authority; sole Workbench publish transaction and unconditional 2.5D publication refusal; production assets/resources/selectors.
- Non-goals: No successor polish/review/queue implementation, runtime cutover, art mutation, network generation, new normalization authority, UI redesign, or unrelated cleanup.
- Acceptance: R0-01 a real reviewed/staged READY session with nonterminal package metadata resumes to EDITABLE_WORKBENCH using its existing candidate/handoff/document and exact bytes without a conversion call; mismatched READY proof fails closed. R0-02 changed source/plan/profile/reference/session/candidate or absent/wrong-target/wrong-contract Workbench refuses completed reuse and package closure; unchanged valid completed cells including edited Workbench pixels resume without destructive writes. R0-03 an eight-direction fixture with completed NE, blocked N and pending later valid directions progresses later directions in one service invocation and on restart, retains blocked reasons, and never fabricates a selected Workbench. R0-04 the actual default OPUI source/animations root rejects an existing same-generation 12f/128px semantic counterpart for requested 15f; source-parent and generation-scoped root controls agree; a legacy-96 counterpart remains allowed for 2.5D creation.
- Validation: Add the four focused regressions first; run ingress, targets, asset-schema, SourceArtService, registration-profile, Workbench creation and Textual-enabled UI smokes; retain explicit legacy-96 controls and attempted 2.5D publish refusal; one run_validation.py --changed --json at closeout, Python compile checks and git diff --check. Use disposable fixtures, no production art writes.
- Task overrides: none
- Deferred: WB25-3 polish automation remains draft and needs the recorded authoring-chat refresh after this correction passes independent re-review.

## Delta Rules

Address only R0-01 through R0-04. Preserve original finding IDs in the paired re-review as fixed/unresolved/regressed; new findings use cycle 1 IDs. No feature redesign.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Evidence: READY handoff sessions resume from the existing reviewed candidate, idempotent handoff proof, and exact target Workbench without reconversion or document rewrite. Terminal reuse and package closure revalidate current source, target/profile/reference/plan authority, Source Session candidate/review/handoff, and Workbench identity/frame contract/existence while retaining edited document bytes. Direction packages continue after per-cell failures and the UI reports aggregate plus selected-cell state without opening a missing Workbench. Creation collision scanning resolves source-parent, default `source/animations`, and generation-scoped roots. Focused regressions and all required changed-file checks passed; see `OPERATOR_2_5D_WORKBENCH_INGRESS_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md`.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: The parent implementation's happy-path smokes did not exercise the four persistence/collision boundaries identified by fresh review. Direction-set UI expected one process return value, so partial progress needed a structured result path. The graph database was absent in the newly claimed worktree and required initialization before change analysis.
- Root cause / contributing factors: Terminal package state was treated as proof; the interrupted handoff boundary was not modeled; a direction comprehension propagated the first exception; the default source root was already `source/animations` but the generation path was appended beneath it.
- Prevention / pipeline improvement: Added direct crash-window recovery, terminal source/session/candidate/workbench verification, independent direction progression and UI no-open coverage, plus all three source-root shape controls and alternate-frame collision regression. Final changed-file sweep ran after the last code change.
- Tooling / docs drift discovered: `none`
- Follow-up: `review-operator-2-5d-workbench-ingress-review-corrections-1`
- What worked: Focused fixtures used disposable source sessions and preserved the edited Workbench document byte-for-byte during READY recovery.

## Handoff

- Next workstream: `review-operator-2-5d-workbench-ingress-review-corrections-1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: `none`
- Next action: Claim the fresh-context paired re-review and verify R0-01 through R0-04 against the landed correction.
- Blockers or open questions: `none`
