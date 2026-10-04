# CUSTODIAN DEATH HANDOFF FOUNDATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `custodian-death-handoff-foundation-recovery-1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `custodian-death-flow, operator-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, workflow`
- Paired review workstream: `review-custodian-death-handoff-foundation-recovery-1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `09ebb90e78e4568f81f4a7fc270da0a3d158d445`
- Authoring chat: `not-recorded`
- Goal: Make Custodian lethal damage a campaign-level exactly-once event instead of an actor-owned life decrement, establishing the recovery-capable death handoff without leaving the player in an unhandled dead state.
- Completion boundary: Done when `Operator` no longer calls `GameState.lose_life()`; one lethal Operator event emits one structured death handoff, the active `CampaignSession` resolves exactly once through `WorldSimulationRuntime`, and the existing global Game Over remains only as an explicit compatibility fallback after that outcome until R2 replaces it with Post recovery. Facility/siege terminal-failure paths remain unchanged.
- Current measured state: R1 is implemented on fresh current main. Operator emits one structured `operator_down` snapshot; the attached `OperatorDeathCampaignBinding` latches reentry, resolves an active unresolved `CampaignSession` through `WorldSimulationRuntime`, and then invokes the transitional Game Over fallback. Without a live campaign runtime, it preserves Game Over without fabricating a campaign. The actor no longer calls `GameState.lose_life()`.
- Evidence: `custodian/game/actors/operator/operator.gd` lethal path and `_finish_death()`; `custodian/game/systems/core/state/game_state.gd` `total_lives`, `lose_life()`, and `trigger_game_over()`; `custodian/game/systems/simulation/world_simulation_runtime.gd` `session` and `resolve_campaign()`; `custodian/game/state/run/campaign_session.gd` `resolve_once()`; `custodian/game/state/run/campaign_outcome.gd`; `custodian/tools/validation/game_over_flow_smoke.gd`; `custodian/tools/validation/campaign_outcome_exactly_once_smoke.gd`.
- Task-specific authority: `design/02_features/operator/PERSISTENT_RECOVERY_AND_ARMAMENT_REGISTRATION.md`; `design/02_features/operator/PERSISTENT_RECOVERY_IMPLEMENTATION_ROADMAP.md`; `design/04_architecture/CAMPAIGN_FLOW_AND_GAME_LOOP.md`; `custodian/docs/ARCHITECTURE.md`.
- Work surface: Primary owner is the Operator death handoff in `custodian/game/actors/operator/operator.gd`; campaign consequence belongs to the live run/simulation boundary in `custodian/game/systems/simulation/world_simulation_runtime.gd` / `custodian/game/state/run/campaign_session.gd`, with a narrow scene/binding adapter under the existing `custodian/game/world/bindings/` pattern if needed. `GameState` may retain the compatibility fallback but must not remain the ordinary Operator death owner. Focused validation and the recovery roadmap are downstream consumers.
- Change: Add one exactly-once Operator-down handoff carrying the existing structured death context. Remove the direct `GameState.lose_life()` call from the Operator. Route that handoff through the existing world/run binding layer to the active `WorldSimulationRuntime.resolve_campaign(&"FAILURE", ...)` seam when an unresolved campaign session exists. After successful/recognized campaign failure resolution, preserve the current Game Over modal as a clearly transitional compatibility fallback so R1 never leaves the runtime permanently dead with no recovery path. If no live campaign session exists, preserve a safe legacy fallback rather than fabricating a campaign. Keep campaign outcome creation inside `CampaignSession.resolve_once()`; do not duplicate outcome sealing in actor or UI code.
- Preserve: Operator death animation/cancellation/telemetry/world-history recording; exactly-once `CampaignSession` outcome semantics; existing Command Post / Sundered Keep terminal game-over triggers; `GameState.trigger_game_over()` modal/stat/restart behavior for true current callers; deterministic simulation ownership; current P-9/inventory behavior; current `_finish_death()` no-revive behavior while compatibility Game Over is active.
- Non-goals: No Post recovery or return transition yet; no local Crèche recovery; no corpse/death-site persistence changes; no armament registration model; no inventory persistence migration; no fabrication changes; no Designation Mooring; no removal of `GameState.total_lives` / `lives_remaining` for unrelated compatibility callers; no new lore exposition or recovery UI.
- Acceptance: (1) repository search proves `operator.gd` no longer calls `GameState.lose_life()` or decrements lives; (2) one lethal Operator event produces exactly one structured death handoff and, with one live unresolved campaign, exactly one valid `CampaignOutcome` with failure result/reason; (3) repeated lethal/reentrant death handling cannot emit a second campaign outcome or a second macro handoff; (4) the compatibility Game Over occurs only after the campaign failure handoff in the campaign-active case and remains available when no campaign runtime can accept the event; (5) Command Post / Sundered Keep direct `GameState.trigger_game_over(...)` behavior still passes existing validation; (6) no recovery, inventory, weapon, or fabrication behavior changes in this slice; (7) the roadmap records R1 completion evidence and advances Current Program Position truthfully at closeout.
- Validation: Add focused coverage for the Operator-down -> campaign-resolution -> compatibility-fallback ordering and duplicate suppression. Run `custodian/tools/validation/game_over_flow_smoke.gd` and `custodian/tools/validation/campaign_outcome_exactly_once_smoke.gd` as required regressions, plus the narrowest existing world-simulation live/binding smoke selected by changed-file validation. Run changed-file closeout once after focused tests. Moment Forge: not required unless implementation unexpectedly changes death presentation timing or visual behavior.
- Task overrides: `none`
- Deferred: R2 `custodian-post-recovery-reintegration` replaces the compatibility Game Over with actual Post recovery/reintegration. R3-R8 own armament persistence, death-site equipment semantics, local/fabricated recovery infrastructure, capacity progression/UI, and final legacy-lives cleanup.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: source search confirms `operator.gd` no longer calls `lose_life`; the focused handoff smoke verifies structured context, one failure outcome, duplicate suppression, outcome-before-Game-Over ordering, legacy-life preservation, no-session fallback, resolved/unstarted-session fallback, and no-revive behavior. `game_over_flow_smoke.gd` and `campaign_outcome_exactly_once_smoke.gd` pass. Changed-file closeout selected 55 tests with complete file coverage: 48 passed, 4 skipped, and 3 pre-existing failures reproduced on untouched `main` (`grunt_falcon_reversal`, `operator_animated_sprite_canonical`, `operator_ranged_ready_input`). The first sweep also found a malformed fixture in `visual_review_handoff`; it was corrected and passed on the second sweep.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: The original workstream ID had been superseded on current main. Its requested resume produced merge conflicts; the refreshed packet directed a new recovery identity, so that merge was aborted and the old checkpoint was used only for donor comparison. A direct first Godot launch also preceded complete fresh-worktree import. Three failures found by changed-file closeout reproduced on untouched current `main`.
- Root cause / contributing factors: A user-specified recovery command targeted a stale workstream ID after the packet had been refreshed; direct Godot script launch bypassed the import-aware validation runner.
- Prevention / pipeline improvement: After fetching, read the latest packet before resuming stale workstream state; use the dispatch receipt's refreshed workstream ID. Run focused Godot checks through `run_validation.py` in fresh worktrees so import/cache preparation is explicit. Track the three confirmed baseline test failures separately.
- Tooling / docs drift discovered: The old donor branch's recovery evidence was hundreds of commits behind; the refreshed packet correctly separates new execution from donor history. Fresh worktrees need their first import before raw direct script runs.
- Follow-up: manual-follow-up
- What worked: Dispatch verified the new claim and isolated worktree; focused handoff/regression smokes passed.

## Handoff

- Next action: Author and execute R2 against the landed R1 binding and current Campaign / Hub / world-return surfaces; do not replace the explicit compatibility fallback until the R2 return/reintegration path is proven.
- Best starting files: `custodian/game/world/bindings/operator_death_campaign_binding.gd`; `custodian/game/systems/simulation/world_simulation_runtime.gd`; `custodian/game/state/run/campaign_session.gd`; persistent Hub ownership and the current world-return lifecycle.
- Blockers or open questions: No implementation blocker for R1. Architecture-sensitive R2 packet refresh requires the user/ChatGPT planning owner because the authoring chat URL is not recorded.
