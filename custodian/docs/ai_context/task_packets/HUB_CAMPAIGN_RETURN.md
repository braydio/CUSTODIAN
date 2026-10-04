# HUB CAMPAIGN RETURN — H6

- Packet schema: `custodian.task_packet.v2`
- Workstream: `hub-campaign-return`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-hub-muster-continuity-port-deployment`
- Locks: `hub-runtime, world-lifecycle, campaign-outcome`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-hub-campaign-return`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `c2d6452ac10d`

- Goal: Close the first CampaignRegion → persistent Hub return: apply one valid CampaignOutcome to persistent Hub state exactly once, release the disposable Campaign runtime, restore the reviewed Hub, and return the Operator through the Continuity Port west return bay at `Spawn_CampaignReturn`.
- Completion boundary: Consume the authoritative `WorldSimulationRuntime.campaign_resolved(outcome)` / CampaignSession outcome seam, validate it against the active deployment, apply it through the persistent HubState owner once, then request Campaign→Hub through the major-context lifecycle. Campaign teardown is legal only after outcome application is confirmed or already-confirmed idempotent. Successful return clears resolved deployment/prewarm state only after Hub restoration succeeds.
- Current measured state: `CampaignSession.resolve_once()` and `HubState.apply_campaign_outcome()` already provide exactly-once primitives; `WorldSimulationRuntime.resolve_campaign()` emits `campaign_resolved`. No live runtime currently owns persistent HubState or routes this event into a major-context return. Persistent-recovery R1 has now landed: `OperatorDeathCampaignBinding` resolves one active CampaignSession failure before an unconditional transitional Game Over fallback. H6 must consume that same outcome authority rather than duplicate death resolution; R2 later owns death-specific fallback suppression/reintegration.
- Evidence: `CAMPAIGN_FLOW_AND_GAME_LOOP.md`; `WORLD_TRANSITION_SYSTEM.md`; `game/state/persistent/hub_state.gd`; `campaign_session.gd`; `campaign_outcome.gd`; `world_simulation_runtime.gd`; `campaign_outcome_exactly_once_smoke.gd`; persistent recovery roadmap/current packets; H1 `Spawn_CampaignReturn`.
- Task-specific authority: reviewed H5 deployment/transition owner; persistent Hub selection/state owner from H3; CampaignSession/WorldSimulationRuntime exactly-once contracts; H1 Port return marker.
- Work surface: Campaign-resolved binding into the major-context/Hub campaign coordinator; authoritative HubState; Campaign teardown/reset; Hub host restoration; focused return smoke. Reuse the landed persistent-recovery death outcome seam. The return owner must expose an outcome-keyed accepted/completed result or signal sufficient for R2 to correlate one exact death outcome without inventing a second coordinator.
- Change: Subscribe one persistent authority to the active Campaign resolution event. Verify outcome belongs to the active accepted deployment, then call `HubState.apply_campaign_outcome()`. Treat APPLIED as success; treat OUTCOME_ALREADY_APPLIED as idempotent success only when that exact outcome is already present in the authoritative HubState; malformed/mismatched outcomes fail without teardown. After confirmed application, transition to the existing Hub runtime, release Campaign runtime/services, place Operator at `Spawn_CampaignReturn=(2592,-3008)`, rebind camera/navigation, resume Hub control, then clear/reset resolved Contract/bootstrap state. Consume the landed R1 death outcome through this same path rather than adding a second death-result path. Preserve structured outcome identity through return and expose an accepted/completed result keyed to the exact `outcome_id` (or an equally strict existing identity) so R2 can layer death-specific recovery later. H6 does not remove R1's fallback or re-arm its death latch.
- Preserve: CampaignSession/HubState exactly-once semantics; partial/failure/abandon result identity; H5 accepted scenario/seed trace; H4 Twin branch; true terminal Game Over callers outside ordinary Campaign resolution; current persistent Operator/inventory contracts except where separately changed by reviewed recovery work.
- Non-goals: No local Crèche/Post recovery; no R1 death-latch re-arm; no death-specific fallback removal; no armament registration; no save serialization expansion; no next-offer generator; no second CampaignOutcome type; no direct Campaign→Twin return.
- Acceptance: one Campaign resolution produces at most one valid outcome, one Hub mutation/history entry, and one return request; duplicate delivery cannot double-apply or double-transition; malformed/mismatched outcome leaves Campaign authoritative and reports failure; Hub mutation is committed before Campaign destruction; successful return removes/disables transient Campaign runtime and restores one Hub at exact Spawn_CampaignReturn; camera/navigation/input are Hub-bound before control resumes; bootstrap/selection clear only after successful return; R1 death uses the same resolution path without a second failure/outcome owner; the return lifecycle exposes accepted/completed identity for the exact outcome so adjacent recovery can correlate it without treating all FAILURE outcomes alike; Hub outcome dedupe still survives snapshot restore.
- Validation: Add focused Campaign-return smoke covering success, duplicate event, already-applied idempotent retry, malformed/mismatched rejection, forced Hub-restore failure/rollback, teardown ordering, exact return spawn, and bootstrap/selection cleanup. Re-run `campaign_outcome_exactly_once_smoke.gd`, WorldSimulation live smoke, H5/H2 smokes, and any landed recovery/death-handoff regression selected by current main; then changed-file closeout + `git diff --check`.
- Task overrides: `none`
- Deferred: local/Post recovery program, specifically R2 `custodian-post-recovery-reintegration`; next offer cycle; save/load expansion; return audiovisual polish.
- Cross-program recovery refresh chat: https://chatgpt.com/c/6abca2bb-1b3c-83ea-a3ae-e3d368c88461?src=history_search. If H6 or its paired review lands evidence that requires R2 to be refreshed, the H6/HR6 closing summary must surface this exact URL and identify R2 as refresh-required.

## Temporary Refresh Gate — REMOVE WHEN REFRESHED

After `review-hub-muster-continuity-port-deployment` passes, inspect the landed return API, accepted deployment/session identity, HubState owner, bootstrap cleanup policy, and current persistent-recovery/death-handoff state. R1 is now landed, so bind to its authoritative Campaign resolution path and preserve an outcome-keyed return acceptance/completion seam for R2. Update exact seams/tests, remove this section, set ready/auto. Refresh in place. If this refresh changes what R2 must consume, record that in the closing summary with https://chatgpt.com/c/6abca2bb-1b3c-83ea-a3ae-e3d368c88461?src=history_search.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `<fill at closeout>`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `<fill at closeout>`
- Friction severity: `<fill at closeout>`
- What went wrong: `<fill at closeout>`
- Root cause / contributing factors: `<fill at closeout>`
- Prevention / pipeline improvement: `<fill at closeout>`
- Tooling / docs drift discovered: `<fill at closeout>`
- Follow-up: `<fill at closeout>`

## Handoff

- Next action: Refresh after HR5; H7 waits for reviewed H6 plus reviewed optional H4.
- Best starting files: reviewed H5 lifecycle/deploy owner; HubState; CampaignSession/Outcome; WorldSimulationRuntime; current recovery program; H1 return marker.
- Blockers or open questions: exact return/cleanup API is a dependency/live-main output. R2 recovery remains separate and planning-chat gated at https://chatgpt.com/c/6abca2bb-1b3c-83ea-a3ae-e3d368c88461?src=history_search.
