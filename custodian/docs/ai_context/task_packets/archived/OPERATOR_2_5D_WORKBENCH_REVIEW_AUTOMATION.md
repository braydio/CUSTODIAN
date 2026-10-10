# OPERATOR 2.5D WORKBENCH REVIEW AUTOMATION + RUNTIME SANDBOX

> REFRESHED / READY FOR IMPLEMENTATION  
> WB25-3, its R0-01 proposal-integrity correction, and the fresh cycle-1 re-review are complete. Consume the landed polish/apply boundary exactly; do not let review receipts, family matrices, or sandbox requests become mutation or publication authority.

- Packet schema: custodian.task_packet.v2
- Workstream: operator-2-5d-workbench-review-automation
- Status: complete
- Dispatch: auto
- Priority: P1
- Depends on: review-operator-2-5d-workbench-polish-automation-review-corrections-1
- Locks: operator-workbench-ui, operator-art-agent, operator-review-automation, operator-runtime-preview
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, workflow, visual, runtime
- Paired review workstream: review-operator-2-5d-workbench-review-automation
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: substantial engineering default
- Reviewed main: 119fa1a19427dce838977422d5186e3624e3457e
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Visual review: conditional
- Goal: Make exact-current QA, 8-direction family review, generation-aware sequence review, structured review receipts, and a bounded real-Godot sandbox one guided acceptance path so 2.5D art can become truthfully RUNTIME_VERIFIED without changing production generation selection.
- Completion boundary: Add one review authority over the landed target/Workbench/polish evidence, a truthful family matrix, backward-compatible generation-aware review sequences, hash-bound per-leaf review receipts, and a debug-only Godot sandbox that displays exact selected 128px Workbench pixels on a real Operator context. No 2.5D source publication, runtime-generation cutover, selector/catalog mutation, gameplay-semantic mutation, or autonomous art approval.

## Agent Handoff / Planning Decisions — 2026-10-09

**WB25-3 is accepted. Do not reopen its architecture. The review slice must consume it rather than create a second QA or proposal engine.**

### Accepted predecessor truth

- `Operator2DPolish.attach()` binds the exact existing `operator_2_5d_128` Workbench to the ordinary Art Agent session; it does not recreate or reconcile the document.
- `Operator2DPolish.analyze()` re-inspects the physical Workbench, renders current frames, consumes masks/landmarks/current metrics, adds temporal/baseline/component diagnostics, runs the existing Art Agent QA owner, and writes `polish_analysis.json`.
- QA schema is the live `custodian.operator_art_qa.v2`: severities are `critical`, `major`, and `advisory`, with class-specific findings. Do not restore obsolete planning labels such as HARD_FAIL/STRUCTURAL_WARN as a second taxonomy.
- WB25-3 correction R0-01 is mandatory: `Operator2DPolish.apply()` never trusts caller proposal geometry/deltas. It re-inspects the document, re-renders current pixels, reloads masks/landmarks, re-derives the eligible proposal, and only then delegates a narrow `erase_pixels` or `move_region` operation through Art Agent scope/journal/undo.
- Review automation may display or retain proposal/finding data, but **a receipt or cached proposal is never mutation authority**. Any later apply still goes through the corrected WB25-3 boundary.
- Accepted canonical authority remains profile SHA `05e92192af68b2f4e7516f59a0938e536926f3525a31b42dd7695f61d77ca761` and normalized-reference SHA `e529df0e0ceaeb941f67ed18ce93799755053b7c516a9f02a5b6929248e25fb9`.
- 2.5D publication remains unavailable before WB25-6. WB25-4 may verify runtime presentation in a sandbox, but it may not write canonical 2.5D source, generated runtime PNGs, `operator_runtime_manifest.generated.json`, `operator_runtime_frames.tres`, or production selector policy.

### Live seams the old draft did not know

