# CORRECTION: OPERATOR WORKBENCH ANIMATION CREATION SERVICE PUBLICATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-workbench-animation-creation-review-corrections-1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-operator-workbench-animation-creation`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, asset-pipeline, workflow`
- Paired review workstream: `review-operator-workbench-animation-creation-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `c5ba129967e0428702af95da476b8271f178efbe`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Visual review: `none`
- Parent implementation: `operator-workbench-animation-creation`; `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_ANIMATION_CREATION.md`
- Parent review: `review-operator-workbench-animation-creation`; `custodian/docs/ai_context/task_packets/archived/REVIEW_OPERATOR_WORKBENCH_ANIMATION_CREATION.md`
- Findings addressed: `R0-01`
- Affected acceptance: Valid previously absent full-body/modular creation can publish from OPUI and CLI through one guarded Operator art transaction, with schema validation, exact saved pixels, normalization and refreshed DORMANT catalog/browser truth.
- Current defect/evidence: `ui/service.py:888-889` reads unassigned function-local `identity`; its only assignment occurs later in the adopted-FX branch. Fresh real saved-Aseprite full-body and modular service publication attempts both raise NameError before mutation; existing smoke tests remain green. See `REVIEW_OPERATOR_WORKBENCH_ANIMATION_CREATION_CLAUDE_SUMMARY.md`.
- Goal: Make schema-valid creation publish through the shared service while rejecting invalid semantic/path contracts before mutation.
- Completion boundary: Fix the creation guard and add focused real-model/real-workbench service regressions for both templates; establish that the guarded transaction is reached and produces the parent acceptance outputs. Close through ordinary validation and paired re-review.
- Current measured state: Lower-level CREATE/rollback fixtures pass; UI/CLI real creation publication is unreachable. Saved manifest/document bytes remain intact on failure.
- Evidence: Parent review summary and Independent Review receipt; landed implementation `3e4a4df336ed963c096018319cc9208b33b39573`.
- Task-specific authority: Parent Workbench, Art Agent creation and Asset V2 specialized Operator authorities remain authoritative; no new publisher or intake route.
- Work surface: `custodian/tools/operator/ui/service.py::_validated_publication_paths`; existing creation/UI/mirror/art-worktree validation files; CLI publication call and UI consumers only as required by the regressions.
- Required correction:
  1. Bind creation semantic validation to explicit trusted selected identity and per-binding layer/owner authority, without dependence on the later adopted-FX branch variable.
  2. Add service-boundary tests for full-body and synchronized modular creation using the real model/workbench APIs. Do not satisfy these by the dual-fake service bypass or by directly calling lower-level publish alone.
  3. Prove valid saved creation reaches the guarded art publisher, preserves schema-derived publication allowlists, publishes exact saved pixels, normalizes to source-backed editing, and refreshes catalog/browser discovery with DORMANT truth when unwired. Downstream mocks may be used for targeted guard tests, but document which integrated stages use real tooling and retain the existing real art-checkout/pipeline checks.
  4. Add negative semantic owner/layer/identity/path and target-race cases so the fix cannot simply remove validation. Refusal must preserve saved document bytes and canonical preimages.
- Preserve: Single UI/CLI publisher; startup/readiness/recovery and receipt behavior; external-art inbox/source_work intake; no native inbox bounce; exact rollback; existing FX adoption and mirror behavior; no runtime/gameplay binding; current template/body contract.
- Non-goals: UX hierarchy redesign, new templates, external import wizard, autonomous generation, gameplay wiring, broad recovery rewrite.
- Acceptance:
  - R0-01: valid full-body and modular six-frame 96x96 saved sessions pass creation publication guard and invoke the guarded service transaction without NameError.
  - R0-01: successful service publication normalizes the saved session and exposes the new source/catalog identity with DORMANT truth; source/runtime RGBA matches authored pixels.
  - R0-01: corrupted owner/layer/semantic/path contracts and a target appearing after preview refuse publication without source overwrite or document loss.
  - R0-01: existing edit, FX adoption, mirror, readiness/recovery and scoped art checkout fixtures remain green.
- Validation: Extend/run focused Workbench UI/model fixtures first, then mirror and art-worktree fixtures; run existing Operator import-preflight/SpriteFrames/modular/runtime checks as needed to prove integrated new CREATE stages; one changed-file closeout JSON. Refresh Reviewed main to the actual correction target before archive.
- Task overrides: `none`
- Deferred: Optional interactive Textual pilot requires its declared dependency; no aesthetic gate is introduced.

## Handoff

- Next action: Auto-dispatch the paired cycle-1 re-review after this correction packet archives.
- Blockers or open questions: none for the bounded correction.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Superseded/legacy production path disposition: intentionally-preserved
- Evidence: `OPERATOR_WORKBENCH_ANIMATION_CREATION_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md`; real WorkbenchService publication passed for full-body and modular sessions, with schema/owner/layer/path guards, post-preview collision refusal, exact source/runtime pixels, manifest normalization, DORMANT discovery, and an 8-check changed-file sweep.

## Execution Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The first modular Godot smoke ran before this fresh worktree had a generated script-class cache and emitted parse/load failures.
- Root cause / contributing factors: The worktree was newly created and had not yet run the changed-file validation warm-up.
- Prevention / pipeline improvement: Run the task's changed-file validation before standalone Godot scripts that depend on the generated class cache.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: Saved-Aseprite full-body and modular sessions crossed the real UI/CLI service and guarded publisher callback in the same fixture.

## Next Handoff

- Next workstream: review-operator-workbench-animation-creation-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab
- Refresh reason: none
- Next action: Auto-dispatch the paired cycle-1 re-review; resume downstream cockpit/UX planning only after it passes.
- Blockers or open questions: The optional Textual interactive pilot remains unrun because its dependency is absent; service-level UI/CLI publication was exercised.
