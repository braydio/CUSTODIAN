# CORRECTION: WB25-2 Saved Aseprite Contract Proof

- Packet schema: custodian.task_packet.v2
- Workstream: operator-2-5d-workbench-ingress-review-corrections-2
- Status: complete
- Dispatch: auto
- Priority: P1
- Depends on: review-operator-2-5d-workbench-ingress-review-corrections-1
- Locks: operator-workbench-ui, operator-workbench-publish, operator-source-normalization, operator-art-generation-schema
- Kind: correction
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, asset-pipeline, workflow
- Paired review workstream: review-operator-2-5d-workbench-ingress-review-corrections-2
- Review cycle: 2
- Max automatic review cycles: 2
- Reviewed main: 667370e3443818253112980497e2ee0d71f21d68
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Visual review: none
- Parent implementation: operator-2-5d-workbench-ingress-review-corrections-1; custodian/docs/ai_context/task_packets/archived/OPERATOR_2_5D_WORKBENCH_INGRESS_REVIEW_CORRECTIONS_1.md
- Parent review: review-operator-2-5d-workbench-ingress-review-corrections-1; custodian/docs/ai_context/task_packets/archived/REVIEW_OPERATOR_2_5D_WORKBENCH_INGRESS_REVIEW_CORRECTIONS_1.md
- Findings addressed: R1-01, R0-02
- Affected acceptance: Wrong-contract Workbench refuses completed reuse/package closure; READY recovery proves its exact editable target while preserving valid artist edits.
- Current defect/evidence: A real physical 12f/128px Aseprite saved document beneath unchanged 15f/128px target manifest passes process_cell and validate_package. Existing Workbench saved-document inspection rejects that same document; see R1-01 and the parent review summary.
- Goal: Derive ingress editable/completion proof from the exact physical saved Aseprite contract as well as existing target/Source Session/manifest evidence.
- Completion boundary: Close R1-01 / remaining R0-02 in the existing ingress/Workbench inspection owners; add focused physical-document controls; preserve the other three accepted fixes.
- Current measured state: R1-01 / remaining R0-02 fixed; ingress physically inspects saved document frames, canvas, and uniform timing before recovery or completion. Real 12f/128px, wrong-canvas, and unreadable document controls refuse without changing document, candidate, or handoff bytes; a real edited 15f/128px document resumes unchanged.
- Evidence: REVIEW_OPERATOR_2_5D_WORKBENCH_INGRESS_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md; /tmp/wb25-r1-independent-probes.json; operator_2_5d_ingress.py::_validate_workbench/_validate_ready_proof; animation_workbench.py::reconcile_saved_document_contract.
- Task-specific authority: Archived WB25-2/correction contracts and active Operator Workbench/Source Session design; existing Workbench owns saved-document inspection; ingress owns orchestration only. The current review confirms an objective contract gap and authorizes this bounded execution without a human design refresh.
- Work surface: custodian/tools/operator/operator_2_5d_ingress.py; minimal existing Workbench saved-document inspection helper if needed for shared read-only use; custodian/tools/validation/operator_2_5d_ingress_smoke.py; directly affected existing focused Workbench validation only.
- Required correction: Inspect the exact saved Aseprite document before terminal reuse, READY recovery, existing REVIEWED Workbench reuse/handoff and package closure. Refuse unreadable documents and physical frame/canvas mismatch against the bound target. Reuse the existing inspection authority; do not silently reconcile/migrate mismatched documents or overwrite artist edits. Keep failure read-only for document/candidate/handoff/production bytes and avoid repeated conversion/destructive handoff.
- Preserve: Source Session target/digest/profile/reference/plan authority; exact AnimationSelection.authoring_identity; direction workspace mapping; R0-01 crash recovery, R0-03 independent sibling progress, R0-04 default-root collisions; valid saved pixel edits; legacy-96 behavior and production bytes; sole guarded publisher and unconditional 2.5D publish refusal.
- Non-goals: No new import/creation/publisher authority, contract migration, UI redesign, network generation, runtime promotion, production art mutation, or WB25-3 polish work.
- Acceptance: R1-01/R0-02: real readable saved 12f/128px and 15f/wrong-canvas documents with unchanged valid 15f/128px manifests are refused in completed process_cell, validate_package and READY recovery; unreadable nonempty document also refuses. The existing valid 15f/128px document and a legitimate Aseprite pixel edit resume/close while preserving document bytes. A nonterminal READY cell restores receipts without conversion or destructive handoff when the saved contract is valid; mismatched READY and existing REVIEWED documents fail before handoff/canonical/runtime mutation. All preservation controls stay green.
- Validation: Add physical saved-document regressions first using real Aseprite documents and actual saved pixel edits, then run ingress, targets, asset-schema, SourceArtService, registration-profile, Workbench creation and Textual-enabled UI smokes. Use disposable fixtures; retain legacy-96 and attempted 2.5D publish-refusal controls. One run_validation.py --changed --json at closeout, Python compile checks and git diff --check.
- Task overrides: none
- Deferred: WB25-3 remains draft and requires the recorded authoring-chat refresh after successful cycle-2 re-review.

## Delta Rules

Address only R1-01 and remaining R0-02. Retain stable finding IDs. This is the final automatic correction cycle; unresolved blocking findings in its fresh review become human_required.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Evidence: The Workbench physical-document inspection is reused as a read-only operation from ingress. Completed reuse, package closure, and READY recovery refuse real 12f/128px, 15f/wrong-canvas, and unreadable saved documents without changing document/candidate/handoff bytes. A legitimate Aseprite pixel edit survives successful READY recovery byte-for-byte. Required focused checks, changed-file validation, compilation, and diff checks passed; see `OPERATOR_2_5D_WORKBENCH_INGRESS_REVIEW_CORRECTIONS_2_CLAUDE_SUMMARY.md`.

## Execution Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The first expanded smoke run tried to close an intentionally incomplete eight-direction package; the validation correctly rejected its pending N cell.
- Root cause / contributing factors: The added READY-recovery control reused a package whose N session had been staged earlier for a separate resumability check.
- Prevention / pipeline improvement: Keep the physical-document package-closure control on its own complete one-direction fixture; retain the multi-direction package only for the READY recovery path.
- Tooling / docs drift discovered: The claimed worktree had no code-review graph database; initialized and updated it before review.
- Follow-up: review-operator-2-5d-workbench-ingress-review-corrections-2
- What worked: Real saved Aseprite fixtures prove the physical contract independently from manifest claims while checking document and handoff preservation.

## Next Handoff

- Next workstream: review-operator-2-5d-workbench-ingress-review-corrections-2
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: none
- Next action: Claim the paired cycle-2 review from fresh context and independently verify R1-01 plus retained WB25-2 corrections.
- Blockers or open questions: none for implementation; unresolved blocking findings at this final automatic review cycle require a human decision.

## Independent Review

- Status: `passed`
- Review workstream: `review-operator-2-5d-workbench-ingress-review-corrections-2`
- Reviewed on main: `b59eeb3c526b8661944bce08922e6a66edf30f89`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Blocking defects: `0`
- Material evidence gaps: `0`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `none`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- Retained dispositions: `R1-01 fixed; R0-02 fixed; R0-01 fixed; R0-03 fixed; R0-04 fixed`
- Detailed review summary: `REVIEW_OPERATOR_2_5D_WORKBENCH_INGRESS_REVIEW_CORRECTIONS_2_CLAUDE_SUMMARY.md`
- Follow-up workstream: `none`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