- `operator_animation_targets.project_targets()` is still the generation-aware leaf/family coverage/workflow projection authority. Family review must group these records; it may not maintain its own completion counters.
- `WorkbenchService.preview()` intentionally refuses non-legacy selections. WB25-4 must add an exact 2.5D review-frame loader over the landed Workbench/Art Agent render evidence rather than silently falling back to legacy runtime pixels.
- `ReviewSequence` / `TimelineClip` are currently schema v1 and generation-blind; the existing generic preview provider resolves semantic identity without `art_generation`. WB25-4 must extend this authority backward-compatibly instead of creating a second 2.5D sequence format.
- Current Motion launch writes `custodian.operator_motion_request.v2` with `source=runtime` and resolves `operator_runtime_frames.tres`. It is useful semantic/timing precedent but **cannot be reused unchanged** for 2.5D sandbox proof.
- `animation_workbench.inspect_saved_document_contract()` already returns physical `frames`, `width`, `height`, and per-frame `durations`; sandbox/sequence timing must use those current saved-document facts. Do not invent a 12 FPS default for the first family, whose authoring FPS was deliberately left unknown.
- Production presentation doctrine remains strict: `OperatorBodyPresenter` owns body-layer visibility. A debug sandbox may add a bounded debug presentation owner/seam if needed, but must not directly toggle production body-layer visibility from an arbitrary tool script.

### Review-state doctrine

WB25-4 owns **review evidence**, not publication state.

- Review receipt may derive/report current publication readiness/state from the Workbench/target projection, but may never write or promote it.
- `RUNTIME_VERIFIED` in WB25-4 means: exact current target/Workbench/profile/reference hashes match the receipt; objective review is non-blocking; required human review is satisfied; and the hash-bound Godot sandbox proof passed.
- A later document/source/profile/reference/timing change makes the receipt stale and clears effective verification.
- `PUBLISHED` remains a separate later authority. Before WB25-6 the truthful 2.5D published count is expected to be zero; do not manufacture publication merely to satisfy the queue vocabulary.
- WB25-5 must be able to derive its queue from `project_targets()` + these receipts. No new stored progress database.

- Current measured state: WB25-3 landed and its R0-01 correction/re-review passed with zero remaining findings. The exact existing 2.5D Workbench can be attached to Art Agent; physical frame/canvas/timing is inspectable read-only; polish analysis now contains current QA + temporal/baseline/components and proposals; apply re-authenticates proposal geometry/registration against a fresh render before mutation. Target projection already owns generation-aware coverage/workflow/stale-reference state. Existing Sequence and Motion tooling remain legacy-generation-shaped, and there is no 2.5D review receipt owner or debug runtime presenter.
- Evidence: `OPERATOR_2_5D_WORKBENCH_POLISH_AUTOMATION_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md`; `REVIEW_OPERATOR_2_5D_WORKBENCH_POLISH_AUTOMATION_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md`; `operator_2_5d_polish.py`; `operator_animation_targets.py`; `animation_workbench.inspect_saved_document_contract`; `art_agent/qa.py`; `ui/service.py`; `animation_preview.py`; `animation_motion_preview.py`; `operator_motion_calibration.gd`; `operator_body_presenter.gd`; runtime animation authority docs.
- Task-specific authority: landed WB25-1 target projection; WB25-2 exact target/Workbench physical contract; corrected WB25-3 QA/polish/apply boundary; existing Sequence/Motion review semantics; `OperatorBodyPresenter` for body visibility; `OperatorAnimationSelector` + generated runtime package as immutable production runtime authority.
- Work surface: recommended new pure owner `custodian/tools/operator/operator_2_5d_review.py`; `ui/service.py`, `ui/state.py`, `ui/app.py` and one bounded review/family surface; `animation_preview.py` only for additive sequence-v2/generation compatibility; existing polish/Art Agent code read-only except a proven review API adapter; recommended debug sandbox under `custodian/tools/operator/runtime_preview/` and `custodian/scenes/debug/`; `operator_body_presenter.gd` / presentation-controller or the smallest Operator debug accessor only if required to preserve sole visibility authority; focused Python/UI/Godot validation. Do not touch production sync/build/selector/generated-resource code.

