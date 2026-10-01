# CUSTODIAN POST RECOVERY REINTEGRATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `custodian-post-recovery-reintegration`
- Status: `blocked`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `custodian-death-handoff-foundation`
- Locks: `custodian-death-flow`
- Kind: `implementation`
- Review: `none`
- Goal: Replace R1 ordinary Custodian death Game Over with campaign failure outcome application and Post recovery/reintegration, returning ordinary control without rewinding completed world truth.
- Completion boundary: One campaign-ending death seals and applies one outcome, transitions to a valid Post recovery surface, restores the recovered Operator to playable control, and preserves terminal facility Game Over callers and safe no-campaign compatibility behavior.
- Current measured state: R1 attaches `OperatorDeathCampaignBinding` to every Operator; `operator_down(context)` is latched before `WorldSimulationRuntime.resolve_campaign(FAILURE, reason)` and the adapter invokes transitional Game Over. `HubState.apply_campaign_outcome` already deduplicates outcomes, but no persistent Hub/flow/transition autoload owns the complete return loop. `LevelLoader.complete_return_to_world` and `WorldIngressSite.restore_world_origin` implement authored-level origin return; `RouteTraversalManager.request_exit` owns route exits. These are local return seams, not proof of a Post campaign-return authority.
- Evidence: `custodian/game/world/bindings/operator_death_campaign_binding.gd`; `custodian/game/state/persistent/hub_state.gd`; `custodian/game/world/levels/level_loader.gd`; `custodian/game/world/procgen/ingress/world_ingress_site.gd`; `custodian/game/world/routes/route_traversal_manager.gd`; `custodian/project.godot`.
- Task-specific authority: `design/02_features/operator/PERSISTENT_RECOVERY_AND_ARMAMENT_REGISTRATION.md`; `design/02_features/operator/PERSISTENT_RECOVERY_IMPLEMENTATION_ROADMAP.md`; `design/04_architecture/CAMPAIGN_FLOW_AND_GAME_LOOP.md`; `design/04_architecture/WORLD_TRANSITION_SYSTEM.md`.
- Work surface: R1 binding; live campaign/session runtime and persistent Hub ownership; world lifecycle/boot and existing authored-level return adapters; Operator recovery reset; focused validation.
- Change: Re-derive live macro transition ownership before editing. Add the minimum single campaign return/reintegration authority needed to consume the R1 handoff, freeze campaign play, retain and apply the sealed outcome once to persistent Hub state, transition to a valid Post surface and restore player control. Reuse existing local transition contracts where applicable; do not equate authored-level origin return with Post recovery. Remove ordinary campaign death dependence on the R1 modal only when the return transaction is safe, with an explicit failure fallback. Preserve duplicate suppression across transition callbacks and restore/retry boundaries.
- Preserve: death cancellation/telemetry/context; exactly-once outcome creation in `CampaignSession`; exactly-once application in `HubState`; existing terminal Game Over/stat/restart behavior; deterministic world truth; current carried inventory, P-9 and equipment behavior.
- Non-goals: No armament registration, corpse/death-site persistence, local Crèche, fabrication, capacity progression, lore exposition or broad legacy lives cleanup.
- Acceptance: (1) one lethal active-campaign death produces one failure outcome and one persistent application before teardown; (2) recovery ends at a valid Post with a living controllable Operator and no ordinary Game Over; (3) reentrant/repeated completion callbacks cannot duplicate outcomes, Hub mutation or recovered actors; (4) campaign simulation does not continue after resolution or rewind prior truth; (5) failed return and no-session authored contexts retain a safe explicit fallback; (6) facility terminal Game Over and current inventory/equipment regressions pass; (7) roadmap records R2 evidence and advances truthfully.
- Validation: Extend R1 death-handoff coverage for the new recovery path and retain its ordering/duplicate/context controls. Run `custodian/tools/validation/campaign_outcome_exactly_once_smoke.gd`, `custodian/tools/validation/game_over_flow_smoke.gd`, `custodian/tools/validation/world_simulation_live_scene_smoke.gd`, and the narrow existing level-return tests selected by changed files. Add focused return failure/retry and reintegration tests, then one changed-file closeout. Use Moment Forge only if acceptance adds presentation timing that structured state cannot prove.
- Task overrides: `none`
- Deferred: R3-R8 retain equipment persistence, local recovery infrastructure, capacity/player workflow and convergence ownership.

## Handoff

- Next action: Verify current transition/Hub ownership, implement one transactional Post recovery loop, then author R3 against the resulting persistence surface.
- Blockers or open questions: No user judgment required; choose the existing valid Post/compound entry surface using the active boot/level authority, and document its runtime identity. Do not claim full Campaign Flow architecture completion from this bounded death-return slice.
