# OPERATOR INTERACTION DOMAIN EXTRACTION — SLICE F5

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-interaction-domain-extraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-dependency-injection-spine`
- Locks: `operator-runtime`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `931b830d54f2a217d1b473109f708636ac89f21f`
- Goal: Extract interaction target/build/repair/terminal field-work coordination into one focused authority and give interactables an opt-in semantic Operator success beat instead of leaving the existing `interaction/success_01` body+FX family dormant.
- Completion boundary: Done when target acquisition and interaction/build/repair/terminal-deploy coordination live behind an `OperatorInteractionController`-class authority with explicit world dependencies; current Operator public interaction behavior remains delegated; a typed opt-in success-result contract can request `unarmed/interaction/success_01` without making every interaction animate; moving success uses lower cadence + upper/FX when legal, stationary success can use the authored pair; and no duplicate interaction state remains in the actor.
- Current measured state: Interaction target selection, build/repair and terminal deployment helpers remain in `operator.gd`. The canonical manifest already publishes `unarmed/interaction/success_01/{e,w}` as 5-frame 96x96 lower_body + upper_body + FX, but the reachability contract intentionally classifies it pending a generic interaction-success contract. Existing interactables signal success in domain-specific ways, so there is no safe global "every interact()" animation trigger.
- Evidence: interaction/build/repair functions in `operator.gd`; active interaction/build/repair design docs; canonical reachability/manifest entry for `interaction/success_01`; interaction/terminal/build focused tests selected by validation manifest.
- Task-specific authority: Operator runtime architecture; interaction/build/repair feature authorities; canonical animation authority.
- Work surface: New interaction controller under `game/actors/operator/interaction/`; actor facade; existing interactable result seams; semantic presentation controller; focused interaction/build/repair tests.
- Change:
  1. Move current interaction target acquisition/selection and field-work request coordination (interact, build, repair, terminal deploy/pickup/carry queries) behind one controller with explicit injected dependencies.
  2. Preserve actual world/build/repair authority in the existing systems. The Operator controller requests and coordinates; it does not duplicate wall/terminal/repair simulation state.
  3. Define the smallest typed/semantic result by which an interactable or field-work operation may opt into an Operator acknowledgement beat. No implicit animation on all successful interactions.
  4. Wire `unarmed/interaction/success_01` through `OperatorPresentationController` for opt-in results. If movement remains legal, keep lower locomotion cadence and use upper+FX success; if stationary, the existing lower+upper+FX authored pair may present. Completion of the cosmetic beat never delays or causes the underlying interaction success.
  5. If required success upper/FX art is missing for the requested facing, use the exact existing E/W authored projection policy or skip the optional beat; never substitute unrelated action art.
  6. Reconcile reachability from `DORMANT_PENDING_INTERACTION_SUCCESS_CONTRACT` to the factual live state when the first consumer lands.
  7. Remove actor-local duplicate target/field-work orchestration after controller delegation is complete.
- Preserve: interaction priority, build/repair timing/cost/ownership, terminal deployment/carry semantics, UI-open gating, input routing, world mutation authorities, fixed tick.
- Non-goals: No redesign of build/repair/terminal systems. No gameplay reward for the success animation. No mandatory movement lock. No new interaction art. No Field Patch work.
- Acceptance: One interaction controller owns Operator-side target/field-work coordination; existing build/repair/terminal behavior passes unchanged; at least one deterministic opt-in fixture proves success presentation without changing simulation outcome; non-opt-in interactions do not animate; moving/stationary presentation uses complete valid composition and cannot block gameplay completion; reachability matches the real consumer.
- Validation: Add focused interaction-controller/result-contract smoke, then directly affected build/repair/terminal/interact tests. Prove success-result timing independently from animation completion and assert lower/upper/FX identity/visibility deterministically. Use a tiny renderer crop only if registration cannot be proven from layer metrics. One changed-file closeout.
- Task overrides: `none`
- Deferred: Additional interaction-specific gestures remain content-owned and should not turn this controller into an animation catalog.

## Handoff

- Next action: Extract target/field-work coordination, then add the optional semantic success-result presentation once the controller has a clean completion event.
- Best starting files: interaction/build/repair/terminal portions of `operator.gd`; existing interactable result APIs; presentation controller; reachability ledger.
- Blockers or open questions: None.
