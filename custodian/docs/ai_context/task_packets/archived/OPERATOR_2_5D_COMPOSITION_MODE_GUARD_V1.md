# OPERATOR 2.5D COMPOSITION MODE GUARD V1

- Packet schema: custodian.task_packet.v2
- Workstream: operator-2-5d-composition-mode-guard-v1
- Status: complete
- Dispatch: auto
- Priority: P1
- Depends on: review-operator-2-5d-cohort-dependency-closure-review-corrections-1
- Locks: operator-runtime-animation
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, runtime, workflow
- Paired review workstream: review-operator-2-5d-composition-mode-guard-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: precise mechanical presentation owner/mode and fallback safety require independent runtime falsification
- Reviewed main: a9cdcc5bd7376fbce2b94a97e96c11a050da2863
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Visual review: none
- Goal: Enforce the approved full-body-first, selectively modular Operator presentation contract at the existing semantic presentation seam, so absent/partial/invalid 2.5D split compositions cannot falsely appear available or render alongside another body. Preserve all live legacy behavior.
- Completion boundary: One bounded **fixture-only, disabled-for-production** preflight/compatibility contract in the existing Operator presentation path, with negative and positive runtime tests for full-body/split/exclusive modes, generation consistency, clock and preemption. No live 2.5D generation switch, source asset writes, or new animation state machines.
- Current measured state: `OPERATOR_RUNTIME_ARCHITECTURE.md` already owns one-body visibility through `OperatorBodyPresenter` and semantic requests through `OperatorPresentationController`/`OperatorAnimationSelector`; `OperatorAnimationPlayer` handles playback. `present_animation` handles full-body and `present_split_body_action` handles a lower+upper pair. `operator.gd::_sync_unarmed_posture` currently demands E/W legacy `lower_body+upper_body`; `_sync_modular_locomotion_layers` prefers legacy split movement. The reviewed source-grounded `OPERATOR_2_5D_COHORT_DEPENDENCY_CLOSURE.md` reports proposed seven-family/56-direction `unarmed_neutral_motion_v1` NOT_RELEASE_ELIGIBLE, eight editable 15f/128px full-body idle directions, zero effective review receipts, six unknown frame/loop/FPS family contracts, all examined transitions/preemption edges OPEN; 2.5D plan is 69 full_body families/552 directions. No approved 128px split layers or production generation policy exists. Preemption/sockets/FX, guard-parry, dodge, melee, ranged and action settle edges require future release-level proof.
- Evidence: `custodian/game/actors/operator/presentation/operator_presentation_controller.gd`; `operator_body_presenter.gd`, `operator_body_presentation_plan.gd`, `operator_animation_player.gd`, `operator_animation_selector.gd`; `custodian/game/actors/operator/operator.gd::_update_animation/_sync_unarmed_posture/_sync_modular_locomotion_layers`; `custodian/tools/validation/operator_visual_ownership_smoke.gd`, `operator_unarmed_posture_smoke.gd`, `operator_modular_layers_smoke.gd`; `custodian/docs/reports/operator_presentation/OPERATOR_2_5D_COHORT_DEPENDENCY_CLOSURE.md`; `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`.
- Task-specific authority: **Approved composition doctrine** in `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`; `OperatorBodyPresenter` one-owner contract; existing `OperatorAnimationSelector` exact identity; archived reviewed cohort report and `OPERATOR_2_5D_VISUAL_CONTRACT.md` root/direction constraints. Simulation/attack/contact clocks remain the existing controller authorities; `WB25-6` owns any real generation switch, publication, rollback and human chosen cohort.
- Work surface: `custodian/game/actors/operator/presentation/operator_presentation_controller.gd` plus smallest helper/plan extension if justified, existing `operator_body_presenter.gd` only for proven invariant defects, `custodian/tools/validation/operator_visual_ownership_smoke.gd` and a narrowly scoped new focused Godot smoke with `validation_manifest.json`; design/AI context drift note. `operator.gd` integration limited to demonstrably necessary delegation, preferably unchanged.
- Change:
  1. Add one explicit **preflight-only** composition eligibility/validation path owned by the existing presentation controller or existing body plan. It must distinguish: (a) an accepted authored `full_body` composition for ordinary idle/locomotion and committed whole-body states; (b) accepted `lower_body+upper_body` pair only for independently legal concurrent locomotion+upper action; (c) existing exclusive authored rigs; (d) independently owned weapon/FX overlays. Do not infer a modular split from action name alone or switch existing legacy callers to new modes.
  2. For a hypothetical `operator_2_5d_128` fixture, validate exact target semantic identity, required layers, authored eight-direction policy/sector, 128px body registration and a common approved generation and profile. Use the existing target/manifest/profile/selector authorities as evidence; do not derive art generation from a caller-supplied assertion or infer readiness from dimensions alone. If existing runtime metadata cannot independently establish generation for a given clip, report `UNKNOWN/BLOCKED` and defer missing generation-aware metadata contract to WB25-6, rather than invent a second runtime animation registry. Compatibility/evidence checks must be read-only until an existing owner authorizes publication.
  3. Validate an **entire** proposed composition before owner transfer: full-body means one body renderer; split means **both** valid body layers and a valid visible clock; required weapon/socket/FX must be attached to the actual owner. Incomplete/mixed/synthetic split or visible 96px+128px body combination rejects without retiring the current valid owner. Preempting one owner retires its stale body/overlays and leaves no hidden active completion clock. State transitions preserve legal caller-owned cancel semantics.
  4. Test lower travel-facing / upper aim-facing independently in split-mode fixtures, retaining accepted registration/root and no synthetic N/W mirroring of the 2.5D body. Preserve lower loop progress when the upper animation alone changes, where current presentation methods already support that. A planted hit/guard-break/dodge/knockdown/finisher must not be decomposed or granted locomotion permission by the presentation layer.
  5. Keep the runtime code non-activated for 2.5D until WB25-6 has approved timing, real verified source, full graph/edge closure and transactional rollback. Do not create or modify the generation policy, player art, Aseprite workspace or existing 69-family target rows. State clearly in the implementation summary which 2.5D behaviors remain **unimplemented**, and provide one small code path/contract WB25-6 can consume, rather than introducing a parallel animation selector or a second stateful controller.