- Change:
  1. Add one `Operator2DReview`-class owner. It accepts an exact `AnimationSelection(authoring_generation=operator_2_5d_128)`, resolves the exact target record/workspace/Art Agent session, re-inspects current physical document contract, and consumes current `Operator2DPolish.analyze()` / QA output. It does not duplicate metrics, proposal rules, masks, landmarks, profile coordinates, or target projection.
  2. Add a deterministic ignored per-leaf receipt path under `.ai/operator_animation_workbench/review_receipts/operator_2_5d_128/<profile>/<group>/<action>/<direction>.json`. Bind at least: schema; authoring identity; exact Workbench manifest/document hashes; current rendered-frame/source digest; physical frame/canvas/durations; canonical profile/reference SHA; QA status/findings digest; human-review status/provenance when required; sandbox request/result digests; and effective `runtime_verified`.
  3. Receipt staleness is fail-closed. Any authoring identity, Workbench document/manifest hash, rendered-frame digest, profile/reference SHA, physical frame/canvas/duration contract, or sandbox request/result mismatch invalidates effective verification. A stale receipt may remain as history but never counts as current queue/review truth.
  4. Map live QA honestly: `RED`/critical blocks objective completion; `NEEDS_HUMAN_REVIEW`/major requires explicit human disposition; `YELLOW` advisory findings remain visible but do not become invented blockers unless an existing finding class says otherwise; `GREEN` is objectively clean. Do not auto-approve subjective art direction.
  5. Add FAMILY REVIEW by grouping the exact `project_targets()` leaves for one generation/profile/group/action. Show all required directions and each leaf's coverage, workflow, stale flag, current QA/review state, human gate, sandbox state, and effective verification. `MISSING`, `PROJECTED`, `LEGACY_FALLBACK`, stale, or absent-direction cells remain visibly incomplete and can never be counted as reviewed 2.5D.
  6. Family review owns no counters. Family completion is derived from required target directions/layers + current receipts on every read. One verified direction cannot mark siblings complete.
  7. Extend `ReviewSequence` additively to schema v2 with `TimelineClip.art_generation` appended/defaulted to `legacy_96` so positional v1 constructors remain compatible. Read v1 as legacy; write v2 when generation-aware clips are present. Timeline lookup must match generation as well as semantic identity.
  8. Keep one sequence editor/authority. Add a generation-aware clip-loader seam: legacy clips keep using `AnimationPreviewProvider`; 2.5D clips load exact current Workbench review frames. Do not make the generic legacy provider pretend 2.5D runtime art exists.
  9. Add presets only when their exact component identities exist: idle→walk→idle; relaxed→draw→ready; fast01→02→03→04→ready; block enter→hold→hit→hold; dodge→recovery. Derive clip timing from the exact saved-document duration contract or already-authored review timing. If timing/identity is absent, mark the preset unavailable/incomplete; never invent gameplay windows or a fallback FPS.
  10. Reuse `motion_event_markers()` / existing gameplay contact metadata only as semantic review annotations. Missing metadata stays missing; review tooling cannot create combat timing facts.
  11. Add one immutable local runtime-preview bundle under `.ai/operator_animation_workbench/runtime_preview/<request-id>/`. Copy/export the exact current selected Workbench frames into the bundle, record per-frame durations and all authority hashes, and hash the request. The Godot process must revalidate the request/frame bytes before display.
  12. Add a debug-only Godot sandbox that instances the real Operator scene plus real Camera2D/world presentation context, but loads selected 2.5D full-body frames directly from the request bundle into an in-memory debug `SpriteFrames`/body presenter. It must not read selected pixels from production runtime manifests/resources and must accept 128px `full_body` directly without lower/upper decomposition.
  13. Preserve production body-visibility authority. If a new debug body owner or narrow presenter accessor is required, route acquisition through `OperatorBodyPresenter` and keep it sandbox-only. No arbitrary tool script may write production Operator body `.visible` state directly. The sandbox may be an isolated fresh Operator instance so teardown can free the whole preview context rather than reconstruct live gameplay state.
  14. Sandbox preserves the Operator root/world position, visual anchor/scale, BlobShadow/contact relation, fake/presentation elevation, and camera framing appropriate to the real scene. It must not advance gameplay semantics merely to animate review pixels.
  15. Before sandbox launch capture hashes of `operator_runtime_manifest.generated.json`, `operator_runtime_frames.tres`, generation policy (if present), and selected production runtime assets. After teardown prove them unchanged. No call to runtime sync/build/publish/selector mutation is allowed.
  16. A successful sandbox emits a structured result bound to the request hash and observed presentation facts. Only the review owner may project that evidence into a current receipt; the sandbox does not edit queue/Workbench/plan state.
  17. Subjective unresolved art direction produces one compact visual-review handoff only after objective QA/family/sequence/sandbox checks. The returned human decision is hash-bound to the exact receipt evidence. If those pixels/hashes later change, that decision is stale.
  18. Review UI may expose WB25-3 proposals and an explicit Apply action, but Apply must continue calling the corrected `WorkbenchService.polish_apply()` / `Operator2DPolish.apply()` boundary. Never construct Art Agent operations from cached review-receipt coordinates.

