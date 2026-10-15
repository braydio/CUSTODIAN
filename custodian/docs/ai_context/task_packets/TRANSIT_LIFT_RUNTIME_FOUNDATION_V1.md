# TRANSIT LIFT RUNTIME FOUNDATION V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `transit-lift-runtime-foundation-v1`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `local-transit-lift, awakening-interaction`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, architecture`
- Paired review workstream: `review-transit-lift-runtime-foundation-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `extracts and hardens a live interaction/lifecycle authority while preserving Awakening compatibility`
- Reviewed main: `350ee94e4b3b80010c0970903f3418966df3b851`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391`
- Visual review: `none`
- Goal: Replace Awakening-only two-stop lift mechanics with one reusable same-map local transit authority, then migrate Awakening through a thin compatibility consumer.
- Completion boundary: A reusable owner under `game/world/traversal/` supports stable 2+ station identity, deterministic busy/departure/arrival/cancel lifecycle and exactly-once actor lock cleanup. Awakening keeps its route, node/prompt/stations/one-owner-two-affordance contract and public compatibility.
- Current measured state: `AwakeningTransitLift` is scene-specific: fixed LOWER/UPPER enum, hard-coded art/coordinates, 48px station radius, await timers plus Tween, screen-dim cycle, final actor teleport, portal-transition lock, and debug-reset coupling. There is no dedicated generic lift lifecycle smoke. Ash-Bell/Forlorn lift-like systems are route transitions and are not equivalent consumers.
- Evidence: `game/world/awakening/awakening_transit_lift.gd`; `awakening_first_return.gd`; `awakening_first_return_progression_smoke.gd::_check_lift`; affordance presenter; live search of Ash-Bell/Forlorn route lift code.
- Task-specific authority: new local-transit owner owns station/cycle state; Operator owns its public control lock seam; AwakeningLayout owns geography; LevelLoader/RouteTraversalManager remain separate transition authorities.
- Work surface: new reusable local lift + station definition under `custodian/game/world/traversal/`; thin `awakening_transit_lift.gd` adapter/composition; dedicated lifecycle test; existing Awakening progression/affordance validation.
- Change:
  1. Implement `LocalTransitLift2D` or equivalently focused owner with stable StringName station IDs, station/arrival positions and deterministic ordering. Support 2+ stations and a 3-station test fixture.
  2. Track explicit idle/busy/origin/destination/cycle token. Reject duplicate station IDs, unknown destination, request while busy, and actor not eligible/near the departure station.
  3. Centralize actor control lock/unlock. A generic local-transit lock is preferred if added; retain `set_portal_transition_locked` only as compatibility fallback. Success, cancel, reset, invalid actor and tree exit must unlock at most once.
  4. Replace uncancellable free-running await/Tween state ownership with a cancellation-safe cycle. Presentation may tween/animate from phase/progress, but stale callbacks must never change station or unlock a newer cycle.
  5. Emit stable lifecycle signals sufficient for presentation: start/departure, phase/progress as justified, successful arrival/finish, cancellation. Current station changes only on successful arrival.
  6. Keep `AwakeningTransitLift` as a thin adapter/subclass/composition boundary as needed. Preserve `Zone05_DustLung/Interactables/TransitLift`, `SERVICE LIFT`, lower `(384,-3008)`, upper `(384,-3424)`, one interactable owner, two affordance mounts, `is_busy()`, reset behavior and existing public enum/signals through compatibility translation.
  7. Current dim/sprite movement may remain only as compatibility presentation in B1. Make generic mechanics independent of those Awakening assets.
  8. Do not migrate `AshBellLiftIngressSite`, Forlorn Ritualant level-exit lift or campaign/level route transitions; record them as audited non-consumers.
- Preserve: Awakening progression, Locker→Dust→Undergate route, station positions, one lift gameplay owner, affordance parity, persistent Operator identity, route-transition systems and existing Asset V2 lift families.
- Non-goals: no Dust Lung V2 geometry cutover, new lift art/audio/camera polish, route-transition unification or generalized moving-platform physics.
- Acceptance:
  1. Generic fixture proves forward/reverse travel and a 3-station configuration with stable IDs and exact arrival state.
  2. Busy second request, duplicate station ID, invalid/removed actor, reset mid-cycle and owner tree exit abort deterministically and leave actor control unlocked exactly once.
  3. Current station is unchanged on cancel and changes exactly once on successful arrival; stale prior-cycle callbacks cannot overwrite a later cycle.
  4. Awakening progression still finds the same lift node/prompt/station positions/public compatibility signals; exactly one interactable owner and two physical affordance mounts remain.
  5. Mutation back to the old uncancellable await/Tween lifecycle or a second station gameplay owner fails focused coverage.
- Validation: Add/register a dedicated local-transit lifecycle smoke. Rerun Awakening progression, affordance-contract and directly affected lower/upper connection geometry, then changed-file validation and `git diff --check`.
- Task overrides: `none`
- Deferred: Visual/game-feel polish remains the existing `awakening-interactible-locker-lift-presentation-v1`, refresh-gated after B1 review.

## Handoff
- Next workstream: `review-transit-lift-runtime-foundation-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391`
- Refresh reason: `none`
- Next action: `Implement reusable mechanics + Awakening migration, land, then run fresh paired review.`
- Blockers or open questions: `none`