- Preserve: Existing 96px split locomotion/guard/parry/ranged/melee and existing full-body committed actions, exact E/W legacy sector choices, visible body-owned presentation clock, movement/input/combat states and hit windows, weapon socket/FX owner lifecycle, live SpriteFrames, generated manifest/catalog, all 2.5D source/Workbench files and their unapproved timing, no 2.5D production.
- Non-goals: Building 2.5D runtime generation, art conversion or splitting an accepted PNG into halves, changing the source target plan to create modular art, extending guard-parry gameplay/polish (owned by `operator-guard-parry-composition-polish`), a second body presenter, making all 69 planned families modular, activating dormant head/cape, changing movement legality, publication or WB25-6 promotion.
- Acceptance: (A) Test data proves full-body ordinary idle and committed action remain single-body; (B) paired modular movement+aim/guard with approved compatible fixtures succeeds with one owner, separate aim/travel facing, stable lower clock and owner-scoped weapon/FX; (C) missing upper/lower, incompatible art generation, stale/untrusted profile, source/sector gaps and unavailable runtime-generation provenance fail closed **before mutation**; (D) owner handoff, preemption and action return never show dual bodies, ghost overlay, duplicate completion or hidden-active clock; (E) legacy exact E/W projection and ranged/guard/melee gameplay/animation cases are behaviorally unchanged; (F) no real `operator_2_5d_128` activation, artwork/manifests/source/selector policy/source hash mutations, and no invented FPS/receipt; (G) no second selector, runtime database, authority or substantial growth in `operator.gd`.
- Validation: Existing `operator_visual_ownership_smoke.gd`, `operator_unarmed_posture_smoke.gd`, `operator_modular_layers_smoke.gd`, `operator_guard_flow_smoke.gd`, `operator_parry_presentation_smoke.gd`, `operator_runtime_animation_authority_smoke.py`, `operator_2_5d_cohort_dependency_closure_smoke.py` if present; focused new fixture/negative-control test registered in `validation_manifest.json`; `python3 custodian/tools/validation/run_validation.py --changed --json`, `check_ai_context.py --json`, `validate_review_pairing.py`, `task_packet_index.py`, `git diff --check`. Use Godot serialized project/import lock; do not run a full runtime suite merely to prove a presentation-only contract.
- Task overrides: none
- Deferred: Future WB25-6 generation-aware runtime metadata and cutover, actual 128px split-layer authoring only for evidence-justified combinations, human selection of cohort, artist FPS, final visual subjective release acceptance.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Superseded/legacy production path disposition: intentionally-preserved
- Evidence: `OperatorPresentationController.preflight_composition_fixture_only()` is a pure structural preflight and has no production caller. It checks mode/owner fit, unique complete body shape, plan registration, exact selector identity and SpriteFrames playback, and completion-clock membership before any owner transfer. The focused `operator_2_5d_composition_preflight` fixture passed full-body, independently faced split movement+guard, and exclusive-rig shapes; it rejected missing/duplicate layers, stale exact identities and mode/owner mismatch without owner mutation, kept movement permission false, and ignored a caller's generation claim. Generation status remains `UNKNOWN/BLOCKED` because current runtime metadata does not bind clip identities to an approved generation/profile. The final changed-file sweep is recorded in the durable summary. The five named Godot presentation regressions and both Python authority/cohort smokes passed. No source assets, generated runtime art, selector policy, target rows, or production generation behavior changed.

## Execution Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: The first Godot fixture attempt ran in a cold worktree without its ignored import/class cache and could not resolve global classes. After the required serialized project import, the focused test and changed sweep passed.
- Root cause / contributing factors: New linked worktrees do not carry the coordination checkout's generated Godot import cache; the validation runner initially timed out when the fixture failed before reaching its quit path.
- Prevention / pipeline improvement: Initialize/import the Godot project under its shared lock before direct script-based presentation validation in a cold worktree, then ensure failing fixtures always report and quit.
- Tooling / docs drift discovered: none
- Follow-up: review-operator-2-5d-composition-mode-guard-v1
- What worked: Keeping structural fixture readiness separate from generation approval preserved a useful positive contract while refusing to manufacture 2.5D provenance.

## Handoff

- Next workstream: review-operator-2-5d-composition-mode-guard-v1
- Next packet state: ready/auto, dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Next action: Fresh independent review after guard code lands; return real compositional gaps to WB25-6 planning without releasing art.
- Blockers or open questions: None for fixture-only composition hardening; actual 2.5D publication remains separately gated.