- Preserve: exact WB25-1 target projection; WB25-2 Source Session/physical-document authority; WB25-3 corrected proposal/apply/journal/undo semantics; accepted profile/reference/root semantics; legacy Sequence/Motion behavior; production Operator selector/runtime package; gameplay timing/contact authority; legacy browser/preview.
- Non-goals: no 2.5D publication; no runtime generation cutover; no queue/progress prioritization; no generation brief exporter; no combat timing/balance change; no second QA engine; no automatic human/art approval; no network generation; no production save-game/runtime-policy change.
- Acceptance: (1) an exact current 2.5D leaf produces a receipt bound to current Workbench/render/profile/reference/physical timing hashes; changing any bound input makes it stale and removes effective verification; (2) forged/stale cached polish proposals displayed by REVIEW still cannot mutate unless WB25-3 fresh re-derivation accepts them; (3) an 8-direction family matrix derives every cell from target projection + receipts and leaves missing/fallback/projected/stale siblings incomplete; (4) sequence v1 loads unchanged as legacy, v2 round-trips art generation, and a mixed legacy/2.5D fixture selects the correct source for every clip without identity aliasing; (5) preset timing comes from saved/authored evidence and a missing timing/identity fixture refuses rather than inventing FPS/contact windows; (6) sandbox request is hash-bound to exact current 128 full-body Workbench frames/durations; a tampered frame/request refuses before display; (7) real-Operator sandbox shows the selected 2.5D pixels at the correct scale/root/shadow/camera context through the presentation authority, then exits cleanly; (8) production runtime manifest/SpriteFrames/selector/generated assets are byte-identical before/after sandbox; (9) review receipt can truthfully become current `runtime_verified=true` only after objective + required-human + sandbox gates pass, while publication remains separately unowned/unset; (10) no receipt/family/sequence/sandbox path bypasses the corrected WB25-3 mutation boundary.
- Validation: Add one focused `operator_2_5d_review_smoke.py` covering receipt hashing/staleness, QA state mapping, family derivation, forged cached proposal negative control, sequence-v1 compatibility + v2 generation round-trip/source selection, and human-gate invalidation. Add the smallest headless Godot sandbox smoke covering request/frame tamper refusal, real Operator/presenter ownership, 128 full-body playback/physical durations, root/scale/shadow/camera facts, teardown, and production-resource no-diff. Re-run `operator_2_5d_polish`, `operator_2_5d_ingress`, `operator_animation_targets`, `operator_animation_preview_timeline`, `operator_workbench_ui`, directly affected Operator presentation-authority smoke(s), and runtime-animation-authority smoke. Finish with `run_validation.py --changed --json`, compile/check-only coverage, and `git diff --check`. Visual handoff only if an exact current leaf still has unresolved subjective findings after objective proof.
- Task overrides: none
- Deferred: WB25-5 queue/progress/NEXT/generation briefs; WB25-6 canonical 2.5D publication/runtime cohort cutover; autonomous art generation.

## Context Pack

- Repomix: `recommended`
- Include: `custodian/tools/operator/operator_2_5d_polish.py,custodian/tools/operator/operator_animation_targets.py,custodian/tools/operator/animation_workbench.py,custodian/tools/operator/animation_preview.py,custodian/tools/operator/animation_motion_preview.py,custodian/tools/operator/ui/service.py,custodian/tools/operator/ui/state.py,custodian/tools/operator/ui/app.py,custodian/tools/operator/ui/widgets/timeline.py,custodian/tools/operator/art_agent/service.py,custodian/tools/operator/art_agent/qa.py,custodian/tools/operator/art_agent/metrics.py,custodian/game/actors/operator/operator.gd,custodian/game/actors/operator/operator.tscn,custodian/game/actors/operator/presentation/operator_body_presenter.gd,custodian/game/actors/operator/presentation/operator_body_presentation_plan.gd,custodian/game/actors/operator/presentation/operator_presentation_controller.gd,custodian/tools/debug/operator_motion_calibration.gd,custodian/scenes/debug/operator_motion_calibration.tscn,custodian/tools/validation/operator_2_5d_polish_smoke.py,custodian/tools/validation/operator_animation_preview_timeline_smoke.py,custodian/tools/validation/operator_workbench_ui_smoke.py,custodian/tools/validation/operator_runtime_animation_authority_smoke.py,custodian/content/data/operator/authoring/operator_art_profile.json,design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md,design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md,design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md,design/02_features/animation/OPERATOR_2_5D_WORKBENCH_MIGRATION_ROADMAP.md`
- Purpose: `landed WB25-3 QA/apply integrity + generation-aware target state + current Sequence/Motion contracts + sole body-presentation authority + immutable production runtime surfaces needed for review receipts/family/sequence/sandbox proof`

