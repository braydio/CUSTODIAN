# VAULTWING RUNTIME HARDENING

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vaultwing-runtime-hardening`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `stealth-perception-foundation`
- Locks: `vaultwing-runtime`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `ba04d9e8ee`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6abb151e-693c-83ea-8563-b7cd74c2960b`
- Goal: Harden the remaining Vaultwing runtime ownership seams exposed by the inclusive audit without recreating species-local hearing or changing wild combat/bond balance.
- Completion boundary: This workstream begins after the shared stealth-perception foundation lands. It owns fixed-step bond advancement, bond-transition versus restore reconciliation, allegiance-sensitive damage compatibility output, `hostile_fauna` compatibility cleanup, narrowly proven dead Vaultwing fields, and focused regression coverage. Generic hearing/perception architecture belongs to `stealth-perception-foundation`.
- Current measured state: `VaultwingBondState` advances feed cooldowns/acceptance/trial clocks from `_process(delta)`; BONDED restore currently calls the same `on_bond_completed()` hook as a live first-time transition; `Vaultwing._damage_result()` hard-codes `eligible_hostile=true`; the actor adds `hostile_fauna` at initialization with no corresponding bonded cleanup; fresh search found no live consumer of actor export `attack_damage` and no read of `strike_contact_tested`.
- Evidence: `custodian/game/actors/ambient/vaultwing/vaultwing.gd`; `vaultwing_behavior_controller.gd`; `vaultwing_bond_state.gd`; `vaultwing_behavior_profile.gd`; `custodian/game/actors/core/actor_allegiance_component.gd`; `custodian/game/systems/combat/actor_relationship_resolver.gd`; `vaultwing_runtime_smoke.gd`; `vaultwing_bond_smoke.gd`; `actor_relationship_contract_smoke.gd`.
- Task-specific authority: `design/02_features/ambient/VAULTWING_SYSTEM.md`; `design/02_features/ambient/VAULTWING_SLICE_B_BONDING.md`; `design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md`; `design/02_features/stealth/STEALTH_PERCEPTION_AND_ALARM_SYSTEM.md` for the boundary that hearing is not Vaultwing-owned.
- Work surface: Vaultwing actor/controller/bond-state runtime; focused Vaultwing/relationship validation; consequence-driven active docs only.
- Change: Move bond gameplay clocks to an explicit fixed simulation step owned from the Vaultwing physics spine; preserve current timing within one physics tick. Split live bond completion from restored-BONDED reconciliation so restore cannot replay first-bond side effects. Derive `eligible_hostile` from current allegiance. Remove or synchronize the stale `hostile_fauna` compatibility index. Re-check and remove only still-proven-dead `attack_damage` and `strike_contact_tested` residue.
- Preserve: Wild health/damage/timing; dive/bite contact; seeded movement; feed thresholds/counts; bait IDs; trial timing/distances; same-instance bond lifecycle; spawn/provenance; Asset V2 presentation; current relationship and targetability semantics; shared stealth-perception ownership from the dependency.
- Non-goals: No hearing implementation; no alarm work; no full behavior-controller decomposition; no Slice C commands; no global save orchestration; no bait inventory; no SFX; no art; no corpse/permanent bonded-death policy; no mounting; no ecological response redesign.
- Acceptance: Bond progression and cooldowns mutate only from the fixed simulation tick; existing feed/trial milestones remain equivalent within one physics tick; restoring BONDED state reconciles alliance/hostility without transition-only completion behavior; BONDED damage results are not hostile-eligible while wild hostile results remain eligible; BONDED actors are not semantically indexed as hostile fauna; proven-dead fields are removed without behavior regression; Vaultwing runtime/bond/relationship focused validation remains green.
- Validation: `vaultwing_runtime`; `vaultwing_bond`; `actor_relationship_contract`; `vaultwing_world_spawn` if changed-file ownership reaches spawn compatibility; close once with `python3 custodian/tools/validation/run_validation.py --changed --json`.
- Task overrides: `none`
- Deferred: NPA-8 perception/behavior/combat/presentation decomposition; white-box test seam cleanup; durable rejection of `vaultwing_unassigned` before global save registration; profile-data single-source cleanup; death/corpse policy; production SFX/inventory/global save/Slice C.
## Refresh Planning Authority

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6abb151e-693c-83ea-8563-b7cd74c2960b`
- Refresh instruction: Bring the landed predecessor/review evidence and any material live-main drift back to this conversation. Re-derive the packet here with the user before promoting it to implementation-ready; do not let the execution agent silently reinterpret architecture, scope, sequencing, or acceptance.
