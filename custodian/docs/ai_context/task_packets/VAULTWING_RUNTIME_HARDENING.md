# VAULTWING RUNTIME HARDENING

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vaultwing-runtime-hardening`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `stealth-perception-foundation, review-stealth-perception-foundation`
- Locks: `vaultwing-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-vaultwing-runtime-hardening`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `fixed-step/persistence/relationship ownership hardening; independent review should verify restore semantics and absence of species-local perception regression`
- Reviewed main: `0c80f6a5a1c64168a39b841fa5de362d98728664`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Visual review: `none`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery/closeout summary and final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Harden Vaultwing-local runtime ownership after shared hearing/perception lands, without recreating species-local sensing or redesigning wild combat/bond balance.
- Completion boundary: This slice owns fixed-step bond advancement, restored-BONDED versus live first-bond transition reconciliation, allegiance-sensitive damage compatibility output, `hostile_fauna` compatibility cleanup, still-proven-dead Vaultwing actor/controller fields, and focused regression ownership. Shared acoustic sensing is consumed from the dependency and is not reimplemented here. Broader species/controller decomposition and NPA-8 remain out of scope.
- Current measured state: `VaultwingBondState` advances encounter cooldown, safe feed dwell and bond-trial clocks from `_process(delta)`; `from_save_dict()` restores BONDED allegiance and currently calls the same actor `on_bond_completed()` hook used by a live first-time bond transition; `Vaultwing._damage_result()` still hard-codes `eligible_hostile=true`; `Vaultwing._ready()` adds `hostile_fauna` before allegiance/bond reconciliation; actor export `attack_damage=12` remains present while dive/bite damage live in the behavior profile, and `strike_contact_tested` remains a controller field that prior audit found without a live read. The predecessor packet owns the acoustic consumer seam and must be reviewed complete before this slice starts.
- Evidence: `custodian/game/actors/ambient/vaultwing/vaultwing.gd`; `vaultwing_behavior_controller.gd`; `vaultwing_bond_state.gd`; `vaultwing_behavior_profile.gd`; `design/02_features/ambient/VAULTWING_SYSTEM.md`; `design/02_features/ambient/VAULTWING_SLICE_B_BONDING.md`; `design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md`; `design/04_architecture/ACTOR_RELATIONSHIP_AND_TARGETABILITY.md`; reviewed predecessor stealth packet/receipt; `vaultwing_runtime`, `vaultwing_bond`, `actor_relationship_contract` and world-spawn validation.
- Task-specific authority: Vaultwing design/bonding docs own wild/bond behavior; the NPA actor-facet architecture owns boundaries; actor relationship authority owns allegiance/targetability; the reviewed stealth-perception dependency owns hearing/observation semantics.
- Work surface: Vaultwing actor, behavior controller only where proven residue remains, bond-state fixed-step/restore seam, focused relationship/runtime/bond/world-spawn validation and validation-manifest ownership, consequence-driven active docs only.
- Change: Replace bond-state gameplay mutation from `_process` with an explicit fixed simulation step called from the Vaultwing physics spine at the same gameplay cadence; preserve durations within one physics tick. Split live first-time bond completion effects from restore reconciliation so loading BONDED restores durable stage/allegiance/hostility/presentation-safe state without replaying transition-only logs/signals/greeting/approach side effects. Derive combat compatibility output `eligible_hostile` from current semantic relationship/allegiance instead of hard-coding true. Keep the legacy `hostile_fauna` group only as a synchronized compatibility index if a live consumer still requires it; otherwise remove it and prove semantic consumers use the resolver. Re-search and remove `attack_damage`, `strike_contact_tested`, or other named audit residue only when current-main callsites prove them dead; do not broaden into controller refactoring.
- Preserve: Wild max health/current combat damage/timing; dive/bite contact behavior and deterministic seeded movement; species profile values; feed thresholds/counts; accepted bait IDs; trial radii/timing; same-instance bond lifecycle; stable creature ID/provenance; Asset V2 presentation; targetability rules including HIGH flight; reviewed shared perception behavior; no change to future commands/mounting.
- Non-goals: No hearing/acoustic implementation; no alarm work; no full behavior-controller decomposition; no Slice-C companion commands; no global save orchestration; no bait inventory; no SFX/art; no corpse/permanent bonded-death policy; no ecological redesign; no NPA-8 cross-family convergence.
- Acceptance: (1) bond cooldown/feed/trial gameplay clocks mutate only from the fixed simulation tick; (2) current timing stays equivalent within one physics tick; (3) live first bond still performs its current transition semantics exactly once; (4) restoring an already-BONDED save restores stage, durable bond values, health, stable ID, allegiance/hostility and safe runtime state without replaying first-bond-only transition effects; (5) BONDED/operator-allied damage results are not hostile-eligible while wild hostile results remain eligible; (6) semantic hostile discovery/target qualification does not depend on stale `hostile_fauna` membership, and any retained group is synchronized compatibility only; (7) only currently proven-dead fields are removed; (8) reviewed shared perception remains the only acoustic owner and Vaultwing adds no replacement hearing math; (9) Vaultwing runtime/bond/relationship focused tests remain deterministic.
- Validation: Run `vaultwing_bond` first with explicit fixed-tick progression and live-bond-vs-restore negative controls. Run `vaultwing_runtime`, `actor_relationship_contract`, and `vaultwing_world_spawn` when changed ownership reaches spawn/group compatibility. Re-run the predecessor acoustic contract as a regression to prove no hearing path returned. Register/narrow manifest ownership if moving clocks or deleting fields changes test selection. Finish with `python3 custodian/tools/validation/run_validation.py --changed --json` and `git diff --check`.
- Task overrides: `none`
- Deferred: NPA-8 perception/behavior/combat/presentation/facet convergence; companion command policy; durable world-simulation/reification integration; global persistence ownership; corpse/permanent bonded-death policy; production SFX/inventory; broader profile single-source cleanup.

## Handoff

- Next workstream: `review-vaultwing-runtime-hardening`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh reason: `none`
- Next action: After implementation lands, continue autonomously into the fresh-context paired review.
- Blockers or open questions: `none`