Generate once from the claimed worktree:

```bash
scripts/ai/pack-context.sh task "<Include value above>" "operator-2-5d-workbench-review-automation"
```

Use the coordination-root CRG only for baseline orientation; exact worktree files and `git diff` remain implementation/review truth.

## Recommended receipt shape

```json
{
  "schema": "custodian.operator_2_5d_review_receipt.v1",
  "authoring_identity": "operator_2_5d_128:unarmed/posture/idle_relaxed_01/ne",
  "authority": {
    "workbench_manifest_sha256": "...",
    "workbench_document_sha256": "...",
    "render_sha256": "...",
    "canonical_profile_sha256": "05e92192af68b2f4e7516f59a0938e536926f3525a31b42dd7695f61d77ca761",
    "normalized_reference_sha256": "e529df0e0ceaeb941f67ed18ce93799755053b7c516a9f02a5b6929248e25fb9",
    "frames": 15,
    "frame_size": [128, 128],
    "durations": [0.1]
  },
  "qa": {"status": "GREEN", "findings_sha256": "..."},
  "human_review": {"status": "NOT_REQUIRED"},
  "sandbox": {"status": "PASSED", "request_sha256": "...", "result_sha256": "..."},
  "runtime_verified": true
}
```

The example duration is illustrative only. Runtime code must record the actual physical saved-document duration array; never copy the example value.

## Recommended sandbox boundary

```text
exact 2.5D Workbench selection
  → current physical contract + render
  → immutable .ai runtime-preview bundle
  → hash-bound debug request
  → isolated Godot debug scene
  → real Operator scene + Camera2D/world context
  → OperatorBodyPresenter-authorized debug 128px full-body presenter
  → structured result
  → teardown/free isolated scene
  → prove production runtime hashes unchanged
```

The sandbox is proof, not publication.

## Refresh Planning Authority

- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh status: **consumed / final pre-claim refresh complete**
- Refresh instruction: WB25-3 correction R0-01 + fresh re-review and current target/Sequence/Motion/presentation APIs have been consumed. WB25-4 is now `ready/auto`. Re-open planning only for a genuine contradiction in landed authority or a new human-owned art-direction choice.


## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Evidence: `operator_2_5d_review_smoke.py` passed the hash-bound receipt/bundle, QA-state, family-incomplete, mixed-generation sequence, real Operator sandbox, request/frame tamper refusal, presentation ownership, and production-runtime fence assertions. Seven predecessor/focused checks passed. Changed-file validation passed 28/28 selected checks with complete changed-file coverage; `py_compile` and `git diff --check` passed.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: `The first changed-file sweep included generated Godot .import sidecars and reported the new sandbox scene as uncovered; a concurrent worktree also started another sweep during execution.`
- Root cause / contributing factors: `Godot import sidecars were created before changed-file selection, and the new .tscn had not yet been listed as an owner of the sandbox smoke. Independent worktrees can start overlapping broad validation despite the repository single-sweep guidance.`
- Prevention / pipeline improvement: `Register both sandbox script and scene with the focused smoke, remove generated sidecars before changed-file selection, and coordinate broad sweep starts across active worktrees.`
- Tooling / docs drift discovered: `paired_review_runner.py scans successor Next Handoff planning-refresh fields as if they gate the current review; the supplied WB25-4 review packet explicitly says WB25-5 refresh is not a current-review gate.`
- Follow-up: `manual-follow-up`
- What worked: `The focused real-Godot smoke proved the exact-pixel path and fail-closed tamper behavior; the second changed sweep completed with full coverage.`

## Next Handoff
- Next workstream: `review-operator-2-5d-workbench-review-automation`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: `none`
- Next action: `Launch the paired review from a fresh reviewer context. Harden paired_review_runner.py separately so it scopes current-review gate detection to the current packet authority and excludes successor handoff fields.`
- Blockers or open questions: `none`
